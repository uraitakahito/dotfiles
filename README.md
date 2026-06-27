# dotfiles

開発環境のための個人用 dotfiles リポジトリ。
設定ファイルの配置は [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) に従います。

## VS Code Dev Containers に従った設計

このリポジトリは [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) の dotfiles 機能に従って設計されています。
しかしながら、開発時に任意のエディタで利用できるようにするため、 Dockerfile内で明示的に利用されることを想定しています。

次のように明示的に呼び出してください:

```Dockerfile
RUN cd /home/${user_name} && \
    git clone ${dotfiles_repository} && \
    cd dotfiles && \
    git checkout ${dotfiles_commit} && \
    ./install.sh
```

サンプルとなるDockerfileは [hello-javascript/Dockerfile.dev.container](https://github.com/uraitakahito/hello-javascript/blob/7fae0a52f9b760efc5ffc8816d5ba205de2b8b31/Dockerfile.dev.container#L213-L220)にあります。

### VS Code Dev Containers機能を使う場合

`settings.json` に以下を追加してください：

```json
{
    "dotfiles.repository": "https://github.com/your-username/dotfiles",
    "dotfiles.targetPath": "~/dotfiles",
    "dotfiles.installCommand": "install.sh"
}
```
