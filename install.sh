#!/usr/bin/env bash
# Install claude-env script + sample configs.
# Idempotent. Re-running is safe.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/bin"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m  %s\n' "$*" >&2; }

# 1. Script
mkdir -p "$BIN"
cp -v "$REPO/bin/claude-env" "$BIN/claude-env"
chmod +x "$BIN/claude-env"

# 2. PATH (bash + zsh, only if missing)
add_path() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  grep -qE 'PATH="?\$HOME/bin' "$rc" && return 0
  echo 'export PATH="$HOME/bin:$PATH"' >> "$rc"
  say "added \$HOME/bin to PATH in $rc"
}
add_path "$HOME/.bashrc"
add_path "$HOME/.zshrc"

# 3. Presets directory + sample (never overwrite existing)
mkdir -p "$CFG/claude-env"
if [[ ! -f "$CFG/claude-env/presets" ]]; then
  cp -v "$REPO/config/presets.example" "$CFG/claude-env/presets"
  say "created $CFG/claude-env/presets — edit it with your projects"
else
  say "$CFG/claude-env/presets already exists — leaving untouched"
fi

# 4. tmux.conf (ask before overwriting)
TMUX_CONF="$HOME/.tmux.conf"
if [[ -f "$TMUX_CONF" ]]; then
  warn "$TMUX_CONF exists — not overwriting. See $REPO/config/tmux.conf for reference."
else
  cp -v "$REPO/config/tmux.conf" "$TMUX_CONF"
  say "installed $TMUX_CONF"
fi

# 5. Ghostty config (ask before overwriting)
GHOSTTY_CONF="$CFG/ghostty/config"
mkdir -p "$CFG/ghostty"
if [[ -f "$GHOSTTY_CONF" ]]; then
  warn "$GHOSTTY_CONF exists — not overwriting. See $REPO/config/ghostty.conf for reference."
else
  cp -v "$REPO/config/ghostty.conf" "$GHOSTTY_CONF"
  say "installed $GHOSTTY_CONF"
fi

# 6. Dependency check
need=()
for tool in tmux git claude; do
  command -v "$tool" >/dev/null 2>&1 || need+=("$tool")
done
if (( ${#need[@]} )); then
  warn "missing required tools: ${need[*]}"
fi
command -v difit  >/dev/null 2>&1 || warn "difit not found (optional): npm i -g difit"
command -v ghostty >/dev/null 2>&1 || warn "ghostty not found (only needed if you use it as terminal)"

say "done. Open a new shell or run:  source ~/.bashrc"
say "then:  claude-env --list"
