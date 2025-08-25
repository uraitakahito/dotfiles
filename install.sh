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
cd ~/ || exit
# https://github.com/git/git/blob/master/Documentation/RelNotes/1.7.12.txt#L21-L23
mkdir -p .config/git
if [ ! -f .config/git/ignore ]; then
  ln -fs "$SCRIPT_DIR/.gitignore_global" .config/git/ignore
fi

if is-docker; then
  mkdir -p ~/.vscode-server/data/Machine
  ln -fs "$SCRIPT_DIR/vscode/settings.json" .vscode-server/data/Machine
  ln -fs "$SCRIPT_DIR/vscode/mcp.json" .vscode-server/data/Machine
elif is-darwin; then
  ln -fs "$SCRIPT_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User"
  ln -fs "$SCRIPT_DIR/vscode/mcp.json" "$HOME/Library/Application Support/Code/User"
fi

if [ -e ~/.zshrc ] && [ "$(grep -c myzshrc ~/.zshrc)" -eq 0 ]; then
  echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc
elif [ ! -e ~/.zshrc ]; then
  echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc
fi

#
# Python
#
if [ ! -f "$HOME/.ruff.toml" ]; then
  ln -fs "$SCRIPT_DIR/.ruff.toml" "$HOME/.ruff.toml"
fi

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
if [ ! -d ~/.gemini ]; then
  mkdir -p ~/.gemini
fi
ln -fs "$SCRIPT_DIR/.gemini/settings.json" ~/.gemini/settings.json

#
# zsh history in docker
#
if [ -d /zsh-volume ]; then
  if [ ! -e /zsh-volume/.zsh_history ]; then
    touch /zsh-volume/.zsh_history
  fi
  if [ -e /zsh-volume/.zsh_history ]; then
    ln -fs /zsh-volume/.zsh_history ~/.zsh_history
  fi
fi

#
# Debug log
#
mkdir -p ~/.log
printenv > ~/.log/install.sh.log

echo "-----Finish!!------"
