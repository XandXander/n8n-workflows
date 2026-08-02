# ENVIRONMENT.md - Runtime Environment Documentation

**Project:** XandAI / n8n Automation Platform  
**Last updated:** 2026-07-24

---

## ⚠️ КРИТИЧЕСКИЕ ПРАВИЛА ДЛЯ LLM (DEPLOYMENT & API)
При генерации скриптов автоматизации, деплоя, cURL-запросов или CI/CD пайплайнов для этой среды строго соблюдай следующие параметры:
1. **Метод обновлений воркфлоу:** Используй только метод **PATCH** (официальный метод Public API v1).
2. **API Endpoint:** `https://xandai.ru{id}`
3. **Заголовок авторизации:** `X-N8N-API-KEY: <REDACTED>` (никогда не выводи реальный ключ в чат).
4. **Запрещенные поля (Read-only):** При отправке PATCH-запроса для обновления воркфлоу полностью удаляй из тела JSON следующие поля: `id`, `versionId`, `active`, `createdAt`, `updatedAt`, `shared`, `tags`, `triggerCount`, `pinData`. Если их отправить, API n8n вернет ошибку.

---

## Purpose

This document describes the runtime environment of the project. It contains OS, Docker, application configuration, environment variables, external services, community nodes, runtime limitations, API configuration, and local development environment details.

Business logic is documented separately in `PROJECT_KNOWLEDGE.md`.

---

## Operating System

- **OS:** Ubuntu 24.04.4 LTS
- **Kernel:** Linux 6.8.0-124-generic
- **Architecture:** x86_64
- **Virtualization:** KVM
- **Timezone:** Europe/Moscow

---

## Hardware Resources

- **CPU:** 2 vCPU
- **Memory:** 3.8 GB RAM
- **Swap:** 4 GB
- **Disk:** 38 GB SSD
- **Available disk space:** approx 25 GB

---

## Docker Environment

- Docker Engine enabled as system service. Containers start automatically after reboot.
- **Docker Compose project name:** `n8n`
- **Compose file:** `/opt/beget/n8n/docker-compose.yml`
- Persistent storage uses Docker local-persist volumes.

---

## Docker Containers

| Container | Image | Purpose |
|---|---|---|
| **n8n** | `docker.n8n.io/n8nio/n8n:latest` (обновлено до версии 2.30.7+) | Main workflow engine |
| **n8n Worker** | `docker.n8n.io/n8nio/n8n:latest` | Background execution worker (`command: worker`) |
| **PostgreSQL** | `pgvector/pgvector:pg16` | Workflow database (extensions: pgcrypto, uuid-ossp) |
| **Redis** | `redis:6-alpine` | Queue backend |
| **Traefik** | `traefik:3.6.5` | HTTPS reverse proxy (Let's Encrypt) |
| **Gotenberg** | `gotenberg/gotenberg:8` | HTML → PDF conversion |

---

## n8n Runtime Configuration

- **Execution Mode:** `regular`
- **Binary Data Mode:** `filesystem`
- **Execution Pruning:** Enabled, retention 336 hours
- **Save Successful Executions:** `none`
- **Save Failed Executions:** `all`
- **Maximum Concurrent Executions:** `5`
- **Maximum Payload:** 32 MB
- **Environment Access From Code Nodes:** **Разрешено** (`N8N_BLOCK_ENV_ACCESS_IN_NODE=false`)
- **Git Bare Repositories:** Disabled
- **Personalization:** Disabled
- **Settings File Permissions:** Enforced

---

## API Configuration

| Parameter | Value |
|---|---|
| **API Endpoint** | `https://xandai.ru/api/v1/workflows` |
| **Authentication Header** | `X-N8N-API-KEY` |
| **HTTP Method for Updates** | **PATCH** |
| **API Enabled** | `N8N_API_ENABLED=true` |
| **Active API Key** | `<REDACTED>` |
| **Read-only fields (не отправлять при обновлении)** | `id, versionId, active, createdAt, updatedAt, shared, tags, triggerCount, pinData` |

---

## Validation & Deployment Pipeline

| Component | Details |
|---|---|
| **Validator** | `n8n-workflow-validator` (глобально, схема соответствует n8n 2.x) |
| **Validation check** | Синтаксис, структура nodes/connections, запрещённые поля |
| **Deployment method** | PATCH-запрос к `/api/v1/workflows/{id}` |
| **Post-deploy** | Git commit + push (при наличии изменений) |

---

## Environment Variables

The runtime configuration is stored in `/opt/beget/n8n/.env`

The file contains: PostgreSQL configuration, Redis configuration, n8n configuration, Webhook configuration, Encryption key, Credentials, API keys.

⚠️ **Sensitive values must never be:**  
- committed to Git  
- exported into documentation  
- included in prompts sent to external LLMs  

Always replace secret values with `<REDACTED>` when sharing configuration.

---

## Persistent Directories

| Directory | Path |
|---|---|
| Project root | `/opt/beget/n8n` |
| n8n data | `/opt/beget/n8n/n8n_storage` |
| Workflow storage | `/opt/beget/n8n/n8n_storage/storage/workflows` |
| Database | `/opt/beget/n8n/db_storage` |
| Redis | `/opt/beget/n8n/redis_storage` |
| Traefik certificates | `/opt/beget/n8n/traefik_data` |
| Backups | `/opt/beget/n8n/backups` |

---

## Community Nodes

Installed packages in `/opt/beget/n8n/n8n_storage/nodes`:
- `@tavily/n8n-nodes-tavily`
- `n8n-nodes-yandexgpt`
- `n8n-nodes-yandex-disk`
- `n8n-nodes-yandex-dialogs`
- `n8n-nodes-wkhtmltopdf`

---

## Database & Queue Environment

- **Database:** PostgreSQL 16 (pgvector) | Host: `postgres` | Port: 5432 (Internal Network Only)
- **Queue Backend:** Redis | Host: `redis` (Queue health checks enabled)

---

## Reverse Proxy & Security

- **Proxy:** Traefik 3.6.5 | Public domain: `https://xandai.ru` (HTTP -> HTTPS redirect, Let's Encrypt)
- **Security:** Redis and Postgres are not exposed. n8n is strictly behind Traefik. Secrets are only in `.env`. Binary data is on the filesystem. Workflow encryption uses `N8N_ENCRYPTION_KEY`.

---

## Backup & Automatic Updates

- **Backups:** Target directory `/opt/beget/n8n/backups`. Contains `.sql.gz` and `.tar.gz`. *Примечание: Автоматический запуск через cron на сервере не настроен, создание бэкапов выполняется вручную.*
- **Updates:** OS security updates via `unattended-upgrades`. Docker containers are updated manually.

---

## Resource Constraints

The environment is strictly optimized for 1 production instance of n8n, 1 worker, PostgreSQL, Redis, Traefik, and Gotenberg. Any future extensions (additional workers, local LLMs, vector databases) must be pre-evaluated against 2 vCPU, 3.8 GB RAM, and 25 GB available disk space.

---

## Local Development Environment (Windows)

- **Host OS:** Windows 10
- **Open WebUI:** `http://localhost:8080`
- **Git Repository:** `E:\РАБОТА ДОМА\WEB\N8N BEGET\FOREIGN\DEEPSEEK\GIT`
- **Workflow Validator Path:** `C:\Users\user\AppData\Roaming\npm` (модуль `n8n-workflow-validator`, схема n8n 2.x)
- **Local API Key:** `<REDACTED>`
- **Deployment pipeline:** Validation -> PATCH to API -> Git commit + push
