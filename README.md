```console
% curl -L -O https://raw.githubusercontent.com/uraitakahito/claude-code-docker/refs/heads/main/Dockerfile
% curl -L -O https://raw.githubusercontent.com/uraitakahito/claude-code-docker/refs/heads/main/docker-entrypoint.sh
% chmod 755 docker-entrypoint.sh
% PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
% docker container run -d --rm --init --mount type=bind,src=`pwd`,dst=/app --mount type=bind,src=$HOME/.gitconfig,dst=/home/developer/.gitconfig --name $PROJECT-container $PROJECT-image
```

And type [`fdshell /bin/zsh`](https://github.com/uraitakahito/dotfiles/blob/d6214f4ed6d63fd437ab53d18eba9705a118e1e8/zsh/myzshrc#L93-L101) or [`fdvscode`](https://github.com/uraitakahito/dotfiles/blob/d6214f4ed6d63fd437ab53d18eba9705a118e1e8/zsh/myzshrc#L103-L111) .

## prompts

This provides cross-project prompts that are common to both GitHub Copilot and Claude Code.

GitHub Copilot is invoked from [settings.json](https://github.com/uraitakahito/dotfiles/blob/76109f5dc3b004abb10f1399adb84c7f4749f708/settings.json#L50).

Claude Code is invoked from [CLAUDE.md](https://github.com/uraitakahito/dotfiles/blob/a4bc06bfbd64ff0944110182ef36e23001999988/.claude/CLAUDE.md)
