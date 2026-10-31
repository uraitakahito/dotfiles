#
# Zsh-specific PATH helper functions
#
# This file uses Zsh glob qualifiers and must NOT be sourced by bash scripts.
# It is loaded only by zshrc. For bash-compatible functions, see helper.zsh.
#

#
# PATH helper functions using Zsh glob qualifiers (N-/):
#   N - nullglob: returns empty if no match (no error)
#   - - follows symlinks when evaluating
#   / - matches only directories
#

# Add directory to PATH if it exists (prepend)
# Usage: path_prepend /usr/local/bin
path_prepend() {
  path=($1(N-/) $path)
}
