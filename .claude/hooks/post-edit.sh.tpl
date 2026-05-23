#!/usr/bin/env bash
# Post-edit hook (template).
#
# Reads tool input from stdin (JSON), greps the touched file for project-specific
# anti-patterns, and writes warnings to stderr (non-blocking).
#
# This template is rendered by /bootstrap-claude into one or more concrete scripts
# (typically post-edit-backend.sh and post-edit-frontend.sh) with the regex catalog
# inlined per layer.
#
# Hook spec: https://docs.anthropic.com/en/docs/claude-code/hooks

set -uo pipefail

# ---------------------------------------------------------------------
# Read and parse the hook payload
# ---------------------------------------------------------------------

payload="$(cat || true)"
[ -z "$payload" ] && exit 0

file=""
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
fi
if [ -z "$file" ]; then
  file="$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
fi

# ---------------------------------------------------------------------
# Layer filter — only run on files matching this hook's layer.
# {{LAYER_GLOB}} is replaced by the bootstrap (e.g. *apps/api/src/*.ts)
# ---------------------------------------------------------------------

case "$file" in
  {{LAYER_GLOB}}) ;;
  *) exit 0 ;;
esac

# Skip test / fixture files — different rules apply
case "$file" in
  {{TEST_GLOBS}}) exit 0 ;;
esac

[ -f "$file" ] || exit 0

# ---------------------------------------------------------------------
# Warnings helper
# ---------------------------------------------------------------------

warn() {
  printf '⚠️  [{{LAYER_NAME}}-hook] %s\n' "$1" >&2
}

# ---------------------------------------------------------------------
# Project-specific checks (rendered by /bootstrap-claude)
#
# Each check follows this shape:
#
# # CODE: short description
# if grep -nE 'REGEX' "$file" >/dev/null; then
#   lines="$(grep -nE 'REGEX' "$file" | head -3)"
#   warn "CODE: <message> Lines: $lines"
# fi
# ---------------------------------------------------------------------

{{CHECKS_BODY}}

exit 0
