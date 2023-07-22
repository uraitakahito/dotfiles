FROM debian:bullseye

ARG user_id=501
ARG group_id=20
ARG user_name=developer
# The WORKDIR instruction can resolve environment variables previously set using ENV.
# You can only use environment variables explicitly set in the Dockerfile.
# https://docs.docker.com/engine/reference/builder/#/workdir
ARG home=/home/${user_name}

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    less \
    sudo \
    procps \
    zsh \
    sed \
    curl \
    ca-certificates \
    git \
    gnupg2
RUN apt-get install -y --no-install-recommends vim emacs
RUN apt-get install -y --no-install-recommends \
  tmux \
  # fzf needs PAGER(less or something)
  fzf \
  exa \
  trash-cli

COPY bin/set-superuser-and-group.sh ${home}/bin/
RUN ${home}/bin/set-superuser-and-group.sh ${group_id} ${user_id} ${user_name}

#
# prezto
# https://github.com/sorin-ionescu/prezto
#
RUN git clone --recursive \
  https://github.com/sorin-ionescu/prezto.git \
  "${ZDOTDIR:-${home}}/.zprezto"

RUN ln -s ${home}/.zprezto/runcoms/zlogin     ${home}/.zlogin \
  && ln -s ${home}/.zprezto/runcoms/zlogout   ${home}/.zlogout \
  && ln -s ${home}/.zprezto/runcoms/zpreztorc ${home}/.zpreztorc \
  && ln -s ${home}/.zprezto/runcoms/zprofile  ${home}/.zprofile \
  && ln -s ${home}/.zprezto/runcoms/zshenv    ${home}/.zshenv \
  && ln -s ${home}/.zprezto/runcoms/zshrc     ${home}/.zshrc

#
# Starship
# https://starship.rs/
#
RUN curl -sS https://starship.rs/install.sh > ${home}/bin/install-starship.sh && \
  chmod 0755 ${home}/bin/install-starship.sh && \
  ${home}/bin/install-starship.sh --yes && \
  echo 'eval "$(starship init zsh)"' >> ${home}/.zshrc

RUN chown -R ${user_id}:${group_id} ${home}

USER ${user_name}
WORKDIR /home/${user_name}

ENTRYPOINT ["tail", "-F", "/dev/null"]
