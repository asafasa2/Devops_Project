from fastapi import APIRouter

router = APIRouter(prefix="/curriculum", tags=["curriculum"])


@router.get("")
async def get_curriculum():
    """Phase 1 stub — single Linux subject."""
    return [
        {
            "subject": "linux",
            "title": "Linux Fundamentals",
            "description": "systemd, storage, permissions, processes, bash scripting",
            "labs_count": 1,
        }
    ]
