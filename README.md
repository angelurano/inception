*This project has been created as part of the 42 curriculum by migugar2.*

# Description

**Inception** is a system administration project focused on containerization and service orchestration with **Docker** and **Docker Compose**. The goal is to design and deploy a multi-container web infrastructure built entirely from custom `Dockerfile`s (without pulling pre-built application images from Docker Hub).

The stack consists of three isolated services running on `alpine:3.23.6` and communicating over a dedicated internal bridge network (`inception`):

- **NGINX**: The sole entry point to the infrastructure, listening exclusively on port `443` with a self-signed X.509 certificate and enforcing `TLSv1.2` / `TLSv1.3`. It serves static assets directly from the shared WordPress volume and proxies PHP requests to WordPress over FastCGI (`wordpress:9000`).
- **WordPress + PHP-FPM**: Runs `php-fpm83` in the foreground (`-F`) without an embedded web server. On startup, its entrypoint waits for MariaDB, downloads WordPress via WP-CLI if missing, generates `wp-config.php`, installs the site with HTTPS URLs, and creates the required administrator (without `admin` in the username) and regular author user.
- **MariaDB**: Runs `mariadbd` in the foreground (`--console`), configured to accept connections over the internal Docker network (`bind-address = 0.0.0.0`, `skip-name-resolve`) and bootstrapped idempotently on first launch with the WordPress database and user.

All service daemons run directly as **PID 1** in the foreground (no background sleep/tail loops), and sensitive credentials are injected via **Docker Secrets** rather than stored in Git or image layers.

### Virtual Machines vs Docker

- **Virtual Machines (VMs)** run on top of a hypervisor that virtualizes complete hardware (CPU, RAM, disk, NICs) and boots an entire independent guest operating system with its own kernel. This provides strong hardware-level isolation, at the cost of higher memory overhead, larger disk footprints, and slower startup times.
- **Docker Containers** share the host operating system's Linux kernel and isolate processes in user space using kernel **Namespaces** (PID, network, mount, UTS, IPC) and **cgroups** (CPU/memory limits). Containers start in milliseconds, use minimal overhead, and guarantee identical runtime environments across hosts.

### Secrets vs Environment Variables

- **Environment Variables** (`srcs/.env`) are convenient for non-sensitive configuration such as domain names, database names, non-privileged usernames, or host paths (`DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, `WP_TITLE`, `DATA_PATH`). However, they are visible via `docker inspect`, process listings, and inherited child processes.
- **Docker Secrets** (`secrets/*.txt` mounted at `/run/secrets/<name>`) are designed specifically for sensitive credentials (`db_password`, `db_root_password`, `wp_admin_password`, `wp_user_password`). They are mounted in memory as read-only files inside only the containers that explicitly declare them, keeping passwords out of `Dockerfile`s, image history, and environment dumps.

### Docker Network vs Host Network

- **Host Network (`network_mode: host`)** removes network isolation between the container and the host machine, binding container ports directly to the host's network interfaces. This breaks isolation and can cause port conflicts (and is forbidden in Inception).
- **Docker Bridge Network (`inception`, `driver: bridge`)** creates a private virtual network for the stack. Containers resolve one another by service name using Docker's embedded DNS (for example, `mariadb:3306` and `wordpress:9000`), while remaining unreachable from the outside world except for ports explicitly published on the entry-point service (`443:443` on `nginx`).

### Docker Volumes vs Bind Mounts

- **Bind Mounts** map an arbitrary host path directly into a container. They depend heavily on the host directory structure and permissions, and are not managed as first-class objects by Docker's volume lifecycle commands.
- **Docker Named Volumes** are managed directly by Docker (`docker volume ls`, `docker volume inspect`), stored under Docker's storage area (`/var/lib/docker/volumes/`), and decoupled from host-specific paths.
- **Approach used in this project**: `db_data` and `wp_data` are defined as **named volumes** using the `local` driver with `type: none` and `o: bind` pointing to `${DATA_PATH}/mariadb` and `${DATA_PATH}/wordpress` (defaulting to `/home/migugar2/data`). This combines Docker's named-volume management with deterministic persistence at the host path required by the subject, ensuring database and website files survive container destruction and rebuilds.

# Instructions

### Prerequisites

Ensure the following are installed on the host machine:
- **Docker Engine** and **Docker Compose** (v2)
- **GNU Make**

### Installation & Configuration

1. **Clone the repository and enter it:**
   ```bash
   git clone <repository-url> && cd inception
   ```

2. **Create the environment file:**
   ```bash
   cp srcs/.env.example srcs/.env
   ```
   Update the values in `srcs/.env` for your deployment (domain, database name/user, WordPress title/accounts, and `DATA_PATH`).

3. **Create the Docker secret files** (containing the passwords for MariaDB and WordPress):
   ```text
   secrets/db_password.txt
   secrets/db_root_password.txt
   secrets/wp_admin_password.txt
   secrets/wp_user_password.txt
   ```

4. **Add local host resolution** in `/etc/hosts` so the configured domain resolves locally:
   ```text
   127.0.0.1   migugar2.42.fr
   ```

### Compilation & Execution

Run all commands from the root of the repository:

- **Build and start the stack** (creates host data directories, builds all images, and starts containers in detached mode):
  ```bash
  make
  ```
- **Build images only** (without starting containers):
  ```bash
  make build
  ```
- **Start the stack** (rebuilds if needed and starts containers):
  ```bash
  make up
  ```
- **Stop and remove containers and network** (persistent data in `$(DATA_PATH)` is preserved):
  ```bash
  make down
  ```
- **Override the host data directory** (defaults to `/home/migugar2/data`):
  ```bash
  make DATA_PATH=/custom/path
  ```

### Access

Once the containers are running, open the site in a browser:
- **WordPress site:** `https://migugar2.42.fr` *(accept the self-signed TLS certificate warning)*
- **Admin dashboard:** `https://migugar2.42.fr/wp-admin`

# Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Docker Secrets Documentation](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker Hub](https://hub.docker.com/)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/packages)
- [NGINX Documentation (SSL / FastCGI)](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/documentation/)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)

### AI Usage

AI assistance was used during development as a technical reviewer and study mentor—specifically to review `Dockerfile` layer ordering and `nginx.conf` / FastCGI directives, diagnose WSL2 + Docker Desktop bind-mount and PHP `memory_limit` issues, and help structure and refine this documentation. All configurations, builds, and runtime behaviors were tested and verified directly in the project environment.

