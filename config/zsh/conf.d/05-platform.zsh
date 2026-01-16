# Platform-specific settings

#
# Mac
#
if is-darwin; then
  #
  # brew
  #
  if [ -e /opt/homebrew/bin/brew ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
  fi

  #
  # zsh-completions
  #
  # You may also need to force rebuild `zcompdump`:
  #
  #   rm -f ~/.zcompdump; compinit
  #
  # Additionally, if you receive "zsh compinit: insecure directories" warnings when attempting
  # to load these completions, you may need to run these commands:
  #
  #   chmod go-w '/opt/homebrew/share'
  #   chmod -R go-w '/opt/homebrew/share/zsh'
  #
  if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
  fi

  #
  # Visual Studio Code
  #
  # To run VS Code from the terminal by typing `code`, add it the $PATH environment variable:
  #
  code_path=/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin
  if [ -d $etc ]; then
    export PATH=$code_path:${PATH}
  fi

  #
  # Docker
  #
  etc=/Applications/Docker.app/Contents/Resources/etc
  target=$ZSH_CONFIG_DIR/completion
  if [ -d $etc ]; then
    ln -fs $etc/docker.zsh-completion $target/_docker
    ln -fs $etc/docker-compose.zsh-completion $target/_docker-compose
    fpath=($target $fpath)
    zstyle ':completion:*:*:docker:*' option-stacking yes
    zstyle ':completion:*:*:docker-*:*' option-stacking yes
    autoload -Uz compinit && compinit -i
  fi

  #
  # SSH
  #
  if [ ! -d ~/.ssh ]; then
    # Prepare the directory in advance to prevent it from being owned by root when mounting keys
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
  fi


  #
  # Docker CLI Plugins
  #
  plugins=$HOME/.docker/cli-plugins
  if [ -d $plugins ]; then
    export PATH=$plugins:${PATH}
  fi

  #
  # PostgreSQL(psql)
  #
  if type brew &>/dev/null; then
    libpq=$(brew --prefix)/opt/libpq/bin
    if [ -d $libpq ]; then
      export PATH=$libpq:${PATH}
    fi
  fi

  #
  # Alias
  #
  alias bell='afplay /System/Library/Sounds/Frog.aiff'
fi

#
# Docker
#
if is-docker; then
  # This setting preserves the history even after restarting the Docker container.
  # https://github.com/uraitakahito/claude-code-docker/blob/0224b6a1c03bc3f47ebff7bcd23ab23da8a9f23c/Dockerfile#L32-L51
  if [ -d /zsh-volume ]; then
    export HISTFILE=/zsh-volume/.zsh_history
  fi
fi
