"""
Docker SDK wrapper — spin up/down lab containers.
"""

import time
import docker
from docker.errors import NotFound
from typing import List, Dict, Any

MANAGED_LABEL = "devops-lab.managed"
SESSION_LABEL = "devops-lab.session_id"
LAB_LABEL = "devops-lab.lab_id"

_client = None


def _c():
    """Lazy-init Docker client using environment (auto-detects socket path)."""
    global _client
    if _client is None:
        _client = docker.from_env()
    return _client


def _image_uses_systemd(image: str) -> bool:
    """Return True if the image CMD is /sbin/init (systemd as PID 1)."""
    try:
        img = _c().images.get(image)
        cmd = img.attrs.get("Config", {}).get("Cmd") or []
        return any("init" in part for part in cmd)
    except Exception:
        return False


def start_lab_container(session_id: str, lab_def: dict) -> str:
    """Create and start the first container defined in the lab YAML. Returns container_id."""
    container_spec = lab_def["containers"][0]
    image = container_spec["image"]
    env = container_spec.get("environment", [])
    privileged = container_spec.get("privileged", False)
    uses_systemd = _image_uses_systemd(image)

    # Build volumes: lab YAML declarations first
    volumes: dict = {}
    for vol in container_spec.get("volumes", []):
        host, _, container_path = vol.partition(":")
        volumes[host] = {"bind": container_path, "mode": "rw"}

    # Systemd requires cgroup mount
    if uses_systemd:
        volumes["/sys/fs/cgroup"] = {"bind": "/sys/fs/cgroup", "mode": "rw"}

    tmpfs = {}
    if uses_systemd:
        tmpfs = {
            "/run": "rw,nosuid,nodev,size=100m",
            "/run/lock": "rw,nosuid,nodev,noexec,size=50m",
        }

    # Create per-session bridge network
    network_name = f"devops-lab-net-{session_id}"
    try:
        _c().networks.create(network_name, driver="bridge")
    except Exception:
        pass  # already exists

    run_kwargs = dict(
        image=image,
        detach=True,
        name=f"devops-lab-{session_id}",
        labels={
            MANAGED_LABEL: "true",
            SESSION_LABEL: session_id,
            LAB_LABEL: lab_def["id"],
        },
        environment=env,
        privileged=privileged,
        volumes=volumes,
        network=network_name,
    )
    if uses_systemd:
        run_kwargs["cgroupns"] = "host"
    if tmpfs:
        run_kwargs["tmpfs"] = tmpfs

    container = _c().containers.run(**run_kwargs)
    return container.id


def wait_for_systemd(container_id: str, timeout: int = 45) -> None:
    """Poll until systemd reports system-running. No-op for non-systemd containers."""
    container = _c().containers.get(container_id)

    # First probe: exit immediately if this is not a systemd container
    first = container.exec_run(["systemctl", "is-system-running"], user="root")
    first_out = first.output.decode().strip() if first.output else ""
    if "Failed to connect to bus" in first_out or "No such file" in first_out:
        return  # not systemd
    if first_out in ("running", "degraded"):
        return

    deadline = time.time() + timeout
    while time.time() < deadline:
        result = container.exec_run(["systemctl", "is-system-running"], user="root")
        output = result.output.decode().strip() if result.output else ""
        if output in ("running", "degraded"):
            return
        time.sleep(1)
    raise TimeoutError(f"systemd did not reach running state within {timeout}s")


def run_setup_commands(container_id: str, commands: List[str]) -> None:
    """Execute each setup command inside the container as root."""
    container = _c().containers.get(container_id)
    for cmd in commands:
        container.exec_run(["bash", "-c", cmd], user="root")
        # setup commands may fail intentionally (e.g. 'systemctl restart nginx || true')


def run_validation(container_id: str, validation_steps: List[dict]) -> List[Dict[str, Any]]:
    """Run each validation step; compare exit code to expected_exit."""
    container = _c().containers.get(container_id)
    results = []
    for step in validation_steps:
        cmd = step["command"]
        expected_exit = step.get("expected_exit", 0)
        hint = step.get("hint")
        result = container.exec_run(["bash", "-c", cmd], user="root")
        exit_code = result.exit_code
        results.append({
            "command": cmd,
            "passed": exit_code == expected_exit,
            "exit_code": exit_code,
            "hint": hint,
        })
    return results


def stop_lab_container(session_id: str) -> None:
    """Stop and remove containers + network for this session."""
    try:
        containers = _c().containers.list(
            all=True,
            filters={"label": f"{SESSION_LABEL}={session_id}"}
        )
        for container in containers:
            try:
                container.stop(timeout=5)
            except Exception:
                pass
            try:
                container.remove(force=True)
            except Exception:
                pass
    except Exception:
        pass

    # Remove network
    network_name = f"devops-lab-net-{session_id}"
    try:
        network = _c().networks.get(network_name)
        network.remove()
    except NotFound:
        pass
    except Exception:
        pass


def cleanup_orphaned_containers() -> int:
    """Remove all containers labeled devops-lab.managed=true. Called on startup."""
    removed = 0
    try:
        containers = _c().containers.list(
            all=True,
            filters={"label": f"{MANAGED_LABEL}=true"}
        )
        for container in containers:
            try:
                container.stop(timeout=3)
            except Exception:
                pass
            try:
                container.remove(force=True)
                removed += 1
            except Exception:
                pass
    except Exception:
        pass
    return removed
