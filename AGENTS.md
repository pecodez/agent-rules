# AGENTS.md

## Project Overview

**agent-rules** is a shared repository of AI agent rules and skills for Claude Code and Cursor. Rules are defined once and symlinked into project directories. Both agents read the same source files through their native conventions.

Licensed under MIT. Author: Phil Ewington.

## Repository Structure

```
agents/
  rules/           Shared rules (*.mdc, no frontmatter). Symlinked into both
                   .cursor/rules/ and .claude/content/ for each target project.
  cursor/
    rules/         Cursor-only rules or alwaysApply frontmatter wrappers.
                   Symlinked into .cursor/rules/ only.
  claude/
    rules/         Claude Code-only rules. Symlinked into .claude/content/ only.
    AGENTS.md      TOC for Claude Code. Symlinked as AGENTS.md in target projects.
  skills/          Skill directories (each contains SKILL.md + supporting files).
install.sh         Installer — clones repo and symlinks into target projects.
LICENSE
README.md
```

### Rule format

Shared rules in `agents/rules/` use no frontmatter. Cursor treats them as agent-requested rules (the agent reads the rule body and decides when to apply it based on conditions written in prose). Claude Code reads them on demand via AGENTS.md.

Rules that have agent-specific behaviour use clearly headed sections:

```markdown
## Cursor: [Section Name]
If you are operating in Cursor, ...

## Claude Code: [Section Name]
If you are operating as Claude Code, ...
```

Rules in `agents/cursor/rules/` may use Cursor frontmatter (`alwaysApply`, `globs`) when guaranteed loading is required. Rules in `agents/claude/rules/` are plain markdown (`.mdc` extension, no frontmatter needed).

### Key Concepts

- **Shared rules** (`agents/rules/*.mdc`): Single source of truth for rules that apply to both agents. No frontmatter. Conditions written in the rule body.
- **Cursor-only rules** (`agents/cursor/rules/*.mdc`): Rules or frontmatter wrappers that are only relevant to Cursor.
- **Claude Code-only rules** (`agents/claude/rules/*.mdc`): Rules only relevant to Claude Code.
- **AGENTS.md** (`agents/claude/AGENTS.md`): Hand-maintained TOC. Symlinked into target projects so Claude Code knows which rules exist and when to read them. Rules are not auto-loaded — Claude Code reads them on demand.
- **Skills** (`agents/skills/<name>/`): Directories containing a `SKILL.md` plus optional supporting files. Symlinked for both agents.

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
   - Symlinks each `agents/rules/*.mdc` → `.cursor/rules/<name>.mdc` (Cursor) and `.claude/content/<name>.mdc` (Claude Code)
   - Symlinks each `agents/cursor/rules/*.mdc` → `.cursor/rules/<name>.mdc`
   - Symlinks each `agents/claude/rules/*.mdc` → `.claude/content/<name>.mdc`
   - Symlinks `agents/claude/AGENTS.md` → `AGENTS.md` (project root)
   - Symlinks each `agents/skills/<name>/` → `.claude/skills/<name>/` and `.cursor/skills/<name>/`
3. Uses the `relink()` helper for idempotent symlink creation

Nothing is placed in `.claude/rules/` — Claude Code does not auto-load rules. AGENTS.md at the project root is the entry point.

## Adding New Rules

### Shared rule (both agents)

1. Create a `.mdc` file in `agents/rules/` with **no frontmatter**.
2. Write conditions and rule content in plain markdown.
3. If the rule has agent-specific behaviour, use `## Cursor:` and `## Claude Code:` sections.
4. Add an entry to `agents/claude/AGENTS.md` with the condition and `@.claude/content/<name>.mdc` reference.
5. Re-run the installer on target projects.

### Cursor-only rule

1. Create a `.mdc` file in `agents/cursor/rules/`.
2. Add Cursor frontmatter if needed (`alwaysApply`, `globs`, `description`).
3. Re-run the installer.

### Claude Code-only rule

1. Create a `.mdc` file in `agents/claude/rules/`.
2. Add an entry to `agents/claude/AGENTS.md`.
3. Re-run the installer.

## Adding New Skills

1. Create a new directory under `agents/skills/<skill-name>/`
2. Add a `SKILL.md` file (required — this is what Cursor sees)
3. Add any supporting files alongside it
4. Re-run the installer

## Conventions

- **Shell script style**: The installer uses POSIX `sh` (`set -eu`). Keep it portable.
- **Helper functions**: `log()`, `warn()`, `die()`, `have()` for colored output and capability checking.
- **Idempotent operations**: The `relink()` function ensures re-running is safe.
- **No frontmatter in shared rules**: Frontmatter belongs only in `agents/cursor/rules/` when required.
- **AGENTS.md is the Claude Code entry point**: All Claude Code rule loading is mediated by AGENTS.md conditions.
