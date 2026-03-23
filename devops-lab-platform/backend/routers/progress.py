import json
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.database import get_db
from backend.models.schemas import LabProgress

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("")
async def get_progress(db: Session = Depends(get_db)):
    """Return all lab progress records (user_id=1 hardcoded in Phase 1)."""
    rows = db.query(LabProgress).all()
    return [
        {
            "id": row.id,
            "lab_id": row.lab_id,
            "session_id": row.session_id,
            "completed": row.completed,
            "completed_at": row.completed_at,
            "validation_results": json.loads(row.validation_results) if row.validation_results else None,
        }
        for row in rows
    ]
