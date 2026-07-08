# MCP (Claude Code CLI)

Claude Code CLI 用の MCP サーバー定義 `mcp.json` を置くスロット。

- `install.sh` が `mcp.json` を検出したら `~/.config/mcp/mcp.json` に symlink する
  （無ければ空フォルダのまま＝リンク切れを作らない）。
- 起動時に読み込む（中身を入れてから）:

      claude --mcp-config ~/.config/mcp/mcp.json

いまはスロット予約のみで `mcp.json` は未配置。サーバー（xing5 / taylorwilsdon 等）と
認証を決めたら、その `mcp.json` をここに追加する。
