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
# Apple Container
#
# buildkit 以外の稼働中コンテナを全部止める。buildkit は `container build`
# が使うビルダーで、Apple が com.apple.container.* ラベルを付けている
# プラットフォーム所有のコンテナなので残す。
#
# 判定を ID の文字列一致にしているのは意図的。ラベル
# (com.apple.container.resource.role) で見れば改名にも強いが jq が要る。
# ビルダーが改名されたら巻き添えで止まる点を承知の上で、1行で読み切れる
# 方を選んでいる。止まったら buildkit は `container builder start` で戻せる。
#
# `container ls -q` は稼働中のみを返す (-a なし) ので停止済みには触らない。
# 対象がゼロのとき BSD xargs はコマンドを実行しないため、引数ゼロの
# `container stop` ("no containers specified" でエラー) にはならない。
#
alias cstop='container ls -q | grep -v "^buildkit$" | xargs container stop'

#
# Claude Code
#
# For Claude Opus and Sonnet, effort replaces budget_tokens as the recommended way to control thinking depth.
#   https://platform.claude.com/docs/en/build-with-claude/effort
#
# One important detail: low, medium, and high persist across sessions. Set it once and it sticks until you change it. max resets when your session ends.
#   https://kentgigger.com/posts/claude-code-effort-parameter
#
alias ccm="claude --model opus --effort max"
alias ccms="claude --model opus --effort max --dangerously-skip-permissions"
alias ccmr="claude --model opus --effort max --remote-control"
