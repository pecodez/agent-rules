# AGENTS.md

## Project Overview

**agent-rules** is a shared repository of AI agent rules and skills that get symlinked into multiple project directories. It provides a single source of truth for Cursor (`.cursor`) and Claude Code (`.claude`) agent configurations.

Licensed under MIT. Author: Phil Ewington.

## Repository Structure

```
agents/
  rules/           # Flat rule files (*.mdc for Cursor format)
    always-ask-agent-mode.mdc
    confidence-rating.mdc
  skills/           # Skill directories (each contains SKILL.md + supporting files)
    <skill-name>/
      SKILL.md
      ...
install.sh          # Installer script — clones repo and symlinks into target projects
LICENSE
```

### Key Concepts

- **Rules** (`agents/rules/*.md` or `*.mdc`): Flat markdown files defining agent behavior. Each becomes both a Claude Code auto-loaded rule and a Cursor project rule.
- **Skills** (`agents/skills/<name>/`): Directories containing a `SKILL.md` plus optional supporting files. Symlinked as skills for both Claude Code and Cursor.

## Installation & Usage

The installer (`install.sh`) clones/updates this repo to `~/.local/share/agent-rules` and creates symlinks into target project directories.

```sh
# Install into one or more projects
curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
  | sh -s -- ~/code/proj1 ~/code/proj2

# Or via environment variable
PROJECTS="~/code/proj1 ~/code/proj2" \
  curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh | sh
```

### Environment Overrides

| Variable | Default | Description |
|---|---|---|
| `REPO_URL` | `https://github.com/pecodez/agent-rules.git` | Git URL of the rules repo |
| `REPO_BRANCH` | `main` | Branch to install |
| `INSTALL_DIR` | `~/.local/share/agent-rules` | Where the master copy lives |

## How the Installer Works

1. Fetches/updates the repo via `git clone` (preferred) or `curl + tar` (fallback)
2. For each target project directory:
   - Creates `.claude/rules/`, `.claude/skills/`, `.cursor/rules/`, `.cursor/skills/`
   - Symlinks each `agents/rules/*.md` or `*.mdc` file → `.claude/rules/<name>.md` and `.cursor/rules/<name>.mdc`
   - Symlinks each `agents/skills/<name>/` directory → `.claude/skills/<name>/` and `.cursor/skills/<name>/`
3. Uses the `relink()` helper for idempotent symlink creation (removes existing before creating)

## Adding New Rules

1. Create a new `.mdc` file in `agents/rules/`
2. Use Cursor frontmatter format at the top:
   ```yaml
   ---
   description: Brief description of the rule
   globs:                    # optional file glob patterns
   alwaysApply: true         # or false
   ---
   ```
3. Write the rule content in markdown below the frontmatter
4. Re-run the installer on target projects to pick up new rules

## Adding New Skills

1. Create a new directory under `agents/skills/<skill-name>/`
2. Add a `SKILL.md` file (required — this is what Cursor sees)
3. Add any supporting files alongside it
4. Re-run the installer

## Conventions

- **Shell script style**: The installer uses POSIX `sh` (`set -eu`), not Bash. Keep it portable.
- **Helper functions**: `log()`, `warn()`, `die()`, `have()` for colored output and capability checking.
- **Idempotent operations**: The `relink()` function ensures re-running is safe — it removes and recreates symlinks.
- **Rule file format**: Rules use `.md` or `.mdc` extension with YAML frontmatter (`description`, `globs`, `alwaysApply` fields). The installer handles both extensions.


