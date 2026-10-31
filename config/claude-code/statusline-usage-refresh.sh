#!/bin/bash
#
# Refresh the per-model weekly windows (such as Fable) that statusline.sh shows
# next to 5h / 7d. The statusLine stdin lacks them, so this asks Claude Code
# itself with the get_usage control request; the OAuth token never passes
# through this script.
#
# get_usage is experimental (its shape may change), so every attempt records
# its outcome, and statusline.sh warns when attempts keep failing instead of
# the figures going stale or disappearing unnoticed.
#
# Files in ${XDG_CACHE_HOME:-~/.cache}/claude-statusline/ (the JSON ones on one line):
#   usage.json        last good answer: {"fetched_at", "windows": [{"name", "pct", "resets_at"}]}
#   state.json        last attempt: {"attempt_at", "fails", "reason", "detail"}, reason null on success
#   last-failure.txt  raw output of the last failed attempt
#
set -u

dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
lock="$dir/refresh.lock"
timeout=30
mkdir -p "$dir" || exit 0

# One refresher at a time across sessions. mkdir is atomic; a lock older than
# two minutes is stale, since an attempt never outlives the timeout.
if ! mkdir "$lock" 2>/dev/null; then
  [ -n "$(find "$lock" -maxdepth 0 -mmin +2 2>/dev/null)" ] || exit 0
  rmdir "$lock" 2>/dev/null
  mkdir "$lock" 2>/dev/null || exit 0
fi
trap 'rmdir "$lock" 2>/dev/null' EXIT

now=$(date +%s)
out=""

# record [REASON DETAIL]: write state.json; no REASON means success.
record() {
  local prev tmp
  prev=$(jq -c . "$dir/state.json" 2>/dev/null)
  tmp=$(mktemp "$dir/state.XXXXXX") || return
  if jq -cn --argjson now "$now" --arg reason "${1:-}" --arg detail "${2:-}" --argjson prev "${prev:-null}" '
    if $reason == "" then {attempt_at: $now, fails: 0, reason: null, detail: null}
    else {attempt_at: $now, fails: (($prev.fails // 0) + 1), reason: $reason, detail: $detail} end' >"$tmp"
  then mv -f "$tmp" "$dir/state.json"; else rm -f "$tmp"; fi
}

# fail REASON DETAIL: keep the raw output for debugging, record the failure, stop.
fail() {
  printf '%s\n' "$out" | tail -c 4000 >"$dir/last-failure.txt"
  record "$1" "$2"
  exit 0
}

command -v claude >/dev/null 2>&1 || fail no-claude "claude is not on PATH"

# Hooks off (no herdr report, no push notification), nothing saved, no MCP
# servers. The alarm set by perl survives exec, so claude dies after $timeout s.
out=$(printf '%s\n' '{"type":"control_request","request_id":"statusline","request":{"subtype":"get_usage","skip_behaviors":true}}' |
  env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH \
    perl -e 'alarm shift; exec @ARGV' "$timeout" \
    claude -p --input-format stream-json --output-format stream-json --verbose \
      --model haiku --no-session-persistence --strict-mcp-config \
      --settings '{"disableAllHooks":true}' 2>&1)
status=$?

response=$(printf '%s\n' "$out" | jq -cR 'fromjson? | select(.type? == "control_response") | .response' 2>/dev/null | head -n 1)
if [ -z "$response" ]; then
  [ "$status" -eq 142 ] && fail timeout "no answer within ${timeout}s" # 128 + SIGALRM
  fail no-answer "exit $status: $(printf '%s\n' "$out" | grep -v '^[[:space:]]*$' | tail -n 1 | cut -c 1-160)"
fi

# Check the answer against the shape this script knows and normalise it, so a
# change in get_usage only ever needs a fix in this jq program. model_scoped is
# absent when Claude Code knows nothing about the windows (an answer from its
# cached data, or every row hidden by its allowlist); [] means there are none.
result=$(printf '%s' "$response" | jq -c --argjson now "$now" '
  def epoch: if . == null then null
             else sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601 end;
  def window:
    if type == "object" and (.display_name | type) == "string"
      and has("utilization") and (.utilization | type | IN("number", "null"))
      and has("resets_at") and (.resets_at | type | IN("string", "null"))
    then {name: .display_name, pct: (.utilization | if . == null then null else floor end),
          resets_at: (.resets_at | epoch)}
    else error("unexpected model_scoped entry \(tojson | .[:120])") end;
  .response as $r
  | if .subtype != "success" then {reason: "error", detail: (.error // "no error message" | tostring)}
    elif ($r | type) != "object" or ($r | has("rate_limits") | not) then {reason: "shape", detail: "no rate_limits"}
    elif $r.rate_limits == null then
      if $r.rate_limits_available == false
      then {reason: "no-access", detail: "rate_limits_available is false"}
      else {reason: "unavailable", detail: "the usage endpoint gave no answer"} end
    elif ($r.rate_limits | type) != "object" then {reason: "shape", detail: "rate_limits is not an object"}
    elif ($r.rate_limits | has("model_scoped") | not) then {reason: "unknown", detail: "no model_scoped"}
    elif ($r.rate_limits.model_scoped | type) != "array" then {reason: "shape", detail: "model_scoped is not an array"}
    else try {fetched_at: $now, windows: [$r.rate_limits.model_scoped[] | window]}
         catch {reason: "shape", detail: .}
    end' 2>/dev/null) || fail shape "the answer could not be checked"

reason=$(printf '%s' "$result" | jq -r '.reason // empty')
[ -z "$reason" ] || fail "$reason" "$(printf '%s' "$result" | jq -r .detail)"

# Anything that stops us before record runs shows up as "stalled" in statusline.sh.
tmp=$(mktemp "$dir/usage.XXXXXX") || exit 0
if printf '%s\n' "$result" >"$tmp" && mv -f "$tmp" "$dir/usage.json"; then record; else rm -f "$tmp"; fi
