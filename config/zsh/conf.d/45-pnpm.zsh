# pnpm — define PNPM_HOME ahead of time so `pnpm setup` is never needed
# (`pnpm setup` would rewrite ~/.zshrc and clash with the dotfiles symlink strategy).
# PNPM_HOME must be exported BEFORE pnpm reads ~/.config/pnpm/rc, where ${PNPM_HOME}/{store,state} are referenced.

if is-darwin; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
path_prepend "$PNPM_HOME"

if (( $+commands[pnpm] )); then
  eval "$(pnpm completion zsh)"
fi
