#!/bin/bash
#
# container-init.sh — set up dotfiles' container-side conventions at startup.
#
# Called by the dev image's docker-entrypoint.sh *after* the volumes are
# mounted. The template's entrypoint stays generic; this script owns the
# specifics (volume ownership, Claude Code config). Best-effort and
# idempotent; it must never abort the container (the caller runs under set -e).
#
set -u

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Make a freshly-mounted (root-owned) named volume writable by the dev user.
# No-op if the path is empty or not a directory. Never fatal.
_own() {
	[ -n "${1:-}" ] && [ -d "$1" ] && sudo -n chown -R "$(id -u):$(id -g)" "$1" 2>/dev/null || true
}

# 1) Volume ownership.
_own "${CLAUDE_CONFIG_DIR:-}"
_own /zsh-volume

# 2) Claude Code config: re-create the symlinks a mounted volume shadows.
[ -n "${CLAUDE_CONFIG_DIR:-}" ] && "$HERE/config/claude-code/seed-config-dir.sh" || true
