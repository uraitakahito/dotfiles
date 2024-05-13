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

source "$HOME/dotfiles/zsh/modules/helper/init.sh"

cd ~/
ln -fs $SCRIPT_DIR/.gitignore_global .
ln -fs $SCRIPT_DIR/.tmux.conf .
ln -fs $SCRIPT_DIR/.vimrc .

# Copy settings.json if this script is running in a container
if [ -e /.dockerenv ]; then
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

# temporary test code
if has-vscode-remote-containers; then
  echo 'Hello VSCode remote containers'
  echo 'Hello VSCode remote containers' > ~/vscode-if
else
  echo 'else statement' > ~/vscode-else
fi

if has-path; then
  echo 'Hello Path'
  echo 'Hello Path' > ~/path-if
else
  echo 'Hello Path' > ~/path-else
fi

# temporary test code
printenv >> ~/myenv

echo "-----Finish!!------"
