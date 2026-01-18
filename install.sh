#!/bin/bash
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

source $SCRIPT_DIR/config/zsh/functions/helper.zsh

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
ln -fs "$SCRIPT_DIR/config/git/ignore" ~/.config/git/ignore

#
# VS Code
#
if is-docker; then
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
# Ruff (Python linter)
#
mkdir -p ~/.config/ruff
ln -fs "$SCRIPT_DIR/config/ruff/ruff.toml" ~/.config/ruff/ruff.toml

#
# CLAUDE CODE
#
# https://docs.anthropic.com/ja/docs/claude-code/memory
#
mkdir -p ~/.claude
ln -fs "$SCRIPT_DIR/config/claude-code/settings.json" ~/.claude/settings.json
ln -fs "$SCRIPT_DIR/config/claude-code/CLAUDE.md" ~/.claude/CLAUDE.md

#
# Gemini CLI
#
mkdir -p ~/.config/gemini
ln -fs "$SCRIPT_DIR/config/gemini/settings.json" ~/.config/gemini/settings.json

#
# Docker
#
mkdir -p ~/.docker
ln -fs "$SCRIPT_DIR/config/docker/config.json" ~/.docker/config.json

#
# Debug log
#
mkdir -p ~/.log
printenv > ~/.log/install.sh.log

echo "-----Finish!!------"
