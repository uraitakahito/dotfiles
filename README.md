# dotfiles

Personal dotfiles repository for a unified development environment.
Provides Docker, Zsh, and VS Code configurations.
Follows [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) for configuration file placement.

## Integration with VS Code Dev Containers

This repository is designed to work with the dotfiles feature of [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers).

Add the following to your VS Code `settings.json`:

```json
{
    "dotfiles.repository": "https://github.com/your-username/dotfiles",
    "dotfiles.targetPath": "~/dotfiles",
    "dotfiles.installCommand": "install.sh"
}
```

When creating a Dev Container, this repository will be cloned automatically and `install.sh` will be executed.

## Installation

```bash
./install.sh
```

## Docker Development Environment Setup

See the comments in [Dockerfile](./Dockerfile) for detailed instructions on building, starting, and connecting.
