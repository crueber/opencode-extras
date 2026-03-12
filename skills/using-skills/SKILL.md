---
name: using-skills
description: Establishes instruction priority and the rule for skill usage - user instructions always win, invoke relevant skills before acting
---

# Using Skills

## Instruction Priority

1. **User instructions** (AGENTS.md, direct requests) — highest priority, always wins
2. **Skills** — override default behavior where they apply
3. **Default behavior** — lowest priority

If AGENTS.md and a skill conflict, follow AGENTS.md.

## The Rule

**If a skill might apply, invoke it before acting — including before asking clarifying questions.**

If an invoked skill turns out not to fit, you don't have to follow it. But check first.

## Skill Priority

When multiple skills could apply:
1. **Process skills first** (debugging, planning) — determine HOW to approach the task
2. **Implementation skills second** — guide execution

## User Instructions Mean WHAT, Not HOW

"Add X" or "Fix Y" does not mean skip skills. The user says what to do; skills say how to do it well.
