# include .env
$(shell cat .env | sed 's,\$$[^{],$$$$,g' | sed 's,\(#\),\\\1,g' | sed 's,^,export ,' | sed 's,=, ?= ,' | sed 's,SHELL ?=,SHELL :=,' > .env.mk)
include .env.mk

.PHONY: build
build:
	docker-compose build

.PHONY: up
up: build
	docker-compose up -d

.PHONY: down
down:
	docker-compose down
	docker volume prune -f

.PHONY: logs
logs:
	docker-compose logs -f

.PHONY: inspect
inspect:
	docker-compose exec modehero bash

.PHONY: ssl
ssl:
	docker-compose exec modehero make _ssl

.PHONY: _ssl
_ssl:
	bench use modehero.com
	bench setup add-domain --site modehero.com $(DOMAIN)
	bench config dns_multitenant on
	sudo PATH=$$PATH HOME=$$HOME -E -H $$(which bench) setup lets-encrypt modehero.com --custom-domain $(DOMAIN)

.PHONY: nginx
nginx:
	docker-compose exec modehero make _nginx

.PHONY: _nginx
_nginx:
	sudo service nginx stop
	sed -i.bak 's,timeout 120,timeout 300s,' $(CURDIR)/config/nginx.conf
	sudo ln -sf $(CURDIR)/config/nginx.conf /etc/nginx/conf.d/frappe-bench.conf
	sudo rm -f /etc/nginx/sites-enabled/default
	sudo service nginx start

.PHONY: start
start: up wait

.PHONY: _start
_start:
	bench start

.PHONY: wait
wait:
	sleep 20

.PHONY: run
run: start install migrate logs

.PHONY: install
install:
	docker-compose exec modehero make _install
	docker-compose stop modehero
	make up

.PHONY: _install
_install: sites/modehero.com apps/erpnext
	bench use modehero.com
	rsync -avzh  site-backup/ sites

sites/modehero.com:
	bench new-site --db-name modehero --db-host db \
	    --mariadb-root-password $$MYSQL_ROOT_PASSWORD \
	    --mariadb-root-username root \
	    --admin-password admin \
	    --source_sql /home/modehero/modehero/mysql/backups/modehero.sql \
	    --force modehero.com
	jq '.encryption_key = "HvcQtwG3_Wh75QY9bxKiQ3ioEjRhipKckjUGKhw11cc="' sites/modehero.com/site_config.json \
		| sponge sites/modehero.com/site_config.json
	jq '.site_name = "Modehero"' sites/modehero.com/site_config.json \
		| sponge sites/modehero.com/site_config.json
	jq 'del(.webserver_port)' sites/common_site_config.json | sponge sites/common_site_config.json

apps/erpnext:
	bench use modehero.com
	bench get-app erpnext $(ERPNEXT_PATH) --branch $(ERPNEXT_BRANCH)
	bench --site modehero.com install-app erpnext
	# rsync -avzh styles sites/assets/css

.PHONY: migrate
migrate:
	docker-compose exec modehero make _migrate

.PHONY: _migrate
_migrate:
	bench migrate

.PHONY: backup
backup:
	docker-compose exec modehero make _backup

.PHONY: _backup
_backup:
	mysqldump -h db -u root -p$$MYSQL_ROOT_PASSWORD modehero > mysql/backups/modehero.sql

.PHONY: prod
prod: start install migrate logs
	# FIXME: certbot-auto is deprecated for ubuntu, use debian in Dockerfile
	# make ssl nginx logs

