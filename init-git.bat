@echo off
echo.
echo ================================================
echo  Inicializando Git Repository para Raisket
echo ================================================
echo.

cd /d "D:\Users\rafael.rivas\raisket"

echo [1/5] Inicializando Git...
git init

echo.
echo [2/5] Agregando todos los archivos...
git add .

echo.
echo [3/5] Creando primer commit...
git commit -m "Initial commit: Raisket MVP boilerplate with Claude AI

- FastAPI backend with Claude 3.5 Sonnet
- Next.js 15 frontend with TypeScript
- Supabase integration (auth + database)
- Qdrant vector database for RAG
- Free HuggingFace embeddings
- Docker Compose for local development
- Complete documentation and 30-day roadmap"

echo.
echo ================================================
echo  Git Inicializado Exitosamente!
echo ================================================
echo.
echo Proximos pasos:
echo.
echo 1. Crea un repositorio en GitHub:
echo    https://github.com/new
echo.
echo 2. Conecta este repositorio:
echo    git remote add origin https://github.com/TU_USUARIO/raisket.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo 3. O usa el script: push-to-github.bat
echo.
pause
