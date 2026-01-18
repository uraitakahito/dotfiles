# Core zsh settings: prompt, options, exports, keybindings

#
# Ensure unique PATH entries (remove duplicates)
#
typeset -U path PATH

#
# prompt
#
local cyan=$'\e[36m' reset=$'\e[m'
PROMPT="%F{green}%m%f %{${cyan}%}%2d%# %{${reset}%}"

#
# Load environment variables
#
if [ -f "$HOME/.env" ]; then
  set -a  # Treat all subsequent variable definitions as exports
  . "$HOME/.env"
  set +a
fi

#
# shortcut
#
# Delete all existing keymaps and reset to the default state.
bindkey -d
# Selects keymap `emacs'.
bindkey -e

#
# compinit
#
autoload -Uz compinit && compinit

#
# Welcome Message
#
my_log $(uname -a)

# Beep off on error in ZLE
setopt no_beep

# Editor
if type "vim" > /dev/null 2>&1; then
  export EDITOR="vim"
fi

#
# the number of commands that are stored in the zsh history file
#
export SAVEHIST=5000000

#
# Share command history across all zsh sessions in real time.
# Useful when working with multiple terminal windows or tabs.
# Ensures history is immediately written to and read from the history file.
#
setopt share_history

#
# Ignore history duplicates
# Do not enter command lines into the history list if they are duplicates of the
# previous event.
#
setopt hist_ignore_dups

#
# When searching for history entries in the line editor, do not display duplicates
# of a line previously found, even if the duplicates are not contiguous.
#
setopt hist_find_no_dups

#
# Do not expand aliases before completion.
#
# Without this option, typing `ll` + Tab shows eza's --color option values
# (always, auto, never) instead of files, because zsh expands the alias
# `ll='eza -l -g --icons'` before completion and uses _eza completion.
#
# With COMPLETE_ALIASES, zsh completes based on the alias name itself,
# allowing `compdef _files ll` to work correctly.
#
setopt COMPLETE_ALIASES

# Inform gpg-agent of the current TTY for user prompts.
# If you want to check gpg, type:
#   echo 'test' | gpg --clearsign
#
# BUT, Unable to List GPG Keys in Dev Container or Sign Git Commits
# https://github.com/microsoft/vscode-remote-release/issues/8549
export GPG_TTY=$TTY

#
# zsh-autosuggestions
#
# If you press `Ctrl + e` or the `→` key (forward-char widget) or End (end-of-line widget) with the cursor at the end of the buffer,
# it will accept the suggestion, replacing the contents of the command line buffer with the suggestion.
#
if [ -f "$ZSH_CONFIG_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$ZSH_CONFIG_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
