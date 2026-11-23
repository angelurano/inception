#!/bin/sh

set -o errexit

if [ ! -f /run/secrets/db_password ] || [ ! -f /run/secrets/db_root_password ]; then
  echo "Docker secrets not found in /run/secrets/" >&2
  exit 1
fi

DB_PASSWORD=$(tr -d '\r\n' < /run/secrets/db_password)
DB_ROOT_PASSWORD=$(tr -d '\r\n' < /run/secrets/db_root_password)

chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null 2>&1

  mariadbd --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

  echo "MariaDB data directory initialized."
fi

exec "$@"

