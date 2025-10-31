# 🚀 Raisket - AI Financial Advisor for Mexico

**AI-powered financial advisor built specifically for the Mexican market.**

Built with FastAPI, Next.js, LangChain, Supabase, and Qdrant. Ready for MVP in 30 days.

---

## 📋 Table of Contents

- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [Development](#-development)
- [Deployment](#-deployment)
- [Cost Breakdown](#-cost-breakdown)
- [30-Day Roadmap](#-30-day-roadmap)

---

## 🛠 Tech Stack

### Backend
- **FastAPI** - Modern async Python framework
- **LangChain** - AI orchestration and RAG
- **Anthropic Claude 3.5 Sonnet** - Language model (superior reasoning for financial advice)
- **HuggingFace Embeddings** - Free, high-quality embeddings (BAAI/bge-small-en-v1.5)
- **Qdrant** - Vector database for embeddings
- **Supabase** - Auth + PostgreSQL database

### Frontend
- **Next.js 15** - React framework with App Router
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Shadcn/ui** - UI components (ready to add)

### Infrastructure
- **Docker** - Containerization
- **Railway/Vercel** - Deployment (recommended)
- **Redis** - Caching (optional)

---

## 📁 Project Structure

```
raisket/
├── backend/                  # FastAPI application
│   ├── app/
│   │   ├── api/v1/          # API routes
│   │   │   ├── chat.py      # Chat endpoints
│   │   │   └── health.py    # Health checks
│   │   ├── core/            # Config & settings
│   │   ├── db/              # Database clients
│   │   ├── models/          # Pydantic schemas
│   │   ├── services/        # Business logic
│   │   │   ├── chat_service.py
│   │   │   └── vector_store.py
│   │   └── main.py          # FastAPI app
│   ├── pyproject.toml       # Python dependencies
│   ├── Dockerfile
│   └── README.md
│
├── frontend/                 # Next.js application
│   ├── app/                 # App Router
│   │   ├── page.tsx         # Landing page
│   │   ├── chat/            # Chat interface
│   │   ├── dashboard/       # User dashboard
│   │   └── layout.tsx
│   ├── components/          # React components
│   │   ├── ui/             # Shadcn components
│   │   ├── chat/           # Chat components
│   │   └── layout/         # Layout components
│   ├── lib/                # Utilities
│   │   ├── api.ts          # API client
│   │   ├── supabase.ts     # Supabase client
│   │   └── utils.ts        # Helpers
│   ├── package.json
│   └── next.config.ts
│
├── docker-compose.yml       # Local development stack
├── .env.example            # Environment template
└── README.md               # This file
```

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.11+** ([download](https://www.python.org/downloads/))
- **Node.js 18+** ([download](https://nodejs.org/))
- **Poetry** (Python package manager): `pip install poetry`
- **Docker** (optional, for local services)
- **Supabase account** ([signup](https://supabase.com))
- **OpenAI API key** ([get key](https://platform.openai.com/api-keys))

### 1. Clone and Setup

```bash
# Clone the repository (if using git)
git clone <your-repo-url>
cd raisket

# Copy environment variables
cp .env.example .env
# Edit .env with your credentials
```

### 2. Setup Backend

```bash
cd backend

# Install dependencies
poetry install

# Copy and configure environment
cp .env.example .env
# Edit .env with your keys

# Run locally (without Docker)
poetry run uvicorn app.main:app --reload --port 8000
```

**Backend will be available at:** http://localhost:8000
**API Docs:** http://localhost:8000/api/v1/docs

### 3. Setup Frontend

```bash
cd frontend

# Install dependencies
npm install

# Copy and configure environment
cp .env.local.example .env.local
# Edit .env.local with your keys

# Run development server
npm run dev
```

**Frontend will be available at:** http://localhost:3000

### 4. Start Supporting Services (Docker)

```bash
# From the root directory
docker-compose up -d

# This starts:
# - Qdrant (vector database) on port 6333
# - Redis (caching) on port 6379
```

---

## 🔧 Development

### Backend Development

```bash
cd backend

# Run with auto-reload
poetry run uvicorn app.main:app --reload

# Run tests
poetry run pytest

# Format code
poetry run black .
poetry run ruff check .

# Type check
poetry run mypy .
```

### Frontend Development

```bash
cd frontend

# Development server with Turbopack
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Lint
npm run lint

# Type check
npm run type-check
```

### Full Stack Development

**Terminal 1 (Backend):**
```bash
cd backend
poetry run uvicorn app.main:app --reload
```

**Terminal 2 (Frontend):**
```bash
cd frontend
npm run dev
```

**Terminal 3 (Services):**
```bash
docker-compose up
```

---

## 🗄 Supabase Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Note your project URL and API keys

### 2. Create Database Tables

Run this SQL in Supabase SQL Editor:

```sql
-- Profiles table (extends auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Conversations table
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own conversations"
  ON public.conversations FOR SELECT
  USING (auth.uid() = user_id);

-- Messages table
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read messages from own conversations"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE conversations.id = messages.conversation_id
        AND conversations.user_id = auth.uid()
    )
  );

-- Financial profiles table
CREATE TABLE public.financial_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  monthly_income DECIMAL(10,2),
  monthly_expenses DECIMAL(10,2),
  savings DECIMAL(10,2),
  debt DECIMAL(10,2),
  risk_tolerance TEXT CHECK (risk_tolerance IN ('conservative', 'moderate', 'aggressive')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.financial_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own financial profile"
  ON public.financial_profiles FOR ALL
  USING (auth.uid() = user_id);

-- Enable pgvector extension for vector search (optional alternative to Qdrant)
CREATE EXTENSION IF NOT EXISTS vector;

-- Documents table with embeddings
CREATE TABLE public.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  content TEXT NOT NULL,
  metadata JSONB,
  embedding vector(1536),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own documents"
  ON public.documents FOR ALL
  USING (auth.uid() = user_id);

-- Create index for vector similarity search
CREATE INDEX ON public.documents USING ivfflat (embedding vector_cosine_ops);
```

### 3. Configure Auth

In Supabase Dashboard:
1. Go to **Authentication > Settings**
2. Enable **Email** auth
3. (Optional) Enable **Google OAuth**
4. Set **Site URL** to your frontend URL

---

## 🚢 Deployment

### Backend Deployment (Railway)

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Initialize project
cd backend
railway init

# Deploy
railway up

# Add environment variables in Railway dashboard
# Link Qdrant Cloud (see below)
```

### Backend Deployment (Render)

1. Connect your GitHub repo
2. Create new **Web Service**
3. Build command: `pip install poetry && poetry install`
4. Start command: `poetry run uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables

### Frontend Deployment (Vercel)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd frontend
vercel

# Or connect GitHub repo in Vercel dashboard
```

### Qdrant Cloud Setup

1. Go to [cloud.qdrant.io](https://cloud.qdrant.io)
2. Create free cluster
3. Copy cluster URL and API key
4. Update `QDRANT_URL` and `QDRANT_API_KEY` in backend env

---

## 💰 Cost Breakdown

### MVP Phase (Month 1)

| Service | Cost | Notes |
|---------|------|-------|
| Supabase | $0 | Free tier (500MB DB, 2GB bandwidth) |
| Qdrant Cloud | $0 | Free tier (1GB vectors) |
| Vercel | $0-20 | Free tier usually sufficient |
| Railway | $5 | Hobby plan for backend |
| OpenAI API | $50-100 | Depends on usage (~1K conversations) |
| **TOTAL** | **$55-125/mo** | ✅ Under $200 budget |

### Growth Phase (1K-10K users)

| Service | Cost | Notes |
|---------|------|-------|
| Supabase | $25 | Pro plan |
| Qdrant Cloud | $50-100 | Paid tier for more vectors |
| Vercel | $20 | Pro plan |
| Railway | $20 | Pro plan |
| OpenAI API | $300-500 | Cache aggressively, optimize prompts |
| **TOTAL** | **$415-665/mo** | Still reasonable at scale |

---

## 📅 30-Day Roadmap

### Week 1: Foundation (Days 1-7)
- [ ] Day 1-2: Setup projects (✅ DONE)
- [ ] Day 3-4: Implement Supabase auth flow
- [ ] Day 5-6: Build basic chat UI with streaming
- [ ] Day 7: Deploy MVP backend + frontend

### Week 2: Core AI (Days 8-14)
- [ ] Day 8-10: Implement RAG with financial documents
- [ ] Day 11-12: Add conversation persistence
- [ ] Day 13-14: Build financial profile onboarding

### Week 3: Features (Days 15-21)
- [ ] Day 15-17: Dashboard with financial charts
- [ ] Day 18-19: Personalized recommendations
- [ ] Day 20-21: Testing + bug fixes

### Week 4: Polish (Days 22-30)
- [ ] Day 22-24: UI/UX improvements
- [ ] Day 25-26: Performance optimization
- [ ] Day 27-28: Analytics + monitoring setup
- [ ] Day 29-30: Demo preparation + docs for fundraising

---

## 🎯 Next Steps

1. **Get API Keys:**
   - OpenAI: https://platform.openai.com/api-keys
   - Supabase: https://supabase.com (create project)
   - Qdrant: https://cloud.qdrant.io (optional, can use local)

2. **Configure Environment:**
   ```bash
   cp .env.example .env
   # Fill in all the values
   ```

3. **Start Development:**
   ```bash
   # Terminal 1: Start services
   docker-compose up -d

   # Terminal 2: Start backend
   cd backend && poetry run uvicorn app.main:app --reload

   # Terminal 3: Start frontend
   cd frontend && npm run dev
   ```

4. **Test the Stack:**
   - Visit http://localhost:3000
   - Try the chat at http://localhost:3000/chat
   - Check API docs at http://localhost:8000/api/v1/docs

5. **Start Building:**
   - Implement auth flow (`/app/auth/page.tsx`)
   - Add financial profile onboarding
   - Build dashboard with charts
   - Implement document upload for RAG

---

## 📚 Resources

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Next.js Docs](https://nextjs.org/docs)
- [LangChain Docs](https://python.langchain.com/)
- [Supabase Docs](https://supabase.com/docs)
- [Qdrant Docs](https://qdrant.tech/documentation/)
- [Shadcn/ui](https://ui.shadcn.com/) - Copy/paste UI components

---

## 🤝 Contributing

This is a solo founder project. If you want to contribute after launch, reach out!

---

## 📄 License

Private project. All rights reserved.

---

## 🆘 Troubleshooting

### Backend won't start
- Check Python version: `python --version` (need 3.11+)
- Reinstall dependencies: `poetry install`
- Check .env file exists with all required vars

### Frontend won't start
- Check Node version: `node --version` (need 18+)
- Delete node_modules and reinstall: `rm -rf node_modules && npm install`
- Check .env.local exists

### Qdrant connection error
- Make sure Docker is running: `docker ps`
- Restart Qdrant: `docker-compose restart qdrant`
- Check QDRANT_URL in backend .env

### OpenAI API errors
- Verify API key is correct
- Check billing at https://platform.openai.com/account/billing
- Watch for rate limits (use caching!)

---

**Built with ❤️ for the Mexican market**

Ready to build your MVP? Let's go! 🚀
