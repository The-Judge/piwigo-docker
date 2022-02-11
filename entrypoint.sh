#!/bin/bash

# Extract application if not yet existing
PIWIGO_DEST=${PIWIGO_DEST:-/var/www/html}
if [ ! -f "${PIWIGO_DEST}/README.md" ]; then
    echo "Piwigo not found; extracting /usr/src/piwigo.tar.gz to ${PIWIGO_DEST} ..." >/dev/stdout 2>/dev/stderr
    install -d -D "${PIWIGO_DEST}"
    tar xfz /usr/src/piwigo.tar.gz --strip-components=1 -C "${PIWIGO_DEST}" >/dev/stdout 2>/dev/stderr
fi

# Copy database config
if [ ! -f "${PIWIGO_DEST}/local/config/database.inc.php" ]; then
    echo "Piwigo database config not found; copying default to ${PIWIGO_DEST}/local/config/database.inc.php ..." >/dev/stdout 2>/dev/stderr
    [[ ! -d "${PIWIGO_DEST}/local/config" ]] && mkdir -p "${PIWIGO_DEST}/local/config"
    cat /usr/src/piwigo_database.inc.php | \
      sed "s/__PIWIGO_DB_NAME__/${PIWIGO_DB_NAME}/g" | \
      sed "s/__PIWIGO_DB_USER__/${PIWIGO_DB_USER}/g" | \
      sed "s/__PIWIGO_DB_PASSWORD__/${PIWIGO_DB_PASSWORD}/g" | \
      sed "s/__PIWIGO_DB_HOST__/${PIWIGO_DB_HOST}/g" > "${PIWIGO_DEST}/local/config/database.inc.php"      
fi

# Load initial database if 'piwigo_users' table not found in database
if [ $(mysql -s -u"${PIWIGO_DB_USER}" -p"${PIWIGO_DB_PASSWORD}" -h"${PIWIGO_DB_HOST}" "${PIWIGO_DB_NAME}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$PIWIGO_DB_NAME' AND table_name = 'piwigo_users';" | tail -n 1) -eq 0 ]; then
    echo "Piwigo database not found; copying default from /usr/src/init_db.gz ..." >/dev/stdout 2>/dev/stderr
    md5pass="$(echo -n ${PIWIGO_ADMIN_PASSWORD} | md5sum | awk '{print $1}')"
    zcat /usr/src/init_db.gz | sed "s/__MD5_PASS_HASH__/${md5pass}/g" | sed "s/__MAIL__/${PIWIGO_ADMIN_EMAIL:-mail@example.com}/g" | \
      mysql -u"${PIWIGO_DB_USER}" -p"${PIWIGO_DB_PASSWORD}" -h"${PIWIGO_DB_HOST}" "${PIWIGO_DB_NAME}"
fi

chown -R www-data:www-data "${PIWIGO_DEST}"

# If this environment is the apache variant
if [ -v APACHE_CONFDIR ]; then
    # first arg is `-f` or `--some-option`
    if [ "${1#-}" != "$1" ]; then
        set -- apache2-foreground "$@"
    fi
# If this environment is the fpm variant
elif [ -x /usr/local/sbin/php-fpm ]; then
    # first arg is `-f` or `--some-option`
    if [ "${1#-}" != "$1" ]; then
        set -- php-fpm "$@"
    fi
fi

exec "$@"
