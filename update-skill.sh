#!/usr/bin/env bash
#
# Sync Flava skills (and skill-creator-v2) into a project's .claude/skills.
# Does not modify claude.md or Copilot instructions — only installs new files
# or updates files that differ from this repo.
#
# Usage:
#   cd /path/to/your-project
#   /path/to/ted-skill/update-skill.sh
#
#   # custom destination:
#   ./update-skill.sh ~/.config/custom/.claude/skills
#
# Requires: run from a checkout of ted-skill (or pass REPO_ROOT).
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_SKILLS="${1:-$PWD/.claude/skills}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; }

# Optional override: REPO_ROOT=/path/to/ted-skill ./update-skill.sh
if [[ -n "${REPO_ROOT_OVERRIDE:-}" ]]; then
  REPO_ROOT="$(cd "$REPO_ROOT_OVERRIDE" && pwd)"
fi

MARKER="$REPO_ROOT/testing-skill/flava/flava-jira-check/SKILL.md"
if [[ ! -f "$MARKER" ]]; then
  err "This script must run against the ted-skill repo (missing: $MARKER)"
  err "Clone the repo, or install via: install-flava-skill.sh"
  exit 1
fi

mkdir -p "$DEST_SKILLS"

sync_file() {
  local rel="$1"
  local src="$REPO_ROOT/$rel"
  local dest="$2"
  if [[ ! -f "$src" ]]; then
    err "Missing source file: $src"
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
    ok "installed $rel → $(basename "$dest")"
    return 0
  fi
  if cmp -s "$src" "$dest"; then
    info "unchanged $(basename "$dest")"
    return 0
  fi
  cp "$src" "$dest"
  ok "updated $rel → $(basename "$dest")"
}

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  Flava skills sync (no claude.md)      ║"
echo "╚════════════════════════════════════════╝"
echo ""
info "Repo:  $REPO_ROOT"
info "Dest:  $DEST_SKILLS"
echo ""

# --- skill-creator-v2 ---
info "skill-creator-v2"
SKILL_CREATOR_REL=(
  "skills/skill-creator-v2/SKILL.md"
  "skills/skill-creator-v2/LICENSE.txt"
  "skills/skill-creator-v2/agents/analyzer.md"
  "skills/skill-creator-v2/agents/comparator.md"
  "skills/skill-creator-v2/agents/grader.md"
  "skills/skill-creator-v2/assets/eval_review.html"
  "skills/skill-creator-v2/eval-viewer/generate_review.py"
  "skills/skill-creator-v2/eval-viewer/viewer.html"
  "skills/skill-creator-v2/references/schemas.md"
  "skills/skill-creator-v2/scripts/__init__.py"
  "skills/skill-creator-v2/scripts/aggregate_benchmark.py"
  "skills/skill-creator-v2/scripts/generate_report.py"
  "skills/skill-creator-v2/scripts/improve_description.py"
  "skills/skill-creator-v2/scripts/package_skill.py"
  "skills/skill-creator-v2/scripts/quick_validate.py"
  "skills/skill-creator-v2/scripts/run_eval.py"
  "skills/skill-creator-v2/scripts/run_loop.py"
  "skills/skill-creator-v2/scripts/utils.py"
)
for rel in "${SKILL_CREATOR_REL[@]}"; do
  sync_file "$rel" "$DEST_SKILLS/skill-creator-v2/${rel#skills/skill-creator-v2/}"
done

sync_flava_pair() {
  local name="$1"
  info "$name"
  sync_file "testing-skill/flava/$name/SKILL.md" "$DEST_SKILLS/$name/SKILL.md"
  if [[ -f "$REPO_ROOT/testing-skill/flava/$name/evals/evals.json" ]]; then
    sync_file "testing-skill/flava/$name/evals/evals.json" "$DEST_SKILLS/$name/evals/evals.json"
  fi
}

sync_flava_pair "flava-commit-skill"
sync_flava_pair "flava-jira-check"
sync_flava_pair "flava-jira-create-sre-ticket"
sync_flava_pair "flava-pr-skill"
sync_flava_pair "flava-weekly-report"

chmod -R a+rX "$DEST_SKILLS" 2>/dev/null || true

echo ""
ok "Skills synced under: $DEST_SKILLS"
echo ""
