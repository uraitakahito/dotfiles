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
# - Body is Markdown-formatted, including the short session id and the
#   Claude message (when present in the payload).
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
proj=$(basename "${cwd:-?}")

# Per-event Priority / Tags so receivers can distinguish event kinds.
case "$event" in
  Stop)         priority="default"; tags="white_check_mark,claude-code" ;;
  Notification) priority="high";    tags="bell,claude-code" ;;
  *)            priority="default"; tags="claude-code" ;;
esac

# Markdown body: project + short session id, plus Claude's message
# when present (Notification events carry the permission prompt etc).
body="**Project**: \`${proj}\`
**Session**: \`${session_id:-?}\`"
[ -n "$message" ] && body="${body}

> ${message}"

curl -fsS \
  -H "Title: Claude ${event} (${proj})" \
  -H "Priority: $priority" \
  -H "Tags: $tags" \
  -H "Markdown: yes" \
  -d "$body" \
  "ntfy.sh/${NTFY_TOPIC}" >/dev/null
