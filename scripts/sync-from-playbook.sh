#!/usr/bin/env bash
# Copy AI playbook templates into the current repo (bootstrap or refresh).
# Usage: run from the root of YOUR project (not from inside the playbook repo).
#
#   curl -fsSL https://raw.githubusercontent.com/nebaricc/ai-native-dev-playbook/main/scripts/sync-from-playbook.sh | bash
#   # or clone the playbook and:
#   /path/to/ai-native-dev-playbook/scripts/sync-from-playbook.sh
#
# Environment:
#   PLAYBOOK_URL   Git URL (default: https://github.com/nebaricc/ai-native-dev-playbook.git)
#   PLAYBOOK_REF   Branch or tag (default: main)
#
# Flags:
#   --dry-run       Print actions only
#   --skip-root     Do not overwrite CLAUDE.md or .cursorrules (update skills/rules only)
#   --skills-only   Copy only templates/.claude/skills/ -> ./.claude/skills/ (smallest pull)
#   --with-ci       Also copy templates/.github/workflows/*.yml into .github/workflows/
#   -h, --help      Show help

set -euo pipefail

PLAYBOOK_URL="${PLAYBOOK_URL:-https://github.com/nebaricc/ai-native-dev-playbook.git}"
PLAYBOOK_REF="${PLAYBOOK_REF:-main}"
DRY_RUN=0
SKIP_ROOT=0
SKILLS_ONLY=0
WITH_CI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-root) SKIP_ROOT=1 ;;
    --skills-only) SKILLS_ONLY=1 ;;
    --with-ci) WITH_CI=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -40
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if [[ $SKILLS_ONLY -eq 1 ]] && [[ $SKIP_ROOT -eq 1 ]]; then
  echo "Note: --skills-only already skips root files; --skip-root is redundant." >&2
fi

if [[ ! -d .git ]]; then
  echo "Error: run this from the root of a git repository (no .git directory here)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If this script lives inside a checkout of the playbook, use it and skip clone.
if [[ -f "$SCRIPT_DIR/../templates/CLAUDE.md" ]]; then
  PLAYBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  echo "Using local playbook at $PLAYBOOK_ROOT"
else
  PLAYBOOK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/playbook-sync.XXXXXX")"
  cleanup() { rm -rf "$PLAYBOOK_ROOT"; }
  trap cleanup EXIT

  echo "Cloning $PLAYBOOK_URL (ref: $PLAYBOOK_REF) ..."
  if git clone --depth 1 --branch "$PLAYBOOK_REF" "$PLAYBOOK_URL" "$PLAYBOOK_ROOT" 2>/dev/null; then
    :
  else
    rm -rf "$PLAYBOOK_ROOT"
    mkdir -p "$PLAYBOOK_ROOT"
    git clone --depth 1 "$PLAYBOOK_URL" "$PLAYBOOK_ROOT"
    git -C "$PLAYBOOK_ROOT" checkout "$PLAYBOOK_REF"
  fi
fi

TEMPLATES="$PLAYBOOK_ROOT/templates"

if [[ ! -d "$TEMPLATES" ]]; then
  echo "Error: templates directory not found at $TEMPLATES" >&2
  exit 1
fi

run_cp() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would copy: $src -> $dest"
  else
    cp -f "$src" "$dest"
    echo "Updated: $dest"
  fi
}

run_rsync_dir() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would sync directory: $src/ -> $dest/"
  elif command -v rsync >/dev/null 2>&1; then
    # No --delete: keeps files you added locally; new/updated playbook files still copy over.
    rsync -a "$src/" "$dest/"
    echo "Synced: $dest/"
  else
    cp -a "$src"/. "$dest"/
    echo "Synced (cp): $dest/"
  fi
}

if [[ $SKILLS_ONLY -eq 1 ]]; then
  run_rsync_dir "$TEMPLATES/.claude/skills" "./.claude/skills"
  echo ""
  echo "Done. Only .claude/skills/ was synced. Ensure CLAUDE.md tells Claude to load skills when relevant."
  exit 0
fi

if [[ $SKIP_ROOT -eq 0 ]]; then
  run_cp "$TEMPLATES/CLAUDE.md" "./CLAUDE.md"
  run_cp "$TEMPLATES/.cursorrules" "./.cursorrules"
fi

run_rsync_dir "$TEMPLATES/.claude" "./.claude"
run_rsync_dir "$TEMPLATES/.cursor/rules" "./.cursor/rules"
mkdir -p ./specs
run_cp "$TEMPLATES/specs/_TEMPLATE.md" "./specs/_TEMPLATE.md"

if [[ $WITH_CI -eq 1 ]]; then
  mkdir -p ./.github/workflows
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would sync: $TEMPLATES/.github/workflows/ -> ./.github/workflows/"
  elif command -v rsync >/dev/null 2>&1; then
    rsync -a "$TEMPLATES/.github/workflows/" "./.github/workflows/"
    echo "Synced: ./.github/workflows/"
  else
    shopt -s nullglob
    for f in "$TEMPLATES"/.github/workflows/*.yml; do
      cp -f "$f" "./.github/workflows/"
    done
    echo "Copied CI workflow templates to ./.github/workflows/"
  fi
fi

echo ""
echo "Done. Customize CLAUDE.md and .cursorrules for your stack, then commit."
if [[ $SKIP_ROOT -eq 1 ]]; then
  echo "(Skipped CLAUDE.md / .cursorrules; merge any template changes manually if needed.)"
fi
