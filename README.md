```console
% PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
% docker container run -d --rm --init --mount type=bind,src=`pwd`,dst=/app --mount type=bind,src=$HOME/.gitconfig,dst=/home/developer/.gitconfig --name $PROJECT-container $PROJECT-image
```

And type [`fdshell /bin/zsh`](https://github.com/uraitakahito/dotfiles/blob/d6214f4ed6d63fd437ab53d18eba9705a118e1e8/zsh/myzshrc#L93-L101) or [`fdvscode`](https://github.com/uraitakahito/dotfiles/blob/d6214f4ed6d63fd437ab53d18eba9705a118e1e8/zsh/myzshrc#L103-L111) .
