#!/usr/bin/env python3
"""Fail when a Claude Code permission rule uses the legacy ":*" suffix.

Claude Code reads Bash(X:*) as a literal prefix, so a * inside X is never
expanded and the rule silently matches nothing. The startup warning covers
only deny/ask rules, and only in sessions that get to show it, so check here.
"""
import json
import sys


def main(path):
    with open(path, encoding="utf-8") as f:
        permissions = json.load(f)["permissions"]
    legacy = [
        (kind, rule)
        for kind in ("allow", "deny", "ask")
        for rule in permissions.get(kind, [])
        if rule.endswith(":*)")
    ]
    for kind, rule in legacy:
        print(f"{path}: {kind}: {rule}: write a trailing ' *' instead of ':*'", file=sys.stderr)
    return 1 if legacy else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
