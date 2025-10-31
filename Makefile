.PHONY: help install dev-backend dev-frontend dev-services dev stop clean test lint format

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Raisket - Development Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Install all dependencies
	@echo "$(BLUE)Installing backend dependencies...$(NC)"
	cd backend && poetry install
	@echo "$(BLUE)Installing frontend dependencies...$(NC)"
	cd frontend && npm install
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

setup: ## Initial setup (copy env files, install deps)
	@echo "$(BLUE)Setting up project...$(NC)"
	cp -n .env.example .env || true
	cd backend && cp -n .env.example .env || true
	cd frontend && cp -n .env.local.example .env.local || true
	@make install
	@echo "$(GREEN)✓ Setup complete! Edit .env files with your credentials$(NC)"

dev-services: ## Start supporting services (Qdrant, Redis)
	@echo "$(BLUE)Starting services...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Services started$(NC)"

dev-backend: ## Start backend API in development mode
	@echo "$(BLUE)Starting backend API...$(NC)"
	cd backend && poetry run uvicorn app.main:app --reload --port 8000

dev-frontend: ## Start frontend in development mode
	@echo "$(BLUE)Starting frontend...$(NC)"
	cd frontend && npm run dev

dev: ## Start all services (run in separate terminals)
	@echo "$(BLUE)Starting full development environment...$(NC)"
	@echo "Run these commands in separate terminals:"
	@echo "  1. make dev-services"
	@echo "  2. make dev-backend"
	@echo "  3. make dev-frontend"

stop: ## Stop all services
	@echo "$(BLUE)Stopping services...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

clean: ## Clean up (remove node_modules, caches, etc.)
	@echo "$(BLUE)Cleaning up...$(NC)"
	rm -rf frontend/node_modules
	rm -rf frontend/.next
	rm -rf backend/.pytest_cache
	rm -rf backend/__pycache__
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

test-backend: ## Run backend tests
	@echo "$(BLUE)Running backend tests...$(NC)"
	cd backend && poetry run pytest

test-frontend: ## Run frontend tests
	@echo "$(BLUE)Running frontend tests...$(NC)"
	cd frontend && npm test

test: test-backend test-frontend ## Run all tests

lint-backend: ## Lint backend code
	@echo "$(BLUE)Linting backend...$(NC)"
	cd backend && poetry run ruff check .

lint-frontend: ## Lint frontend code
	@echo "$(BLUE)Linting frontend...$(NC)"
	cd frontend && npm run lint

lint: lint-backend lint-frontend ## Lint all code

format-backend: ## Format backend code
	@echo "$(BLUE)Formatting backend...$(NC)"
	cd backend && poetry run black .

format-frontend: ## Format frontend code
	@echo "$(BLUE)Formatting frontend...$(NC)"
	cd frontend && npm run prettier --write .

format: format-backend ## Format all code

type-check-backend: ## Type check backend
	@echo "$(BLUE)Type checking backend...$(NC)"
	cd backend && poetry run mypy .

type-check-frontend: ## Type check frontend
	@echo "$(BLUE)Type checking frontend...$(NC)"
	cd frontend && npm run type-check

type-check: type-check-backend type-check-frontend ## Type check all code

build-backend: ## Build backend Docker image
	@echo "$(BLUE)Building backend image...$(NC)"
	docker build -t raisket-backend ./backend

build-frontend: ## Build frontend for production
	@echo "$(BLUE)Building frontend...$(NC)"
	cd frontend && npm run build

build: build-backend build-frontend ## Build all for production

logs-services: ## View Docker services logs
	docker-compose logs -f

logs-backend: ## View backend logs (if running in background)
	tail -f backend/app.log 2>/dev/null || echo "No backend log file found"

health-check: ## Check if all services are running
	@echo "$(BLUE)Checking services...$(NC)"
	@curl -s http://localhost:8000/api/v1/health > /dev/null && echo "$(GREEN)✓ Backend API is running$(NC)" || echo "✗ Backend API is not running"
	@curl -s http://localhost:3000 > /dev/null && echo "$(GREEN)✓ Frontend is running$(NC)" || echo "✗ Frontend is not running"
	@curl -s http://localhost:6333/collections > /dev/null && echo "$(GREEN)✓ Qdrant is running$(NC)" || echo "✗ Qdrant is not running"
	@docker exec raisket-redis-1 redis-cli ping > /dev/null 2>&1 && echo "$(GREEN)✓ Redis is running$(NC)" || echo "✗ Redis is not running"

db-migrate: ## Run database migrations (Supabase)
	@echo "$(BLUE)Apply migrations in Supabase dashboard manually$(NC)"
	@echo "Copy content from docs/supabase-schema.sql"

quick-start: setup dev-services ## Quick start (setup + start services)
	@echo "$(GREEN)✓ Quick start complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit .env files with your API keys"
	@echo "  2. Run: make dev-backend  (in terminal 1)"
	@echo "  3. Run: make dev-frontend (in terminal 2)"
