# agent-rules

Shared AI agent rules and skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Cursor](https://cursor.com), managed from a single repository and symlinked into your projects.

Define your rules once, install them everywhere. When you update the repo, every project gets the latest rules automatically — no copying files around.

## How it works

The installer clones this repository to a local directory (`~/.local/share/agent-rules` by default) and creates symlinks from each target project into that shared copy. Both Claude Code and Cursor pick up the rules natively through their standard conventions:

| Agent | Symlink target | Behavior |
|---|---|---|
| **Claude Code** | `.claude/rules/<name>.md` | Auto-loaded into every session |
| **Cursor** | `.cursor/rules/<name>.mdc` | Applied as project rules (`alwaysApply` via frontmatter) |

Skills (multi-file directories) are symlinked to `.claude/skills/<name>/` for Claude Code. Cursor has no multi-file skill concept, so the skill's `SKILL.md` is exposed as a project rule instead.

Because all projects point back to the same source, editing a rule in any project's `.claude/rules/` or `.cursor/rules/` modifies the shared copy.

## Installation

### Quick start

Install rules into one or more project directories:

```sh
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/project-a ~/code/project-b
```

### Using an environment variable

```sh
PROJECTS="~/code/project-a ~/code/project-b" \
  curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh | sh
```

### Prerequisites

- **git** (preferred) — the installer clones the repo with `--depth 1`
- **curl + tar** (fallback) — used if git is not available

## Configuration

All configuration is done through environment variables. Set them before running the installer to override defaults.

| Variable | Default | Description |
|---|---|---|
| `REPO_URL` | `https://github.com/pecodez/agent-rules.git` | Git URL of the rules repository |
| `REPO_BRANCH` | `main` | Branch to install |
| `INSTALL_DIR` | `~/.local/share/agent-rules` | Where the shared copy of the repo is stored |
| `PROJECTS` | *(none)* | Space-separated list of project directories (alternative to passing them as arguments) |

### Examples

Install from a fork:

```sh
REPO_URL="https://github.com/yourname/agent-rules.git" \
  curl -fsSL https://raw.githubusercontent.com/yourname/agent-rules/main/install.sh \
  | sh -s -- ~/code/my-project
```

Use a custom local directory:

```sh
INSTALL_DIR="$HOME/.agent-rules" \
  curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/my-project
```

Install from a feature branch:

```sh
REPO_BRANCH="experimental" \
  curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/my-project
```

## Updating

Re-run the same install command. The installer is idempotent:

1. If the shared copy already exists, it pulls the latest changes (`git fetch` + `git reset --hard`)
2. Symlinks are removed and recreated, picking up any new or renamed rules

```sh
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/project-a ~/code/project-b
```

There is no separate update command — installing and updating are the same operation.

## What gets installed

For each target project, the installer creates:

```
your-project/
├── .claude/
│   ├── rules/
│   │   ├── always-ask-agent-mode.md  → symlink
│   │   └── confidence-rating.md      → symlink
│   └── skills/
│       └── <skill-name>/             → symlink (if skills exist)
└── .cursor/
    ├── rules/
    │   ├── always-ask-agent-mode.mdc → symlink
    │   ├── confidence-rating.mdc     → symlink
    │   └── skill-<name>.mdc          → symlink (if skills exist)
    └── skills/
```

## Included rules

### `always-ask-agent-mode`

Requires the agent to ask for explicit user confirmation before making any changes. The agent must pause and confirm at every step — not just at the start of a task. Clarifying questions are never interpreted as permission to proceed.

### `confidence-rating`

Mandates a structured confidence footer on every response with a percentage rating (High / Medium / Low / Uncertain), justification, and sources. Defines mode-specific requirements for Ask, Plan, and Agent modes.

## Repository structure

```
agents/
  rules/              *.md or *.mdc rule files
  skills/             skill directories (each contains SKILL.md + supporting files)
install.sh            installer script
AGENTS.md             project documentation for AI agents
LICENSE               MIT
README.md             this file
```

## Adding your own rules

1. Create a new `.mdc` file in `agents/rules/`:

   ```yaml
   ---
   description: Brief description of what the rule does
   globs:
   alwaysApply: true
   ---
   ```

2. Write the rule content in markdown below the frontmatter.

3. Re-run the installer on your projects to pick up the new rule.

## Adding skills

1. Create a directory under `agents/skills/<skill-name>/`.
2. Add a `SKILL.md` file (required).
3. Add any supporting files alongside it.
4. Re-run the installer.

Claude Code gets the full skill directory. Cursor sees `SKILL.md` as a project rule named `skill-<name>.mdc`.

## Important notes

- **Symlinks, not copies.** Editing a rule file inside a target project modifies the shared source. This is by design — it keeps everything in sync.
- **Re-run after changes.** After adding, renaming, or removing rules, re-run the installer on each target project.
- **POSIX sh.** The installer is written for `/bin/sh` compatibility. No Bash required.
- **Shallow clone.** The repo is cloned with `--depth 1` by default, so full git history is not available in the local copy.
- **`.gitignore` the symlinks.** You may want to add `.claude/` and `.cursor/rules/` to your project's `.gitignore` so the symlinks aren't committed.

## License

MIT
