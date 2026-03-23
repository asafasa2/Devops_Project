"""
Lab lifecycle endpoints.

POST   /labs/start              → start container + ttyd, return session
GET    /labs/definitions        → list available lab YAMLs
GET    /labs/{session_id}       → session status
POST   /labs/{session_id}/validate → run validation steps
POST   /labs/{session_id}/stop  → stop (alias, supports sendBeacon)
DELETE /labs/{session_id}       → stop + cleanup
"""

import asyncio
import fcntl
import json
import os
import pty
import struct
import subprocess
import termios
import glob
from datetime import datetime
from pathlib import Path
from typing import List

import yaml
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from backend.database import get_db
from backend.models.schemas import (
    LabStartRequest, LabStartResponse, LabStatusResponse,
    ValidationResult, ValidationStepResult, LabDefinitionSummary,
    LabSession as LabSessionModel, LabProgress,
)
from backend.services import session as session_store
from backend.services import lab_manager, ttyd_manager

router = APIRouter(prefix="/labs", tags=["labs"])

LAB_DEFS_DIR = Path(__file__).parent.parent / "lab_definitions"


# ── Helpers ───────────────────────────────────────────────────────────────────

def _load_lab_def(lab_id: str) -> dict:
    path = LAB_DEFS_DIR / f"{lab_id}.yml"
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Lab '{lab_id}' not found")
    with open(path) as f:
        return yaml.safe_load(f)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/definitions", response_model=List[LabDefinitionSummary])
async def get_definitions():
    """Scan lab_definitions/*.yml and return summary list."""
    results = []
    for yml_path in sorted(LAB_DEFS_DIR.glob("*.yml")):
        with open(yml_path) as f:
            lab = yaml.safe_load(f)
        results.append(LabDefinitionSummary(
            id=lab["id"],
            title=lab["title"],
            subject=lab["subject"],
            difficulty=lab["difficulty"],
            estimated_minutes=lab["estimated_minutes"],
            editor_enabled=lab.get("editor_enabled", False),
        ))
    return results


@router.post("/start", response_model=LabStartResponse)
def start_lab(request: LabStartRequest, db: Session = Depends(get_db)):
    lab_def = _load_lab_def(request.lab_id)
    session_id = session_store.create_session(request.lab_id)

    try:
        # 1. Start container
        session_store.update_session(session_id, status="starting_container")
        container_id = lab_manager.start_lab_container(session_id, lab_def)
        session_store.update_session(session_id, container_id=container_id)

        # 2. Wait for systemd
        session_store.update_session(session_id, status="booting_systemd")
        lab_manager.wait_for_systemd(container_id)

        # 3. Run setup commands
        session_store.update_session(session_id, status="running_setup")
        lab_manager.run_setup_commands(container_id, lab_def.get("setup_commands", []))

        # 4. Start ttyd
        port = session_store.allocate_port()
        session_store.update_session(session_id, ttyd_port=port)
        pid = ttyd_manager.start_ttyd(session_id, container_id, port)
        ttyd_url = ttyd_manager.get_ttyd_url(port)

        session_store.update_session(session_id, status="ready", ttyd_pid=pid)

        # 5. Persist to DB
        db_session = LabSessionModel(
            id=session_id,
            lab_id=request.lab_id,
            status="ready",
            container_id=container_id,
            ttyd_port=port,
            ttyd_pid=pid,
        )
        db.add(db_session)
        db.commit()

        return LabStartResponse(
            session_id=session_id,
            lab_id=request.lab_id,
            status="ready",
            ttyd_url=ttyd_url,
            ttyd_port=port,
            instructions=lab_def.get("instructions", ""),
            objectives=lab_def.get("objectives", []),
            title=lab_def["title"],
            editor_enabled=lab_def.get("editor_enabled", False),
            editor_default_path=lab_def.get("editor_default_path"),
        )

    except Exception as exc:
        # Best-effort cleanup before propagating
        try:
            ttyd_manager.stop_ttyd(session_id)
        except Exception:
            pass
        try:
            lab_manager.stop_lab_container(session_id)
        except Exception:
            pass
        port = session_store.get_session(session_id)
        if port and port.get("ttyd_port"):
            session_store.release_port(port["ttyd_port"])
        session_store.delete_session(session_id)
        raise HTTPException(status_code=500, detail=str(exc))


@router.get("/{session_id}", response_model=LabStatusResponse)
async def get_lab_status(session_id: str):
    sess = session_store.get_session(session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")
    port = sess.get("ttyd_port")
    ttyd_url = ttyd_manager.get_ttyd_url(port) if port else None
    return LabStatusResponse(
        session_id=session_id,
        lab_id=sess["lab_id"],
        status=sess["status"],
        ttyd_url=ttyd_url,
        ttyd_port=port,
    )


@router.post("/{session_id}/validate", response_model=ValidationResult)
def validate_lab(session_id: str, db: Session = Depends(get_db)):
    sess = session_store.get_session(session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")

    container_id = sess.get("container_id")
    if not container_id:
        raise HTTPException(status_code=400, detail="Container not running")

    lab_def = _load_lab_def(sess["lab_id"])
    raw_results = lab_manager.run_validation(container_id, lab_def.get("validation_steps", []))

    step_results = [ValidationStepResult(**r) for r in raw_results]
    all_passed = all(r.passed for r in step_results)

    # Persist progress
    results_json = json.dumps([r.dict() for r in step_results])
    progress = LabProgress(
        lab_id=sess["lab_id"],
        session_id=session_id,
        completed=all_passed,
        completed_at=datetime.utcnow() if all_passed else None,
        validation_results=results_json,
    )
    db.add(progress)
    db.commit()

    return ValidationResult(
        session_id=session_id,
        lab_id=sess["lab_id"],
        all_passed=all_passed,
        results=step_results,
    )


@router.websocket("/{session_id}/ws")
async def terminal_ws(websocket: WebSocket, session_id: str):
    """
    Raw PTY WebSocket terminal — bypasses ttyd entirely.
    Spawns docker exec connected to a pty, streams raw bytes both ways.
    Accepts JSON text frames {"type":"resize","cols":N,"rows":N} for resize.
    """
    await websocket.accept()

    sess = session_store.get_session(session_id)
    if not sess or not sess.get("container_id"):
        await websocket.close(1008)
        return

    container_id = sess["container_id"]

    # Create a PTY pair and start bash inside the container
    master_fd, slave_fd = pty.openpty()
    fcntl.ioctl(master_fd, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
    fcntl.fcntl(master_fd, fcntl.F_SETFL, os.O_NONBLOCK)

    proc = subprocess.Popen(
        ["docker", "exec", "-it", container_id, "/bin/bash"],
        stdin=slave_fd, stdout=slave_fd, stderr=slave_fd,
        close_fds=True, preexec_fn=os.setsid,
    )
    os.close(slave_fd)

    loop = asyncio.get_event_loop()
    output_queue: asyncio.Queue = asyncio.Queue()

    def _pty_readable():
        """Called by the event loop when master_fd has data to read."""
        while True:
            try:
                data = os.read(master_fd, 4096)
                if data:
                    output_queue.put_nowait(data)
            except BlockingIOError:
                break  # no more data right now
            except OSError:
                output_queue.put_nowait(None)  # EOF sentinel
                loop.remove_reader(master_fd)
                break

    loop.add_reader(master_fd, _pty_readable)

    async def forward_output():
        while True:
            data = await output_queue.get()
            if data is None:
                break
            try:
                await websocket.send_bytes(data)
            except Exception:
                break

    async def forward_input():
        try:
            while True:
                msg = await websocket.receive()
                if msg["type"] == "websocket.disconnect":
                    break
                raw = msg.get("bytes")
                if raw:
                    os.write(master_fd, raw)
                    continue
                text = msg.get("text")
                if text:
                    try:
                        d = json.loads(text)
                        if d.get("type") == "resize":
                            rows = d.get("rows", 24)
                            cols = d.get("cols", 80)
                            fcntl.ioctl(master_fd, termios.TIOCSWINSZ,
                                        struct.pack("HHHH", rows, cols, 0, 0))
                    except Exception:
                        pass
        except WebSocketDisconnect:
            pass
        except Exception:
            pass

    output_task = asyncio.create_task(forward_output())
    input_task = asyncio.create_task(forward_input())

    await asyncio.wait([output_task, input_task], return_when=asyncio.FIRST_COMPLETED)

    for task in [output_task, input_task]:
        if not task.done():
            task.cancel()
            try:
                await task
            except (asyncio.CancelledError, Exception):
                pass

    loop.remove_reader(master_fd)
    try:
        os.close(master_fd)
    except OSError:
        pass
    proc.terminate()


def _do_stop(session_id: str, db: Session) -> dict:
    sess = session_store.get_session(session_id)
    if not sess:
        return {"message": "Session not found (already stopped?)"}

    ttyd_manager.stop_ttyd(session_id)
    lab_manager.stop_lab_container(session_id)

    port = sess.get("ttyd_port")
    if port:
        session_store.release_port(port)

    # Update DB record
    db_sess = db.query(LabSessionModel).filter(LabSessionModel.id == session_id).first()
    if db_sess:
        db_sess.status = "stopped"
        db_sess.stopped_at = datetime.utcnow()
        db.commit()

    session_store.delete_session(session_id)
    return {"message": "Lab stopped"}


@router.delete("/{session_id}")
def stop_lab(session_id: str, db: Session = Depends(get_db)):
    return _do_stop(session_id, db)


@router.post("/{session_id}/stop")
def stop_lab_beacon(session_id: str, db: Session = Depends(get_db)):
    """sendBeacon-compatible alias for DELETE."""
    return _do_stop(session_id, db)
