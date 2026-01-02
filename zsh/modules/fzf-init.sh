#!/usr/bin/zsh
#
# fzf-dependent functions
# This file is only sourced when fzf is available
#

#
# select-history - reverse-i-search with fzf
#
function select-history() {
  BUFFER=$(fc -l -n 1 | tail -r | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
  CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

#
# fgitshow - git commit browser
#
fgitshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

#
# fcd - cd to selected directory
#
fcd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

#
# fdshell - Login to Docker with shell
#   usage: fdshell /bin/bash
#
fdshell() {
  local cid
  cid=$(docker ps | sed 1d | fzf | awk '{print $1}')
  [ -n "$cid" ] && docker exec -it "$cid" $1
}

#
# fdstop - Stop a running container
#   usage: fdstop
#
fdstop() {
  local cid
  cid=$(docker ps | sed 1d | fzf | awk '{print $1}')
  [ -n "$cid" ] && docker stop "$cid"
}

#
# fdvscode - Attach to a running container with VS Code
#   usage: fdvscode
#   https://github.com/microsoft/vscode-remote-release/issues/5278#issuecomment-1625401636
#
fdvscode() {
  local cid
  cid=$(docker ps | sed 1d | fzf | awk '{print $NF}')
  [ -n "$cid" ] && code --folder-uri vscode-remote://attached-container+$(printf "$cid" | od -A n -t x1 | sed 's/ *//g' | tr -d '\n')/app
}

#
# fghbrowse - Open the selected GitHub repository from the list in the browser.
#   usage: fghbrowse
#
fghbrowse() {
  local repo
  repo=$(gh repo list -L 1000 | fzf | awk '{print $1}')
  [ -n "$repo" ] && gh browse -R $repo
}

#
# fkill - Select a process to kill using fzf
#   usage: fkill
#
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill
  fi
}

#
# frg - Search files with ripgrep (or grep), select with fzf, and open in the editor
#   usage: frg
#
frg() {
  grep_cmd="grep --recursive --line-number --invert-match --regexp '^\s*$' * 2>/dev/null"

  if type "rg" >/dev/null 2>&1; then
      grep_cmd="rg --hidden --no-ignore --line-number --no-heading --invert-match '^\s*$' 2>/dev/null"
  fi

  read -r file line <<<"$(eval $grep_cmd | fzf --select-1 --exit-0 | awk -F: '{print $1, $2}')"
  ( [[ -z "$file" ]] || [[ -z "$line" ]] ) && return
  $EDITOR $file +$line
}

#
# fssh - SSH login to a host selected from the ~/.ssh/config file using fzf
#   usage: fssh
#   https://qiita.com/kamykn/items/9a831862038efa4e9f8f
#   https://dev.classmethod.jp/articles/iterm2-ssh-change-profile/
#
fssh() {
    local sshLoginHost
    sshLoginHost=$(cat ~/.ssh/config | grep -i ^host | awk '{print $2}' | fzf)

    if [ "$sshLoginHost" = "" ]; then
        return 1
    fi

    echo -ne "\033]1337;SetProfile=$sshLoginHost\a"
    ssh ${sshLoginHost}
    echo -ne "\033]1337;SetProfile=Default\a"
}
