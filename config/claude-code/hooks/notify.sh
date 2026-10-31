#!/bin/bash
#
# Claude Code hook: push what finished, and how, to ntfy.sh. Tapping the push
# opens the session on claude.ai (Remote Control).
#
# Usage (settings.json hooks):
#   notify.sh prompt         UserPromptSubmit: remember the request and when it began
#   notify.sh stop           Stop: done, waiting for an answer, or still working in the background
#   notify.sh notification   Notification: permission prompts and questions only
#
# Nothing is sent while you are at the Mac (keyboard or mouse used within the
# last minute), nor when NTFY_TOPIC is unset (Dev Containers, CI).
# NTFY_DRYRUN=1 prints the JSON instead of sending it.
#
set -u
umask 077

[ -n "${NTFY_TOPIC:-}" ] || exit 0
event="${1:-}"
payload=$(cat)
field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-notify"
state="$state_dir/$(field .session_id).json"

# Anything printed for UserPromptSubmit reaches Claude as context, so print nothing.
if [ "$event" = prompt ]; then
  mkdir -p "$state_dir" || exit 0
  find "$state_dir" -name '*.json' -mtime +1 -delete 2>/dev/null # sessions that never stopped
  printf '%s' "$payload" | jq -c --argjson now "$(date +%s)" '{prompt: (.prompt // ""), started_at: $now}' >"$state"
  exit 0
fi

# At the Mac, the terminal already tells you. HIDIdleTime is in nanoseconds.
idle=$(ioreg -c IOHIDSystem 2>/dev/null | awk '/HIDIdleTime/ { print int($NF / 1000000000); exit }')
[ "${idle:-60}" -ge 60 ] || exit 0

cwd=$(field .cwd)
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
where="$(basename "${cwd:-?}")${branch:+ ($branch)}"

case "$event" in
  stop)
    # The reply comes with the payload; the transcript may not have it yet.
    reply=$(field .last_assistant_message)
    request=$(jq -r '.prompt // empty' "$state" 2>/dev/null)
    started=$(jq -r '.started_at // empty' "$state" 2>/dev/null)
    took=""
    if [ -n "$started" ]; then
      s=$(($(date +%s) - started))
      if [ "$s" -ge 3600 ]; then took="$((s / 3600))時間$((s % 3600 / 60))分"
      elif [ "$s" -ge 60 ]; then took="$((s / 60))分"
      else took="${s}秒"; fi
    fi
    # Work left in the background wakes the session up again later, so keep the
    # request for that final push and say so quietly.
    running=$(printf '%s' "$payload" | jq '.background_tasks // [] | length' 2>/dev/null)
    if [ "${running:-0}" -gt 0 ]; then
      title="⏳ 裏で続行中（${running} 件）" priority=2
    else
      rm -f "$state"
      case "$(printf '%s\n' "$reply" | grep -v '^[[:space:]]*$' | tail -n 1)" in
        *'？' | *'?') title="❓ 返事待ち" priority=4 ;;
        *) title="✅ 完了" priority=3 ;;
      esac
    fi
    title="$title · $where${took:+ · $took}"
    # The request, then the first three lines of the reply (headings skipped) as plain text.
    message=$(jq -rn --arg req "$request" --arg reply "$reply" '
      def plain: gsub("\\*\\*|`"; "") | gsub("\\s+"; " ");
      [if $req == "" then empty else "依頼: \($req | plain | .[:60])" end]
      + [$reply | split("\n")[] | select(test("^\\s*(#|\\*\\*[^*]*\\*\\*\\s*$)") | not)
         | sub("^[>*\\s-]+"; "") | select(test("\\S")) | plain | .[:90]][:3]
      | join("\n") | if . == "" then "（本文なし）" else . end')
    ;;
  notification)
    message=$(field .message)
    case "$(field .notification_type)" in
      permission_prompt)
        # AskUserQuestion and ExitPlanMode wait for you even in bypass mode.
        case "$message" in
          *AskUserQuestion*) title="❓ 質問" ;;
          *ExitPlanMode*) title="📋 計画の確認" ;;
          *) title="🔐 許可待ち" ;;
        esac ;;
      elicitation_dialog | elicitation_url_dialog | agent_needs_input) title="❓ 入力待ち" ;;
      *) exit 0 ;; # idle_prompt repeats the stop push; auth_success and the like are noise
    esac
    title="$title · $where" priority=4
    ;;
  *) exit 0 ;;
esac

# A tap opens this session on claude.ai; the ID is set while Remote Control is connected.
click="${CLAUDE_CODE_BRIDGE_SESSION_ID:+https://claude.ai/code/$CLAUDE_CODE_BRIDGE_SESSION_ID}"
# The herdr pane says where the session runs, for when you are back at the desk.
title="$title${HERDR_PANE_ID:+ · $HERDR_PANE_ID}"
# The reply's first link (a PR, a page) becomes a button.
json=$(jq -cn --arg topic "$NTFY_TOPIC" --arg title "$title" --arg message "$message" --argjson priority "$priority" \
  --arg click "$click" --arg reply "${reply:-}" '
  {topic: $topic, title: $title, message: $message, priority: $priority}
  + if $click == "" then {} else {click: $click} end
  + ([$reply | scan("https://[!-~]+")][0] // null
     | if . == null then {} else {actions: [{action: "view", label: "リンクを開く",
                                          url: sub("[)\\].,;:`>]+$"; "")}]} end)')
if [ -n "${NTFY_DRYRUN:-}" ]; then printf '%s\n' "$json"; exit 0; fi
curl -fsS -d "$json" https://ntfy.sh/ >/dev/null
