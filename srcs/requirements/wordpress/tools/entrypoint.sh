#!/bin/sh
set -e

DB_PASSWORD=$(tr -d '\r\n' < /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(tr -d '\r\n' < /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(tr -d '\r\n' < /run/secrets/wp_user_password)

echo "Waiting for database connection..."
while ! mariadb-admin ping -h mariadb -u "${MYSQL_USER}" --password="${DB_PASSWORD}" > /dev/null 2>&1; do
  sleep 2
done
echo "Database connection established."

cd /var/www/wordpress

if [ ! -f /var/www/wordpress/wp-load.php ]; then
  echo "WordPress not found in /var/www/wordpress - downloading..."
  wp core download --allow-root
fi

if [ ! -f /var/www/wordpress/wp-config.php ]; then
  echo "Configuring WordPress..."
  wp config create \
    --allow-root \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="mariadb:3306"
fi

if ! wp core is-installed --allow-root; then
  echo "Installing WordPress..."
  wp core install \
    --allow-root \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"

  wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
    --allow-root \
    --role=author \
    --user_pass="${WP_USER_PASSWORD}"
fi

chown -R nobody:nobody /var/www/wordpress

exec "$@"

