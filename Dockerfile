FROM frappe/bench as bench

SHELL ["/bin/bash", "-c"]

 RUN set -o pipefail \
   && sudo apt-get update \
   && sudo apt-get install -y --no-install-recommends \
     curl \
     git \
     python-dev \
     python-pip \
     python-wheel \
     python-setuptools \
     redis-server \
     xvfb \
     libfontconfig \
     wkhtmltopdf \
     libopenblas-dev \
    #  libmysqlclient-dev \
     build-essential \
    #  mysql-client \
     cron
  # && sudo rm -rf /var/lib/apt/lists/* 

USER root
ENV HOME=/home/frappe

USER frappe
WORKDIR $HOME

ARG GITHUB_TOKEN
RUN bench init --frappe-branch main \
 --frappe-path https://${GITHUB_TOKEN}@github.com/modehero/frappe modehero

WORKDIR $HOME/modehero
COPY . .

RUN sudo chown -R frappe:frappe ./run.sh ./mysql ./site-backup
RUN chmod +x ./run.sh
RUN sudo apt install -y tmux rsync

# ENTRYPOINT [ "/bin/sh","-c","./run.sh" ]