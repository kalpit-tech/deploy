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
    && git remote add origin https://${GITHUB_TOKEN}@github.com/modehero/home
#     && git pull origin master \
#     && chmod 777 .ssh/* \
#     && sudo rm -r .ssh /root/.ssh 

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
     python3-venv \
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
ARG C_UID=1000
ARG C_GID=1000
RUN set -o pipefail \
  && usermod -u ${C_UID} modehero \
  && ([ -e $(cat /etc/group | grep '${C_GID}') ] || groupmod -g ${C_GID} modehero) \
  && chown -R modehero:modehero $HOME
USER modehero

USER root
ENV HOME=/home/modehero

USER modehero
WORKDIR $HOME

ARG FRAPPE_PATH
ARG FRAPPE_BRANCH
RUN bench init --frappe-branch main --frappe-path https://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@github.com/kalpit-tech/frappe modehero
# RUN bench init --frappe-branch main \
# --frappe-path https://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@github.com/modehero/frappe modehero/
WORKDIR $HOME/modehero
COPY --chown=modehero:modehero . .

RUN set -o pipefail \
  && sudo apt-get update \
  && sudo apt-get install software-properties-common -y\
  && sudo add-apt-repository ppa:certbot/certbot -y \
  && sudo DEBIAN_FRONTEND=noninteractive apt install python-certbot-nginx -y


RUN set -o pipefail

ENTRYPOINT [ "/bin/sh","-c","./run.sh" ]
# ENTRYPOINT [ "/bin/sh","-c","./run-locally.sh" ]

#   && sudo -- sh -c -e "echo '${SERVER_IP}       ${DOMAIN}' >> /etc/hosts"; 
