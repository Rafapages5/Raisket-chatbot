from typing import List, Dict, Any
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_qdrant import QdrantVectorStore
from langchain.schema import Document
from app.core.config import settings
import uuid


class VectorStoreService:
    """Service for managing vector embeddings and similarity search."""

    def __init__(self) -> None:
        self.client = QdrantClient(
            url=settings.QDRANT_URL,
            api_key=settings.QDRANT_API_KEY,
        )

        # Using free HuggingFace embeddings (sentence-transformers)
        # BAAI/bge-small-en-v1.5: 384 dimensions, free, excellent quality
        # Alternative: Use Voyage AI if you have VOYAGE_API_KEY for 1024 dimensions
        self.embeddings = HuggingFaceEmbeddings(
            model_name="BAAI/bge-small-en-v1.5",
            model_kwargs={"device": "cpu"},
            encode_kwargs={"normalize_embeddings": True}
        )

        self.collection_name = settings.QDRANT_COLLECTION_NAME
        self.vector_size = 384  # Size for bge-small-en-v1.5
        self._ensure_collection()

    def _ensure_collection(self) -> None:
        """Create collection if it doesn't exist."""
        try:
            self.client.get_collection(self.collection_name)
        except Exception:
            # Collection doesn't exist, create it
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=self.vector_size, distance=Distance.COSINE),
            )

    async def add_documents(
        self, documents: List[Document], user_id: str | None = None
    ) -> List[str]:
        """Add documents to vector store."""
        vector_store = QdrantVectorStore(
            client=self.client,
            collection_name=self.collection_name,
            embedding=self.embeddings,
        )

        # Add metadata
        for doc in documents:
            if user_id:
                doc.metadata["user_id"] = user_id
            doc.metadata["id"] = str(uuid.uuid4())

        ids = await vector_store.aadd_documents(documents)
        return ids

    async def similarity_search(
        self, query: str, k: int = 5, user_id: str | None = None
    ) -> List[Document]:
        """Search for similar documents."""
        vector_store = QdrantVectorStore(
            client=self.client,
            collection_name=self.collection_name,
            embedding=self.embeddings,
        )

        # Build filter if user_id provided
        search_kwargs: Dict[str, Any] = {"k": k}
        if user_id:
            search_kwargs["filter"] = {"user_id": user_id}

        results = await vector_store.asimilarity_search(query, **search_kwargs)
        return results

    async def delete_user_documents(self, user_id: str) -> None:
        """Delete all documents for a user."""
        self.client.delete(
            collection_name=self.collection_name,
            points_selector={"filter": {"must": [{"key": "user_id", "match": {"value": user_id}}]}},
        )


# Singleton instance
vector_store_service = VectorStoreService()
