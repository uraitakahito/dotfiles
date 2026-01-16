# dotfiles

Personal dotfiles repository for a unified development environment.
Provides Docker, Zsh, and VS Code configurations.
Includes development guidelines based on SOLID principles and Domain-Driven Design.

## ディレクトリ構造

```
dotfiles/
├── config/
│   ├── Code/User/          # VS Code設定
│   ├── claude-code/        # Claude Code設定
│   ├── gemini/             # Gemini CLI設定
│   ├── git/                # Git設定
│   ├── ruff/               # Ruff設定
│   ├── tmux/               # tmux設定
│   ├── vim/                # Vim設定
│   └── zsh/                # Zsh設定
│       ├── zshrc           # エントリーポイント
│       ├── conf.d/         # モジュール化された設定
│       ├── functions/      # ヘルパー関数
│       ├── completion/     # 補完定義
│       └── plugins/        # プラグイン
├── install.sh              # インストールスクリプト
└── Dockerfile
```

## インストール

```bash
./install.sh
```

## メモ

ezaのaliasを設定しています。`ls` コマンドを使わずに `a` や `ll` を使いましょう。
（定義: `config/zsh/conf.d/10-aliases.zsh`）

## Docker開発環境の構築

ビルド・起動・接続の詳細な手順は [Dockerfile](./Dockerfile) のコメントを参照してください。
