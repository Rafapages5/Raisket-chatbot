# 🚀 Setup Git Repository para Raisket

## Pasos para Subir a GitHub

### 1. Inicializar Git Localmente

```bash
cd D:\Users\rafael.rivas\raisket

# Inicializar repositorio
git init

# Agregar todos los archivos
git add .

# Primer commit
git commit -m "Initial commit: Raisket MVP boilerplate with Claude AI

- FastAPI backend with Claude 3.5 Sonnet
- Next.js 15 frontend with TypeScript
- Supabase integration (auth + database)
- Qdrant vector database for RAG
- Free HuggingFace embeddings
- Docker Compose for local development
- Complete documentation and 30-day roadmap"
```

### 2. Crear Repositorio en GitHub

**Opción A: Desde la Web (Recomendado)**
1. Ve a: https://github.com/new
2. Repository name: `raisket`
3. Description: `AI Financial Advisor for Mexico - Built with Claude, FastAPI & Next.js`
4. **Important:** ❌ NO marques "Initialize this repository with a README"
5. Click "Create repository"

**Opción B: Con GitHub CLI**
```bash
# Si tienes gh CLI instalado
gh repo create raisket --private --source=. --remote=origin
```

### 3. Conectar y Subir

```bash
# Agregar remote (reemplaza TU_USUARIO con tu username de GitHub)
git remote add origin https://github.com/TU_USUARIO/raisket.git

# Subir a GitHub
git branch -M main
git push -u origin main
```

### 4. Verificar Archivos Sensibles NO se Subieron

Revisa que estos archivos estén en `.gitignore` (✅ ya están):
- `.env`
- `.env.local`
- `node_modules/`
- `__pycache__/`
- `.venv/`

```bash
# Verificar que .gitignore funciona
git status

# NO deberías ver archivos .env o node_modules
```

---

## 📁 Estructura del Repositorio

Tu repositorio incluirá:

```
raisket/
├── backend/              ← FastAPI + Claude + LangChain
├── frontend/             ← Next.js 15 + TypeScript
├── docs/                 ← Database schemas
├── docker-compose.yml
├── README.md
├── QUICKSTART.md
├── CLAUDE_VS_OPENAI.md
├── STACK_DECISIONS.md
├── PROJECT_SUMMARY.md
├── .gitignore
└── .env.example         ← Template (sin secrets)
```

**NO incluirá:**
- ❌ `.env` (secrets)
- ❌ `node_modules/`
- ❌ `.venv/`
- ❌ `__pycache__/`

---

## 🔐 Secrets en GitHub (Para CI/CD Futuro)

Cuando quieras deploy automático, agrega secrets:

1. Ve a: Settings > Secrets and variables > Actions
2. New repository secret
3. Agrega:
   - `ANTHROPIC_API_KEY`
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `SUPABASE_SERVICE_KEY`

---

## 📝 Comandos Git Útiles

```bash
# Ver estado
git status

# Ver diferencias
git diff

# Agregar cambios específicos
git add backend/app/services/

# Commit con mensaje detallado
git commit -m "Feature: Add user authentication"

# Push
git push

# Ver historial
git log --oneline

# Crear branch para feature
git checkout -b feature/dashboard
```

---

## 🌿 Estrategia de Branches (Recomendada)

```
main          ← Producción (protegida)
  ├── develop ← Desarrollo activo
  │   ├── feature/auth
  │   ├── feature/chat
  │   └── feature/dashboard
```

**Setup:**
```bash
# Crear branch develop
git checkout -b develop
git push -u origin develop

# Para cada feature
git checkout develop
git checkout -b feature/nombre-feature
# ... hacer cambios ...
git push -u origin feature/nombre-feature
# Crear Pull Request en GitHub
```

---

## 📋 Ejemplo de .github/workflows (CI/CD Futuro)

Crea `.github/workflows/test.yml` cuando quieras CI:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd backend
          pip install poetry
          poetry install
      - name: Run tests
        run: cd backend && poetry run pytest

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: cd frontend && npm install
      - name: Lint
        run: cd frontend && npm run lint
```

---

## 🏷️ Tags para Releases

```bash
# Cuando llegues a MVP
git tag -a v0.1.0 -m "MVP Release - Basic chat + auth"
git push origin v0.1.0

# Cuando lances
git tag -a v1.0.0 -m "Production Release - Full financial advisor"
git push origin v1.0.0
```

---

## ✅ Checklist Pre-Push

Antes de cada push importante:

- [ ] Corre `git status` para ver qué subes
- [ ] Revisa que NO haya `.env` o secrets
- [ ] README.md está actualizado
- [ ] Tests pasan (cuando los tengas)
- [ ] Código está formateado
- [ ] Commit message es descriptivo

---

## 🎯 Siguiente Paso

```bash
# 1. Inicializa Git
cd D:\Users\rafael.rivas\raisket
git init
git add .
git commit -m "Initial commit: Raisket MVP boilerplate"

# 2. Crea repo en GitHub
# Ve a: https://github.com/new

# 3. Conecta y sube
git remote add origin https://github.com/TU_USUARIO/raisket.git
git push -u origin main
```

**¡Listo para GitHub! 🚀**
