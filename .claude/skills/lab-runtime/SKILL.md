---
name: lab-runtime
description: >
  Managing Docker-based lab containers and ttyd terminal sessions for the DevOps learning platform.
  Use this skill whenever working on lab_manager.py, ttyd_manager.py, session.py, lab lifecycle
  endpoints (POST /labs/start, DELETE /labs/{id}), Docker SDK for Python, container networking
  isolation, or anything related to spinning up, connecting to, or tearing down lab environments.
  Also trigger for Dockerfile authoring in lab-images/, docker-compose service definitions for
  lab containers, or debugging container startup/cleanup issues.
---

# Lab Runtime Skill

This skill covers all Docker container lifecycle and ttyd terminal management for the platform.

## Architecture

Each lab session creates:
1. One or more Docker containers (defined in the lab YAML)
2. One ttyd process per container that needs a terminal
3. A session record linking the user to their containers

The flow: `POST /labs/start` → read YAML → `docker.containers.run()` → `ttyd` subprocess → return WebSocket URL.

## Docker SDK Patterns

Use the `docker` Python package (not subprocess calls to `docker` CLI).

```python
import docker
client = docker.from_env()

# Start a lab container
container = client.containers.run(
    image="devops-lab/base-linux:latest",
    name=f"lab-{session_id}-{container_name}",
    detach=True,
    privileged=lab_def.get("privileged", False),
    environment=lab_def.get("environment", []),
    labels={"devops-lab": "true", "session-id": session_id},
    network_mode="none",  # isolation by default
)
```

Key rules:
- Always label containers with `session-id` and `devops-lab=true` for cleanup
- Default `network_mode="none"` — only override for networking labs
- Use `container.exec_run()` for setup_commands from the YAML
- For teardown: stop + remove container, kill ttyd process, remove volumes

## ttyd Management

ttyd exposes a container's shell as a WebSocket. Run it as a subprocess:

```python
import subprocess
proc = subprocess.Popen(
    ["ttyd", "-p", str(port), "-o", "docker", "exec", "-it", container_id, "/bin/bash"],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE
)
```

Port allocation: maintain a simple port pool (e.g., 7000–7999). Track used ports in session state.
Frontend connects via: `ws://localhost:{port}/ws`

## Session Cleanup

`DELETE /labs/{id}` MUST:
1. Kill the ttyd subprocess (SIGTERM, then SIGKILL after 5s)
2. Stop and remove all containers with matching session label
3. Remove associated Docker volumes
4. Free the port back to the pool
5. Delete session state from Redis/memory

Never leave orphaned containers. Add a periodic cleanup that removes any container labeled `devops-lab=true` older than 2 hours.

## Validation

To validate a lab step, exec a command in the running container:

```python
exit_code, output = container.exec_run(cmd=validation_step["command"])
passed = (exit_code == validation_step["expected_exit"])
```

## Lab YAML Loading

Read all `.yml` files from `backend/lab_definitions/` at startup. Validate against the schema. Cache in memory as a dict keyed by `id`.

## Security

- `network_mode="none"` prevents containers from reaching the host or internet
- For networking labs that need inter-container communication, create a dedicated Docker network per session and attach only that session's containers
- Never mount host paths into lab containers
- Resource limits: `mem_limit="512m"`, `cpu_period=100000`, `cpu_quota=50000`

## Error Handling

- If container fails to start: return 500 with the Docker error message
- If ttyd fails to bind port: retry with next available port (up to 3 attempts)
- If cleanup fails: log the error, mark session as "dirty", background task retries cleanup
