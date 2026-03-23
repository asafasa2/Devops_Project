---
name: lab-yaml-authoring
description: >
  Writing and validating YAML lab definition files for the DevOps learning platform.
  Use this skill whenever creating new lab definitions in backend/lab_definitions/,
  writing setup_commands, validation_steps, objectives, or instructions for any lab,
  authoring Dockerfiles in lab-images/, or designing a new hands-on exercise for any
  curriculum subject (Linux, networking, CI/CD, Terraform, Ansible, monitoring, security).
  Also trigger when the user says "add a lab", "new exercise", "write a lab YAML", or
  references any lab by ID like linux_01_systemd.
---

# Lab YAML Authoring Skill

This skill covers how to write high-quality, self-contained lab definitions.

## Schema (every field explained)

```yaml
id: <subject>_<number>_<slug>    # e.g., linux_03_permissions
title: "Human-readable title"
subject: linux|networking|cicd|terraform|ansible|monitoring|security
difficulty: beginner|intermediate|advanced
estimated_minutes: 15-45         # keep within a 30-min study session

containers:
  - name: lab-host               # unique within this lab
    image: devops-lab/<image>:latest
    privileged: false            # true only for systemd labs
    environment:
      - LAB_ID=<id>
      - CUSTOM_VAR=value
    # Optional: for multi-container labs
    network: lab-net             # only for networking labs

objectives:                      # 2-5 learning goals
  - "Understand X"
  - "Practice Y"

setup_commands:                  # run inside the container BEFORE user gets access
  - "command 1"                  # break something, seed data, configure state
  - "command 2"

validation_steps:                # checked in order when user clicks "Validate"
  - command: "shell command to check"
    expected_exit: 0             # 0 = success, non-zero = failure
    hint: "Shown to user if this step fails"
  - command: "another check"
    expected_exit: 0
    hint: "Another hint"

instructions: |                  # Markdown — shown in the sidebar next to the terminal
  ## Your Mission
  Describe the scenario. What is broken? What should the user do?
  
  ### Getting Started
  ```
  suggested first command
  ```
  
  ### Hints
  - Hint 1
  - Hint 2
```

## Naming Conventions

- IDs: `{subject}_{two-digit-number}_{short_slug}` — e.g., `networking_04_dns`
- YAML filenames match the ID: `networking_04_dns.yml`
- Container images: `devops-lab/{purpose}:latest`

## Writing Good Labs

**Setup commands** should create a realistic broken/incomplete state. The user's job is to diagnose and fix. Patterns:
- Break a config file with `sed`
- Stop/disable a service
- Set wrong permissions
- Create a half-configured resource

**Validation steps** should test the end state, not the method. Check outcomes:
- `systemctl is-active <service>` — service is running
- `curl -s -o /dev/null -w '%{http_code}' http://localhost` — HTTP 200
- `stat -c '%a' /path/to/file` with `expected_output: "644"` — permissions correct
- `grep -q 'expected_line' /etc/config` — config contains the right value

**Instructions** should:
- Start with a 2-sentence scenario ("You're a new sysadmin. The web server is down.")
- Give the first command to run (lower the barrier to entry)
- Include 2-3 progressive hints (not the answer)
- End with a "What you learned" summary

## Subject-Specific Guidance

**Linux labs:** Use `devops-lab/base-linux` image. Privileged=true only for systemd. Cover: service management, file permissions, disk/LVM, process signals, bash scripting.

**Networking labs:** Use `devops-lab/networking-lab` image. Multi-container setups for firewall rules. Tools: iptables, nftables, tcpdump, nmap, dig, openssl.

**CI/CD labs:** Use `devops-lab/cicd-lab` image. Pre-install Jenkins CLI or gitlab-runner. User writes/fixes Jenkinsfile or .gitlab-ci.yml.

**Terraform labs:** Use `devops-lab/terraform-lab` image. Docker provider only (NOT AWS). User writes .tf files, runs plan/apply, validates resource state.

**Ansible labs:** Use `devops-lab/ansible-lab` image. Multi-container: 1 controller + 2 targets. User writes playbooks, runs them, validates target state.

**Monitoring labs:** Use `devops-lab/monitoring-lab` image. Pre-install Prometheus + Grafana. User writes alerting rules, configures exporters, builds dashboards.

**Security labs:** Use `devops-lab/base-linux` image. CIS benchmark checks, auditd rules, fail2ban config. Validation = running a hardening check script.

## Common Pitfalls

- Don't use `sleep` in setup_commands — use proper waits or accept eventual consistency
- Don't validate method (e.g., "user ran `apt install`") — validate outcome
- Keep setup_commands idempotent — running them twice should produce the same state
- Test that validation_steps actually fail on a fresh container (before the user fixes anything)
