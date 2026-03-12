# AGENTS.md

Guidance for agentic coding agents working in this repository.

## What This Repo Is

A personal collection of [OpenCode](https://opencode.ai) modes and skills, managed as a single repo and symlinked into `~/.config/opencode` via `install.sh`. There is no build system, no package manager, and no test suite. All content is shell scripts and Markdown.

## Repository Structure

```
modes/                        # Custom agent modes (.md files with YAML frontmatter)
skills/<skill-name>/SKILL.md  # Reusable skills, one per subdirectory
install.sh                    # Symlinks modes/ and skills/ into ~/.config/opencode
remove.sh                     # Removes those symlinks
README.md                     # Human-facing documentation
AGENTS.md                     # This file
```

## Build / Lint / Test Commands

There is no build step, no test runner, and no linter. Manual verification:

```sh
# Verify the install script runs cleanly (safe to re-run)
./install.sh

# Verify the remove script runs cleanly (safe to re-run)
./remove.sh

# Check shell scripts for syntax errors
bash -n install.sh
bash -n remove.sh

# Check that a new skill symlink was created correctly
ls -la ~/.config/opencode/skills/
```

There are no single-test or unit-test commands — this repo has no automated tests.

## Shell Script Conventions (`install.sh`, `remove.sh`)

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail` at the top of every script
- Variables: `UPPER_SNAKE_CASE` for globals, `local lower_snake_case` for function-locals
- Functions: `lower_snake_case` names
- Always declare local variables with `local` inside functions
- Quote all variable expansions: `"${VAR}"`, `"${array[@]}"`
- Use `[ ]` for file tests, `[[ ]]` for string/pattern comparisons
- Guard array iteration against empty globs: `[ -e "$file" ] || continue`
- Echo output is prefixed with two spaces for indentation: `echo "  linked: ..."`
- Scripts must be idempotent — running them multiple times must be safe

## Mode File Conventions (`modes/*.md`)

Each mode file is a Markdown document with a YAML frontmatter block:

```yaml
---
description: One-line description shown in the OpenCode mode picker
temperature: 0.1
tools:
  bash: true
  read: true
  grep: true
  write: true
  edit: true
---
```

- `description` is required and must be a single sentence
- `temperature` is typically `0.1` for deterministic, plan-following work
- List only the tools the mode actually needs
- The body is plain GitHub-flavored Markdown
- Use `##` for top-level sections, `###` for subsections
- Use `- [ ]` checkboxes for success criteria that agents can check off
- Use fenced code blocks with language tags (` ```sh `, ` ```markdown `, etc.)
- Write instructions in second-person imperative: "You will...", not "The agent should..."
- Avoid em-dashes in prose — use plain hyphens or rewrite the sentence

### Mode naming

- Filenames: `kebab-case.md`
- Descriptions: short, action-oriented ("Implement technical plans from plans/ with verification")

## Skill File Conventions (`skills/<name>/SKILL.md`)

Each skill lives in its own subdirectory. The file is a Markdown document with YAML frontmatter:

```yaml
---
name: skill-name
description: One or two sentence description loaded by the skill tool
---
```

- `name` must match the subdirectory name exactly
- `description` is shown when the skill is listed — make it self-contained and searchable
- The body follows the same Markdown conventions as modes
- Skills are loaded on demand; write them to be self-contained with no assumed context
- Announce usage at the start: `"I'm using the <skill-name> skill to..."`
- Include a Quick Reference table and Example Workflow section where appropriate
- Include explicit **Never** / **Always** red-flag sections for critical safety rules
- Remove all project-specific or person-specific references — skills must be generic

### Skill naming

- Directory and `name` field: `kebab-case`
- Filenames are always `SKILL.md` (uppercase)

## README Conventions

- Keep the Skills table in `README.md` in sync when adding or removing skills
- One row per skill: `` `skill-name` `` | short description
- Description should match or summarize the `description` field in `SKILL.md`

## General Editing Rules

- Never add AI attribution, co-author lines, or "Generated with" comments to any file
- Fix broken things immediately — do not defer obvious issues to a follow-up
- Prefer editing existing files over creating new ones
- Do not create documentation files unless explicitly requested
- Do not use emojis unless the user explicitly asks for them
- Commit messages: imperative mood, present tense, no trailing period
  - Good: `Add using-git-worktrees skill and update README`
  - Bad: `Added the git worktrees skill.`
- Group logically related changes into a single commit; unrelated changes get separate commits
- Never commit with `-A` or `.` glob — always stage files explicitly

## Adding a New Skill

1. Create `skills/<name>/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Write the skill body following the conventions above
4. Add a row to the Skills table in `README.md`
5. Run `./install.sh` to verify the symlink is created correctly
6. Commit both the new skill and the README update together

## Adding a New Mode

1. Create `modes/<name>.md`
2. Add YAML frontmatter with `description`, `temperature`, and `tools`
3. Write the mode body following the conventions above
4. Run `./install.sh` to verify the symlink is created correctly
5. Commit the new mode file

## Worktree Preference

If working in an isolated branch, place worktrees in `.worktrees/` (project-local, hidden).
Verify it is gitignored before creating: `git check-ignore -q .worktrees`
If not ignored, add `.worktrees/` to `.gitignore` and commit that change first.
