from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse
from app.models.schemas import ChatRequest, ChatResponse, ChatMessage
from app.services.chat_service import chat_service
from typing import List

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    """
    Process a chat message and return AI response.

    Args:
        request: Chat request with message and user context

    Returns:
        ChatResponse with AI message and sources
    """
    try:
        response = await chat_service.chat(
            message=request.message,
            user_id=request.user_id,
            conversation_history=None,  # TODO: Load from DB
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing chat: {str(e)}")


@router.post("/chat/stream")
async def chat_stream(request: ChatRequest) -> StreamingResponse:
    """
    Stream chat responses for better UX.

    Args:
        request: Chat request with message and user context

    Returns:
        Streaming response with AI message chunks
    """
    try:

        async def generate() -> AsyncGenerator[str, None]:
            async for chunk in chat_service.chat_stream(
                message=request.message,
                user_id=request.user_id,
                conversation_history=None,  # TODO: Load from DB
            ):
                yield chunk

        return StreamingResponse(generate(), media_type="text/event-stream")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error streaming chat: {str(e)}")


@router.get("/conversations/{conversation_id}")
async def get_conversation(conversation_id: str) -> dict:
    """
    Get conversation history.

    TODO: Implement conversation retrieval from Supabase
    """
    return {"conversation_id": conversation_id, "messages": []}
