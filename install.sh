#!/bin/bash
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

source $SCRIPT_DIR/zsh/modules/helper/init.sh

cd ~/ || exit
ln -fs "$SCRIPT_DIR/.tmux.conf" .
ln -fs "$SCRIPT_DIR/.vimrc" .

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

if [ -e ~/.zshrc ] && [ "$(grep -c myzshrc ~/.zshrc)" -eq 0 ]; then
  echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc
elif [ ! -e ~/.zshrc ]; then
  echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc
fi

#
# Ruff (Python linter)
#
mkdir -p ~/.config/ruff
ln -fs "$SCRIPT_DIR/config/ruff/ruff.toml" ~/.config/ruff/ruff.toml

#
# CLAUDE CODE
#

#
# https://docs.anthropic.com/ja/docs/claude-code/memory
#
if [ ! -d ~/.claude ]; then
  ln -fs "$SCRIPT_DIR/.claude" "$HOME/.claude"
fi

#
# Gemini CLI
#
mkdir -p ~/.config/gemini
ln -fs "$SCRIPT_DIR/config/gemini/settings.json" ~/.config/gemini/settings.json

#
# Debug log
#
mkdir -p ~/.log
printenv > ~/.log/install.sh.log

echo "-----Finish!!------"
