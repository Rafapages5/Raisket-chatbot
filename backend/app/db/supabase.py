from supabase import create_client, Client
from app.core.config import settings


class SupabaseClient:
    """Singleton Supabase client."""

    _instance: Client | None = None

    @classmethod
    def get_client(cls) -> Client:
        """Get or create Supabase client instance."""
        if cls._instance is None:
            cls._instance = create_client(
                supabase_url=settings.SUPABASE_URL,
                supabase_key=settings.SUPABASE_KEY,
            )
        return cls._instance

    @classmethod
    def get_admin_client(cls) -> Client:
        """Get Supabase client with service role (admin privileges)."""
        return create_client(
            supabase_url=settings.SUPABASE_URL,
            supabase_key=settings.SUPABASE_SERVICE_KEY,
        )


def get_supabase() -> Client:
    """Dependency injection for Supabase client."""
    return SupabaseClient.get_client()
