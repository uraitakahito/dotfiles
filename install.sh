#!/bin/bash
set -u

# Install script for VSCode Remote Container or Codespaces
# https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

cd ~/
ln -fs $SCRIPT_DIR/.gitignore_global .

echo "-----Finish!!------"
