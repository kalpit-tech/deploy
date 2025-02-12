if [ ! -d sites/modehero.com ]; then
    log "In if"
    # export $(egrep -v '^#' .env | xargs)
    bench start &
    export start=$!
    sleep 10
    bench new-site --db-name modehero --db-host db \
        --mariadb-root-password $MYSQL_ROOT_PASSWORD \
        --mariadb-root-username root \
        --admin-password admin \
        --source_sql /home/modehero/modehero/mysql/backups/modehero.sql \
        --force modehero.com

    sudo kill -9 $start
    sudo pkill -9 redis*
    sudo pkill -9 python*
    bench use modehero.com
    bench start &
    export start=$!
    bench get-app erpnext https://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@github.com/kalpit-tech/erpnext --branch main
    bench --site modehero.com install-app erpnext
    # rsync -avzh styles sites/assets/css
    rsync -avzh  site-backup/ sites
    sudo pkill -9 redis*
    sudo pkill -9 python*
    bench start
else
    export $(egrep -v '^(#|UID=|GID=)' .env | xargs)
    # bench start
    bench start &
    export start=$!
    sleep 10
    bench new-site --db-name modehero --db-host db \
        --mariadb-root-password $MYSQL_ROOT_PASSWORD \
        --mariadb-root-username root \
        --admin-password admin \
        --source_sql /home/modehero/modehero/mysql/backups/modehero.sql \
        --force modehero.com

    sudo kill -9 $start
    sudo pkill -9 redis*
    sudo pkill -9 python*
    bench use modehero.com
    bench start &
    export start=$!
    # bench get-app erpnext https://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@github.com/kalpit-tech/erpnext --branch main
    bench get-app erpnext https://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@github.com/ajaytc/modehero_erpnext --branch main
    bench --site modehero.com install-app erpnext
    # rsync -avzh styles sites/assets/css
    rsync -avzh  site-backup/ sites
    sudo pkill -9 redis*
    sudo pkill -9 python*
    bench start
fi