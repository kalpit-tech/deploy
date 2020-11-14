bench start&
export start=$!
sleep 10
bench new-site --db-name modehero --db-host db \
    --mariadb-root-password 123 \
    --mariadb-root-username root \
    --admin-password admin \
    --install-app erpnext \
    --source_sql /home/frappe/modehero/mysql/backups/modehero.sql \
    --force modehero.com

sudo kill -9 $start
bench use modehero.com
bench start &
export start=$!
bench get-app erpnext https://0015f9ea85506bbcf614bdc25e41da24fafa2d2f@github.com/modehero/modehero --branch main
bench --site modehero.com install-app erpnext