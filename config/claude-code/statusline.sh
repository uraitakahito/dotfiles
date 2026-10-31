#!/bin/bash
#
# Claude Code statusLine: show 5h / 7d rate-limit usage and reset times,
# plus the per-model weekly windows (such as Fable).
#
# Reads JSON session data from stdin (Claude Code passes it automatically).
# Extracts rate_limits.{five_hour,seven_day}.{used_percentage,resets_at}.
#
# rate_limits is supplied only for Claude.ai Pro/Max subscribers AFTER the
# first API response of the session. API-key auth and pre-first-response
# states fall back to "--%" / "--:--" without erroring.
#
# Output (one line, ANSI-colored):
#    5h 23%   15:30      7d 41%   Mon 09:00    Fable 30%
#
# The per-model windows are not in the stdin JSON: statusline-usage-refresh.sh
# caches them, and this script starts it in the background when the cache is
# due. Figures the last refresh could not confirm are dimmed, and from the
# second failure in a row a warning names the reason, so a refresher that
# stops working never goes unnoticed.
#
# Reference: https://code.claude.com/docs/en/statusline.md

input=$(cat)

pct5=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
pct7=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
reset5=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
reset7=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Floor decimals to integers (% strip after the dot).
[ -n "$pct5" ] && pct5=${pct5%%.*}
[ -n "$pct7" ] && pct7=${pct7%%.*}

# Format epoch seconds with strftime. macOS uses BSD `date -r`, Linux uses GNU `date -d @`.
format_reset() {
  local epoch="$1" fmt="$2"
  [ -z "$epoch" ] && return 0
  if [[ "$OSTYPE" == darwin* ]]; then
    date -r "$epoch" "+$fmt" 2>/dev/null
  else
    date -d "@$epoch" "+$fmt" 2>/dev/null
  fi
}

reset5_fmt=$(format_reset "$reset5" "%H:%M")
reset7_fmt=$(format_reset "$reset7" "%a %H:%M")

# ANSI escapes (ANSI-C quoting works in bash 3.2).
RESET=$'\033[0m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'

# Pick a color by usage percentage. Empty (placeholder) → no color.
colorize_pct() {
  local pct="$1"
  [ -z "$pct" ] && return 0
  if [ "$pct" -lt 50 ]; then
    printf '%s' "$GREEN"
  elif [ "$pct" -lt 80 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$RED"
  fi
}

# Nerd Font icons (Font Awesome PUA), expressed as UTF-8 byte escapes so this
# works on macOS bash 3.2 where `printf '\uXXXX'` is not supported.
ICON_5H=$'\xef\x89\x92'    # U+F252 hourglass
ICON_7D=$'\xef\x81\xb3'    # U+F073 calendar
ICON_ARROW=$'\xef\x81\xa1' # U+F061 arrow-right
ICON_MODEL=$'\xef\x80\xad' # U+F02D book
ICON_WARN=$'\xef\x81\xb1'  # U+F071 warning

disp_pct5=${pct5:+${pct5}%}
: "${disp_pct5:=--%}"
disp_pct7=${pct7:+${pct7}%}
: "${disp_pct7:=--%}"
disp_reset5=${reset5_fmt:-"--:--"}
disp_reset7=${reset7_fmt:-"--- --:--"}

color5=$(colorize_pct "$pct5")
color7=$(colorize_pct "$pct7")

usage_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
usage_refresh="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}/statusline-usage-refresh.sh"

# usage_fail REASON DETAIL: record a failure the refresher could not record
# itself. When nothing can be written, warn at once instead of never.
usage_fail() {
  local prev tmp
  u_reason=$1 u_fails=$((u_fails + 1)) u_attempt=$now
  prev=$(jq -c . "$usage_dir/state.json" 2>/dev/null)
  if tmp=$(mktemp "$usage_dir/state.XXXXXX" 2>/dev/null) &&
    jq -cn --argjson now "$now" --arg reason "$1" --arg detail "$2" --argjson prev "${prev:-null}" \
      '{attempt_at: $now, fails: (($prev.fails // 0) + 1), reason: $reason, detail: $detail}' >"$tmp" &&
    mv -f "$tmp" "$usage_dir/state.json"; then
    return
  fi
  [ -z "$tmp" ] || rm -f "$tmp"
  u_fails=2
}

# Per-model windows, shown where the 5h / 7d figures are.
models_out=""
if [ -n "$pct7" ]; then
  now=$(date +%s)
  # Each file is one line of JSON; a missing or broken one counts as empty.
  # Out comes a header line (last outcome, failures in a row, last attempt, last
  # launch, 7d % at that launch, whether the cache is due), then one per window.
  usage=$(cat "$usage_dir/state.json" "$usage_dir/usage.json" "$usage_dir/launch.json" 2>/dev/null |
    jq -rRs --argjson now "$now" '
      split("\n") | map(fromjson? | objects) | add // {}
      | (.fetched_at // 0) as $f
      | [.reason // "-", .fails // 0, .attempt_at // 0, .launched_at // 0, .launched_pct7 // -1,
         (if $now - $f >= 1800 or any(.windows[]?.resets_at | numbers; . > $f and . <= $now)
          then 1 else 0 end)],
        (.windows[]? | [.name, .pct // "--", .resets_at // "-"])
      | @tsv')
  { IFS=$'\t' read -r u_reason u_fails u_attempt u_launched u_pct7 u_due; u_windows=$(cat); } <<<"$usage"

  # A refresh launched two minutes ago that never reported back was killed or
  # never ran. Count it as a failure, or nothing would ever say so.
  if [ "$u_launched" -gt "$u_attempt" ] && [ $((now - u_launched)) -ge 120 ]; then
    usage_fail stalled "launched at $(format_reset "$u_launched" "%m-%d %H:%M:%S"), never reported back"
  fi
  # Refresh when the cache is due or 7d usage rose since the last launch; never
  # while a refresh is in flight, and not within five minutes of a failure.
  if [ "$u_launched" -le "$u_attempt" ] &&
    { [ "$u_reason" = "-" ] || [ $((now - u_attempt)) -ge 300 ]; } &&
    { [ "$u_due" = 1 ] || [ "$pct7" -gt "$u_pct7" ]; }; then
    mkdir -p "$usage_dir" 2>/dev/null
    if [ ! -x "$usage_refresh" ]; then
      usage_fail no-refresher "$usage_refresh is missing or not executable"
    elif printf '{"launched_at":%s,"launched_pct7":%s}\n' "$now" "$pct7" 2>/dev/null >"$usage_dir/launch.json"; then
      nohup "$usage_refresh" </dev/null >/dev/null 2>&1 &
    else
      usage_fail no-cache "cannot write to $usage_dir"
    fi
  fi

  # Dim what the last refresh could not confirm.
  while IFS=$'\t' read -r name pct epoch; do
    [ -n "$name" ] || continue
    color=$DIM
    [ "$u_reason" = "-" ] && [ "$pct" != "--" ] && color=$(colorize_pct "$pct")
    # Fable resets with the week; the server's two reset times differ by a second or so.
    reset_part=""
    if [ "$epoch" != "-" ] && { [ -z "$reset7" ] || [ $((epoch > reset7 ? epoch - reset7 : reset7 - epoch)) -gt 120 ]; }; then
      reset_part="  $DIM$ICON_ARROW $(format_reset "$epoch" "%a %H:%M")$RESET"
    fi
    models_out+="   $ICON_MODEL $name $color$pct%$RESET$reset_part"
  done <<<"$u_windows"
  # From the second failure in a row, say why.
  if [ "$u_reason" != "-" ] && [ "$u_fails" -ge 2 ]; then
    models_out="${models_out:-   $ICON_MODEL} $YELLOW$ICON_WARN $u_reason$RESET"
  fi
fi

printf '%s 5h %s%s%s  %s%s %s%s   %s 7d %s%s%s  %s%s %s%s%s\n' \
  "$ICON_5H" "$color5" "$disp_pct5" "$RESET" \
  "$DIM" "$ICON_ARROW" "$disp_reset5" "$RESET" \
  "$ICON_7D" "$color7" "$disp_pct7" "$RESET" \
  "$DIM" "$ICON_ARROW" "$disp_reset7" "$RESET" "$models_out"
