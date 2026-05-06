#!/bin/bash
#
# Claude Code statusLine: show 5h / 7d rate-limit usage and reset times.
#
# Reads JSON session data from stdin (Claude Code passes it automatically).
# Extracts rate_limits.{five_hour,seven_day}.{used_percentage,resets_at}.
#
# rate_limits is supplied only for Claude.ai Pro/Max subscribers AFTER the
# first API response of the session. API-key auth and pre-first-response
# states fall back to "--%" / "--:--" without erroring.
#
# Output (one line, ANSI-colored):
#    5h 23%   15:30      7d 41%   Mon 09:00
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

disp_pct5=${pct5:+${pct5}%}
: "${disp_pct5:=--%}"
disp_pct7=${pct7:+${pct7}%}
: "${disp_pct7:=--%}"
disp_reset5=${reset5_fmt:-"--:--"}
disp_reset7=${reset7_fmt:-"--- --:--"}

color5=$(colorize_pct "$pct5")
color7=$(colorize_pct "$pct7")

printf '%s 5h %s%s%s  %s%s %s%s   %s 7d %s%s%s  %s%s %s%s\n' \
  "$ICON_5H" "$color5" "$disp_pct5" "$RESET" \
  "$DIM" "$ICON_ARROW" "$disp_reset5" "$RESET" \
  "$ICON_7D" "$color7" "$disp_pct7" "$RESET" \
  "$DIM" "$ICON_ARROW" "$disp_reset7" "$RESET"
