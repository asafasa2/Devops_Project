# Skills Installation Guide

## Quick Install (Claude Code CLI)

Run these commands from your project root to install each skill:

```bash
# Install all 4 skills
claude skill install ./skills/lab-runtime
claude skill install ./skills/lab-yaml-authoring
claude skill install ./skills/curriculum-authoring
claude skill install ./skills/ttyd-terminal
```

## Manual Install (if `claude skill install` is not available)

Copy the skill folders into your project's `.claude/skills/` directory:

```bash
mkdir -p .claude/skills
cp -r skills/lab-runtime .claude/skills/
cp -r skills/lab-yaml-authoring .claude/skills/
cp -r skills/curriculum-authoring .claude/skills/
cp -r skills/ttyd-terminal .claude/skills/
```

Then add them to your `.claude/settings.json`:

```json
{
  "skills": [
    ".claude/skills/lab-runtime",
    ".claude/skills/lab-yaml-authoring",
    ".claude/skills/curriculum-authoring",
    ".claude/skills/ttyd-terminal"
  ]
}
```

## What Each Skill Does

| Skill | Triggers On | Saves Tokens By |
|-------|-------------|-----------------|
| **lab-runtime** | Docker SDK, container lifecycle, ttyd subprocess, session cleanup | Pre-loads Docker SDK patterns, port management, cleanup logic |
| **lab-yaml-authoring** | Creating/editing lab YAML files, writing exercises | Pre-loads schema, naming conventions, validation patterns |
| **curriculum-authoring** | Writing lessons, quizzes, concept pages | Pre-loads Markdown structure, quiz JSON schema, style guide |
| **ttyd-terminal** | xterm.js, WebSocket terminal, frontend Lab UI | Pre-loads exact xterm.js config, ttyd protocol, reconnection logic |

## Token Savings Estimate

Without skills: CLAUDE.md contains everything (~160 lines always in context).
With skills: CLAUDE.md stays lean. Each skill loads only when its topic comes up.
Estimated savings: ~40-60% fewer input tokens per message on focused tasks.
