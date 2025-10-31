# 🚀 Raisket

> **AI Financial Advisor for the Mexican Market**

Built with Claude AI, FastAPI, Next.js, and Supabase. Production-ready boilerplate designed for solo founders to ship fast.

[![License: Private](https://img.shields.io/badge/License-Private-red.svg)]()
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green.svg)](https://fastapi.tiangolo.com/)
[![Next.js](https://img.shields.io/badge/Next.js-15.0-black.svg)](https://nextjs.org/)
[![Claude](https://img.shields.io/badge/Claude-3.5%20Sonnet-orange.svg)](https://anthropic.com/)

---

## ✨ Features

- 🤖 **AI-Powered Financial Advice** using Claude 3.5 Sonnet
- 💬 **Real-time Chat Interface** with streaming responses
- 🔍 **RAG (Retrieval-Augmented Generation)** with free HuggingFace embeddings
- 🔐 **Supabase Authentication** ready to implement
- 📊 **PostgreSQL Database** with Row-Level Security
- 🎯 **Vector Search** using Qdrant
- 🐳 **Docker Compose** for local development
- 📱 **Responsive UI** with Tailwind CSS

---

## 🛠 Tech Stack

### Backend
- **[FastAPI](https://fastapi.tiangolo.com/)** - Modern Python async framework
- **[Anthropic Claude 3.5 Sonnet](https://anthropic.com/)** - Superior reasoning for financial analysis
- **[LangChain](https://python.langchain.com/)** - AI orchestration and RAG
- **[Qdrant](https://qdrant.tech/)** - Vector database for semantic search
- **[Supabase](https://supabase.com/)** - Auth + PostgreSQL

### Frontend
- **[Next.js 15](https://nextjs.org/)** - React framework with App Router
- **[TypeScript](https://www.typescriptlang.org/)** - Type safety
- **[Tailwind CSS](https://tailwindcss.com/)** - Utility-first styling
- **[shadcn/ui](https://ui.shadcn.com/)** - Ready to integrate

### Infrastructure
- **Docker & Docker Compose** - Containerization
- **Railway / Vercel** - Deployment (recommended)
- **GitHub Actions** - CI/CD (ready to add)

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- Docker Desktop
- [Anthropic API Key](https://console.anthropic.com/)
- [Supabase Account](https://supabase.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/raisket.git
cd raisket

# Setup environment variables
cp .env.example .env
# Edit .env with your API keys

# Start Docker services
docker-compose up -d

# Install backend dependencies
cd backend
pip install poetry
poetry install

# Install frontend dependencies
cd ../frontend
npm install

# Run backend (terminal 1)
cd backend
poetry run uvicorn app.main:app --reload

# Run frontend (terminal 2)
cd frontend
npm run dev
```

Visit:
- Frontend: http://localhost:3000
- API Docs: http://localhost:8000/api/v1/docs

📖 **Full setup guide:** [QUICKSTART.md](QUICKSTART.md)

---

## 📁 Project Structure

```
raisket/
├── backend/              # FastAPI application
│   ├── app/
│   │   ├── api/v1/      # API endpoints
│   │   ├── core/        # Configuration
│   │   ├── models/      # Pydantic schemas
│   │   └── services/    # Business logic
│   └── pyproject.toml
│
├── frontend/            # Next.js application
│   ├── app/            # App Router pages
│   ├── components/     # React components
│   ├── lib/            # Utilities
│   └── package.json
│
├── docs/               # Database schemas
├── docker-compose.yml
└── README.md
```

---

## 🔑 Environment Variables

### Backend

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
SECRET_KEY=your-secret-key
```

### Frontend

```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

See `.env.example` files for complete reference.

---

## 💰 Cost Breakdown

### MVP Phase (0-1K users)

| Service | Cost |
|---------|------|
| Supabase | $0 (free tier) |
| Qdrant Cloud | $0 (free tier) |
| Vercel | $0 (free tier) |
| Railway | $5 (hobby plan) |
| Claude API | $50-100 |
| **Total** | **$55-105/month** |

### Production Phase (1K-10K users)

| Service | Cost |
|---------|------|
| Supabase | $25 (pro plan) |
| Qdrant | $50-100 |
| Vercel | $20 |
| Railway | $20 |
| Claude API | $200-400 |
| **Total** | **$315-565/month** |

---

## 📚 Documentation

- [📖 Complete Guide](README.md)
- [⚡ Quick Start (15 min)](QUICKSTART.md)
- [🤖 Why Claude vs OpenAI](CLAUDE_VS_OPENAI.md)
- [🎯 Tech Stack Decisions](STACK_DECISIONS.md)
- [📊 Project Summary](PROJECT_SUMMARY.md)
- [🔧 Git Setup](SETUP_GIT.md)

---

## 🎯 Roadmap

### Week 1 (MVP Foundation)
- [x] Backend API with Claude integration
- [x] Frontend with chat interface
- [x] Database schema
- [ ] Authentication implementation
- [ ] Conversation persistence

### Week 2 (Core Features)
- [ ] Financial profile onboarding
- [ ] RAG with user documents
- [ ] Dashboard with analytics
- [ ] Personalized recommendations

### Week 3-4 (Polish & Launch)
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] Testing & bug fixes
- [ ] Production deployment

---

## 🧪 Testing

```bash
# Backend tests
cd backend
poetry run pytest

# Frontend lint
cd frontend
npm run lint

# Type checking
cd frontend
npm run type-check
```

---

## 🚢 Deployment

### Backend (Railway)

```bash
railway login
railway init
railway up
```

### Frontend (Vercel)

```bash
vercel login
vercel
```

See deployment guides in [README.md](README.md) for detailed instructions.

---

## 🤝 Contributing

This is a private project. If you'd like to contribute after launch, please reach out.

---

## 📄 License

Private - All rights reserved

---

## 👨‍💻 Author

**Raisket Team**
- Website: [Coming Soon]
- Twitter: [@raisket_mx]

---

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com/) for Claude AI
- [FastAPI](https://fastapi.tiangolo.com/) community
- [Supabase](https://supabase.com/) team
- [Vercel](https://vercel.com/) for Next.js
- [LangChain](https://langchain.com/) ecosystem

---

## 📊 Project Stats

![Lines of Code](https://img.shields.io/tokei/lines/github/YOUR_USERNAME/raisket)
![Last Commit](https://img.shields.io/github/last-commit/YOUR_USERNAME/raisket)
![Stars](https://img.shields.io/github/stars/YOUR_USERNAME/raisket)

---

**Built with ❤️ for the Mexican market**

*Ready to transform personal finance in Mexico 🇲🇽*
