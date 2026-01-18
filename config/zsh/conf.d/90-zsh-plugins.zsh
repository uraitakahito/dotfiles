# Zsh plugins
#
# This file is loaded last to ensure all other configurations are complete
# before loading plugins.

#
# zsh-autosuggestions
#
# If you press `Ctrl + e` or the `→` key (forward-char widget) or End (end-of-line widget) with the cursor at the end of the buffer,
# it will accept the suggestion, replacing the contents of the command line buffer with the suggestion.
#
if [ -f "$ZSH_CONFIG_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$ZSH_CONFIG_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

#
# fast-syntax-highlighting
#
# Feature rich syntax highlighting for Zsh.
# https://github.com/zdharma-continuum/fast-syntax-highlighting
#
if [ -f "$ZSH_CONFIG_DIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]; then
  source "$ZSH_CONFIG_DIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  fast-theme safari >/dev/null 2>&1
fi
