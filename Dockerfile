# Features of this Dockerfile
#
# - Not based on devcontainer; use by attaching VSCode to the container
# - Claude Code is pre-installed
# - Includes dotfiles and extra utilities
# - Assumes host OS is Mac
# - Passes the GH_TOKEN environment variable into the container
#
# Build the Docker image:
#
#   PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg TZ=Asia/Tokyo --build-arg user_id=`id -u` --build-arg group_id=`id -g`
#
# To rebuild layers after COPY when dotfiles change:
#
#   PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg TZ=Asia/Tokyo --build-arg user_id=`id -u` --build-arg group_id=`id -g` --build-arg CACHEBUST=$(date +%s)
#
# (First time only) Create a volume for command history:
#
# Create a volume to persist the command history executed inside the Docker container.
# It is stored in the volume because the dotfiles configuration redirects the shell history there.
#   https://github.com/uraitakahito/dotfiles/blob/b80664a2735b0442ead639a9d38cdbe040b81ab0/zsh/myzshrc#L298-L305
#
#   docker volume create $PROJECT-zsh-history
#
# Start the Docker container (DooD enabled — see SOCKETPATH below):
# - /run/host-services/ssh-auth.sock is a virtual socket provided by Docker
#   Desktop for Mac and OrbStack.
# - /var/run/docker.sock is bind-mounted to /var/run/docker-host.sock inside the
#   container; the docker-outside-of-docker feature's docker-init.sh script
#   forwards it to /var/run/docker.sock at runtime (GID sync or socat proxy).
#
#   docker container run -d --rm --init -v /run/host-services/ssh-auth.sock:/agent.sock -e SSH_AUTH_SOCK=/agent.sock -v /var/run/docker.sock:/var/run/docker-host.sock -e GH_TOKEN=$(gh auth token) --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume --name $PROJECT-container $PROJECT-image
#
# Windows users: run the above command from a **WSL2 shell** with Docker
# Desktop's "Enable integration with my default WSL distro" turned on. The
# container expects /var/run/docker.sock to be a unix socket; PowerShell-native
# invocation would pass the named-pipe path (//./pipe/docker_engine) which is
# incompatible.
#
# Log into the container.
#
#   OR
#
# Connect from VS Code:
#
# 1. Open Command Palette (Shift + Command + P)
# 2. Select Dev Containers: Attach to Running Container
# 3. Open the /app directory
#
# For details:
#   https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container
#
# (First time only) change the owner of the command history folder:
#
#   sudo chown -R $(id -u):$(id -g) /zsh-volume

# Debian 12.14
FROM debian:bookworm-20260518

ARG user_name=developer
ARG user_id
ARG group_id
# https://github.com/uraitakahito/features/releases/tag/2.0.1
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG features_commit="9f7e672e27207f374d56e5da7f862b0b5b110b3f"
# https://github.com/uraitakahito/extra-utils/releases/tag/1.4.0
ARG extra_utils_repository="https://github.com/uraitakahito/extra-utils.git"
ARG extra_utils_commit="18ed6c714f1ecf58930ced0a3d2e281cf1977994"

ARG LANG=C.UTF-8
ENV LANG="$LANG"
ARG TZ=UTC
ENV TZ="$TZ"

#
# Git
#
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        ca-certificates=20230311+deb12u1 \
        git=1:2.39.5-0+deb12u3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# clone features
#
RUN cd /usr/src && \
    git clone ${features_repository} && \
    cd features && \
    git checkout ${features_commit}

#
# Add user and install common utils.
#
# For the list of installed packages, see:
#   https://github.com/uraitakahito/features/blob/deb6cf416fda206b99c7b771e9caa12e6952f9c7/src/common-utils/main.sh#L35-L78
#
RUN USERNAME=${user_name} \
    USERUID=${user_id} \
    USERGID=${group_id} \
    CONFIGUREZSHASDEFAULTSHELL=true \
    UPGRADEPACKAGES=false \
    # When using ssh-agent inside Docker, add the user to the root group
    # to ensure permission to access the mounted socket.
    #   https://github.com/uraitakahito/features/blob/59e8acea74ff0accd5c2c6f98ede1191a9e3b2aa/src/common-utils/main.sh#L467-L471
    ADDUSERTOROOTGROUP=true \
        /usr/src/features/src/common-utils/install.sh

#
# Install extra utils.
#
RUN cd /usr/src && \
    git clone ${extra_utils_repository} && \
    cd extra-utils && \
    git checkout ${extra_utils_commit} && \
    ADDEZA=true \
    ADDGITLEAKS=true \
    ADDGRPCURL=true \
    ADDHADOLINT=true \
    ADDMAKE=true \
    ADDXXD=true \
    ADDYQ=true \
    \
    ADDCLAUDECODE=true \
    # Claude Code is installed under $HOME, so the username must be specified.
    USERNAME=${user_name} \
    \
    # Pin tool versions (env-overridable since extra-utils 1.3.0; consistent
    # with this repo's philosophy of pinning everything).
    GITLEAKSVERSION=8.30.1 \
    GRPCURLVERSION=1.9.3 \
    HADOLINTVERSION=2.12.0 \
    YQVERSION=4.53.2 \
    \
    UPGRADEPACKAGES=false \
        /usr/src/extra-utils/utils/install.sh

#
# Install docker-outside-of-docker (uses host's docker daemon via socket mount)
# https://github.com/uraitakahito/features/tree/2.0.1/src/docker-outside-of-docker
#
# Version pins (consistent with the dotfiles' philosophy of pinning everything):
#   VERSION=29.4.3        # moby-cli package version (Microsoft Moby repo)
#   MOBYBUILDXVERSION=0.33.0  # moby-buildx package version (Microsoft Moby repo)
#   DOCKERDASHCOMPOSEVERSION=v2  # Compose major version (enum: none|latest|v1|v2)
#
# Note: VERSION / MOBYBUILDXVERSION here track the moby-cli / moby-buildx
# package versions in https://packages.microsoft.com/ (NOT the docker/cli or
# docker/buildx upstream GitHub tag versions, which differ).
#
# SOCKETPATH is set explicitly (matches the default) to make the socket path
# visible in the Dockerfile. The container expects the host's docker socket to
# be mounted at this path at runtime; see the run command in the header comment.
#
RUN VERSION=29.4.3 \
    MOBY=true \
    MOBYBUILDXVERSION=0.33.0 \
    DOCKERDASHCOMPOSEVERSION=v2 \
    INSTALLDOCKERBUILDX=true \
    INSTALLDOCKERCOMPOSESWITCH=false \
    SOCKETPATH=/var/run/docker-host.sock \
    USERNAME=${user_name} \
        /usr/src/features/src/docker-outside-of-docker/install.sh

COPY docker-entrypoint.sh /usr/local/bin/

USER ${user_name}

#
# dotfiles - Copy local files with COPY
# CACHEBUST: Changing this value invalidates the cache for the following steps
#
ARG CACHEBUST=1
COPY --chown=${user_name}:${user_name} . /home/${user_name}/dotfiles

#
# Install dotfiles
#
RUN /home/${user_name}/dotfiles/install.sh

WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["tail", "-F", "/dev/null"]
