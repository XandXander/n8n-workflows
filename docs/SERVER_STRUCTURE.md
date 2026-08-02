# SERVER_STRUCTURE.md - Server Infrastructure Documentation

**Project:** XandAI / n8n Automation Platform  
**Last updated:** 2026-07-24 (Синхронизировано)

---

## 1. Server & Hardware Specs
* **Hostname:** `pbbnobdtrg`
* **OS:** `Ubuntu 24.04.4 LTS` (Kernel: `Linux 6.8.0-124-generic`, `x86_64`)
* **Virtualization:** `KVM` (Timezone: `Europe/Moscow`)
* **CPU:** `2 vCPU`
* **RAM:** `3.8 GB` (Swap: `4 GB`)
* **Disk:** `38 GB SSD` (Used: `14 GB`, Free: `25 GB`)

---

## 2. Main Project Directory
* **Root Path:** `/opt/beget/n8n`
* **Root Files:** `docker-compose.yml`, `.env`, `init-data.sh`, `healthcheck.js`, `n8n-osint-key.json`
* **Subdirectories:** `backups/`, `db_storage/`, `redis_storage/`, `n8n_storage/`, `traefik_data/`

---

## 3. Docker Environment
* **Service:** Docker Engine enabled as a system service (`systemctl status docker`).
* **Autostart:** Enabled automatically after server reboot.
* **Compose Project Name:** `n8n`
* **Compose File Path:** `/opt/beget/n8n/docker-compose.yml`
* **Network:** `n8n_default` (Driver: `bridge`, Subnet: `172.18.0.0/16`, Gateway: `172.18.0.1`)
* **Volumes:** Persistent storage uses local-persist (`n8n_db_storage`, `n8n_n8n_storage`, `n8n_redis_storage`, `n8n_traefik_data`).

---

## 4. Running Containers Matrix

| Container | Image | Internal IP | Host Port | Purpose |
|---|---|---|---|---|
| **n8n** | `docker.n8n.io/n8nio/n8n:latest` (2.30.7+) | `172.18.0.5` | `127.0.0.1:5678` | Main workflow engine (Traefik only) |
| **n8n Worker** | `docker.n8n.io/n8nio/n8n:latest` (2.30.7+) | `172.18.0.6` | None | Background execution (`command: worker`) |
| **PostgreSQL** | `pgvector/pgvector:pg16` | `172.18.0.3` | `127.0.0.1:5432` | DB (Extensions: `pgcrypto`, `uuid-ossp`) |
| **Redis** | `redis:6-alpine` | `172.18.0.2` | None | Queue backend (Internal only) |
| **Traefik** | `traefik:3.6.5` | `172.18.0.4` | `80`, `443` | Reverse proxy & Let's Encrypt TLS |
| **Gotenberg** | `gotenberg/gotenberg:8` | `172.18.0.7` | `3000` | HTML → PDF conversion |

---

## 5. Data Storage Mapping
* **n8n Data:** `/opt/beget/n8n/n8n_storage` (configs, executions, binary files, community nodes, logs).
* **Workflows:** `/opt/beget/n8n/n8n_storage/storage/workflows`
* **PostgreSQL:** `/opt/beget/n8n/db_storage` (persistent database).
* **Redis:** `/opt/beget/n8n/redis_storage` (redis persistence).
* **Traefik:** `/opt/beget/n8n/traefik_data` (SSL Let's Encrypt certificates).

---

## 6. Networking & Reverse Proxy
* **Public Domain:** `https://xandai.ru`
* **SSL:** Let's Encrypt TLS certificates.
* **Routing:** HTTP is automatically redirected to HTTPS.
* **n8n Health Check:** Custom `healthcheck.js` requests `http://127.0.0.1:5678/` with Host header `xandai.ru`. HTTP 200 = healthy.
* **PostgreSQL Init:** Script `init-data.sh` creates extensions, database user, and grants permissions.

---

## 7. Community Nodes Installed
* `@tavily/n8n-nodes-tavily`
* `n8n-nodes-yandexgpt`
* `n8n-nodes-yandex-disk`
* `n8n-nodes-yandex-dialogs`
* `n8n-nodes-wkhtmltopdf`

---

## 8. n8n Runtime Engine Configuration
* **Binary Data Mode:** `filesystem`
* **Execution Mode:** `regular`
* **Maximum Concurrent Executions:** `5`
* **Maximum Payload:** `32 MB`
* **Successful Executions:** `disabled` (none)
* **Failed Executions:** `stored` (all)
* **Execution Pruning:** Enabled (Retention: `336 hours`)

---

## 9. Security & Infrastructure Status
* **Isolation:** Database and Redis have no public ports exposed. n8n is strictly behind Traefik proxy.
* **Secrets:** Stored exclusively in `/opt/beget/n8n/.env`. Forbidden to commit to Git or expose to external LLMs.
* **Backups:** Located in `/opt/beget/n8n/backups`. Formats: `n8n_pg_YYYYMMDD_HHMMSS.sql.gz` and `n8n_vol_YYYYMMDD_HHMMSS.tar.gz`. *Note: No cron jobs found, backups are triggered manually.*
* **Updates:** OS security via `unattended-upgrades`. Docker containers are updated manually (Watchtower is not installed).

---

## 10. Infrastructure Topology



```
                    Internet
                        │
                        ▼
                  Traefik (HTTPS)
                        │
                        ▼
                    n8n Server
                        │
      ┌─────────────────┼──────────────────┐
      │                 │                  │
      ▼                 ▼                  ▼
  PostgreSQL         Redis           n8n Worker
      │
      ▼
 Workflow Database

                    │
                    ▼
              Gotenberg PDF
```

---

# 19. Production Status

Current deployment is a production Docker environment consisting of:

- Ubuntu Server
- Docker
- Docker Compose
- Traefik
- n8n
- PostgreSQL
- Redis
- Gotenberg

The architecture separates application, database, queue, reverse proxy and PDF generation into dedicated containers with persistent storage.