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

.PHONY: logs
logs:
	docker-compose logs -f

.PHONY: inspect
inspect:
	docker-compose exec modehero bash

.PHONY: backup
backup: SHELL := docker-compose exec modehero $(SHELL)
backup:

.PHONY: ssl
ssl:
	docker-compose exec modehero make _ssl

.PHONY: _ssl
_ssl:
	bench use modehero.com
	bench setup add-domain $(DOMAIN)
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

.PHONY: stop
stop:
	docker-compose stop

.PHONY: start
start:
	docker-compose start

.PHONY: run
run: up logs

.PHONY: _run
_run: sites/modehero.com apps/erpnext
	bench use modehero.com
	rsync -avzh  site-backup/ sites
	bench start

sites/modehero.com:
	bench start& echo $$! > start.PID
	sleep 10
	bench new-site --db-name modehero --db-host db \
	    --mariadb-root-password $$MYSQL_ROOT_PASSWORD \
	    --mariadb-root-username root \
	    --admin-password admin \
	    --source_sql /home/modehero/modehero/mysql/backups/modehero.sql \
	    --force modehero.com
	sudo kill -9 $$(cat start.PID)
	sudo pkill -9 redis* || true
	sudo pkill -9 python* || true
	# sed -i '$s/}/,\n"site_name":"Modehero",\n"encryption_key":"HvcQtwG3_Wh75QY9bxKiQ3ioEjRhipKckjUGKhw11cc="\n}' /home/modehero/modehero/sites/modehero.com/site_config.json

apps/erpnext:
	bench use modehero.com
	bench get-app erpnext https://github.com/modehero/erpnext --branch main
	bench --site modehero.com install-app erpnext
	# rsync -avzh styles sites/assets/css

.PHONY: backup
backup:
	docker-compose exec modehero make _backup

.PHONY: _backup
_backup:
	mysqldump -h db -u root -p$$MYSQL_ROOT_PASSWORD modehero > mysql/backups/modehero.sql

.PHONY: prod
prod:
	make up
	sleep 20
	make ssl nginx logs

