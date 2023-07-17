## Usage

### Use Visual Studio Code

The **[Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** supports two primary operating models:

1. You can use a container as your full-time development environment
2. You can attach to a running container to inspect it

#### 1. container as your full-time development environment

- Run the Docker Desktop application to start Docker.
- Open the **Command Palette** (Command + Shift + P) to run the command **Dev Containers: Reopen in Container**
- Check the development environment by opening the **Terminal** (Ctrl + Shift + `)

#### 2. Attach to a running container

- Run the Docker Desktop application to start Docker.

Build the image:

```console
% docker image build -t $(basename `pwd`)-image ./ --build-arg user_id=`id -u` --build-arg group_id=`id -g`
```

Run docker containers:

```console
% docker run -d --rm --init --name $(basename `pwd`)-container $(basename `pwd`)-image
```

And Open the **Command Palette** to run the command **Dev Containers: Attach to Running Container**

See Also: [Attach to a Docker container](https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container)

### Vim or Emacs (in other words, only terminal)

The procedure is the same up to the point where the container is started.

Execute zsh within a running Docker container:

```console
% docker exec -it $(basename `pwd`)-container /bin/zsh
```

And type vim or emacs :-D
