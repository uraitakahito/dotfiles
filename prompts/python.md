# Python

## 開発コマンド

### テスト

テストの全体実行方法

```bash
# 詳細出力付きで全テストを実行する場合
uv run pytest -s -v --setup-show
```

### リンティングと型チェック

```bash
# Ruffリンターを実行
uv run ruff check .

# Pyrightで型チェックを実行（Pylanceと同等）
uv run pyright

# 型チェックのみ（警告を含む全て表示）
uv run pyright --outputjson | jq '.generalDiagnostics[] | select(.severity != "information")'
```

**重要:** コードを修正した後はテスト、リンティング、型チェックを必ず実施してください。
