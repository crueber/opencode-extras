# opencode-extras

Personal collection of custom [OpenCode](https://opencode.ai) commands, modes, and skills. Also compatible with [Claude Code](https://claude.ai/code) and Pi. Everything is managed in a single repo.

## Structure

```
agents/              # Custom agent modes (.md files with YAML frontmatter)
commands/            # Custom slash commands
skills/              # Reusable skill instructions loaded on demand (SKILL.md files)
opencode.json        # OpenCode config (permissions, plugins) - review before installing
install.sh           # Unified installer entrypoint: ./install.sh <target>
install-claude.sh    # Thin compatibility wrapper for ./install.sh claude
remove.sh            # Removes the OpenCode symlinks
```

## Skills

Skills are loaded into a conversation on demand via the `skill` tool. Each skill lives in its own subdirectory under `skills/` with a `SKILL.md` file.

| Skill | Description |
|---|---|
| `analyze-code` | Analyzes codebase implementation details; dives into specific component details |
| `git-commit` | Creates a git commit with user approval and no AI attribution |
| `research-code` | Documents the codebase as-is for historical context |
| `search-web` | Researches questions using web search and returns sourced findings |
| `using-git-worktrees` | Creates isolated git worktrees with smart directory selection and safety verification |
| `systematic-debugging` | Forces root cause investigation before any fix is attempted; use for any bug or unexpected behavior |
| `code-review` | Dispatches a focused code reviewer subagent to evaluate a phase or feature against its requirements |
| `receiving-code-review` | Guides technical evaluation of incoming review feedback - verify before implementing, push back when wrong |
| `finishing-development-branch` | Verifies tests and presents structured merge/PR/discard options with worktree cleanup |
| `audiobookshelf-api` | Reference for the Audiobookshelf REST API - auth, all endpoint groups, filtering, pagination, and Socket.io events |
| `acli-jira` | Reference for working with Jira via the acli CLI - viewing, searching, creating, editing, transitioning, and commenting on tickets |
| `solidjs-conventions` | Best conventions for writing SolidJS front ends - signals, reactivity, control flow, stores, effects, and component patterns |
| `golang-conventions` | Idiomatic Go conventions for solid engineering discipline - error handling, interfaces, concurrency, testing, naming, and project structure |
| `ruby-conventions` | Idiomatic Ruby conventions for solid engineering discipline - naming, error handling, blocks, testing, metaprogramming, and project structure |

## Usage

### Unified installer

Clone this repo anywhere, then run:

```sh
./install.sh <target>
```

Supported targets:

- `opencode` - install into `~/.config/opencode`
- `claude` - install into `~/.claude`
- `pi` - install into `~/.pi/agent`

If you run `./install.sh` with no target, or with an invalid target, it prints usage and exits non-zero without installing anything.

Examples:

```sh
./install.sh opencode
./install.sh claude
./install.sh pi
```

### OpenCode target (`./install.sh opencode`)

Requires `~/.config/opencode` to already exist (OpenCode installed). The installer creates `agents`, `commands`, and `skills` subdirectories as needed, symlinks each file from this repo into the appropriate location, and symlinks `opencode.json` as a top-level config file that controls OpenCode permissions and plugins. Review `opencode.json` before running because it encodes personal preferences.

### Claude target (`./install.sh claude`)

Requires `~/.claude` to already exist (Claude Code installed). The installer:

- Symlinks `commands/` and `skills/` directly into `~/.claude/`
- Transforms each agent from `agents/` into `~/.claude/agents/` with Claude-compatible frontmatter (`name` and `description`) while preserving the markdown body
- Uses a sentinel comment to distinguish generated files from hand-authored files
- Cleans stale generated agent files and stale symlinks that pointed to removed repo content

`install-claude.sh` is kept as a wrapper that invokes `./install.sh claude` from the repo directory.

### Pi target (`./install.sh pi`)

Creates these directories as needed:

- `~/.pi/agent`
- `~/.pi/agent/skills`
- `~/.pi/agent/prompts`

The installer:

- Symlinks `skills/` into `~/.pi/agent/skills` with idempotent behavior and stale symlink cleanup
- Generates Pi prompt templates from `agents/*.md` into `~/.pi/agent/prompts/*.md`
  - Generated prompts include a sentinel comment
  - Prompts keep a `description` frontmatter field
  - OpenCode-specific frontmatter fields are dropped
  - Markdown body after frontmatter is preserved
  - Existing non-generated prompt files are not overwritten
  - Stale generated prompts are removed if source agents are deleted
- Prints a concise note that `commands/` has no direct Pi mapping

To remove the symlinks:

```sh
./remove.sh
```

This only removes symlinks that point to files in this repo; any other files are left alone.

`./remove.sh` only removes OpenCode symlinks under `~/.config/opencode`. It does not remove Claude artifacts under `~/.claude` or Pi artifacts under `~/.pi/agent`.

Running install commands again is safe. Existing correct symlinks are left in place, stale symlinks are cleaned up, and generated files are refreshed while preserving any non-generated files.
