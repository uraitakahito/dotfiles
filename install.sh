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
if [ ! -f .gitconfig ]; then
  ln -fs "$SCRIPT_DIR/.gitconfig" .
fi

# Copy settings.json if this script is running in a container
if is-docker; then
  mkdir -p ~/.vscode-server/data/Machine
  ln -fs "$SCRIPT_DIR/settings.json" .vscode-server/data/Machine
fi

if [ -d /zsh-volume ]; then
  if [ ! -e /zsh-volume/.zsh_history ]; then
    touch /zsh-volume/.zsh_history
  fi
  if [ -e /zsh-volume/.zsh_history ]; then
    ln -fs /zsh-volume/.zsh_history ./.zsh_history
  fi
fi

if [ -e ~/.zshrc ] && [ "$(grep -c myzshrc ~/.zshrc)" -eq 0 ]; then
  echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc
elif [ ! -e ~/.zshrc ]; then
  echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc
fi

#
# Debug log
#
mkdir -p ~/.log
printenv > ~/.log/install.sh.log

echo "-----Finish!!------"
