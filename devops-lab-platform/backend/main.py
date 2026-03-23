"""
FastAPI application entry point.

Run from devops-lab-platform/backend/:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Or from the repo root (after pip install -r requirements.txt):
    uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
"""

import asyncio
import logging
from contextlib import asynccontextmanager
from datetime import datetime, timedelta

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.database import create_tables
from backend.services import session as session_store
from backend.services.lab_manager import cleanup_orphaned_containers
from backend.services import ttyd_manager, lab_manager
from backend.routers import labs, curriculum, progress, files

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def session_cleanup_loop() -> None:
    """Every 60 s, stop sessions whose last heartbeat is >5 min ago."""
    while True:
        await asyncio.sleep(60)
        cutoff = datetime.utcnow() - timedelta(minutes=5)
        for sess in session_store.list_sessions():
            try:
                heartbeat = datetime.fromisoformat(sess.get("last_heartbeat_at", ""))
                if heartbeat < cutoff:
                    session_id = sess["session_id"]
                    logger.info("Cleaning up stale session %s", session_id)
                    ttyd_manager.stop_ttyd(session_id)
                    lab_manager.stop_lab_container(session_id)
                    port = sess.get("ttyd_port")
                    if port:
                        session_store.release_port(port)
                    session_store.delete_session(session_id)
            except Exception as exc:
                logger.warning("Error during session cleanup: %s", exc)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    create_tables()
    removed = cleanup_orphaned_containers()
    if removed:
        logger.info("Cleaned up %d orphaned containers on startup", removed)
    task = asyncio.create_task(session_cleanup_loop())

    yield

    # Shutdown — stop all active sessions
    task.cancel()
    for sess in session_store.list_sessions():
        try:
            ttyd_manager.stop_ttyd(sess["session_id"])
            lab_manager.stop_lab_container(sess["session_id"])
        except Exception:
            pass


app = FastAPI(
    title="DevOps Lab Platform",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(labs.router)
app.include_router(curriculum.router)
app.include_router(progress.router)
app.include_router(files.router)


@app.get("/")
async def root():
    return {"status": "ok"}
