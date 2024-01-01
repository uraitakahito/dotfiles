FROM debian:bullseye

ARG user_id=501
ARG group_id=20
ARG user_name=developer
# The WORKDIR instruction can resolve environment variables previously set using ENV.
# You can only use environment variables explicitly set in the Dockerfile.
# https://docs.docker.com/engine/reference/builder/#/workdir
ARG home=/home/${user_name}

RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  apt-get install -y -qq --no-install-recommends \
    less \
    sudo \
    procps \
    zsh \
    sed \
    curl \
    ca-certificates \
    iputils-ping \
    net-tools \
    git \
    gnupg2
RUN apt-get install -y -qq --no-install-recommends vim emacs
RUN apt-get install -y -qq --no-install-recommends \
  tmux \
  # fzf needs PAGER(less or something)
  fzf \
  exa \
  trash-cli

# Add superuser
RUN curl -sS https://raw.githubusercontent.com/uraitakahito/set-superuser-and-group/main/set-superuser-and-group.sh > /usr/local/bin/set-superuser-and-group.sh && \
  chmod 755 /usr/local/bin/set-superuser-and-group.sh && \
  set-superuser-and-group.sh ${group_id} ${user_id} ${user_name} && \
  chown -R ${user_id}:${group_id} ${home}

COPY bin/docker-entrypoint.sh /usr/local/bin/

USER ${user_name}

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["tail", "-F", "/dev/null"]
