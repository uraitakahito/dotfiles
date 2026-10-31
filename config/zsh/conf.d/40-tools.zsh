# Development tools configuration

#
# rbenv
#
path_prepend $HOME/.rbenv/bin
if (( $+commands[rbenv] )); then
  eval "$(rbenv init - zsh)"
fi

#
# nodenv
#
if (( $+commands[nodenv] )); then
  eval "$(nodenv init - zsh)"
fi

#
# node_modules/.bin
# A relative entry is looked up from the current directory each time.
# Add it unconditionally: an existence check would run only once, at startup.
#
path+=(./node_modules/.bin)

#
# uv
# https://zenn.dev/tadayosi/articles/522efbda48fbf4
#
if type uv &>/dev/null; then
  eval "$(uv generate-shell-completion zsh)"

  _uv_run_mod() {
      if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
          _arguments '*:filename:_files'
      else
          _uv "$@"
      fi
  }
  compdef _uv_run_mod uv
fi

#
# Go
# https://github.com/devcontainers/features/tree/main/src/go
# https://go.dev/wiki/GOPATH
#
path_prepend /usr/local/go/bin
path_prepend /go/bin
path_prepend $HOME/go/bin

#
# zoxide
# https://github.com/ajeetdsouza/zoxide
#
if type zoxide > /dev/null 2>&1; then
  export _ZO_DATA_DIR=${XDG_DATA_HOME-$HOME/.zoxide/data}
  eval "$(zoxide init zsh)"
fi
