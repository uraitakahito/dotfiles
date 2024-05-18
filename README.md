## Personalizing Dev Containers with dotfile repositories

In settings.json:

```json
{
  "dotfiles.repository": "xxxxx/dotfiles",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "install.sh"
}
```

CAUTION:

DONOT INPUT `~/dotfiles/install.sh` BUT `install.sh`.

## Tips

### Running a command and then killing it

```console
% docker container run -it --rm --init --name $PROJECT-container $PROJECT-image ls /
```

### How to save zsh history

To save history, create volume:

```console
% docker volume create zsh-volume
% docker run -it --rm -v zsh-volume:/zsh-volume alpine touch /zsh-volume/.zsh_history
% docker run -it --rm -v zsh-volume:/zsh-volume alpine chown -R `id -u`:`id -g` /zsh-volume
% docker run -it --rm -v zsh-volume:/zsh-volume alpine /bin/ash
```

And run docker containers with volume:

```console
% docker run -d --rm --init --mount type=volume,src=zsh-volume,dst=/zsh-volume --name $PROJECT-container $PROJECT-image
% docker exec -it $PROJECT-container zsh
% ln -fs /zsh-volume/.zsh_history ~/.zsh_history
```
