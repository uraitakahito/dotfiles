# dotfiles

Personal dotfiles repository for a unified development environment.
Provides Docker, Zsh, and VS Code configurations.
Follows [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) for configuration file placement.

## VS Code Dev Containers との連携

このリポジトリは [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) の dotfiles 機能と連携して使用することを想定しています。

VS Code の設定で以下を指定すると、Dev Container 作成時に自動的にこのリポジトリがクローンされ、`install.sh` が実行されます：

- `dotfiles.repository`: このリポジトリのURL
- `dotfiles.targetPath`: コンテナ内のインストール先パス
- `dotfiles.installCommand`: `install.sh`

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

## Docker開発環境の構築

ビルド・起動・接続の詳細な手順は [Dockerfile](./Dockerfile) のコメントを参照してください。
