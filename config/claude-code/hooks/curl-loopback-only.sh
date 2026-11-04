#!/bin/sh
# PreToolUse (matcher: Bash) の入口。python3 と本体があれば curl-loopback-only.py で行き先を見る。
# どちらかが無い所 (dotfiles の開発用 image には python3 が無い) では、置き換える前の deny の
# 15 本と同じ形を文字で照合する: curl の後ろに書く・送る旗があれば止める (同じ強さ・同じはみ出し)。
# 止めるのは exit 2 だけ。grep が走らないなど、判定できないときも止める側に倒す。
here=$(dirname "$0")
if command -v python3 >/dev/null 2>&1 && [ -f "$here/curl-loopback-only.py" ]; then
  python3 "$here/curl-loopback-only.py" || exit 2
  exit 0
fi
grep -Eq 'curl.*[[:space:]](-X|--request|-d|--data|--json|-F|--form|-T|--upload-file|-u|--user[ =]|--oauth2-bearer|-H.*uthorization|--header.*uthorization)'
case $? in
  0) echo "curl-loopback-only: python3 か本体が無いので、curl の書き込みを置き換える前の deny と同じ形で止めました。" >&2; exit 2 ;;
  1) exit 0 ;;
  *) echo "curl-loopback-only: 判定できなかったので止めました。" >&2; exit 2 ;;
esac
