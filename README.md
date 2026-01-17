# dotfiles

Personal dotfiles repository for a unified development environment.
Provides Docker, Zsh, and VS Code configurations.
Follows [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) for configuration file placement.

## Integration with VS Code Dev Containers

This repository is designed to work with the dotfiles feature of [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers).

When you configure the following VS Code settings, this repository will be cloned automatically when creating a Dev Container and `install.sh` will be executed:

- `dotfiles.repository`: URL of this repository
- `dotfiles.targetPath`: Installation path inside the container
- `dotfiles.installCommand`: `install.sh`

## Directory Structure

```
dotfiles/
├── config/
│   ├── Code/User/          # VS Code settings
│   ├── claude-code/        # Claude Code settings
│   ├── gemini/             # Gemini CLI settings
│   ├── git/                # Git settings
│   ├── ruff/               # Ruff settings
│   ├── tmux/               # tmux settings
│   ├── vim/                # Vim settings
│   └── zsh/                # Zsh settings
│       ├── zshrc           # Entry point
│       ├── conf.d/         # Modularized configuration
│       ├── functions/      # Helper functions
│       ├── completion/     # Completion definitions
│       └── plugins/        # Plugins
├── install.sh              # Installation script
└── Dockerfile
```

## Installation

```bash
./install.sh
```

## Docker Development Environment Setup

See the comments in [Dockerfile](./Dockerfile) for detailed instructions on building, starting, and connecting.
