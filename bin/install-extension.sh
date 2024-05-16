#!/bin/bash
#
# Install basic Visual Studio Code extensions
#
extensions=(
  "eamodio.gitlens"
  "oderwat.indent-rainbow"
)
for extension in ${extensions[@]}; do
  code --install-extension $extension
done
