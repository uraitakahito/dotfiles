# Build Instructions
#
# Run in the dotfiles directory:
#
#   PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g` --build-arg TZ=Asia/Tokyo
#
# To rebuild layers after COPY when dotfiles change:
#
#   PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g` --build-arg TZ=Asia/Tokyo --build-arg CACHEBUST=$(date +%s)
#
# Start Container
#
#   docker volume create $PROJECT-zsh-history
#
#   docker container run -d --rm --init -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock -e GH_TOKEN=$(gh auth token) --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume --name $PROJECT-container $PROJECT-image
#
# Log into the container
#
# Launch Claude Code
#
#   claude --dangerously-skip-permissions
#
# Connect from VS Code
#
# 1. Open Command Palette (Shift + Command + P)
# 2. Select Dev Containers: Attach to Running Container
# 3. Open the /app directory
#
# For details:
#   https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container
#

# Debian 12.13
FROM debian:bookworm-20260112

ARG user_name=developer
ARG user_id
ARG group_id
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG extra_utils_repository="https://github.com/uraitakahito/extra-utils.git"
# Refer to the following URL for Node.js versions:
#   https://nodejs.org/en/about/previous-releases
ARG node_version="24.4.0"

#
# Git
#
RUN apt-get update -qq && \
  apt-get install -y -qq --no-install-recommends \
    ca-certificates \
    git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

#
# clone features
#
RUN cd /usr/src && \
  git clone --depth 1 ${features_repository}

#
# Add user and install common utils.
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
  git clone --depth 1 ${extra_utils_repository} && \
  ADDEZA=true \
    /usr/src/extra-utils/utils/install.sh

COPY docker-entrypoint.sh /usr/local/bin/

USER ${user_name}

#
# dotfiles - Copy local files with COPY
# CACHEBUST: Changing this value invalidates the cache for the following steps
#
ARG CACHEBUST=1
COPY --chown=${user_name}:${user_name} . /home/${user_name}/dotfiles

#
# Fetch zsh plugin submodules
# (COPY does not include the .git directory, so submodules will be empty)
#
RUN git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
  /home/${user_name}/dotfiles/config/zsh/plugins/zsh-autosuggestions && \
  git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
  /home/${user_name}/dotfiles/config/zsh/plugins/fast-syntax-highlighting

#
# Install dotfiles
#
RUN /home/${user_name}/dotfiles/install.sh

#
# Timezone
#
ARG TZ
ENV TZ="$TZ"

#
# Claude Code
#
# Discussion about using nvm during Docker container build:
#   https://stackoverflow.com/questions/25899912/how-to-install-nvm-in-docker
#
RUN curl -fsSL https://claude.ai/install.sh | bash

WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["tail", "-F", "/dev/null"]
