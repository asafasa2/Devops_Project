"""
Manage ttyd processes — one per lab session.
ttyd runs on the HOST, exposes a real shell backed by docker exec.
macOS note: docker exec -it from subprocess works with Docker Desktop.
"""

import subprocess
import time

from backend.services import session as session_store


def start_ttyd(session_id: str, container_id: str, port: int) -> int:
    """
    Spawn a ttyd process that connects to the container's bash shell.
    Returns the PID of the ttyd process.
    """
    cmd = [
        "ttyd",
        "--port", str(port),
        "--writable",
        "docker", "exec", "-it", container_id, "/bin/bash"
    ]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    session_store.store_process(session_id, proc)
    # Give ttyd a moment to bind the port
    time.sleep(1)
    return proc.pid


def stop_ttyd(session_id: str) -> None:
    """Terminate the ttyd process for this session."""
    proc = session_store.get_process(session_id)
    if proc is None:
        return
    try:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
    except Exception:
        pass
    session_store.remove_process(session_id)


def is_ttyd_alive(session_id: str) -> bool:
    """Return True if the ttyd subprocess is still running."""
    proc = session_store.get_process(session_id)
    if proc is None:
        return False
    return proc.poll() is None


def get_ttyd_url(port: int) -> str:
    return f"ws://localhost:{port}/ws"
