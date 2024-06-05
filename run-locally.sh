export $(egrep -v '^(#|UID=|GID=)' .env | xargs)
export SNYK_TOKEN="9c3ba435-89ac-47f8-a9fb-d48c86b01d50"
bench start &
export start=$!;
sleep 10;
# bench get-app erpnext https://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@github.com/kalpit-tech/erpnext --branch main

bench new-site --db-name modehero --db-host db \
    --mariadb-root-password $MYSQL_ROOT_PASSWORD \
    --mariadb-root-username root \
    --admin-password admin \
    --install-app erpnext \
    --source_sql /home/modehero/modehero/mysql/backups/modehero.sql \
    --force modehero.com

sudo kill -9 $start;
bench use modehero.com;
bench start &
export start=$!
# snyk auth 9c3ba435-89ac-47f8-a9fb-d48c86b01d50
# bench get-app erpnext https://$GITHUB_TOKEN@github.com/modehero/erpnext --branch main
bench get-app erpnext https://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@github.com/kalpit-tech/erpnext --branch main
bench --site modehero.com install-app erpnext
tail -f /dev/null