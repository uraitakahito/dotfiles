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

#
# Claude Code
#
# For Claude Opus 4.6 and Sonnet 4.6, effort replaces budget_tokens as the recommended way to control thinking depth.
#   https://platform.claude.com/docs/en/build-with-claude/effort
#
# One important detail: low, medium, and high persist across sessions. Set it once and it sticks until you change it. max resets when your session ends.
#   https://kentgigger.com/posts/claude-code-effort-parameter
#
alias ccm="claude --model claude-opus-4-6 --effort max --remote-control"
alias ccms="claude --model claude-opus-4-6 --effort max --remote-control --dangerously-skip-permissions"
