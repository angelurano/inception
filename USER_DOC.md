# User Documentation

This guide explains how to operate, access, and verify the **Inception** web stack as an end user or site administrator.

## 1. Services Provided

The stack runs three containerized services working together behind a single encrypted entry point:

- **NGINX (`nginx`)**: HTTPS reverse proxy and web server listening only on port `443` (`TLSv1.2` / `TLSv1.3`). It handles encrypted connections, serves static WordPress assets, and forwards PHP requests to WordPress.
- **WordPress + PHP-FPM (`wordpress`)**: Content Management System (CMS) powered by PHP 8.3 (`php-fpm83`). It renders the website and admin panel and stores uploaded media, themes, and plugins.
- **MariaDB (`mariadb`)**: Relational database engine storing WordPress posts, pages, settings, and user accounts.

## 2. Starting and Stopping the Project

Run these commands from the root directory of the repository:

- **Start the stack** (builds images if needed and starts all services in the background):
  ```bash
  make
  ```
  *(Equivalent to `make up`).*

- **Stop the stack** (stops and removes containers and the internal network while keeping your website and database data intact):
  ```bash
  make down
  ```

## 3. Accessing the Website and Administration Panel

1. Ensure the domain resolves locally by verifying `/etc/hosts` contains:
   ```text
   127.0.0.1   migugar2.42.fr
   ```
2. Open a browser and navigate to:
   - **Public Website:** `https://migugar2.42.fr`
   - **Administration Dashboard:** `https://migugar2.42.fr/wp-admin`
3. Because the server uses a self-signed TLS certificate, your browser will display a security warning on the first visit. Accept/proceed past the warning to load the encrypted site.
4. Two WordPress accounts are provisioned automatically on first startup:
   - **Administrator account** (defined by `WP_ADMIN_USER` in `srcs/.env`): full access to themes, plugins, users, and site settings.
   - **Author account** (defined by `WP_USER` in `srcs/.env`): standard content-creation access without administrative privileges.

## 4. Locating and Managing Credentials

Passwords are never stored in Git or image definitions. Credentials are split between:

- **Non-sensitive configuration (`srcs/.env`)**: Stores the domain name (`DOMAIN_NAME`), database name/user (`MYSQL_DATABASE`, `MYSQL_USER`), site title (`WP_TITLE`), and WordPress usernames/emails (`WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`).
- **Passwords (`secrets/*.txt`)**: Stored locally as plain text files (one password per file) and mounted read-only inside containers via Docker Secrets:
  - `secrets/db_password.txt` — MariaDB WordPress user password
  - `secrets/db_root_password.txt` — MariaDB root password
  - `secrets/wp_admin_password.txt` — WordPress administrator password
  - `secrets/wp_user_password.txt` — WordPress author user password

> **Note:** On first initialization, MariaDB and WordPress read these files to create the initial database and user accounts. If you later change a WordPress user's password, update it directly from the WordPress dashboard (`Users` section) or via WP-CLI.

## 5. Checking Service Health

- **Check running containers and status:**
  ```bash
  docker compose -p inception -f srcs/docker-compose.yml ps
  ```
  All three containers (`nginx`, `wordpress`, `mariadb`) should show `Up`.

- **Inspect service logs:**
  ```bash
  docker compose -p inception -f srcs/docker-compose.yml logs
  ```
  Or for a single service (for example, `wordpress`):
  ```bash
  docker logs wordpress
  ```

- **Verify HTTPS response from the terminal:**
  ```bash
  curl -skI https://migugar2.42.fr --resolve migugar2.42.fr:443:127.0.0.1
  ```
  You should receive `HTTP/1.1 200 OK`.
