"""
In-memory session store for Phase 1.
Redis drop-in replacement in Phase 2 — same interface.
"""

import uuid
from datetime import datetime
from typing import Dict, Optional, Set
from subprocess import Popen

_sessions: Dict[str, dict] = {}
_processes: Dict[str, Popen] = {}
_used_ports: Set[int] = set()

PORT_RANGE_START = 7681
PORT_RANGE_END = 7780


# ── Session CRUD ────────────────────────────────────────────────────────────

def create_session(lab_id: str) -> str:
    session_id = str(uuid.uuid4())
    _sessions[session_id] = {
        "session_id": session_id,
        "lab_id": lab_id,
        "status": "created",
        "container_id": None,
        "ttyd_port": None,
        "ttyd_pid": None,
        "created_at": datetime.utcnow().isoformat(),
        "last_heartbeat_at": datetime.utcnow().isoformat(),
    }
    return session_id


def get_session(session_id: str) -> Optional[dict]:
    return _sessions.get(session_id)


def update_session(session_id: str, **kwargs) -> None:
    if session_id in _sessions:
        _sessions[session_id].update(kwargs)
        _sessions[session_id]["last_heartbeat_at"] = datetime.utcnow().isoformat()


def delete_session(session_id: str) -> None:
    _sessions.pop(session_id, None)


def list_sessions() -> list:
    return list(_sessions.values())


# ── Port pool ────────────────────────────────────────────────────────────────

def allocate_port() -> int:
    for port in range(PORT_RANGE_START, PORT_RANGE_END + 1):
        if port not in _used_ports:
            _used_ports.add(port)
            return port
    raise RuntimeError("No available ports in the ttyd pool (7681–7780)")


def release_port(port: int) -> None:
    _used_ports.discard(port)


# ── Process store ────────────────────────────────────────────────────────────

def store_process(session_id: str, proc: Popen) -> None:
    _processes[session_id] = proc


def get_process(session_id: str) -> Optional[Popen]:
    return _processes.get(session_id)


def remove_process(session_id: str) -> None:
    _processes.pop(session_id, None)
