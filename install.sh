#!/bin/sh
# install.sh — Install agent rules and skills into project directories.
#
# Layout expected in this repo:
#   agents/rules/*.md or *.mdc         flat rule files
#   agents/skills/<skill>/SKILL.md     each skill is a subdirectory
#   agents/skills/<skill>/...          (optional supporting files)
#
# What this does for every target project:
#   .claude/rules/<rule>.md            → symlink (Claude Code auto-loaded rule)
#   .claude/skills/<skill>/            → symlink to the whole skill dir
#   .cursor/rules/<rule>.mdc           → symlink (Cursor project rule)
#   .cursor/skills/<skill>/            → symlink to the whole skill dir
#
# The master copy is cloned/updated under ~/.local/share/agent-rules so all
# projects share one source of truth — pull the repo to update everywhere.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
#     | sh -s -- ~/code/proj1 ~/code/proj2
#
#   # install into all git repos under ~/code
#   curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh \
#     | sh -s -- --recursive ~/code
#
#   # or via env var
#   PROJECTS="~/code/proj1 ~/code/proj2" \
#     curl -fsSL https://raw.githubusercontent.com/pecodez/agent-rules/main/install.sh | sh

set -eu

# ---- Configuration -------------------------------------------------------
# EDIT THIS to point at your repo (or override via env var at install time).
REPO_URL="${REPO_URL:-https://github.com/pecodez/agent-rules.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_TARBALL="${REPO_TARBALL:-${REPO_URL%.git}/archive/refs/heads/${REPO_BRANCH}.tar.gz}"
INSTALL_DIR="${INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/agent-rules}"

# ---- Helpers -------------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx \033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Replace whatever's at $2 with a symlink to $1 (idempotent).
relink() {
    src="$1"; dest="$2"
    if [ -L "$dest" ] || [ -e "$dest" ]; then
        rm -rf "$dest"
    fi
    ln -s "$src" "$dest"
}

# ---- Parse flags and target projects -------------------------------------
RECURSIVE=false
remaining=""
for arg in "$@"; do
    case "$arg" in
        -r|--recursive) RECURSIVE=true ;;
        *) remaining="$remaining \"$arg\"" ;;
    esac
done
eval "set -- $remaining" 2>/dev/null || set --

if [ "$#" -eq 0 ] && [ -n "${PROJECTS:-}" ]; then
    # shellcheck disable=SC2086
    set -- $PROJECTS
fi

if [ "$#" -eq 0 ]; then
    cat >&2 <<EOF
Usage: install.sh [--recursive] <project_dir> [project_dir ...]
   or: PROJECTS="<dir1> <dir2>" install.sh

Options:
  -r, --recursive  Find and install into all git repositories under the
                   given directories (one level deep)

Env overrides:
  REPO_URL     git URL of the rules repo
  REPO_BRANCH  branch to install (default: main)
  INSTALL_DIR  where the master copy lives (default: ~/.local/share/agent-rules)
EOF
    exit 1
fi

# If --recursive, expand each argument to its child git repos
if [ "$RECURSIVE" = true ]; then
    expanded=""
    for parent in "$@"; do
        if [ ! -d "$parent" ]; then
            warn "Skipping (not a directory): $parent"
            continue
        fi
        found=false
        for child in "$parent"/*/; do
            [ -d "$child" ] || continue
            [ -d "$child/.git" ] || continue
            expanded="$expanded \"$child\""
            found=true
        done
        if [ "$found" = false ]; then
            warn "No git repositories found under $parent"
        fi
    done
    if [ -z "$expanded" ]; then
        die "No git repositories found. Nothing to install."
    fi
    eval "set -- $expanded"
fi

# ---- Fetch or update master copy -----------------------------------------
mkdir -p "$(dirname "$INSTALL_DIR")"

if [ -d "$INSTALL_DIR/.git" ] && have git; then
    log "Updating existing checkout at $INSTALL_DIR"
    git -C "$INSTALL_DIR" fetch --quiet origin "$REPO_BRANCH"
    git -C "$INSTALL_DIR" reset --hard --quiet "origin/$REPO_BRANCH"
elif have git; then
    log "Cloning $REPO_URL → $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    git clone --quiet --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
elif have curl && have tar; then
    log "git not found; falling back to tarball download"
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    curl -fsSL "$REPO_TARBALL" | tar -xz -C "$INSTALL_DIR" --strip-components=1
else
    die "Need either 'git' or 'curl + tar' to fetch the repo."
fi

RULES_SRC="$INSTALL_DIR/agents/rules"
SKILLS_SRC="$INSTALL_DIR/agents/skills"

[ -d "$RULES_SRC" ]  || warn "No rules dir at $RULES_SRC (skipping rules)"
[ -d "$SKILLS_SRC" ] || warn "No skills dir at $SKILLS_SRC (skipping skills)"

# ---- Install into each target --------------------------------------------
install_to_project() {
    project="$1"

    if [ ! -d "$project" ]; then
        warn "Skipping (not a directory): $project"
        return
    fi

    abs_project="$(cd "$project" && pwd -P)"
    log "Installing into $abs_project"

    mkdir -p "$abs_project/.claude/skills"
    mkdir -p "$abs_project/.claude/rules"
    mkdir -p "$abs_project/.cursor/rules"
    mkdir -p "$abs_project/.cursor/skills"

    # Rules: flat *.md and *.mdc files
    if [ -d "$RULES_SRC" ]; then
        for rule in "$RULES_SRC"/*.md "$RULES_SRC"/*.mdc; do
            [ -e "$rule" ] || continue
            base="$(basename "$rule")"
            # Strip .mdc first, then .md, to get the bare name
            name="${base%.mdc}"
            name="${name%.md}"
            # Claude Code rule: auto-loaded into every session (always .md)
            relink "$rule" "$abs_project/.claude/rules/$name.md"
            # Cursor project rule: lives in .cursor/rules/ (always .mdc)
            relink "$rule" "$abs_project/.cursor/rules/$name.mdc"
        done
    fi

    # Skills: each is a subdirectory containing SKILL.md
    if [ -d "$SKILLS_SRC" ]; then
        for skill_dir in "$SKILLS_SRC"/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name="$(basename "$skill_dir")"
            skill_path="${skill_dir%/}"

            # Claude Code: full skill directory at .claude/skills/<name>/
            relink "$skill_path" "$abs_project/.claude/skills/$skill_name"

            # Cursor: full skill directory at .cursor/skills/<name>/
            relink "$skill_path" "$abs_project/.cursor/skills/$skill_name"
        done
    fi

    printf '    linked into %s/.claude and %s/.cursor\n' \
           "$abs_project" "$abs_project"
}

for project in "$@"; do
    install_to_project "$project"
done

log "Done."
