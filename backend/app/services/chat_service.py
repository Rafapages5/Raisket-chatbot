from typing import List, AsyncGenerator
from langchain_anthropic import ChatAnthropic
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.schema import HumanMessage, AIMessage, SystemMessage
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory
from app.core.config import settings
from app.services.vector_store import vector_store_service
from app.models.schemas import ChatMessage, ChatResponse
import json


class ChatService:
    """Service for AI chat interactions using Claude."""

    def __init__(self) -> None:
        self.llm = ChatAnthropic(
            model=settings.CLAUDE_MODEL,
            anthropic_api_key=settings.ANTHROPIC_API_KEY,
            temperature=0.7,
            max_tokens=4096,
            streaming=True,
        )

        self.system_prompt = """Eres Raisket, un asesor financiero AI especializado en el mercado mexicano.

Tu objetivo es ayudar a usuarios mexicanos a:
- Entender conceptos financieros básicos
- Crear presupuestos personalizados
- Planificar ahorro e inversión
- Optimizar deudas
- Alcanzar metas financieras

IMPORTANTE:
- Siempre considera el contexto económico de México (inflación, tasas, instituciones locales)
- Usa ejemplos con pesos mexicanos (MXN)
- Recomienda instituciones financieras reguladas por CONDUSEF
- Menciona opciones como CETES, AFORES, SOFIPOS cuando sea relevante
- Sé claro, directo y evita jerga técnica innecesaria
- Si no tienes información suficiente, pregunta antes de dar consejos
- NUNCA des consejos de inversión específicos sin conocer el perfil de riesgo del usuario

Responde de forma conversacional, amigable pero profesional. Usa un lenguaje cercano y comprensible."""

    async def chat(
        self, message: str, user_id: str, conversation_history: List[ChatMessage] | None = None
    ) -> ChatResponse:
        """Process a chat message and return response."""

        # Get relevant context from vector store
        relevant_docs = await vector_store_service.similarity_search(
            query=message, k=3, user_id=user_id
        )

        context = "\n\n".join([doc.page_content for doc in relevant_docs])

        # Build messages
        messages = [SystemMessage(content=self.system_prompt)]

        if conversation_history:
            for msg in conversation_history:
                if msg.role == "user":
                    messages.append(HumanMessage(content=msg.content))
                elif msg.role == "assistant":
                    messages.append(AIMessage(content=msg.content))

        # Add context if available
        if context:
            context_message = f"Contexto relevante del usuario:\n{context}\n\n"
            messages.append(SystemMessage(content=context_message))

        messages.append(HumanMessage(content=message))

        # Get response
        response = await self.llm.ainvoke(messages)

        return ChatResponse(
            message=response.content,
            conversation_id="temp-id",  # Replace with actual conversation ID from DB
            sources=[{"content": doc.page_content[:200]} for doc in relevant_docs]
            if relevant_docs
            else None,
        )

    async def chat_stream(
        self, message: str, user_id: str, conversation_history: List[ChatMessage] | None = None
    ) -> AsyncGenerator[str, None]:
        """Stream chat responses for better UX."""

        # Get relevant context
        relevant_docs = await vector_store_service.similarity_search(
            query=message, k=3, user_id=user_id
        )

        context = "\n\n".join([doc.page_content for doc in relevant_docs])

        # Build messages
        messages = [SystemMessage(content=self.system_prompt)]

        if conversation_history:
            for msg in conversation_history:
                if msg.role == "user":
                    messages.append(HumanMessage(content=msg.content))
                elif msg.role == "assistant":
                    messages.append(AIMessage(content=msg.content))

        if context:
            context_message = f"Contexto relevante:\n{context}\n\n"
            messages.append(SystemMessage(content=context_message))

        messages.append(HumanMessage(content=message))

        # Stream response
        async for chunk in self.llm.astream(messages):
            if chunk.content:
                yield chunk.content


# Singleton instance
chat_service = ChatService()
