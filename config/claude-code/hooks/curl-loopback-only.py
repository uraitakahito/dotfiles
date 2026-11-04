#!/usr/bin/env python3
"""PreToolUse (matcher: Bash): curl で書く・鍵を送るのは、行き先が loopback だけのときに限る。

この hook に置き換える前の deny (curl の 15 本) と同じ旗を見る (-X -d -F -T -u と長い名前、
--oauth2-bearer、Authorization のヘッダ)。その旗があるとき、行き先が 1 つ残らず
127.0.0.0/8・::1・localhost なら黙って通す (exit 0。後はいつもの許可の判定)。
次のときは止める (exit 2。理由は stderr で Claude に届く):
  - 外の行き先が 1 つでもある・行き先が読めない
  - 行き先を変える旗がある (-K -x -L -: --resolve --connect-to --proxy …)
  - ssh の先で走る (そこの loopback はこの機械ではない)
  - 文字列の中で走る curl の書き込み (bash -c '…'・$(…)・`…`・シェルに食わせる here-doc)
語に分けられないとき (shlex は "$(… "…" …)" の入れ子の引用符を読めない) は、置き換える前の
deny と同じ照合に戻す: 片の頭が curl で、後ろに書く旗があれば止める。

境界ではない。書き方を変えれば当たらないのは、置き換える前の deny と同じ。外へ書く curl を
止める強さはそのまま、loopback だけを開ける。
"""
import ipaddress
import json
import re
import shlex
import sys
from urllib.parse import urlsplit

# 値を取る短い旗 (curl --help all)。-X -d -F -T -u は書く・送る旗でもある。
SHORT_ARG = set("AbcCdDeEFHKmoPQrtTuUwXxYyz")
WRITE_SHORT = set("XdFTu")
REROUTE_SHORT = set("KxL:")
# 値を取る長い旗。知らない旗は値を取らないとみなす (その値が宛先に見えれば止まる側に倒れる)。
LONG_ARG = {
    "abstract-unix-socket", "aws-sigv4", "cacert", "capath", "cert", "cert-type", "ciphers",
    "config", "connect-timeout", "connect-to", "continue-at", "cookie", "cookie-jar", "data",
    "data-ascii", "data-binary", "data-raw", "data-urlencode", "doh-url", "dump-header",
    "expand-data", "expand-header", "expand-json", "expand-url", "form", "form-string", "header",
    "interface", "json", "keepalive-time", "key", "key-type", "limit-rate", "local-port",
    "max-filesize", "max-redirs", "max-time", "noproxy", "oauth2-bearer", "output", "output-dir",
    "preproxy", "proxy", "proxy-header", "proxy-user", "quote", "range", "referer", "request",
    "resolve", "retry", "retry-delay", "retry-max-time", "socks4", "socks4a", "socks5",
    "socks5-hostname", "speed-limit", "speed-time", "stderr", "trace", "trace-ascii",
    "unix-socket", "upload-file", "url", "url-query", "user", "user-agent", "variable",
    "write-out",
}
WRITE_LONG = ("request", "data", "json", "form", "upload-file", "oauth2-bearer")  # 前方一致 (置き換える前の deny と同じ)
REROUTE_LONG = {"config", "proxy", "preproxy", "resolve", "connect-to", "location",
                "location-trusted", "socks4", "socks4a", "socks5", "socks5-hostname",
                "doh-url", "next"}
CONTROL = {";", "&&", "||", "|", "&", "|&", "(", ")", ";;", "\n", "`"}
REDIRECT = {">", ">>", "<", "<>", ">|", ">&", "&>", "&>>", "<&", "<<", "<<-", "<<<"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
CURL_WORD = re.compile(r"(^|[^A-Za-z0-9_.-])curl($|[^A-Za-z0-9_-])")
HEREDOC = re.compile(r"(?<!<)<<-?(?!<)[ \t]*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")  # <<< は here-string
SUBST = ("$(", "`", "<(", ">(")
# shlex は続いた記号を 1 語にする (")\n"・");")。演算子ごとに分け直す
PUNCT = re.compile(r"[();<>|&\n`]+")
OPS = re.compile(r"<<<|&>>|<<|>>|&&|\|\||;;|\|&|>&|<&|&>|>\||<>|[();<>|&\n`]")


class Stop(Exception):
    pass


class Unreadable(Exception):
    """語に分けられない。置き換える前の deny と同じ照合 (deny_like) に戻す。"""


# 読めないときの代わり: 置き換える前の deny の 15 本と同じ形。&& ; | 改行 $( ` で片に切り、
# 片の頭 (代入と timeout などの包みを除く) が curl で、後ろに書く旗があれば止める。
PIECES = re.compile(r"&&|\|\||;|\||\n|\$\(|`")
DENY_PIECE = re.compile(
    r"\s*(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)*(?:(?:timeout\s+\S+|time|nice|nohup|stdbuf\s+\S+|command|builtin|noglob|xargs)\s+)*"
    r"(?:\S*/)?curl\b.*?\s(-X|--request|-d|--data|--json|-F|--form|-T|--upload-file|-u|--user[ =]"
    r"|--oauth2-bearer|-H\S*\s*\S*uthorization|--header\S*\s*\S*uthorization)",
    re.S)


def deny_like(cmd):
    return any(DENY_PIECE.match(p) for p in PIECES.split(cmd.replace("\\\n", " ")))


def base(word):
    return word.rsplit("/", 1)[-1]


def split_heredocs(cmd):
    """here-doc の本文を外す。シェル・ssh・eval に食わせる本文は、別に返して中を読む。"""
    lines, out, fed, i = cmd.split("\n"), [], [], 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        i += 1
        for m in HEREDOC.finditer(line):
            body = []
            while i < len(lines) and lines[i].lstrip("\t") != m.group(2):
                body.append(lines[i])
                i += 1
            if i >= len(lines):
                raise Unreadable(f"here-doc の終わり {m.group(2)!r} が無い")
            i += 1
            words = {base(w) for w in re.split(r"[\s;&|()]+", line[:m.start()]) if w}
            if words & (SHELLS | {"ssh", "eval"}):
                fed.append("\n".join(body))
    return "\n".join(out), fed


def tokens(cmd):
    lex = shlex.shlex(cmd.replace("\\\n", " "), posix=True, punctuation_chars="();<>|&\n`")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = ""  # 語の途中の # は bash ではただの文字。注釈は下で、語の頭の # だけ
    out, skipping = [], False
    try:
        words = list(lex)
    except ValueError as e:  # 閉じない引用符など
        raise Unreadable(str(e))
    for t in (op for w in words for op in (OPS.findall(w) if PUNCT.fullmatch(w) else [w])):
        if t == "\n":
            skipping = False
        elif skipping:
            continue
        elif t.startswith("#"):
            skipping = True
            continue
        out.append(t)
    return out


def loopback(dest):
    url = dest if "://" in dest else "http://" + dest
    try:
        host = urlsplit(url).hostname
    except ValueError:
        return False
    if not host:
        return False
    if host == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def check_segment(args, nested, after_ssh):
    """curl の後ろの語 (次の制御演算子まで) を読む。止めるなら Stop。"""
    write, reroute, dests = [], [], []
    i = 0
    while i < len(args):
        a = args[i]
        i += 1
        if a in REDIRECT:
            i += 1  # 行き先のファイル
            continue
        if a.isdigit() and i < len(args) and args[i] in REDIRECT:
            continue  # 2>/dev/null の 2
        if a.startswith("--") and len(a) > 2:
            name, eq, val = a[2:].partition("=")
            if name in LONG_ARG and not eq:
                val = args[i] if i < len(args) else ""
                i += 1
            if name.startswith(WRITE_LONG) or name == "user":
                write.append("--" + name)
            if name == "header" and "authorization" in val.lower():
                write.append("--header Authorization")
            if name in REROUTE_LONG:
                reroute.append("--" + name)
            if name == "url":
                dests.append(val)
            continue
        if a.startswith("-") and len(a) > 1:
            for j, ch in enumerate(a[1:], start=1):
                if ch in WRITE_SHORT:
                    write.append("-" + ch)
                if ch in REROUTE_SHORT:
                    reroute.append("-" + ch)
                if ch in SHORT_ARG:
                    val = a[j + 1:]
                    if not val:
                        val = args[i] if i < len(args) else ""
                        i += 1
                    if ch == "H" and "authorization" in val.lower():
                        write.append("-H Authorization")
                    break
            continue
        dests.append(a)
    if not write:
        return
    why = " ".join(dict.fromkeys(write))
    if nested:
        raise Stop(f"{why}: 文字列の中で走る curl の書き込み")
    if after_ssh:
        raise Stop(f"{why}: ssh の先の loopback はこの機械ではない")
    if reroute:
        raise Stop(f"{why}: 行き先を変える旗 {' '.join(dict.fromkeys(reroute))} がある")
    if not dests:
        raise Stop(f"{why}: 行き先が読めない")
    outside = [d for d in dests if not loopback(d)]
    if outside:
        raise Stop(f"{why}: loopback でない行き先 {outside[0]!r}")


def check(cmd, nested=False, depth=0):
    if depth > 3:
        raise Unreadable("入れ子が深すぎる")
    cmd, fed = split_heredocs(cmd)
    for body in fed:
        check(body, True, depth + 1)
    toks = tokens(cmd)
    seg, words = 0, set()  # いまの片の、ここまでの語
    for k, t in enumerate(toks):
        if t in CONTROL:
            seg, words = k + 1, set()
            continue
        if base(t) == "curl":
            end = next((m for m in range(k + 1, len(toks)) if toks[m] in CONTROL), len(toks))
            check_segment(toks[k + 1:end], nested, "ssh" in words)
            words.add("curl")
            continue
        if not CURL_WORD.search(t):
            words.add(base(t))
            continue
        runs_as_code = (
            any(s in t for s in SUBST)
            or "eval" in words or "ssh" in words
            or (k > seg and re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", toks[k - 1]) and words & SHELLS)
        )
        if runs_as_code:
            check(t, True, depth + 1)
        words.add(base(t))


def main():
    data = json.load(sys.stdin)
    if data.get("tool_name") != "Bash":
        return 0
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if "curl" not in cmd:
        return 0
    try:
        check(cmd)
    except Stop as e:
        print(f"curl-loopback-only: 止めました — {e}。curl の書き込みは、行き先が "
              "127.0.0.1・::1・localhost だけのときに通します。外へ送る必要があるなら、"
              "利用者に入力欄の `! curl …` で打ってもらってください。", file=sys.stderr)
        return 2
    except Exception as e:  # Unreadable も、思わぬ例外も: 置き換える前の deny と同じ照合に戻す
        if deny_like(cmd):
            print(f"curl-loopback-only: コマンドを語に分けられず ({type(e).__name__}: {e})、"
                  "curl の書き込みの旗が見えるので止めました (置き換える前の deny と同じ判定)。", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
