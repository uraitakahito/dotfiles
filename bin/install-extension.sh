#!/bin/bash
#
# Install basic Visual Studio Code extensions
#
extensions=(
  "eamodio.gitlens"
  "ms-azuretools.vscode-docker"
  "ms-vscode-remote.remote-containers"
  "oderwat.indent-rainbow"
)
for extension in ${extensions[@]}; do
  code --install-extension $extension
done
