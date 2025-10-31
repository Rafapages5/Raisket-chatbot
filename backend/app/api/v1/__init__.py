from fastapi import APIRouter
from .chat import router as chat_router
from .health import router as health_router

api_router = APIRouter()

api_router.include_router(health_router, tags=["health"])
api_router.include_router(chat_router, prefix="/ai", tags=["chat"])

__all__ = ["api_router"]
