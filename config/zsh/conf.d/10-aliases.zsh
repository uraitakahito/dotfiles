# Alias definitions

#
# Type:
# brew install --cask font-meslo-lg-nerd-font
#
alias a='eza --icons'
alias ll='eza -l -g --icons --time-style=long-iso'
alias d='docker'
if ! is-darwin; then
  # https://github.com/sharkdp/bat/issues/982
  alias bat='batcat --style=plain'
else
  alias bat='bat --style=plain'
fi

#
# Git aliases
#
alias c='git commit -v'
alias g='git'
alias s='git status'

# trash-cli
# https://github.com/andreafrancia/trash-cli
if type trash-put > /dev/null 2>&1; then
  alias rm='trash-put'
fi
