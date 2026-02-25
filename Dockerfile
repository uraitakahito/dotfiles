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
# Start the Docker container(/run/host-services/ssh-auth.sock is a virtual socket provided by Docker Desktop for Mac.):
#
#   docker container run -d --rm --init -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock -e GH_TOKEN=$(gh auth token) --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume --name $PROJECT-container $PROJECT-image
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

# Debian 12.13
FROM debian:bookworm-20260202

ARG user_name=developer
ARG user_id
ARG group_id
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG extra_utils_repository="https://github.com/uraitakahito/extra-utils.git"

ARG LANG=C.UTF-8
ENV LANG="$LANG"
ARG TZ=UTC
ENV TZ="$TZ"

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
  git clone --depth 1 ${extra_utils_repository} && \
  ADDEZA=true \
  ADDGRPCURL=true \
  ADDHADOLINT=true \
  \
  ADDCLAUDECODE=true \
  # Claude Code is installed under $HOME, so the username must be specified.
  USERNAME=${user_name} \
  \
  UPGRADEPACKAGES=false \
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
# Install dotfiles
#
RUN /home/${user_name}/dotfiles/install.sh

WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["tail", "-F", "/dev/null"]
