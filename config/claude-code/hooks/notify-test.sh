#!/bin/bash
#
# Tests for notify.sh: feed it made-up hook payloads with NTFY_DRYRUN=1 and
# check the JSON it would send to ntfy.sh. Needs bash, jq and git.
#
# shellcheck disable=SC2016 # jq programs refer to their own $variables
set -u
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# A fake ioreg: FAKE_IDLE seconds since the last keyboard or mouse input.
mkdir "$tmp/bin"
printf '#!/bin/sh\necho "  |   \\"HIDIdleTime\\" = $((${FAKE_IDLE:-300} * 1000000000))"\n' >"$tmp/bin/ioreg"
chmod +x "$tmp/bin/ioreg"
git init -q -b feature "$tmp/repo"
export PATH="$tmp/bin:$PATH" NTFY_TOPIC=test NTFY_DRYRUN=1 XDG_STATE_HOME="$tmp/state"
unset CLAUDE_CODE_BRIDGE_SESSION_ID HERDR_PANE_ID
checks=0 failed=0

# hook EVENT [JQ_ARGS...] PROGRAM: run notify.sh on a payload built by jq ($cwd is the test repo).
hook() {
  local event=$1
  shift
  jq -cn --arg cwd "$tmp/repo" "$@" | "$here/notify.sh" "$event"
}
# expect NAME OUTPUT [TEST]: OUTPUT is JSON for which the jq TEST holds, or empty when TEST is omitted.
expect() {
  checks=$((checks + 1))
  if { [ $# -eq 2 ] && [ -z "$2" ]; } || { [ $# -eq 3 ] && printf '%s' "$2" | jq -e "$3" >/dev/null 2>&1; }; then
    echo "ok   $1"
  else
    echo "FAIL $1: ${2:-(nothing sent)}"
    failed=$((failed + 1))
  fi
}

out=$(hook prompt '{session_id: "s1", cwd: $cwd, prompt: "README を直して"}')
expect "prompt prints nothing (it would reach Claude as context)" "$out"
private=$(find "$tmp/state/claude-notify" -name s1.json -perm 600)
expect "the remembered request is private" "$([ -n "$private" ] || echo "not mode 600")"
reply='**結論**
`README.md` の誤字を直しました。

- 3 か所'
out=$(hook stop --arg r "$reply" '{session_id: "s1", cwd: $cwd, last_assistant_message: $r, background_tasks: []}')
expect "done: status, project, branch, time" "$out" '.title | test("^✅ 完了 · repo \\(feature\\) · [0-9]+秒$")'
expect "done: request and reply as plain text, no session id" "$out" \
  '.message == "依頼: README を直して\nREADME.md の誤字を直しました。\n3 か所" and .priority == 3'

hook prompt '{session_id: "s2", cwd: $cwd, prompt: "直す？"}' >/dev/null
out=$(hook stop '{session_id: "s2", cwd: $cwd, last_assistant_message: "どちらにしますか？"}')
expect "a reply ending in a question waits for you" "$out" '(.title | startswith("❓ 返事待ち · ")) and .priority == 4'

hook prompt '{session_id: "s3", cwd: $cwd, prompt: "調べて"}' >/dev/null
out=$(hook stop '{session_id: "s3", cwd: $cwd, last_assistant_message: "調査を任せました。",
  background_tasks: [{id: "a1", type: "subagent", status: "running"}]}')
expect "background work: a quiet push" "$out" '(.title | startswith("⏳ 裏で続行中（1 件） · ")) and .priority == 2'
out=$(hook stop '{session_id: "s3", cwd: $cwd, last_assistant_message: "まとめました。", background_tasks: []}')
expect "after background work: the request is still known" "$out" \
  '(.title | startswith("✅ 完了 · ")) and (.message | startswith("依頼: 調べて\n"))'

for pair in "Bash:🔐 許可待ち" "AskUserQuestion:❓ 質問" "ExitPlanMode:📋 計画の確認"; do
  out=$(hook notification --arg m "Claude needs your permission to use ${pair%%:*}" \
    '{session_id: "s4", cwd: $cwd, notification_type: "permission_prompt", message: $m}')
  expect "permission prompt for ${pair%%:*}" "$out" ".title == \"${pair#*:} · repo (feature)\" and .priority == 4"
done
out=$(hook notification '{session_id: "s4", cwd: $cwd, notification_type: "idle_prompt", message: "Claude is waiting for your input"}')
expect "idle_prompt is not sent (the stop push said it)" "$out"

out=$(FAKE_IDLE=5 hook stop '{session_id: "s5", cwd: $cwd, last_assistant_message: "x"}')
expect "at the Mac: nothing sent" "$out"
out=$(NTFY_TOPIC='' hook stop '{session_id: "s5", cwd: $cwd, last_assistant_message: "x"}')
expect "NTFY_TOPIC unset: nothing sent" "$out"
out=$(hook stop '{session_id: "s6", cwd: $cwd, last_assistant_message: ""}')
expect "an empty reply says so" "$out" '.message == "（本文なし）"'

export CLAUDE_CODE_BRIDGE_SESSION_ID=session_TEST
out=$(hook stop '{session_id: "s7", cwd: $cwd, last_assistant_message: "x"}')
expect "a tap opens the session on claude.ai" "$out" '.click == "https://claude.ai/code/session_TEST"'
out=$(hook notification '{session_id: "s7", cwd: $cwd, notification_type: "permission_prompt",
  message: "Claude needs your permission to use Bash"}')
expect "so does a permission prompt" "$out" '.click == "https://claude.ai/code/session_TEST"'
unset CLAUDE_CODE_BRIDGE_SESSION_ID
out=$(hook stop '{session_id: "s7", cwd: $cwd, last_assistant_message: "x"}')
expect "without Remote Control: no link" "$out" 'has("click") | not'

out=$(HERDR_PANE_ID=w3:p2 hook stop '{session_id: "s8", cwd: $cwd, last_assistant_message: "x"}')
expect "the herdr pane ends the title" "$out" '.title | endswith(" · w3:p2")'
out=$(hook stop '{session_id: "s8", cwd: $cwd,
  last_assistant_message: "PR を作りました（https://github.com/o/r/pull/1）。CI も通りました。"}')
expect "the first link becomes a button" "$out" \
  '.actions == [{action: "view", label: "リンクを開く", url: "https://github.com/o/r/pull/1"}]'
out=$(hook stop '{session_id: "s8", cwd: $cwd, last_assistant_message: "詳しくは [PR](https://github.com/o/r/pull/2) で。"}')
expect "a Markdown link works too" "$out" '.actions[0].url == "https://github.com/o/r/pull/2"'
out=$(hook stop '{session_id: "s8", cwd: $cwd, last_assistant_message: "x"}')
expect "no link: no button" "$out" 'has("actions") | not'

echo "$checks checks, $failed failed"
[ "$failed" -eq 0 ]
