# pnpm — replicate `pnpm setup` declaratively. `pnpm setup` itself would
# edit ~/.zshrc and clash with the dotfiles symlink strategy.
#
# Layout note: pnpm 10 moved global bins from $PNPM_HOME (flat) to
# $PNPM_HOME/bin/. We put the latter on PATH.

if is-darwin; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
path_prepend "$PNPM_HOME/bin"

# nodenv's shim exists once any Node version has pnpm, and fails in a
# version without it. Ask nodenv only when the shim is what we'd run.
if (( $+commands[pnpm] )) && {
  [[ $commands[pnpm] != */shims/pnpm ]] || nodenv which pnpm &>/dev/null
}; then
  eval "$(pnpm completion zsh)"
fi
