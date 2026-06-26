# Claude Code config directory.
#
# CLAUDE_CONFIG_DIR is the single base dir Claude Code reads
# (v2.1.191: process.env.CLAUDE_CONFIG_DIR ?? ~/.claude). settings.json,
# CLAUDE.md, statusline.sh, hooks, projects (sessions) and credentials all
# live under it.
#
# Honor an existing value (e.g. a Dev Container's ENV=/claude-config);
# otherwise default to the XDG path, matching tmux/git/ruff/pnpm/gemini
# under ~/.config. install.sh resolves the same expression so install and
# runtime agree on the location.
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}"
