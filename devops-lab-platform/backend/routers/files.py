"""
File API — read/write files inside running lab containers.

GET  /labs/{session_id}/files?path=/workspace         → list directory
GET  /labs/{session_id}/files/content?path=/workspace/main.tf → read file
PUT  /labs/{session_id}/files/content                  → write file
"""

import base64
import os
from typing import List

from fastapi import APIRouter, HTTPException, Query

from backend.models.schemas import FileEntry, FileListResponse, FileContentResponse, FileWriteRequest
from backend.services import session as session_store
from backend.services.lab_manager import _c

router = APIRouter(prefix="/labs/{session_id}/files", tags=["files"])

ALLOWED_PREFIXES = ("/workspace", "/etc/", "/opt/", "/home/")
LANGUAGE_MAP = {
    ".tf": "hcl",
    ".hcl": "hcl",
    ".yml": "yaml",
    ".yaml": "yaml",
    ".py": "python",
    ".sh": "shell",
    ".bash": "shell",
    ".groovy": "groovy",
    ".json": "json",
    ".toml": "toml",
    ".ini": "ini",
    ".cfg": "ini",
    ".conf": "ini",
    ".js": "javascript",
    ".ts": "typescript",
    ".md": "markdown",
    ".txt": "plaintext",
    ".service": "ini",
    ".rules": "plaintext",
}


def _validate_path(path: str) -> None:
    """Reject path traversal and restrict to allowed prefixes."""
    normalized = os.path.normpath(path)
    if ".." in normalized:
        raise HTTPException(status_code=400, detail="Path traversal not allowed")
    if not any(normalized.startswith(prefix) for prefix in ALLOWED_PREFIXES):
        raise HTTPException(status_code=403, detail=f"Access denied: path must start with one of {ALLOWED_PREFIXES}")


def _get_container(session_id: str):
    """Get Docker container for a session."""
    sess = session_store.get_session(session_id)
    if not sess or not sess.get("container_id"):
        raise HTTPException(status_code=404, detail="Session not found or container not running")
    try:
        return _c().containers.get(sess["container_id"])
    except Exception:
        raise HTTPException(status_code=404, detail="Container not found")


def _detect_language(path: str) -> str:
    """Detect language from file extension."""
    _, ext = os.path.splitext(path)
    return LANGUAGE_MAP.get(ext.lower(), "plaintext")


@router.get("", response_model=FileListResponse)
async def list_files(session_id: str, path: str = Query("/workspace")):
    """List files in a directory inside the lab container."""
    _validate_path(path)
    container = _get_container(session_id)

    result = container.exec_run(
        ["bash", "-c", f"ls -la --time-style=long-iso {path} 2>/dev/null || echo 'ERROR'"],
        user="root",
    )
    output = result.output.decode(errors="replace").strip()

    if output == "ERROR" or result.exit_code != 0:
        raise HTTPException(status_code=404, detail=f"Directory not found: {path}")

    entries: List[FileEntry] = []
    for line in output.split("\n")[1:]:  # skip "total N" line
        parts = line.split(None, 7)
        if len(parts) < 8:
            continue
        name = parts[7]
        if name in (".", ".."):
            continue
        perms = parts[0]
        file_type = "dir" if perms.startswith("d") else "file"
        try:
            size = int(parts[4])
        except ValueError:
            size = 0
        modified = f"{parts[5]} {parts[6]}"
        entries.append(FileEntry(name=name, type=file_type, size=size, modified=modified))

    return FileListResponse(path=path, entries=entries)


@router.get("/content", response_model=FileContentResponse)
async def read_file(session_id: str, path: str = Query(...)):
    """Read file content from inside the lab container."""
    _validate_path(path)
    container = _get_container(session_id)

    # Check file size first (limit to 1MB)
    size_result = container.exec_run(
        ["bash", "-c", f"stat -c%s {path} 2>/dev/null || echo -1"],
        user="root",
    )
    try:
        size = int(size_result.output.decode().strip())
    except ValueError:
        size = -1
    if size < 0:
        raise HTTPException(status_code=404, detail=f"File not found: {path}")
    if size > 1_048_576:
        raise HTTPException(status_code=413, detail="File too large (>1MB)")

    result = container.exec_run(
        ["bash", "-c", f"cat {path}"],
        user="root",
    )
    if result.exit_code != 0:
        raise HTTPException(status_code=404, detail=f"Cannot read file: {path}")

    content = result.output.decode(errors="replace")
    language = _detect_language(path)

    return FileContentResponse(path=path, content=content, language=language)


@router.put("/content")
async def write_file(session_id: str, request: FileWriteRequest):
    """Write file content to the lab container (base64 internally to avoid escaping)."""
    _validate_path(request.path)
    container = _get_container(session_id)

    encoded = base64.b64encode(request.content.encode()).decode()
    result = container.exec_run(
        ["bash", "-c", f"echo '{encoded}' | base64 -d > {request.path}"],
        user="root",
    )
    if result.exit_code != 0:
        raise HTTPException(status_code=500, detail=f"Failed to write file: {request.path}")

    return {"status": "ok", "path": request.path}
