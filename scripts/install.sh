#!/usr/bin/env bash
# install.sh — Copies the claude-setup .claude/ template into the current directory.
#
# Works with private repos: authenticates via `gh` CLI, SSH keys, or HTTPS
# credential helper — whatever you already have configured.
#
# On first run it clones claude-setup to $CLAUDE_SETUP_DIR (default ~/.claude-setup).
# On subsequent runs it git pulls to stay up to date.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/natanrotta/claude-setup/main/scripts/install.sh)
#   # or, after first install:
#   bash ~/.claude-setup/scripts/install.sh [target-dir]
#
# Env vars:
#   CLAUDE_SETUP_DIR  Local cache path (default: $HOME/.claude-setup)
#   CLAUDE_SETUP_REPO Remote in user/repo form (default: natanrotta/claude-setup)
#   CLAUDE_SETUP_REF  Branch / tag / SHA to install (default: main)

set -euo pipefail

CLAUDE_SETUP_DIR="${CLAUDE_SETUP_DIR:-$HOME/.claude-setup}"
CLAUDE_SETUP_REPO="${CLAUDE_SETUP_REPO:-natanrotta/claude-setup}"
CLAUDE_SETUP_REF="${CLAUDE_SETUP_REF:-main}"
TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"  # absolute path

c_blue=$'\033[1;34m'; c_green=$'\033[1;32m'; c_yellow=$'\033[1;33m'; c_red=$'\033[1;31m'; c_dim=$'\033[2m'; c_reset=$'\033[0m'
say()  { printf '%b%s%b\n' "$c_blue" "› $*" "$c_reset"; }
ok()   { printf '%b%s%b\n' "$c_green" "✓ $*" "$c_reset"; }
warn() { printf '%b%s%b\n' "$c_yellow" "⚠ $*" "$c_reset" >&2; }
die()  { printf '%b%s%b\n' "$c_red" "✗ $*" "$c_reset" >&2; exit 1; }

# ─── 1. Ensure local cache ────────────────────────────────────────────────────

if [ -d "$CLAUDE_SETUP_DIR/.git" ]; then
  say "Atualizando cache local em $CLAUDE_SETUP_DIR"
  git -C "$CLAUDE_SETUP_DIR" fetch --quiet origin "$CLAUDE_SETUP_REF" || die "git fetch falhou — verifique sua autenticação"
  git -C "$CLAUDE_SETUP_DIR" checkout --quiet "$CLAUDE_SETUP_REF"
  git -C "$CLAUDE_SETUP_DIR" reset --hard --quiet "origin/$CLAUDE_SETUP_REF" 2>/dev/null || true
  ok "Cache atualizado"
else
  say "Cache vazio — clonando $CLAUDE_SETUP_REPO em $CLAUDE_SETUP_DIR"
  mkdir -p "$(dirname "$CLAUDE_SETUP_DIR")"

  clone_with() {
    local url="$1"
    git clone --depth 1 --branch "$CLAUDE_SETUP_REF" "$url" "$CLAUDE_SETUP_DIR" --quiet 2>/dev/null
  }

  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    say "Tentando via gh CLI (autenticado)"
    gh repo clone "$CLAUDE_SETUP_REPO" "$CLAUDE_SETUP_DIR" -- --depth 1 --branch "$CLAUDE_SETUP_REF" --quiet \
      && ok "Cloned via gh CLI"
  elif clone_with "git@github.com:$CLAUDE_SETUP_REPO.git"; then
    ok "Cloned via SSH"
  elif clone_with "https://github.com/$CLAUDE_SETUP_REPO.git"; then
    ok "Cloned via HTTPS"
  else
    die "Falha ao clonar. Verifique: gh auth login OU chaves SSH configuradas OU credential helper HTTPS."
  fi
fi

# ─── 2. Sanity check ─────────────────────────────────────────────────────────

[ -d "$CLAUDE_SETUP_DIR/.claude" ] || die "$CLAUDE_SETUP_DIR/.claude não encontrado no clone"

# ─── 3. Target check ─────────────────────────────────────────────────────────

TARGET_CLAUDE="$TARGET/.claude"

if [ -d "$TARGET_CLAUDE" ]; then
  warn "$TARGET_CLAUDE já existe"
  read -p "Sobrescrever? (y/N) " -n 1 -r REPLY
  echo
  [[ "$REPLY" =~ ^[Yy]$ ]] || die "Abortado"
  rm -rf "$TARGET_CLAUDE"
fi

# ─── 4. Copy (excluding files that belong only in the template repo) ─────────

say "Copiando .claude/ para $TARGET_CLAUDE"

# rsync if available — clean exclusion. Fallback to cp + manual rm.
if command -v rsync >/dev/null 2>&1; then
  rsync -a \
    --exclude='CLAUDE.md' \
    "$CLAUDE_SETUP_DIR/.claude/" "$TARGET_CLAUDE/"
else
  cp -R "$CLAUDE_SETUP_DIR/.claude" "$TARGET_CLAUDE"
  # Remove files that are meta-instructions for the template repo, not for consumers.
  rm -f "$TARGET_CLAUDE/CLAUDE.md"
fi

ok ".claude/ instalado em $TARGET_CLAUDE"

# ─── 5. Next-steps banner ────────────────────────────────────────────────────

cat <<EOF

${c_dim}─────────────────────────────────────────${c_reset}
Próximo passo:

  ${c_green}cd $TARGET${c_reset}
  ${c_green}claude${c_reset}

Dentro do Claude Code:

  ${c_green}/bootstrap-claude${c_reset}

Pra atualizar o template no futuro, rode esse mesmo install.sh novamente —
ele faz git pull no cache e re-copia.
EOF
