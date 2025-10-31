# Raisket Backend API

AI Financial Advisor API for Mexico built with FastAPI, LangChain, and Supabase.

## Features

- FastAPI with async support
- LangChain integration for AI conversations
- Qdrant vector database for RAG
- Supabase for authentication and data storage
- OpenAI GPT-4 integration
- Streaming responses
- CORS enabled for frontend integration

## Prerequisites

- Python 3.11+
- Poetry (Python package manager)
- Qdrant (vector database) - optional for local dev
- Supabase account
- OpenAI API key

## Quick Start

### 1. Install dependencies

```bash
poetry install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your credentials:
- `OPENAI_API_KEY`: Your OpenAI API key
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase anon key
- `SUPABASE_SERVICE_KEY`: Your Supabase service role key
- `SECRET_KEY`: Generate with `openssl rand -hex 32`

### 3. Run locally

```bash
poetry run uvicorn app.main:app --reload --port 8000
```

API will be available at: http://localhost:8000

Documentation: http://localhost:8000/api/v1/docs

### 4. Run with Docker

```bash
docker build -t raisket-backend .
docker run -p 8000:8000 --env-file .env raisket-backend
```

## Project Structure

```
backend/
├── app/
│   ├── api/
│   │   └── v1/          # API endpoints
│   │       ├── chat.py   # Chat/AI endpoints
│   │       └── health.py # Health check
│   ├── core/            # Core configuration
│   │   └── config.py    # Settings management
│   ├── db/              # Database clients
│   │   └── supabase.py  # Supabase client
│   ├── models/          # Pydantic models
│   │   └── schemas.py   # Request/response schemas
│   ├── services/        # Business logic
│   │   ├── chat_service.py    # AI chat logic
│   │   └── vector_store.py    # Vector DB operations
│   └── main.py          # FastAPI application
├── pyproject.toml       # Dependencies
├── Dockerfile           # Docker configuration
└── .env.example         # Environment template
```

## API Endpoints

### Health
- `GET /api/v1/health` - Health check
- `GET /api/v1/ping` - Simple ping

### Chat
- `POST /api/v1/ai/chat` - Send chat message
- `POST /api/v1/ai/chat/stream` - Stream chat response
- `GET /api/v1/ai/conversations/{id}` - Get conversation history

## Development

### Run tests
```bash
poetry run pytest
```

### Format code
```bash
poetry run black .
poetry run ruff check .
```

### Type checking
```bash
poetry run mypy .
```

## Deployment

### Railway

1. Install Railway CLI:
```bash
npm i -g @railway/cli
```

2. Login and deploy:
```bash
railway login
railway init
railway up
```

3. Add environment variables in Railway dashboard

### Render

1. Create new Web Service
2. Connect your GitHub repo
3. Set build command: `pip install poetry && poetry install`
4. Set start command: `poetry run uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key | Yes |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_KEY` | Supabase anon key | Yes |
| `SUPABASE_SERVICE_KEY` | Supabase service role key | Yes |
| `SECRET_KEY` | JWT secret key | Yes |
| `QDRANT_URL` | Qdrant instance URL | No (defaults to localhost) |
| `QDRANT_API_KEY` | Qdrant API key | No |
| `REDIS_URL` | Redis URL for caching | No |

## Next Steps

1. Set up Supabase tables (see `/docs/supabase-schema.sql`)
2. Implement authentication middleware
3. Add conversation persistence to Supabase
4. Implement financial analysis endpoints
5. Add document processing for financial statements
6. Set up monitoring and logging

## Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [LangChain Documentation](https://python.langchain.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
