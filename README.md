# opencode-extras

Personal collection of custom [OpenCode](https://opencode.ai) commands, modes, and skills, managed in a single repo and symlinked into `~/.config/opencode`.

## Structure

```
agents/        # Custom agent modes (.md files)
commands/      # Custom slash commands
skills/        # Reusable skill instructions loaded on demand (SKILL.md files)
opencode.json  # OpenCode config (permissions, plugins) - review before installing
install.sh     # Symlinks files into ~/.config/opencode
remove.sh      # Removes those symlinks
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

## Usage

Clone this repo anywhere, then run the install script:

```sh
./install.sh
```

The script requires `~/.config/opencode` to already exist (i.e., opencode must be installed). It creates the `agents` and `skills` subdirectories as needed, symlinks each file from this repo into the appropriate location, and symlinks `opencode.json` as a top-level config file that controls OpenCode permissions and plugins. Review `opencode.json` before running — it encodes personal preferences. Running the script again is safe — already-linked files are skipped, and stale symlinks pointing into this repo are cleaned up automatically.

To remove the symlinks:

```sh
./remove.sh
```

This only removes symlinks that point to files in this repo; any files that were not symlinked are left alone.
