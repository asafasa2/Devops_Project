from sqlalchemy import Column, String, Integer, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from backend.database import Base


# ── SQLAlchemy ORM models ─────────────────────────────────────────────────────

class LabSession(Base):
    __tablename__ = "lab_sessions"

    id = Column(String, primary_key=True, index=True)   # UUID string
    lab_id = Column(String, nullable=False)
    status = Column(String, default="created")
    container_id = Column(String, nullable=True)
    ttyd_port = Column(Integer, nullable=True)
    ttyd_pid = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    stopped_at = Column(DateTime, nullable=True)

    progress = relationship("LabProgress", back_populates="session", cascade="all, delete-orphan")


class LabProgress(Base):
    __tablename__ = "lab_progress"

    id = Column(Integer, primary_key=True, autoincrement=True)
    lab_id = Column(String, nullable=False)
    session_id = Column(String, ForeignKey("lab_sessions.id"), nullable=False)
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, nullable=True)
    validation_results = Column(Text, nullable=True)  # JSON string

    session = relationship("LabSession", back_populates="progress")


# ── Pydantic request/response schemas ─────────────────────────────────────────

class LabStartRequest(BaseModel):
    lab_id: str


class LabStartResponse(BaseModel):
    session_id: str
    lab_id: str
    status: str
    ttyd_url: str
    ttyd_port: int
    instructions: str
    objectives: List[str]
    title: str
    editor_enabled: bool = False
    editor_default_path: Optional[str] = None


class ValidationStepResult(BaseModel):
    command: str
    passed: bool
    exit_code: int
    hint: Optional[str] = None


class ValidationResult(BaseModel):
    session_id: str
    lab_id: str
    all_passed: bool
    results: List[ValidationStepResult]


class LabStatusResponse(BaseModel):
    session_id: str
    lab_id: str
    status: str
    ttyd_url: Optional[str] = None
    ttyd_port: Optional[int] = None


class LabDefinitionSummary(BaseModel):
    id: str
    title: str
    subject: str
    difficulty: str
    estimated_minutes: int
    editor_enabled: bool = False


# ── File API schemas ─────────────────────────────────────────────────────────

class FileEntry(BaseModel):
    name: str
    type: str  # "file" or "dir"
    size: int
    modified: str


class FileListResponse(BaseModel):
    path: str
    entries: List[FileEntry]


class FileContentResponse(BaseModel):
    path: str
    content: str
    language: str


class FileWriteRequest(BaseModel):
    path: str
    content: str
