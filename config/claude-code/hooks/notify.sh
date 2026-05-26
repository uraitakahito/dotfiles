#!/bin/bash
#
# Claude Code hook notification wrapper for ntfy.sh.
#
# Usage:
#   ~/.claude/hooks/notify.sh <event>   # Stop / Notification / ...
#
# Reads Claude Code's hook payload (JSON) from stdin and forwards it to
# ntfy.sh as a structured push notification.
#
# Behavior:
# - Per-event Priority / Tags so Stop (completion) and Notification
#   (input-required) are distinguishable at a glance on the receiver.
# - Title carries event/project so the iOS lock screen (which does not
#   render Markdown via APNs) shows readable metadata in bold.
# - Body is plain text: Claude's message + a short session id.
#
# NTFY_TOPIC unset/empty is treated as "notifications disabled" rather
# than an error, because install.sh symlinks this script on every
# environment (Dev Containers, CI runners, etc.).
#
set -eu

[ -n "${NTFY_TOPIC:-}" ] || exit 0

event="${1:?event name required}"

payload=$(cat)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)
session_id=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null | cut -c1-8 || true)
message=$(printf '%s' "$payload" | jq -r '.message // empty' 2>/dev/null || true)
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null || true)
proj=$(basename "${cwd:-?}")

# Per-event priority / tags and body. Stop has no .message field, so its body
# is derived from the transcript: last main-thread text, else last tool name,
# else a static line — so a Stop notification is never empty "(no message)".
case "$event" in
  Notification)
    priority="high"; tags="bell,claude-code"
    summary="${message:-入力待ちです}" ;;
  Stop|SubagentStop)
    priority="default"; tags="white_check_mark,claude-code"
    last_text=""; last_tool=""
    if [ -n "$transcript" ] && [ -r "$transcript" ]; then
      # idea1: last main-thread text (subagent entries excluded), 1 line, capped.
      last_text=$(jq -r 'select(.type=="assistant" and (.isSidechain|not))
                         | .message.content[]? | select(.type=="text") | .text' \
                  "$transcript" 2>/dev/null | tail -1 | tr '\n' ' ' | cut -c1-180 || true)
      # idea2 fallback: name of the last tool used, when the turn produced no text.
      last_tool=$(jq -r 'select(.type=="assistant" and (.isSidechain|not))
                         | .message.content[]? | select(.type=="tool_use") | .name' \
                  "$transcript" 2>/dev/null | tail -1 || true)
    fi
    summary="${last_text:-${last_tool:+最後の操作: $last_tool}}"
    summary="${summary:-セッションが完了しました}" ;;
  *)
    priority="default"; tags="claude-code"
    summary="${message:-イベント: $event}" ;;
esac

# Plain text body: summary + short session id. The body stays minimal/plain so
# the iOS lock screen (which does not render Markdown via APNs) stays readable.
body="${summary}
(session ${session_id:-?})"

# NTFY_DRYRUN set → print TITLE/body to stderr and skip sending (local testing).
if [ -n "${NTFY_DRYRUN:-}" ]; then
  printf 'TITLE: %s — %s\nTAGS:  %s\nBODY:\n%s\n' "$proj" "$event" "$tags" "$body" >&2
  exit 0
fi

curl -fsS \
  -H "Title: ${proj} — ${event}" \
  -H "Priority: $priority" \
  -H "Tags: $tags" \
  -d "$body" \
  "ntfy.sh/${NTFY_TOPIC}" >/dev/null
