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
ssl: SHELL := docker-compose exec modehero $(SHELL)
ssl:
	bench use modehero.com
	bench setup add-domain $(DOMAIN)
	bench config dns_multitenant on
	sudo PATH=$$PATH HOME=$$HOME -E -H $$(which bench) setup lets-encrypt modehero.com --custom-domain $(DOMAIN)

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

apps/erpnext:
	bench use modehero.com
	bench get-app erpnext https://$$GITHUB_TOKEN@github.com/modehero/erpnext --branch main
	bench --site modehero.com install-app erpnext
	# rsync -avzh styles sites/assets/css
