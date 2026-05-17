# agent-rules

A curated collection of AI agent rules and skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Cursor](https://cursor.com).

Rules are defined once and symlinked into your projects. Both agents pick them up through their native conventions — no manual copying.

## Getting started

### 1. Fork and customise (recommended)

Fork this repository, add your own rules and skills, then use the installer to symlink them into your projects:

```sh
REPO_URL="https://github.com/yourname/agent-rules.git" \
  curl -fsSL https://raw.githubusercontent.com/yourname/agent-rules/main/install.sh \
  | sh -s -- ~/code/project-a ~/code/project-b
```

To pull in upstream changes later, merge from the original repo into your fork using standard git workflow.

### 2. Download and manage manually

Browse the [`agents/rules/`](agents/rules) directory, download the files you want, and place them in `.claude/content/` or `.cursor/rules/`. Update `AGENTS.md` to reference the new files. No installer needed — but no automated updates either.

> **Do not add custom rules to `~/.local/share/agent-rules/`.** The installer runs `git reset --hard` on updates, which will delete any local additions.

## How it works

The installer clones this repository to `~/.local/share/agent-rules` (configurable) and creates symlinks from each target project into that shared copy:

| Agent | Symlink target | Behaviour |
|---|---|---|
| **Cursor** | `.cursor/rules/<name>.mdc` | Agent-requested rules — Cursor's agent reads the rule body to decide when to apply each rule |
| **Claude Code** | `.claude/content/<name>.mdc` + `AGENTS.md` | Not auto-loaded — `AGENTS.md` at the project root acts as a TOC; Claude Code reads rule files on demand |

Skills (multi-file directories) are symlinked to both `.claude/skills/<name>/` and `.cursor/skills/<name>/`, following the [Agent Skills](https://agentskills.io) open standard.

All symlinks point back to the shared copy. Editing a rule inside a target project modifies the source — this is by design.

## Installation

### Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/project-a ~/code/project-b
```

### Install into all projects under a directory

Use `--recursive` to automatically find and install into every git repository one level below the given directory:

```sh
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- --recursive ~/code
```

### Install for one agent only

```sh
# Cursor only — skips .claude/content/ and AGENTS.md
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- --cursor-only ~/code/project-a

# Claude Code only — skips .cursor/rules/
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- --claude-only ~/code/project-a
```

### Using an environment variable

```sh
PROJECTS="~/code/project-a ~/code/project-b" \
  curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh | sh
```

### Prerequisites

- **git** (preferred) — the installer clones the repo with `--depth 1`
- **curl + tar** (fallback) — used automatically if git is not available

## Configuration

All configuration is via environment variables, set before running the installer.

| Variable | Default | Description |
|---|---|---|
| `REPO_URL` | `https://github.com/pecodez/agent-rules.git` | Git URL of the rules repository |
| `REPO_BRANCH` | `main` | Branch to install |
| `INSTALL_DIR` | `~/.local/share/agent-rules` | Where the shared copy is stored locally |
| `PROJECTS` | *(none)* | Space-separated list of project directories (alternative to passing as arguments) |

## Updating

Re-run the install command. There is no separate update step — installing and updating are the same operation.

1. The installer pulls the latest changes from the configured repo (`git fetch` + `git reset --hard`)
2. Symlinks are removed and recreated, picking up any new, renamed, or deleted rules

```sh
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/project-a ~/code/project-b
```

## What gets installed

For each target project, the installer creates:

```
your-project/
├── AGENTS.md                         → symlink (Claude Code TOC)
├── .claude/
│   ├── content/
│   │   ├── always-ask-agent-mode.mdc → symlink
│   │   ├── confidence-rating.mdc     → symlink
│   │   └── file-references.mdc       → symlink
│   └── skills/
│       └── <skill-name>/             → symlink (if skills exist)
└── .cursor/
    ├── rules/
    │   ├── always-ask-agent-mode.mdc → symlink
    │   ├── confidence-rating.mdc     → symlink
    │   └── file-references.mdc       → symlink
    └── skills/
        └── <skill-name>/             → symlink (if skills exist)
```

## Included rules

### `always-ask-agent-mode`

Requires the agent to ask for explicit user confirmation before making any changes. The agent must pause and confirm at every step — not just at the start of a task. Clarifying questions are never interpreted as permission to proceed.

### `confidence-rating`

Mandates a structured confidence footer on every response with a percentage rating (High / Medium / Low / Uncertain), justification, and sources. Includes Cursor mode-specific requirements (Ask / Plan / Agent) and Claude Code response-type requirements.

### `file-references`

Specifies the correct format for citing files and line numbers. Cursor uses `file://` URI links; Claude Code uses the `path:line` shorthand recognised by IDE integrations.

## Repository structure

```
agents/
  rules/              Shared *.mdc rule files (no frontmatter)
  cursor/
    rules/            Cursor-only rules or alwaysApply wrappers
  claude/
    rules/            Claude Code-only rules
    AGENTS.md         TOC symlinked into target projects
  skills/             Skill directories (each contains SKILL.md + supporting files)
install.sh            Installer script
AGENTS.md             Project documentation for AI agents reading this repo
LICENSE               MIT
README.md             This file
```

## Adding rules and skills (fork workflow)

After forking this repo, you can add your own rules and skills.

### Shared rules (both agents)

Create a `.mdc` file in `agents/rules/` with **no frontmatter**. Write conditions in the rule body:

```markdown
# My Rule

Apply this rule when [condition].

## Cursor: [Agent-specific section]
If you are operating in Cursor, ...

## Claude Code: [Agent-specific section]
If you are operating as Claude Code, ...
```

Then add an entry to `agents/claude/AGENTS.md` and re-run the installer.

### Cursor-only rules

Create a `.mdc` file in `agents/cursor/rules/`. You may use frontmatter here if guaranteed loading is needed:

```yaml
---
description: Brief description of the rule
alwaysApply: true
---
```

### Claude Code-only rules

Create a `.mdc` file in `agents/claude/rules/` and add an entry to `agents/claude/AGENTS.md`.

### Skills

1. Create a directory under `agents/skills/<skill-name>/`.
2. Add a `SKILL.md` file (required).
3. Add any supporting files alongside it.
4. Re-run the installer.

Both Claude Code and Cursor get the full skill directory at `.claude/skills/<name>/` and `.cursor/skills/<name>/` respectively.

## Important notes

- **Symlinks, not copies.** Editing a rule inside a target project modifies the shared source.
- **Re-run after changes.** After adding, renaming, or removing rules in your fork, re-run the installer on each target project.
- **Updates are destructive to local changes.** The installer runs `git reset --hard` when updating, so any files added directly to the local install directory will be lost. Use a fork to maintain custom rules.
- **POSIX sh.** The installer is written for `/bin/sh` compatibility. No Bash required.
- **Shallow clone.** The repo is cloned with `--depth 1` by default, so full git history is not available in the local copy.
- **`.gitignore` the symlinks.** You may want to add `.claude/` and `.cursor/` to your project's `.gitignore` so the symlinks aren't committed.

## License

MIT
