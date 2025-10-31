from fastapi import APIRouter
from app.models.schemas import HealthCheck
from app.core.config import settings

router = APIRouter()


@router.get("/health", response_model=HealthCheck)
async def health_check() -> HealthCheck:
    """
    Health check endpoint.

    Returns:
        HealthCheck with status, version, and environment
    """
    return HealthCheck(
        status="healthy",
        version="0.1.0",
        environment=settings.ENVIRONMENT,
    )


@router.get("/ping")
async def ping() -> dict:
    """Simple ping endpoint."""
    return {"message": "pong"}
