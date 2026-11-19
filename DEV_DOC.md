# Developer Documentation

This document describes how to set up, build, manage, debug, and understand data persistence for the **Inception** infrastructure from a developer perspective.

## 1. Environment Setup from Scratch

### Prerequisites

- Linux host or VM (with `x86_64` or `arm64` support) running:
  - **Docker Engine** / **Docker Desktop**
  - **Docker Compose** (v2 plugin)
  - **GNU Make**
- Optional local tooling: `devenv` (`devenv.nix` provides `hadolint` and exports `DATA_PATH` to `.data/` inside the workspace for local development).

### Configuration Steps

1. **Local DNS resolution (`/etc/hosts`):**
   Add the following entry on the host machine:
   ```text
   127.0.0.1   migugar2.42.fr
   ```

2. **Environment variables (`srcs/.env`):**
   Create `srcs/.env` from `srcs/.env.example`:
   ```bash
   cp srcs/.env.example srcs/.env
   ```
   Configure the variables:
   - `DOMAIN_NAME`: Domain served by NGINX and WordPress (e.g., `migugar2.42.fr`).
   - `MYSQL_DATABASE`, `MYSQL_USER`: Database name and application user for WordPress.
   - `DATA_PATH`: Base host directory for persistent volume data (defaults to `/home/migugar2/data` if unset in the environment/Makefile).
   - `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`: WordPress site title and initial users (`WP_ADMIN_USER` must not contain `admin` or `Admin`).

3. **Docker Secrets (`secrets/`):**
   Create the four password files in `secrets/` (ignored by `.gitignore`):
   - `secrets/db_password.txt`
   - `secrets/db_root_password.txt`
   - `secrets/wp_admin_password.txt`
   - `secrets/wp_user_password.txt`

   > Entrypoints strip trailing `\r\n` characters (`tr -d '\r\n'`) when reading secrets from `/run/secrets/<name>`.

## 2. Repository Architecture

```text
.
├── Makefile
├── devenv.nix
├── secrets/                          # Local secret files (git-ignored)
└── srcs/
    ├── .env.example                  # Environment variable template
    ├── docker-compose.yml            # Service, secret, volume, and network definitions
    └── requirements/
        ├── mariadb/                  # Alpine 3.23.6 + MariaDB + bootstrap entrypoint
        ├── wordpress/                # Alpine 3.23.6 + PHP 8.3 FPM + WP-CLI entrypoint
        └── nginx/                    # Alpine 3.23.6 + NGINX + self-signed OpenSSL cert
```

- **Network**: All services share the isolated bridge network `inception` (named `inception_inception` by Compose). Internal service discovery uses service names (`mariadb:3306`, `wordpress:9000`). Only `nginx` publishes port `443:443` to the host.
- **Process Model**: Every container runs its primary daemon directly in the foreground as PID 1 (`mariadbd --user=mysql --console`, `php-fpm83 -F`, `nginx -g "daemon off;"`).

## 3. Building and Launching

### Using the `Makefile`

The `Makefile` uses project name `inception` and compose file `srcs/docker-compose.yml`, and exports `DATA_PATH` (`?=/home/migugar2/data`) so host directory creation and Compose always target the same path:

- `make` / `make up`: Creates `$(DATA_PATH)/mariadb` and `$(DATA_PATH)/wordpress`, builds all local images, and starts containers (`up -d`).
- `make build`: Creates host directories and builds images without starting containers.
- `make down`: Stops and removes containers and the bridge network (data in `$(DATA_PATH)` and volume definitions remain intact).
- `make DATA_PATH=/custom/path`: Overrides the host data directory.

> On memory-constrained environments where parallel Docker Bake builds drop the daemon connection, build sequentially with:
> ```bash
> COMPOSE_PARALLEL_LIMIT=1 make
> ```

### Direct Docker Compose Commands

Equivalent commands (ensure `$(DATA_PATH)/mariadb` and `$(DATA_PATH)/wordpress` exist first):

```bash
docker compose -p inception -f srcs/docker-compose.yml build
docker compose -p inception -f srcs/docker-compose.yml up -d
docker compose -p inception -f srcs/docker-compose.yml down
```

## 4. Managing and Debugging Containers and Images

- **List containers, images, networks, and volumes:**
  ```bash
  docker compose -p inception -f srcs/docker-compose.yml ps
  docker images
  docker network inspect inception_inception
  docker volume inspect inception_db_data inception_wp_data
  ```

- **Rebuild a single service cleanly:**
  ```bash
  docker compose -p inception -f srcs/docker-compose.yml build --no-cache <service>
  docker compose -p inception -f srcs/docker-compose.yml up -d <service>
  ```

- **Stream logs and inspect PID 1 processes:**
  ```bash
  docker compose -p inception -f srcs/docker-compose.yml logs -f
  docker top mariadb
  docker top wordpress
  docker top nginx
  ```

- **Open an interactive shell inside a running container:**
  ```bash
  docker exec -it mariadb sh
  docker exec -it wordpress sh
  docker exec -it nginx sh
  ```

- **Verify TLS protocol enforcement and FastCGI routing:**
  ```bash
  curl -skI --tlsv1.2 --tls-max 1.2 https://migugar2.42.fr --resolve migugar2.42.fr:443:127.0.0.1
  curl -skI --tlsv1.3 https://migugar2.42.fr --resolve migugar2.42.fr:443:127.0.0.1
  curl -skI --tlsv1.1 --tls-max 1.1 https://migugar2.42.fr --resolve migugar2.42.fr:443:127.0.0.1  # Expected to fail (exit code 35)
  ```

- **Lint Dockerfiles:**
  ```bash
  hadolint srcs/requirements/mariadb/Dockerfile srcs/requirements/wordpress/Dockerfile srcs/requirements/nginx/Dockerfile
  ```

## 5. Data Persistence

Persistent state is stored outside the containers using two named Docker volumes backed by host directories via `driver: local` with `type: none` and `o: bind`:

| Volume (`docker-compose.yml`) | Docker Volume Name | Container Mount Point | Host Path (`$(DATA_PATH)`) |
| :--- | :--- | :--- | :--- |
| `db_data` | `inception_db_data` | `/var/lib/mysql` (rw) | `${DATA_PATH:-/home/migugar2/data}/mariadb` |
| `wp_data` | `inception_wp_data` | `/var/www/wordpress` (rw in `wordpress`, `:ro` in `nginx`) | `${DATA_PATH:-/home/migugar2/data}/wordpress` |

### Lifecycle Behavior

- **Idempotent initialization**:
  - `mariadb` initializes system tables and users only if `/var/lib/mysql/mysql` does not exist yet.
  - `wordpress` downloads core files only if `wp-load.php` is absent, creates `wp-config.php` only if absent, and runs `wp core install` / `wp user create` only if `! wp core is-installed`.
- **Surviving restarts/recreates**: Stopping or destroying containers (`make down`, `docker compose down -v`, or image rebuilds) preserves all database tables, posts, themes, and uploads on the host under `$(DATA_PATH)`.
- **Full data reset**: To force a clean re-initialization from scratch, stop the stack (`docker compose -p inception -f srcs/docker-compose.yml down -v`) and remove the contents of `$(DATA_PATH)/mariadb` and `$(DATA_PATH)/wordpress` on the host.
- **WSL2 / Docker Desktop note**: After a host/WSL2 reboot, stale Docker Desktop bind-mount references may trigger `failed to mount local volume ... no such file or directory`. Running `docker compose -p inception -f srcs/docker-compose.yml down -v` clears only the stale Docker volume metadata without deleting files in `$(DATA_PATH)`, allowing `make` to recreate the mount cleanly.

