#!/bin/bash
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# shellcheck source=config/zsh/functions/helper.zsh
source "$SCRIPT_DIR/config/zsh/functions/helper.zsh"

#
# Claude Code config directory (same canonical expression as
# config/zsh/conf.d/02-claude.zsh). Honor an existing CLAUDE_CONFIG_DIR
# (e.g. a Dev Container's ENV=/claude-config); otherwise default to the
# XDG path so install and runtime resolve to the same location.
#
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}"

#
# Sweep stale dotfiles symlinks under known link roots.
#
# Scope: we restrict the walk to directories install.sh actually links
# into. Walking the entire $HOME would trigger macOS TCC (Transparency,
# Consent, and Control — the privacy framework that gates access to
# Documents, Desktop, Photos, etc.) denials for ~/Documents, ~/Desktop,
# ~/Library/Mail, etc. when invoked from iTerm.
#

# HOME 直下のドットファイル (~/.vimrc, ~/.editorconfig, ~/.npmrc)
find "$HOME" -maxdepth 1 -type l -lname "$SCRIPT_DIR/*" -delete 2>/dev/null || true

# install.sh が貼る既知の親ディレクトリ群 (TCC 非保護領域のみ)
LINK_ROOTS=(
  "$CLAUDE_DIR"        # Claude Code config dir (CLAUDE_CONFIG_DIR or XDG default)
  "$HOME/.claude"      # legacy Claude location; sweep stale links left there
  "$HOME/.config"
  "$HOME/.docker"
  "$HOME/.vscode-server"
  "$HOME/Library/Application Support/Code/User"
)
for dir in "${LINK_ROOTS[@]}"; do
  [ -d "$dir" ] && find "$dir" -type l -lname "$SCRIPT_DIR/*" -delete 2>/dev/null || true
done

cd ~/ || exit

#
# tmux
#
# tmux 3.1+ supports ~/.config/tmux/tmux.conf
# https://github.com/tmux/tmux/wiki/FAQ#where-is-my-tmuxconf-file
#
mkdir -p ~/.config/tmux
ln -fs "$SCRIPT_DIR/config/tmux/tmux.conf" ~/.config/tmux/tmux.conf

#
# EditorConfig
#
ln -fs "$SCRIPT_DIR/config/editorconfig/editorconfig" ~/.editorconfig

#
# Vim
#
# Vim uses traditional ~/.vimrc location
# Future: Consider Neovim migration with ~/.config/nvim/init.vim
#
ln -fs "$SCRIPT_DIR/config/vim/vimrc" ~/.vimrc

#
# Git
#
# https://github.com/git/git/blob/master/Documentation/RelNotes/1.7.12.txt#L21-L23
mkdir -p ~/.config/git
ln -fs "$SCRIPT_DIR/config/git/config" ~/.config/git/config
ln -fs "$SCRIPT_DIR/config/git/ignore" ~/.config/git/ignore

#
# Git template (per-repo hooks via init.templateDir) — case A
#
# init.templateDir = ~/.config/git/template (set in config/git/config)
# Symlink the template DIRECTORY. The hook inside stays a REAL file, so
# `git init`/`clone` copies it as a real, self-contained file into each
# repo's .git/hooks -> portable across Docker / other machines.
# (Symlinking the hook FILE would copy an absolute-path symlink that breaks
#  when dotfiles live elsewhere, silently disabling gitleaks.)
# git-lfs hooks are intentionally NOT here; use `git lfs install --local`.
# -n keeps it idempotent (no nesting when the link already exists).
#
ln -fsn "$SCRIPT_DIR/config/git/template" ~/.config/git/template

#
# VS Code
#
if is-container; then
  mkdir -p ~/.vscode-server/data/Machine
  ln -fs "$SCRIPT_DIR/config/Code/User/settings.json" ~/.vscode-server/data/Machine/settings.json
  ln -fs "$SCRIPT_DIR/config/Code/User/mcp.json" ~/.vscode-server/data/Machine/mcp.json
elif is-darwin; then
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
  mkdir -p "$VSCODE_USER_DIR"
  ln -fs "$SCRIPT_DIR/config/Code/User/settings.json" "$VSCODE_USER_DIR/settings.json"
  ln -fs "$SCRIPT_DIR/config/Code/User/mcp.json" "$VSCODE_USER_DIR/mcp.json"
  ln -fs "$SCRIPT_DIR/config/Code/User/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
fi

#
# Zsh
#
ZSHRC_SOURCE="source $SCRIPT_DIR/config/zsh/zshrc"
if [ -e ~/.zshrc ]; then
  # Remove old myzshrc reference if exists
  if grep -q 'myzshrc' ~/.zshrc; then
    sed -i'' -e '/myzshrc/d' ~/.zshrc
  fi
  # Remove old config/zsh/zshrc reference if exists (to update path)
  if grep -q 'config/zsh/zshrc' ~/.zshrc; then
    sed -i'' -e '/config\/zsh\/zshrc/d' ~/.zshrc
  fi
  echo "$ZSHRC_SOURCE" >> ~/.zshrc
else
  echo "$ZSHRC_SOURCE" >> ~/.zshrc
fi

#
# Zsh plugins
#
# Clone plugins directly instead of using git submodules.
# This ensures plugins are available in VS Code Dev Containers
# where submodules are not automatically initialized.
#
ZSH_PLUGINS_DIR="$SCRIPT_DIR/config/zsh/plugins"
mkdir -p "$ZSH_PLUGINS_DIR"

if [ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions/.git" ]; then
  rm -rf "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_PLUGINS_DIR/fast-syntax-highlighting/.git" ]; then
  rm -rf "$ZSH_PLUGINS_DIR/fast-syntax-highlighting"
  git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
    "$ZSH_PLUGINS_DIR/fast-syntax-highlighting"
fi

#
# Ruff (Python linter)
#
mkdir -p ~/.config/ruff
ln -fs "$SCRIPT_DIR/config/ruff/ruff.toml" ~/.config/ruff/ruff.toml

#
# MCP (Claude Code CLI)
#
# Reserved slot. The servers file (config/mcp/mcp.json) is optional and added
# later; symlink it only if present so an empty slot leaves no dangling link.
# Load at runtime with: claude --mcp-config ~/.config/mcp/mcp.json
#
mkdir -p ~/.config/mcp
[ -f "$SCRIPT_DIR/config/mcp/mcp.json" ] && ln -fs "$SCRIPT_DIR/config/mcp/mcp.json" ~/.config/mcp/mcp.json

#
# CLAUDE CODE
#
# https://docs.anthropic.com/ja/docs/claude-code/memory
#
# Delegate to the shared seeder so build-time (host / image) and runtime
# (docker-entrypoint.sh, after a volume is mounted over $CLAUDE_DIR) lay down
# the same symlinks. See config/claude-code/seed-config-dir.sh.
#
CLAUDE_CONFIG_DIR="$CLAUDE_DIR" "$SCRIPT_DIR/config/claude-code/seed-config-dir.sh"

#
# Gemini CLI
#
mkdir -p ~/.config/gemini
ln -fs "$SCRIPT_DIR/config/gemini/settings.json" ~/.config/gemini/settings.json

#
# Docker
#
# Only link on macOS host: config.json sets `currentContext = "orbstack"` which
# only exists on the host. In a Docker container (DooD via socket mount), this
# config would break `docker version` etc. with "context not found".
#
if is-darwin && ! is-container; then
  mkdir -p ~/.docker
  ln -fs "$SCRIPT_DIR/config/docker/config.json" ~/.docker/config.json
fi

#
# npm
#
# npm does NOT natively support $XDG_CONFIG_HOME/npm/npmrc.
# Link to the traditional ~/.npmrc location.
#
ln -fs "$SCRIPT_DIR/config/npm/npmrc" ~/.npmrc

#
# pnpm
#
# pnpm 11 reads user-level config from $XDG_CONFIG_HOME/pnpm/config.yaml
# (YAML, camelCase). pnpm 11 also dropped reading non-auth settings from
# .npmrc, so all non-auth global config lives in this file.
# Per-project policy should live in each project's pnpm-workspace.yaml.
#
mkdir -p ~/.config/pnpm
ln -fs "$SCRIPT_DIR/config/pnpm/config.yaml" ~/.config/pnpm/config.yaml

#
# Debug log
#
mkdir -p ~/.log
printenv > ~/.log/install.sh.log

echo ""
echo "Installation complete!"
echo ""
echo "Note: This dotfiles uses Nerd Fonts icons in the Zsh prompt."
echo "Please install a Nerd Font (e.g., MesloLGS Nerd Font) for proper display."
echo "Download: https://www.nerdfonts.com/"
echo ""
