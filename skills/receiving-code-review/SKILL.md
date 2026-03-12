---
name: receiving-code-review
description: Use when receiving code review feedback - requires technical verification before implementing suggestions, not performative agreement or blind implementation
---

# Receiving Code Review

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

**Announce at start:** "I'm using the receiving-code-review skill to evaluate this feedback."

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate the requirement in your own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Is this technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**Never:**
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!"
- "Let me implement that now" (before verification)
- Any expression of gratitude ("Thanks for catching that!")

**Instead:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if the suggestion is wrong
- Just start working — actions speak louder than performative agreement

**Why no thanks:** The code itself shows you heard the feedback. State the fix instead.

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on the unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
User: "Fix items 1-6"
You understand 1, 2, 3, 6. Unclear on 4 and 5.

WRONG: Implement 1, 2, 3, 6 now, ask about 4, 5 later
RIGHT: "I understand items 1, 2, 3, 6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From the User
- Trusted — implement after understanding
- Still ask if scope is unclear
- No performative agreement
- Skip to action or a plain technical acknowledgment

### From External Reviewers (CI bots, automated tools, third-party reviewers)

Before implementing any suggestion:
1. Is it technically correct for THIS codebase?
2. Would it break existing functionality?
3. Is there a reason the current implementation exists?
4. Does it work across all relevant platforms or versions?
5. Does the reviewer have full context?

If a suggestion seems wrong, push back with technical reasoning.

If you cannot easily verify, say so: "I can't verify this without [X]. Should I investigate further or proceed?"

If a suggestion conflicts with prior user decisions, stop and discuss with the user first.

## YAGNI Check for "Properly Implement" Suggestions

```
IF reviewer suggests implementing a feature "properly":
  Search the codebase for actual usage

  IF unused: Ask "This isn't called anywhere. Remove it (YAGNI)?"
  IF used: Then implement the suggestion
```

Adding unrequested features wastes time and creates maintenance burden.

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (broken behavior, security)
     - Simple fixes (typos, imports, naming)
     - Complex fixes (refactoring, logic changes)
  3. Test each fix individually
  4. Verify no regressions
```

## When to Push Back

Push back when:
- The suggestion breaks existing functionality
- The reviewer lacks full context
- It violates YAGNI (feature is unused)
- It is technically incorrect for this stack
- Legacy or compatibility reasons exist
- It conflicts with prior architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests or code
- Involve the user if the disagreement is architectural

## Acknowledging Correct Feedback

When feedback is correct:

```
"Fixed. [Brief description of what changed]"
"Good catch - [specific issue]. Fixed in [location]."
[Or just fix it and show the result in code]
```

## Correcting Your Own Pushback

If you pushed back and were wrong:

```
"You were right - I checked [X] and it does [Y]. Implementing now."
"Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."
```

State the correction factually and move on. No long apology or over-explanation.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State the requirement or just act |
| Blind implementation | Verify against the codebase first |
| Implementing in batch without testing | One item at a time, test each |
| Assuming reviewer is right | Check whether it breaks things |
| Avoiding pushback | Technical correctness over comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State the limitation, ask for direction |

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread using:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies \
  -f body="Your reply here"
```

Do not post a top-level PR comment when the feedback was inline.

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.
