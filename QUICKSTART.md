# ⚡ Quick Start Guide - Raisket

**Get your MVP running in 15 minutes.**

---

## 📋 Checklist Before Starting

- [ ] Python 3.11+ installed
- [ ] Node.js 18+ installed
- [ ] Poetry installed (`pip install poetry`)
- [ ] Docker installed (optional but recommended)
- [ ] Supabase account created
- [ ] OpenAI API key obtained

---

## 🚀 Step-by-Step Setup

### 1️⃣ Get API Keys (5 min)

#### Anthropic Claude API Key
1. Go to https://console.anthropic.com/settings/keys
2. Click "Create Key"
3. Copy the key (starts with `sk-ant-`)

#### Supabase Setup
1. Go to https://supabase.com
2. Create new project (choose region closest to Mexico: US-East)
3. Wait for project to initialize (~2 minutes)
4. Go to **Settings > API**
5. Copy:
   - Project URL
   - Anon/Public key
   - Service Role key (secret!)

6. Go to **SQL Editor**
7. Copy the entire content from `/docs/supabase-schema.sql`
8. Paste and run it
9. Verify tables were created in **Database > Tables**

### 2️⃣ Configure Environment (3 min)

```bash
# Root directory
cd raisket
cp .env.example .env

# Edit .env with your keys:
# ANTHROPIC_API_KEY=sk-ant-your-key-here
# SUPABASE_URL=https://xxxxx.supabase.co
# SUPABASE_KEY=your-anon-key
# SUPABASE_SERVICE_KEY=your-service-key
# SECRET_KEY=$(openssl rand -hex 32)  # Generate this
```

```bash
# Backend
cd backend
cp .env.example .env
# Copy same values from root .env
```

```bash
# Frontend
cd ../frontend
cp .env.local.example .env.local
# Add:
# NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
# NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
# NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

### 3️⃣ Start Services (2 min)

```bash
# From root directory
docker-compose up -d

# This starts:
# - Qdrant (vector DB) on port 6333
# - Redis (cache) on port 6379

# Verify they're running:
docker ps
```

### 4️⃣ Start Backend (2 min)

```bash
cd backend

# Install dependencies (first time only)
poetry install

# Start server
poetry run uvicorn app.main:app --reload --port 8000

# You should see:
# INFO:     Uvicorn running on http://127.0.0.1:8000
# INFO:     Application startup complete
```

**Test it:** Open http://localhost:8000/api/v1/docs

### 5️⃣ Start Frontend (3 min)

Open a new terminal:

```bash
cd frontend

# Install dependencies (first time only)
npm install

# Start development server
npm run dev

# You should see:
# ▲ Next.js 15.0.0
# - Local:        http://localhost:3000
```

**Test it:** Open http://localhost:3000

---

## ✅ Verify Everything Works

### 1. Check Landing Page
- Go to http://localhost:3000
- You should see the Raisket landing page

### 2. Check API Health
- Go to http://localhost:8000/api/v1/health
- Should return: `{"status":"healthy",...}`

### 3. Test Chat (Basic)
- Go to http://localhost:3000/chat
- Type a message
- You should get a response from the AI

### 4. Check API Docs
- Go to http://localhost:8000/api/v1/docs
- You should see interactive API documentation

---

## 🎯 What You Have Now

✅ **Backend API** running with:
- FastAPI with auto-reload
- LangChain + OpenAI integration
- Qdrant vector database
- Supabase connection
- API documentation

✅ **Frontend** running with:
- Next.js 15 with App Router
- TypeScript + Tailwind CSS
- Basic chat interface
- Supabase auth ready

✅ **Database** ready with:
- User profiles
- Conversations & messages
- Financial profiles
- Document storage with embeddings
- Row-level security enabled

---

## 🏗️ Next Steps - Week 1 Tasks

### Day 1-2: Authentication
```bash
cd frontend/app
# Create auth pages:
# - app/auth/page.tsx (login/signup)
# - Add Supabase auth hooks
# - Protected routes middleware
```

**Resources:**
- Supabase Auth Docs: https://supabase.com/docs/guides/auth
- Next.js Auth: https://supabase.com/docs/guides/auth/server-side/nextjs

### Day 3-4: Improve Chat
```bash
cd frontend/app/chat
# Enhancements:
# - Add streaming responses
# - Save conversations to Supabase
# - Load conversation history
# - Add sources display
```

### Day 5-6: Financial Onboarding
```bash
cd frontend/app
# Create:
# - app/onboarding/page.tsx
# - Multi-step form for financial profile
# - Save to Supabase financial_profiles table
```

### Day 7: Deploy MVP
```bash
# Backend to Railway:
railway login
railway init
railway up

# Frontend to Vercel:
vercel login
vercel

# Update environment variables in both platforms
```

---

## 🔧 Development Commands

### Backend
```bash
cd backend

# Start with auto-reload
poetry run uvicorn app.main:app --reload

# Run tests
poetry run pytest

# Format code
poetry run black .

# Type check
poetry run mypy .
```

### Frontend
```bash
cd frontend

# Development
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Lint
npm run lint
```

### Services
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Restart a service
docker-compose restart qdrant
```

---

## 🐛 Common Issues

### Backend won't start

**Error: `ModuleNotFoundError: No module named 'app'`**
```bash
cd backend
poetry install
```

**Error: `OPENAI_API_KEY not found`**
```bash
# Make sure .env exists in backend/ directory
cd backend
cat .env  # Should show your keys
```

### Frontend won't start

**Error: `Cannot find module 'next'`**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**Error: `NEXT_PUBLIC_SUPABASE_URL is not defined`**
```bash
# Make sure .env.local exists in frontend/ directory
cd frontend
cat .env.local  # Should show your keys
```

### Docker services won't start

```bash
# Check if Docker is running
docker ps

# If not, start Docker Desktop

# Restart services
docker-compose down
docker-compose up -d
```

### Chat not working

1. **Check backend is running:**
   ```bash
   curl http://localhost:8000/api/v1/health
   ```

2. **Check Qdrant is running:**
   ```bash
   curl http://localhost:6333/collections
   ```

3. **Check browser console** for errors (F12)

4. **Verify API URL** in frontend/.env.local:
   ```
   NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
   ```

---

## 📊 Testing the AI Features

### 1. Test Basic Chat
```bash
# Send a test request to the API
curl -X POST http://localhost:8000/api/v1/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "¿Qué son los CETES?",
    "user_id": "test-user"
  }'
```

### 2. Test Vector Search
```python
# In backend directory, start Python shell:
poetry run python

# Test vector store:
from app.services.vector_store import vector_store_service
from langchain.schema import Document

# Add a test document
import asyncio
doc = Document(page_content="Los CETES son inversiones seguras del gobierno mexicano")
asyncio.run(vector_store_service.add_documents([doc], "test-user"))

# Search
results = asyncio.run(vector_store_service.similarity_search("inversiones seguras", user_id="test-user"))
print(results)
```

### 3. Test Supabase Connection
```bash
# Visit your Supabase project:
# https://supabase.com/dashboard/project/YOUR_PROJECT_ID

# Go to Table Editor
# You should see all your tables:
# - profiles
# - conversations
# - messages
# - financial_profiles
# - documents
# - recommendations
```

---

## 🎓 Learning Resources

### FastAPI + LangChain
- Official FastAPI tutorial: https://fastapi.tiangolo.com/tutorial/
- LangChain quickstart: https://python.langchain.com/docs/get_started/quickstart
- RAG tutorial: https://python.langchain.com/docs/tutorials/rag/

### Next.js + Supabase
- Next.js App Router: https://nextjs.org/docs/app
- Supabase + Next.js guide: https://supabase.com/docs/guides/getting-started/quickstarts/nextjs
- Server Components: https://nextjs.org/docs/app/building-your-application/rendering/server-components

### UI Components
- Shadcn/ui: https://ui.shadcn.com/
- Tailwind CSS: https://tailwindcss.com/docs
- Lucide Icons: https://lucide.dev/

---

## 💡 Pro Tips

1. **Keep services running in separate terminals** - easier to see logs
2. **Use the API docs** (http://localhost:8000/api/v1/docs) to test endpoints
3. **Check Supabase logs** in dashboard for auth issues
4. **Use browser DevTools** (F12) to debug frontend issues
5. **Start with simple features** - don't over-engineer the MVP

---

## 🆘 Need Help?

1. Check the main [README.md](README.md) for detailed docs
2. Review [backend/README.md](backend/README.md) for API specifics
3. Check Docker logs: `docker-compose logs -f`
4. Check backend logs in your terminal
5. Check frontend console (F12 in browser)

---

**You're ready to build! 🚀**

Start with authentication, then build the core chat experience. Focus on making something users can interact with in the first week.

Remember: **Shipped is better than perfect.** Get it working, get feedback, iterate.

Good luck with your MVP! 💪
