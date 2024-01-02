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

cd ~/
ln -fs $SCRIPT_DIR/.gitignore_global .
ln -fs $SCRIPT_DIR/.tmux.conf .
ln -fs $SCRIPT_DIR/.vimrc .
ln -fs $SCRIPT_DIR/.vscode .

if [ -d /zsh-volume ]; then
  if [ ! -e /zsh-volume/.zsh_history ]; then
    touch /zsh-volume/.zsh_history
  fi
  ln -fs /zsh-volume/.zsh_history ./.zsh_history
fi

echo 'source ~/dotfiles/zsh/myzshrc' >> ~/.zshrc

echo "-----Finish!!------"
