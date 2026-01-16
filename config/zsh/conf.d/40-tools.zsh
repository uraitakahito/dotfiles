# Development tools configuration

#
# rbenv
#
[[ -d $HOME/.rbenv ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init - zsh)"

#
# nodenv
#
[[ -d $HOME/.nodenv ]] && \
  eval "$(nodenv init - zsh)"
# https://github.com/uraitakahito/features/blob/8291744831e2c42b6c01fe169e98cca2a4b7fbc9/src/node/install.sh#L13
if { [ -d $HOME/.nodenv ] } || { [ -d /usr/local/share/nvm ] }; then
  export PATH=$PATH:./node_modules/.bin
fi

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
#
[[ -d /usr/local/go/bin ]] && \
  export PATH=/usr/local/go/bin:${PATH}
[[ -d /go/bin ]] && \
  export PATH=/go/bin:${PATH}
# https://go.dev/wiki/GOPATH
export PATH=$HOME/go/bin:${PATH}

#
# zoxide
# https://github.com/ajeetdsouza/zoxide
#
if type zoxide > /dev/null 2>&1; then
  export _ZO_DATA_DIR=${XDG_DATA_HOME-$HOME/.zoxide/data}
  eval "$(zoxide init zsh)"
fi
