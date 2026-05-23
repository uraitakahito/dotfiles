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
proj=$(basename "${cwd:-?}")

# Per-event Priority / Tags so receivers can distinguish event kinds.
case "$event" in
  Stop)         priority="default"; tags="white_check_mark,claude-code" ;;
  Notification) priority="high";    tags="bell,claude-code" ;;
  *)            priority="default"; tags="claude-code" ;;
esac

# Plain text body: Claude's message + short session id.
# Title carries project/event metadata; the body stays minimal so the
# iOS lock screen (which does not render Markdown via APNs) is readable.
body="${message:-(no message)}
(session ${session_id:-?})"

curl -fsS \
  -H "Title: ${proj} — ${event}" \
  -H "Priority: $priority" \
  -H "Tags: $tags" \
  -d "$body" \
  "ntfy.sh/${NTFY_TOPIC}" >/dev/null
