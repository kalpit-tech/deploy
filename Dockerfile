FROM ubuntu:18.04 AS home

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
ENV HOME=/home/modehero

RUN set -o pipefail \
  && ln -sf /bin/bash /bin/dash \
  && useradd -ms /bin/bash modehero \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    sudo \
    apt-utils \
    git \
    ca-certificates \
    openssh-client \
    locales \
    gnupg2 \
    wget \
  && rm -rf /var/lib/apt/lists/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN set -o pipefail \
  && usermod -aG sudo modehero \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen \
  && dpkg-reconfigure --frontend=$DEBIAN_FRONTEND locales \
  && mkdir -p $HOME \
  && chown -R modehero:modehero $HOME

USER modehero
WORKDIR $HOME
ARG GITHUB_TOKEN
RUN set -o pipefail \
    && rm .bashrc \
    && git init \
    && git remote add origin https://${GITHUB_TOKEN}@github.com/modehero/home \
    && git pull origin master \
    && chmod 400 .ssh/* \
    && sudo cp -r .ssh /root/.ssh \
    && sudo chown root:root /root/.ssh

RUN set -o pipefail \
   && sudo apt-get update \
   && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb \
   && sudo apt-get install -y --no-install-recommends \
     curl \
     git \
     python3-dev \
     python3-pip \
     python3-wheel \
     python3-setuptools \
     redis-server \
     xvfb \
     libfontconfig \
     libopenblas-dev \
     tmux \
     rsync \
     build-essential \
     mysql-client \
     cron \
     nginx \
     vim \
     jq \
     moreutils \
     wget \
     fontconfig \
     lsof \
     ./wkhtmltox_0.12.6-1.bionic_amd64.deb \
  && rm wkhtmltox_0.12.6-1.bionic_amd64.deb \
  && sudo rm -rf /var/lib/apt/lists/*

ENV PATH=$HOME/.local/bin:$PATH
RUN set -o pipefail \
  && python3 -m pip install --upgrade setuptools pip \
  && python3 -m pip install wheel frappe-bench pandas==0.24.2 numpy==1.18.5

ENV NVM_DIR=$HOME/.nvm
RUN set -o pipefail \
  && mkdir -p $NVM_DIR \
  && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
  && export NVM_DIR="$HOME/.nvm" \
  && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" \
  && nvm install 12.19.1 \
  && npm install -g yarn
ENV PATH=$HOME/.nvm/versions/node/v12.19.1/bin/:$PATH

USER root
ARG UID=1000
ARG GID=1000
RUN set -o pipefail \
  && usermod -u ${UID} modehero \
  && ([ -e $(cat /etc/group | grep '${GID}') ] || groupmod -g ${GID} modehero) \
  && chown -R modehero:modehero $HOME
USER modehero

USER root
ENV HOME=/home/modehero

USER modehero
WORKDIR $HOME

ARG FRAPPE_PATH
ARG FRAPPE_BRANCH
RUN bench init --frappe-branch ${FRAPPE_BRANCH} \
 --frappe-path ${FRAPPE_PATH} modehero

WORKDIR $HOME/modehero
COPY --chown=modehero:modehero . .

# ENTRYPOINT [ "/bin/sh","-c","./run.sh" ]
