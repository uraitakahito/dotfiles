#!/bin/bash
#
# Install basic Visual Studio Code extensions
#
extensions=(
  # https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens
  "eamodio.gitlens"
  # https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker
  "ms-azuretools.vscode-docker"
  # https://marketplace.visualstudio.com/items?itemName=oderwat.indent-rainbow
  "oderwat.indent-rainbow"
)
for extension in ${extensions[@]}; do
  code --install-extension $extension
done
