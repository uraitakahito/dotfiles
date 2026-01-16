# Pythonを使ったプロジェクトの場合の開発ガイドライン

## 開発コマンド(uvを使用している場合)

**重要:** コードを修正した後はテスト、リンティング、型チェックを必ず実施してください。

### one-liner

**python実行時には `uv` を使ってください。**

```bash
uv run python -c "print('hello world')"
```

### テスト

テストの全体実行方法

```bash
# 詳細出力付きで全テストを実行する場合
uv run pytest -s -v --setup-show
# カバレッジを調査する場合
uv run pytest --cov
```

### Ruff でのリンティング

```bash
uv run ruff check .
```

### pyrightでの静的型チェック

```bash
uv run pyright

# 型チェックのみ（警告を含む全て表示）
uv run pyright --outputjson | jq '.generalDiagnostics[] | select(.severity != "information")'
```

静的型チェックのエラーが出ないコードを心がけてください。

## docstring

- reStructuredText形式で書いてください

## ファイル名

> 内部インターフェース（パッケージ、モジュール、クラス、関数、属性、その他の名前）は、依然として先頭にアンダースコア1つを付けて命名すべきである。
> [PEP8 Public and Internal Interfaces](https://peps.python.org/pep-0008/#public-and-internal-interfaces)

## コードガイドライン

### iteration

- forループは、コレクションや範囲に含まれる各要素に対して処理を実行したり副作用を発生させたりするために使います。
- whileループは、一定の条件が満たされている間いてレーションを続けるために使います。
- 内包表記は、コレクションを別のコレクションに変換するために使います。
