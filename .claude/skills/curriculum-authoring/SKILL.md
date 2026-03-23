---
name: curriculum-authoring
description: >
  Writing curriculum content (Markdown lessons, concept explanations, quizzes, and annotated
  examples) for the DevOps learning platform. Use this skill whenever creating or editing files
  in the curriculum/ directory, writing lesson Markdown, building quiz JSON, designing concept
  explanations or annotated code examples for any subject. Also trigger when the user says
  "write a lesson", "add quiz questions", "create curriculum content", "explain a concept page",
  or references any curriculum subject content.
---

# Curriculum Authoring Skill

Covers lesson Markdown, quiz JSON, and concept page structure for all 7 subjects.

## File Structure Per Subject

```
curriculum/<subject>/
├── index.json          # subject metadata + lesson order
├── 01_topic/
│   ├── concept.md      # explanation + annotated examples
│   ├── quiz.json       # 5-10 questions per topic
│   └── examples/       # code snippets referenced by concept.md
│       ├── example_01.sh
│       └── example_02.conf
├── 02_topic/
│   └── ...
```

## index.json Schema

```json
{
  "subject": "linux",
  "title": "Linux Fundamentals",
  "description": "systemd, storage, permissions, processes, bash scripting",
  "lessons": [
    {
      "id": "01_systemd",
      "title": "systemd Service Management",
      "lab_id": "linux_01_systemd",
      "estimated_minutes": 25
    }
  ]
}
```

## concept.md Format

Use this structure consistently:

```markdown
# Topic Title

## What You'll Learn
- Bullet 1
- Bullet 2

## The Concept
2-4 paragraphs explaining the theory. Use analogies from the user's QA/security background
where possible ("Think of a systemd unit like a Jenkins job definition...").

## Annotated Example

<example file="examples/example_01.sh">
Line-by-line annotations. Use comments in the code AND prose below it.
</example>

## Common Mistakes
- Mistake 1: explanation
- Mistake 2: explanation

## Quick Reference
A cheat-sheet table or short reference the user can revisit.

## Next Steps
Link to the hands-on lab for this topic.
```

## Writing Style

- Write for someone who already codes and knows QA — skip "what is a terminal" level basics
- Use the user's context: on-premise, air-gapped, Jenkins/GitLab already in use
- Prefer concrete examples over abstract explanations
- Every concept should connect to a real scenario: "When your Jenkins build fails at 2am..."
- Keep explanations under 500 words per section — this person studies 30 min/day

## quiz.json Schema

```json
{
  "topic_id": "01_systemd",
  "questions": [
    {
      "id": "q1",
      "type": "multiple_choice",
      "question": "What command reloads systemd after editing a unit file?",
      "options": [
        "systemctl restart",
        "systemctl daemon-reload",
        "systemctl reload",
        "service reload"
      ],
      "correct": 1,
      "explanation": "daemon-reload re-reads unit files from disk. restart just restarts the service with the current loaded config."
    },
    {
      "id": "q2",
      "type": "fill_in",
      "question": "Complete the command: journalctl -u nginx --since '___'",
      "answer_pattern": "\\d+ (min|hour|day)s? ago",
      "example_answer": "5 minutes ago",
      "explanation": "journalctl --since accepts relative time expressions."
    }
  ]
}
```

Question types: `multiple_choice`, `fill_in`, `true_false`, `order_steps`.

## Quality Checklist

Before committing any curriculum content:
- [ ] concept.md has at least one annotated, runnable example
- [ ] quiz.json has 5+ questions covering the topic
- [ ] Every quiz question has an `explanation` field
- [ ] The lesson references a matching lab_id
- [ ] No external URLs — all content is self-contained
- [ ] Examples use tools available in the lab Docker image
