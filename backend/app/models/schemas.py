from datetime import datetime
from typing import Any, Dict, List
from pydantic import BaseModel, EmailStr, Field


# User schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: str | None = None


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


# Chat schemas
class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|assistant|system)$")
    content: str


class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None
    user_id: str


class ChatResponse(BaseModel):
    message: str
    conversation_id: str
    sources: List[Dict[str, Any]] | None = None


# Financial schemas
class FinancialProfile(BaseModel):
    user_id: str
    monthly_income: float | None = None
    monthly_expenses: float | None = None
    savings: float | None = None
    debt: float | None = None
    investment_risk_tolerance: str | None = Field(
        None, pattern="^(conservative|moderate|aggressive)$"
    )
    financial_goals: List[str] | None = None


class FinancialRecommendation(BaseModel):
    category: str
    title: str
    description: str
    priority: str = Field(..., pattern="^(high|medium|low)$")
    estimated_impact: float | None = None


# Document schemas
class DocumentUpload(BaseModel):
    user_id: str
    document_type: str
    file_name: str


class DocumentResponse(BaseModel):
    id: str
    user_id: str
    document_type: str
    file_name: str
    processed: bool
    created_at: datetime


# Health check
class HealthCheck(BaseModel):
    status: str
    version: str
    environment: str
