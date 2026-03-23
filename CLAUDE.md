# DevOps Learning Platform — CLAUDE.md

Read this entire file before writing any code. Complete the planning phase at the bottom first.

---

## What We Are Building

A self-hosted DevOps learning platform with real, runnable Linux lab environments in the browser.
Not a simulation — actual terminals backed by Docker containers via ttyd + xterm.js.

**Core loop per subject:** Concept explanation → annotated examples → live terminal lab → quiz

## Who This Is For

A DevOps engineer transitioning from QA at an on-premise offensive cybersecurity company.
- No cloud — everything runs on local Linux servers (air-gapped network)
- CI/CD already exists: Jenkins + GitLab
- Studies ~30 min/day

## Curriculum (strict order)

1. Linux — systemd, storage, permissions, processes, bash scripting
2. Networking — subnetting, iptables/nftables, DNS, TLS/PKI
3. CI/CD — Jenkins + GitLab pipelines, runners, secrets, artifacts
4. Infrastructure as Code — Terraform (local Docker provider only, NOT AWS)
5. Configuration Management — Ansible playbooks, roles, inventory
6. Monitoring — Grafana + Prometheus, alerting rules
7. Security Hardening — CIS benchmarks, auditd, fail2ban

## Previous Project (Kiro) — What Carries Over

Repo: https://github.com/asafasa2/Devops_Project

**Reusable:** Monitoring stack config (Grafana/Prometheus), Jenkinsfile patterns, Ansible role structure, Terraform Docker provider examples, Makefile conventions, general curriculum topic list.

**Needs rewrite:** Backend (was Node.js microservices → now single FastAPI), Frontend (was static HTML → now React+Vite), Lab runtime (had no real terminal — now Docker+ttyd), Database layer (was PostgreSQL microservices → now SQLite dev / PostgreSQL prod), Assessment/quiz system (was separate service → now integrated).

**Was missing:** Real terminal sessions, YAML-defined labs with validation, offline-first architecture, session-scoped disposable containers, progress tracking tied to lab validation.

## Architecture Decisions (do not change unless critical blocker)

### Lab Runtime
- Docker containers per lab session (not WebContainers, not cloud VMs)
- ttyd exposes real shell sessions in the browser
- Each lab = one or more Docker containers + ttyd process
- Labs are isolated, disposable, session-scoped; state persists via Docker volumes

### Backend
- FastAPI (Python) — REST API for lab lifecycle, curriculum, progress
- SQLite (dev), PostgreSQL-ready (prod)
- Redis for session state (in-memory dict fallback if Redis unavailable)
- Docker SDK for Python to manage lab containers

### Frontend
- React + Vite + Tailwind CSS
- xterm.js for in-browser terminal (connects to ttyd WebSocket)
- No external UI component libraries

### Offline-First
- All Docker images pullable once, work offline forever
- No CDN deps at runtime — bundle everything
- Curriculum content = local Markdown/JSON files
- Lab images are pre-built and stored locally

## Project Structure

```
devops-lab-platform/
├── CLAUDE.md
├── docker-compose.yml
├── backend/
│   ├── main.py                 # FastAPI app entry
│   ├── database.py             # SQLAlchemy setup
│   ├── routers/
│   │   ├── labs.py             # POST /labs/start, DELETE /labs/{id}
│   │   ├── curriculum.py       # GET /curriculum, GET /curriculum/{subject}
│   │   └── progress.py         # GET/POST /progress
│   ├── services/
│   │   ├── lab_manager.py      # Docker SDK — spin up/down containers
│   │   ├── ttyd_manager.py     # Manage ttyd processes per session
│   │   └── session.py          # Session state (Redis / memory fallback)
│   ├── lab_definitions/        # YAML files per lab
│   ├── models/schemas.py
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/         # Terminal.jsx, LabPanel.jsx, Quiz.jsx, Curriculum.jsx
│   │   ├── pages/              # Learn.jsx, Lab.jsx, Dashboard.jsx
│   │   └── App.jsx
│   └── package.json
├── lab-images/                 # Dockerfiles per lab environment
│   ├── base-linux/
│   ├── networking-lab/
│   ├── ansible-lab/
│   ├── terraform-lab/
│   ├── monitoring-lab/
│   └── cicd-lab/
└── curriculum/                 # Markdown + JSON content per subject
    ├── linux/ networking/ cicd/ terraform/ ansible/ monitoring/ security/
```

## Lab YAML Schema

```yaml
id: linux_01_systemd
title: "Breaking and fixing a systemd service"
subject: linux
difficulty: beginner
estimated_minutes: 20
containers:
  - name: lab-host
    image: devops-lab/base-linux:latest
    privileged: true
    environment: [LAB_ID=linux_01]
objectives:
  - "Read journalctl output to find the cause"
  - "Fix the unit file and restart correctly"
setup_commands:
  - "sed -i 's/ExecStart=.*/ExecStart=\\/usr\\/bin\\/nonexistent/' /etc/systemd/system/nginx.service"
validation_steps:
  - command: "systemctl is-active nginx"
    expected_exit: 0
    hint: "nginx should be running — did you fix the ExecStart= line?"
instructions: |
  ## Your mission
  nginx is broken. Find out why and fix it.
```

## Key Constraints — Never Violate

1. **Offline-first** — every feature works with no internet after initial `docker-compose pull`
2. **No cloud APIs** in the lab runtime — only local Docker containers
3. **Real tools only** — no mocked terminals, no fake command output
4. **Disposable labs** — `DELETE /labs/{id}` cleanly removes all containers + ttyd processes
5. **Security isolation** — lab containers cannot reach host network or other users' labs
6. **Privileged containers are OK** for systemd labs — document this clearly

## Build Phases (strict order)

### Phase 1 — Foundation (build first, get working end-to-end)
- [ ] FastAPI + lab_manager.py: start/stop one Docker container
- [ ] ttyd_manager.py: expose a shell for that container
- [ ] Terminal.jsx: xterm.js connected to ttyd WebSocket
- [ ] One complete lab: linux_01_systemd (instructions → terminal → validation)
- [ ] Basic progress tracking (lab completed = yes/no)

**Done when:** Open browser → click Start Lab → get real terminal → break/fix systemd → platform validates success.

### Phase 2 — Curriculum Layer
- [ ] Concept pages (Markdown rendered), Quiz component with scoring
- [ ] All 7 Linux labs, Dashboard with progress overview

### Phase 3–7 — Remaining subjects (one phase each)
Networking → CI/CD → Ansible + Terraform → Monitoring → Security Hardening

## Before Writing Any Code

1. Confirm the architecture makes sense for these constraints
2. Identify top 3 hardest technical problems in Phase 1 and propose solutions
3. Ask any clarifying questions
4. Begin Phase 1 only — do not jump ahead
