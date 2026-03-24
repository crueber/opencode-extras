# opencode-extras

Personal collection of custom [OpenCode](https://opencode.ai) commands, modes, and skills. Also compatible with [Claude Code](https://claude.ai/code) via a separate install script. Everything is managed in a single repo.

## Structure

```
agents/              # Custom agent modes (.md files with YAML frontmatter)
commands/            # Custom slash commands
skills/              # Reusable skill instructions loaded on demand (SKILL.md files)
opencode.json        # OpenCode config (permissions, plugins) - review before installing
install.sh           # Symlinks files into ~/.config/opencode (OpenCode)
install-claude.sh    # Installs into ~/.claude (Claude Code)
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

### OpenCode

Clone this repo anywhere, then run:

```sh
./install.sh
```

The script requires `~/.config/opencode` to already exist (i.e., OpenCode must be installed). It creates the `agents`, `commands`, and `skills` subdirectories as needed, symlinks each file from this repo into the appropriate location, and symlinks `opencode.json` as a top-level config file that controls OpenCode permissions and plugins. Review `opencode.json` before running - it encodes personal preferences.

To remove the symlinks:

```sh
./remove.sh
```

This only removes symlinks that point to files in this repo; any other files are left alone.

### Claude Code

Clone this repo anywhere, then run:

```sh
./install-claude.sh
```

The script requires `~/.claude` to already exist (i.e., Claude Code must be installed). It:

- Symlinks `commands/` and `skills/` directly into `~/.claude/` - the format is compatible as-is
- Transforms and writes each agent from `agents/` into `~/.claude/agents/` - OpenCode-specific frontmatter fields (`temperature`, `mode`, `permissions`) are stripped and replaced with a Claude Code-compatible header; the markdown body is preserved verbatim; agents are given full tool access (permissive)

Running the script again is safe - symlinks that already point to this repo are skipped, stale symlinks are cleaned up, and agent files are always regenerated from source.
