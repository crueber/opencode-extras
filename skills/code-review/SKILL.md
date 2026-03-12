---
name: code-review
description: Use when completing a phase or feature implementation to dispatch a focused code reviewer subagent that evaluates work against requirements before proceeding
---

# Code Review

Dispatch a code-reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session history. This keeps the reviewer focused on the work product and preserves your own context for continued work.

**Announce at start:** "I'm using the code-review skill to request a review before proceeding."

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each phase in a plan-driven implementation
- After completing a major feature
- Before merging to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main for full branch
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch a code-reviewer subagent** using the Task tool with the prompt template from `code-reviewer.md` in this skill directory.

Fill in these placeholders:
- `{WHAT_WAS_IMPLEMENTED}` — What you just built
- `{PLAN_OR_REQUIREMENTS}` — What it was supposed to do (link to plan file or paste relevant section)
- `{BASE_SHA}` — Starting commit
- `{HEAD_SHA}` — Ending commit
- `{DESCRIPTION}` — One or two sentence summary

**3. Act on feedback:**
- Fix Critical issues immediately before proceeding
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if the reviewer is wrong — but provide technical reasoning

## Example

```
[Just completed Phase 2: Add verification function]

I'm using the code-review skill to request a review before proceeding.

BASE_SHA=$(git log --oneline | grep "Phase 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code-reviewer subagent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Phase 2 from plans/2025-01-08-conversation-index.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed with fixes

[Fix Important issues, note Minor ones, continue to Phase 3]
```

## Red Flags

**Never:**
- Skip review because "it's a small phase"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Dismiss valid technical feedback without reasoning

**If the reviewer is wrong:**
- Push back with technical reasoning
- Show code or tests that prove it works
- Request clarification on the concern

## Supporting Template

The reviewer subagent prompt template is at `code-reviewer.md` in this directory.
