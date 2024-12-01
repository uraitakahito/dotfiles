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

# Copy settings.json if this script is running in a container
if is-docker; then
  mkdir -p ~/.vscode-server/data/Machine
  ln -fs "$SCRIPT_DIR/settings.json" .vscode-server/data/Machine
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
