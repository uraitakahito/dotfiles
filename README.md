
## How to start up

```console
% PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
% docker container run -it --rm --init --mount type=bind,src=`pwd`,dst=/app --mount type=bind,src=$HOME/.gitconfig,dst=/home/developer/.gitconfig --name $PROJECT-container $PROJECT-image /bin/zsh
```

## Tips

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
