---
name: acli-jira
description: Work with Jira via the ACLI. Covers viewing, searching, creating, editing, transitioning, assigning, and commenting on tickets using acli jira subcommands. Use when the user wants to read or manage Jira work items from the terminal.
---

# acli-jira Skill

## Purpose

Use this skill to interact with Jira. Read tickets, create new work items, update existing ones, search with JQL, transition status, assign, comment, or browse projects. `acli jira` provides full Jira Cloud management from the CLI.

## Quick Reference

| Command | Purpose |
|---|---|
| `acli jira workitem view <KEY>` | View a ticket's details, description, status, assignee |
| `acli jira workitem search --jql "..."` | Find tickets using JQL |
| `acli jira workitem create` | Create a new ticket |
| `acli jira workitem edit --key <KEY>` | Modify summary, description, labels, type, or assignee |
| `acli jira workitem transition --key <KEY>` | Move a ticket to a new status |
| `acli jira workitem assign --key <KEY>` | Change or remove a ticket's assignee |
| `acli jira workitem comment create --key <KEY>` | Add a comment |
| `acli jira workitem comment list --key <KEY>` | Read comments |
| `acli jira project list` | List available projects and discover project keys |
| `acli jira project view --key <KEY>` | View details of a specific project |
| `acli jira sprint list-workitems` | List tickets in a sprint |
| `acli jira board search` | Find boards by name or keyword |

---

## Core Concepts

- **Always use `--json`** on read commands (`view`, `search`, `comment list`, `project list`, etc.) to get machine-readable output.
- **Always use `--yes`** on mutation commands (`edit`, `transition`, `assign`) to skip interactive confirmation prompts that would hang in a non-interactive shell.
- **JQL** (Jira Query Language) is used for searching. Pass it via `--jql "..."`.
- **`@me`** is a shorthand for the authenticated user (works in `--assignee`).
- **Labels** are comma-separated: `--label "bug,backend,urgent"`.
- **Work item types** use Jira issue types: `Task`, `Bug`, `Story`, `Epic`, `Sub-task`, etc. Pass via `--type`.
- **Keys** are project-prefixed IDs like `PROJ-123`. Multiple keys are comma-separated: `--key "PROJ-1,PROJ-2"`.

---

## Recommended Workflow

1. **Discover projects**: `acli jira project list --json` to find available project keys.
2. **Search for tickets**: `acli jira workitem search --jql "project = PROJ AND ..." --json` to find relevant work items.
3. **View a ticket**: `acli jira workitem view PROJ-123 --json` to read full details.
4. **Create/edit/transition** as needed using the commands below.

---

## Common JQL Patterns

```sh
# All open tickets in a project
--jql "project = PROJ AND status != Done"

# Tickets assigned to me
--jql "assignee = currentUser()"

# Bugs created this week
--jql "project = PROJ AND type = Bug AND created >= startOfWeek()"

# Tickets with a specific label
--jql "project = PROJ AND labels = backend"

# Search by summary text
--jql "project = PROJ AND summary ~ \"search term\""

# High priority open items
--jql "project = PROJ AND priority in (High, Highest) AND status != Done"

# Recently updated
--jql "project = PROJ AND updated >= -7d ORDER BY updated DESC"
```

---

## Examples

### View a ticket

```sh
acli jira workitem view PROJ-123 --json

# View specific fields only
acli jira workitem view PROJ-123 --fields "summary,status,assignee,labels,comment" --json
```

### Search for tickets

```sh
# Search with JQL, get JSON output
acli jira workitem search --jql "project = PROJ AND status = 'In Progress'" --json

# Search with specific fields and a result limit
acli jira workitem search --jql "project = PROJ AND assignee = currentUser()" \
  --fields "key,summary,status,priority,labels" --limit 20 --json

# Get count of matching tickets
acli jira workitem search --jql "project = PROJ AND type = Bug" --count
```

### Create a ticket

```sh
# Basic creation
acli jira workitem create \
  --project "PROJ" \
  --type "Task" \
  --summary "Implement feature X" \
  --description "Detailed description here" \
  --label "backend,feature" \
  --assignee "@me" \
  --json

# Create a bug with a parent (sub-task)
acli jira workitem create \
  --project "PROJ" \
  --type "Bug" \
  --summary "Fix login timeout" \
  --description "Users report timeout after 30s on the login page" \
  --label "bug,auth" \
  --parent "PROJ-100" \
  --json

# Create with description from a file
acli jira workitem create \
  --project "PROJ" \
  --type "Story" \
  --summary "User onboarding flow" \
  --description-file description.txt \
  --json
```

### Edit a ticket

```sh
# Edit summary and labels
acli jira workitem edit --key "PROJ-123" \
  --summary "Updated summary" \
  --labels "backend,urgent" \
  --yes --json

# Change assignee
acli jira workitem edit --key "PROJ-123" \
  --assignee "user@company.com" \
  --yes --json

# Remove labels
acli jira workitem edit --key "PROJ-123" \
  --remove-labels "stale" \
  --yes --json
```

### Transition a ticket

```sh
# Move to In Progress
acli jira workitem transition --key "PROJ-123" --status "In Progress" --yes --json

# Mark as Done
acli jira workitem transition --key "PROJ-123" --status "Done" --yes --json

# Transition multiple tickets
acli jira workitem transition --key "PROJ-1,PROJ-2,PROJ-3" --status "Done" --yes --json
```

### Assign a ticket

```sh
# Assign to self
acli jira workitem assign --key "PROJ-123" --assignee "@me" --yes --json

# Assign to someone else
acli jira workitem assign --key "PROJ-123" --assignee "user@company.com" --yes --json

# Remove assignee
acli jira workitem assign --key "PROJ-123" --remove-assignee --yes --json
```

### Comments

```sh
# Add a comment
acli jira workitem comment create --key "PROJ-123" --body "This is ready for review"

# List comments
acli jira workitem comment list --key "PROJ-123" --json
```

### Projects

```sh
# List all projects
acli jira project list --json

# View a specific project
acli jira project view --key "PROJ" --json

# List recently viewed projects
acli jira project list --recent --json
```

### Sprints and boards

```sh
# Find a board
acli jira board search --name "My Team" --json

# List sprints on a board
acli jira board list-sprints --id 42 --json

# List tickets in a sprint
acli jira sprint list-workitems --sprint 101 --board 42 --json
```

---

## Never / Always

**Never:**
- Never omit `--yes` on mutation commands (`edit`, `transition`, `assign`) - the interactive prompt will hang in a non-interactive shell.
- Never assume status names are universal - they are project-specific. If a transition fails, the error message lists valid statuses.
- Never create tickets without confirming the project key first - use `acli jira project list --json` to discover available keys.

**Always:**
- Always use `--json` on read operations so output can be parsed and summarized.
- Always infer appropriate labels from context when creating tickets (area of codebase, type of work) to aid discoverability.
- Always use `--limit` or `--paginate` to manage large result sets.
- Always use `@me` as shorthand when assigning to the authenticated user.

---

## Important Tips

- When creating tickets, ask for the **project key** if not already known. Use `acli jira project list --json` to discover available projects.
- For custom fields not exposed as CLI flags, use `--from-json` with `additionalAttributes`. Generate a template with `acli jira workitem create --generate-json`.
- For board-specific conventions (required fields, custom field mappings, labels, templates), read `~/.config/opencode/skills/acli-jira/boards.md` if it exists. It contains project-specific conventions to follow before creating or managing tickets on known boards.
