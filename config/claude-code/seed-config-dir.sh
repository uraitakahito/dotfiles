#!/bin/bash
#
# seed-config-dir.sh — symlink dotfiles' Claude Code config into $CLAUDE_CONFIG_DIR.
#
# Why this is separate from install.sh:
#   The Apple `container` dev image mounts a named volume over
#   $CLAUDE_CONFIG_DIR (=/claude-config) at RUNTIME so `claude --resume`
#   survives `--rm`. That mount SHADOWS the symlinks install.sh creates at
#   BUILD time. docker-entrypoint.sh calls this script AFTER the volume is
#   mounted to re-create them. Idempotent (ln -f); safe to run on the host
#   too (install.sh delegates here).
#
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#
# Claude Code config directory (same canonical expression as install.sh and
# config/zsh/conf.d/02-claude.zsh). Honor an existing CLAUDE_CONFIG_DIR
# (e.g. a Dev Container's ENV=/claude-config); otherwise default to the XDG
# path so install and runtime resolve to the same location.
#
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}"

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/hooks"
ln -fs "$SCRIPT_DIR/settings.json"   "$CLAUDE_DIR/settings.json"
ln -fs "$SCRIPT_DIR/CLAUDE.md"       "$CLAUDE_DIR/CLAUDE.md"
ln -fs "$SCRIPT_DIR/statusline.sh"   "$CLAUDE_DIR/statusline.sh"
ln -fs "$SCRIPT_DIR/hooks/notify.sh" "$CLAUDE_DIR/hooks/notify.sh"
