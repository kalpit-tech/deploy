# include .env
$(shell cat .env | sed 's,\$$[^{],$$$$,g' | sed 's,\(#\),\\\1,g' | sed 's,^,export ,' | sed 's,=, ?= ,' | sed 's,SHELL ?=,SHELL :=,' > .env.mk)
include .env.mk

.PHONY: %.force
%.force: force := true
%.force: %
	@true

.PHONY: build
build:
	docker-compose build $(if $(force),--force)

.PHONY: up
up: build
	docker-compose up -d modehero

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

.PHONY: _ssl
_ssl:
	bench use $(DOMAIN)
	bench setup nginx --yes
	sudo ln -s $(CURDIR)/config/nginx.conf /etc/nginx/conf.d/$(DOMAIN).conf
	sudo nginx -t
	sudo service nginx restart
	sudo certbot --nginx -d $(DOMAIN)
	sudo ./certificate-auto-cron.sh install
	#bench config dns_multitenant on
	# sudo PATH=$$PATH HOME=$$HOME -E -H $$(which bench) setup lets-encrypt $(DOMAIN) --custom-domain $(DOMAIN)
	#mkdir -p nginx/conf.d
	#cat nginx-format-ssl.conf > nginx/conf.d/$(DOMAIN).conf
	#sed -i 's/example.com/$(DOMAIN)/g' nginx/conf.d/$(DOMAIN).conf
	#./init-letsencrypt.sh $(DOMAIN)

.PHONY: ssl
ssl:
	docker-compose exec modehero sudo service nginx start
	docker-compose exec modehero make _ssl

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
_install: sites/$(DOMAIN) apps/erpnext
	bench use $(DOMAIN)
	rsync -avzh  site-backup/assets sites/.
	rsync -avzh  site-backup/modehero.com/public/files sites/$(DOMAIN)/public/.

sites/$(DOMAIN):
	bench new-site --db-name modehero --db-host db \
	  --mariadb-root-password $$MYSQL_ROOT_PASSWORD \
	  --mariadb-root-username root \
	  --admin-password admin \
	  --source_sql /home/modehero/modehero/mysql/backups/modehero.sql \
	  --force $(DOMAIN)
	bench enable-scheduler
	jq '.encryption_key = "HvcQtwG3_Wh75QY9bxKiQ3ioEjRhipKckjUGKhw11cc="' sites/$(DOMAIN)/site_config.json \
	      | sponge sites/$(DOMAIN)/site_config.json
	jq '.site_name = "Modehero"' sites/$(DOMAIN)/site_config.json \
	      | sponge sites/$(DOMAIN)/site_config.json
	jq 'del(.webserver_port)' sites/common_site_config.json | sponge sites/common_site_config.json

apps/erpnext:
	bench use $(DOMAIN)
	bench get-app erpnext $(ERPNEXT_PATH) --branch $(ERPNEXT_BRANCH)
	bench --site $(DOMAIN) install-app erpnext
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
