#!/bin/bash
set -u

# Install script for VSCode Remote Container or Codespaces
# https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories

# How to debug this script:
#   https://kesin.hatenablog.com/entry/2020/07/10/083000
#
# 1. docker run --entrypoint=bash --rm -it --mount type=bind,src=$(pwd),dst=/home/dotfiles ubuntu
# 2. cd /home/dotfiles
# 3. ./install.sh
# 4. cd ~
# 5. . .profile

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

source $SCRIPT_DIR/zsh/modules/helper/init.sh

cd ~/
# https://github.com/git/git/blob/master/Documentation/RelNotes/1.7.12.txt#L21-L23
mkdir -p .config/git
ln -fs "$SCRIPT_DIR/.gitignore_global" .config/git/ignore
ln -fs $SCRIPT_DIR/.tmux.conf .
ln -fs $SCRIPT_DIR/.vimrc .

# Copy settings.json if this script is running in a container
if is-docker; then
  mkdir -p ~/.vscode-server/data/Machine
  ln -fs $SCRIPT_DIR/settings.json .vscode-server/data/Machine
fi

if [ -d /zsh-volume ]; then
  if [ ! -e /zsh-volume/.zsh_history ]; then
    touch /zsh-volume/.zsh_history
  fi
  if [ -e /zsh-volume/.zsh_history ]; then
    ln -fs /zsh-volume/.zsh_history ./.zsh_history
  fi
fi

if [ -e ~/.zshrc ] && [ `grep -c myzshrc ~/.zshrc` -eq 0 ]; then
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
