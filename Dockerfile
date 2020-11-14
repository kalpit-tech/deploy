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
COPY mysql $HOME/modehero/mysql

RUN sudo chown -R frappe:frappe ./run.sh ./mysql
RUN chmod +x ./run.sh
RUN sudo apt install -y tmux

RUN bench start&
RUN bench new-site --db-name modehero --db-host db \
    --mariadb-root-password $MYSQL_ROOT_PASSWORD \
    --mariadb-root-username root \
    --admin-password admin \
    --source_sql /home/frappe/modehero/mysql/backups/modehero.sql \
    --force modehero.com

RUN bench use modehero.com
RUN bench start &
RUN bench get-app erpnext https://$GITHUB_TOKEN@github.com/modehero/modehero --branch main
RUN bench --site modehero.com install-app erpnext


ENTRYPOINT [ "/bin/sh","-c","bench start" ]