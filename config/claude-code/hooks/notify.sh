#!/bin/bash
#
# Claude Code hook notification wrapper for ntfy.sh.
#
# Usage:
#   ~/.claude/hooks/notify.sh <event>   # event name is included in the title
#
# Claude Code passes the hook payload (JSON) on stdin. We extract `cwd`
# from it so the receiving device can tell which project the event came
# from without opening the message body.
#
# NTFY_TOPIC unset/empty is treated as "notifications disabled" rather
# than an error, because install.sh symlinks this script on every
# environment (Dev Containers, CI runners, etc.) regardless of whether a
# topic is provisioned.
#
set -eu

[ -n "${NTFY_TOPIC:-}" ] || exit 0

event="${1:?event name required}"

payload=$(cat)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)
proj=$(basename "${cwd:-?}")

curl -fsS \
  -H "Title: Claude ${event} (${proj})" \
  -H "Tags: claude-code" \
  -d "${event} fired in ${cwd:-?}" \
  "ntfy.sh/${NTFY_TOPIC}" >/dev/null
