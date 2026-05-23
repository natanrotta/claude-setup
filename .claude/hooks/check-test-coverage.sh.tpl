#!/usr/bin/env bash
# Test coverage gate (template).
#
# Compares the current branch against the base branch and refuses to proceed
# if a new (added/modified) source file lacks its co-located test file.
#
# Designed to be invoked from /finish-task.
# Exit 2 = block. Exit 0 = pass. Stderr is shown to the agent.
#
# The bootstrap renders this template with the project's actual suffix-to-spec
# mapping. If the project does not enforce test coverage, the bootstrap deletes
# this script entirely.

set -uo pipefail

BASE_BRANCH="{{BASE_BRANCH}}"
SOURCE_GLOB="{{SOURCE_GLOB}}"

# Resolve repo root (worktree)
root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$root" ]; then
  echo "[coverage-gate] Not inside a git repo — skipping." >&2
  exit 0
fi

cd "$root"

# Make sure we have the base branch locally
git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null || true

# Compute changed source files vs base
changed="$(git diff --name-only --diff-filter=AM "origin/$BASE_BRANCH...HEAD" -- $SOURCE_GLOB 2>/dev/null || true)"

if [ -z "$changed" ]; then
  exit 0
fi

missing=()

while IFS= read -r f; do
  [ -z "$f" ] && continue

  # Skip test / fixture / mock files
  case "$f" in
    {{TEST_GLOBS}}) continue ;;
  esac

  # Determine expected spec based on the project's mapping
  spec=""
{{SUFFIX_MAPPING_CASES}}

  if [ -n "$spec" ] && [ ! -f "$spec" ]; then
    missing+=("$f → expected: $spec")
  fi
done <<< "$changed"

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo ""
    echo "❌ Test coverage gate failed."
    echo ""
    echo "The following source files were added/modified but have no co-located test file:"
    echo ""
    for entry in "${missing[@]}"; do
      echo "  - $entry"
    done
    echo ""
    echo "Test coverage is mandatory in this project (see CLAUDE.md / patterns/BASELINE.md § Tests)."
    echo "Create the missing tests and re-run /finish-task."
    echo ""
    echo "If a test is genuinely not required for a specific file, invoke /finish-task with"
    echo "argument 'skip-coverage-gate=<file>' and document the reason in the PR body."
  } >&2
  exit 2
fi

exit 0
