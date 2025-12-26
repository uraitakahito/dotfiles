## Steps to Try the Created Dotfiles

```console
% curl -L -O https://raw.githubusercontent.com/uraitakahito/claude-code-docker/refs/heads/main/Dockerfile
% curl -L -O https://raw.githubusercontent.com/uraitakahito/claude-code-docker/refs/heads/main/docker-entrypoint.sh
% chmod 755 docker-entrypoint.sh
```

The subsequent steps are described at the beginning of the downloaded Dockerfile.

## prompts

This provides cross-project prompts that are common to both GitHub Copilot and Claude Code.

GitHub Copilot is invoked from [settings.json](https://github.com/uraitakahito/dotfiles/blob/76109f5dc3b004abb10f1399adb84c7f4749f708/settings.json#L50).

Claude Code is invoked from [CLAUDE.md](https://github.com/uraitakahito/dotfiles/blob/a4bc06bfbd64ff0944110182ef36e23001999988/.claude/CLAUDE.md)
