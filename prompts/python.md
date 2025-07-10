# Pythonを使ったプロジェクトの場合の開発ガイドライン

## 開発コマンド

### uvを使用している場合

**重要:** コードを修正した後はテスト、リンティング、型チェックを必ず実施してください。

#### テスト

テストの全体実行方法

```bash
# 詳細出力付きで全テストを実行する場合
uv run pytest -s -v --setup-show
# カバレッジを調査する場合
uv run pytest --cov
```

#### Ruff でのリンティング

```bash
uv run ruff check .
```

#### pyright(Pylance) での静的型チェック

```bash
uv run pyright

# 型チェックのみ（警告を含む全て表示）
uv run pyright --outputjson | jq '.generalDiagnostics[] | select(.severity != "information")'
```

静的型チェックのエラーが出ないコードを心がけてください。

## docstring

- reStructuredText形式で書いてください
