# DECISIONS.md

## Project Decision Log

**Project:** XandAI / n8n Automation Platform
**Generated:** 2026-07-27
**Source:** Knowledge-base files (ENVIRONMENT.md, SERVER_STRUCTURE.md, n8n_schema.md, node_templates.md, Ограничения и паттерны n8n.md)

---

# Decision: n8n как основной workflow engine

## Date
Unknown

## Context
Требовалась платформа для автоматизации бизнес-процессов, OSINT-пайплайнов и AI-агентов с low-code подходом.

## Decision
Выбран n8n (self-hosted) как основной движок автоматизации.
- Образ: `docker.n8n.io/n8nio/n8n:latest`
- Версия: автообновление до latest (текущая 2.31.6 на новом сервере, была 2.30.7+ на старом) [1][4]
- Self-hosted на собственном VPS

## Alternatives Considered
- Unknown

## Why This Decision Was Made
- Low-code — быстрая разработка без написания бэкенда с нуля
- Self-hosted — полный контроль над данными
- Open-source core — отсутствие лицензионных платежей
- Богатая экосистема интеграций из коробки

## Trade-offs
Плюсы:
- Быстрый запуск прототипов
- Визуальное проектирование процессов

Минусы:
- Ограничения рантайма (Task Runner Sandbox — нет Buffer, нет crypto.randomUUID) [5]
- Версионные breaking changes (поведение Loop/ SplitInBatches, обязательный тумблер «Convert types» в IF) [5]
- Payload limit 32 MB

## Consequences
Весь проект строится вокруг n8n. Workflow — основной артефакт разработки. Git-репозиторий хранит JSON-воркфлоу. Деплой через API.

## Current Status
Accepted

---

# Decision: Docker Compose как метод развёртывания

## Date
Unknown

## Context
Требовалось развернуть n8n со всем окружением (БД, очередь, прокси) на одном VPS.

## Decision
Docker Compose с проектом `n8n` и compose-файлом `/opt/beget/n8n/docker-compose.yml`.
Контейнеры: n8n, n8n Worker, PostgreSQL, Redis, Traefik, Gotenberg (+ Directus на новом сервере) [1][4].
Persistent storage через Docker local-persist volumes.

## Alternatives Considered
- Unknown

## Why This Decision Was Made
- Воспроизводимость окружения
- Изоляция сервисов
- Простота обновления (docker compose pull && up)
- Автозапуск при ребуте (systemd integration)

## Trade-offs
Плюсы:
- Единый compose-файл — простая конфигурация
- Изоляция контейнеров

Минусы:
- Дополнительный overhead по памяти на каждый контейнер
- Все сервисы на одной машине — нет горизонтального масштабирования

## Consequences
Весь production-стек управляется через docker compose. Добавление нового сервиса = добавление контейнера в compose-файл.

## Current Status
Accepted

---

# Decision: PostgreSQL 16 + pgvector как база данных

## Date
Unknown

## Context
Требовалась БД для хранения рабочих данных n8n и векторного поиска (RAG, семантический поиск).

## Decision
Выбран образ `pgvector/pgvector:pg16` — PostgreSQL 16 с расширениями pgvector, pgcrypto, uuid-ossp [1][4].

## Alternatives Considered
- Unknown (возможно, рассматривались Pinecone как внешний векторный сервис — упоминается в ограничениях как внешний вызов через Execute Workflow) [5]

## Why This Decision Was Made
- Одна БД для реляционных данных и векторов — меньше сервисов
- pgvector — зрелое расширение
- Нет необходимости в отдельном векторном хранилище для базовых задач

## Trade-offs
Плюсы:
- Минимальный operational overhead
- SQL + векторы в одном запросе

Минусы:
- pgvector уступает специализированным решениям (Pinecone) на больших объёмах
- Ограничения VPS по RAM/CPU влияют на производительность векторного поиска

## Consequences
PostgreSQL — единственная база данных в проекте. Для внешних high-performance векторных сценариев (вероятно) используется Pinecone через API (упоминается в «Ограничения и паттерны n8n») [5].

## Current Status
Accepted

---

# Decision: Redis 6 (Alpine) как очередь

## Date
Unknown

## Context
n8n требует очередь для фоновых задач, масштабирования и worker-процессов.

## Decision
Выбран `redis:6-alpine` как queue backend [1][4].

## Alternatives Considered
- Unknown

## Why This Decision Was Made
- Лёгкий образ (Alpine)
- Нативная поддержка в n8n
- Достаточно для одного worker'а

## Trade-offs
Плюсы:
- Минимальное потребление памяти
- Простая настройка

Минусы:
- Redis 6, не последняя версия
- Нет кластеризации, один инстанс

## Consequences
Очередь работает. Queue health checks enabled.

## Current Status
Accepted

---

# Decision: Traefik как Reverse Proxy с Let's Encrypt

## Date
Unknown

## Context
Нужен HTTPS-доступ к n8n и другим сервисам с автоматическим получением сертификатов.

## Decision
Выбран Traefik 3.6.5 как HTTPS reverse proxy.
- HTTP → HTTPS redirect
- Let's Encrypt для сертификатов
- Домен: `https://xandai.ru` [1][4]

## Alternatives Considered
- Unknown (возможно, Nginx)

## Why This Decision Was Made
- Нативная интеграция с Docker (автообнаружение контейнеров)
- Автоматический выпуск и обновление сертификатов Let's Encrypt
- Современный API-ориентированный прокси

## Trade-offs
Плюсы:
- Автоматический HTTPS
- Минимум конфигурации
- Docker-native

Минусы:
- Дополнительный контейнер (потребление ресурсов)
- Сложнее в отладке чем Nginx для простых сценариев

## Consequences
Все внешние соединения — HTTPS. PostgreSQL и Redis не exposed наружу.

## Current Status
Accepted

---

# Decision: Gotenberg для HTML → PDF

## Date
Unknown

## Context
Требовалась конвертация HTML-отчётов в PDF.

## Decision
Выбран `gotenberg/gotenberg:8` для конвертации HTML → PDF.
- Эндпоинт: `/forms/chromium/convert/html`
- Формат: A4 (8.27×11.69 дюймов), отступы 0.5
- Поле формы: `files` с бинарным `index.html` [5]

## Alternatives Considered
- wkhtmltopdf (установлен как community node `n8n-nodes-wkhtmltopdf`, но не используется как основной) [1][4]
- Возможно, Puppeteer/Playwright напрямую

## Why This Decision Was Made
- Готовый Docker-сервис, не нужно писать код
- Chromium-based рендеринг — точное отображение современного HTML/CSS
- Stateless, горизонтально масштабируем

## Trade-offs
Плюсы:
- Качественный рендеринг
- Простой API

Минусы:
- Дополнительный контейнер (~500 MB RAM с Chromium)
- Ограниченные возможности кастомизации

## Consequences
HTML→PDF работает. wkhtmltopdf присутствует как legacy/альтернативный вариант.

## Current Status
Accepted

---

# Decision: Directus как Headless CMS

## Date
Unknown (добавлен при миграции на новый сервер)

## Context
Потребовалось структурированное хранение контента с API-доступом для интеграции в n8n-воркфлоу.

## Decision
Добавлен `directus/directus:latest` как вспомогательный сервис [4].

## Alternatives Considered
- Unknown

## Why This Decision Was Made
- Headless CMS с REST/GraphQL API из коробки
- Лёгкое развёртывание
- Гибкая модель данных

## Trade-offs
Плюсы:
- Готовый API для контента
- Web-интерфейс для управления данными

Минусы:
- Дополнительный контейнер (потребление RAM)
- Добавлен только на новом сервере (4 vCPU, 6 GB) — на старом (3.8 GB) его не было

## Consequences
Directus стал частью production-стека на новом сервере.

## Current Status
Accepted

---

# Decision: Миграция VPS — с 2 vCPU / 3.8 GB на 4 vCPU / 6 GB

## Date
Между 2026-07-24 и 2026-07-27

## Context
Старый сервер имел ограничения: 2 vCPU, 3.8 GB RAM, 38 GB SSD, ~25 GB свободно. Этого не хватало для расширения стека.

## Decision
Миграция на новый VPS:
- CPU: 2 vCPU → 4 vCPU (3-3.3 GHz)
- RAM: 3.8 GB → 6 GB
- Disk: 38 GB SSD → 80 GB NVMe
- Available: ~25 GB → ~61 GB
- Timezone: Europe/Moscow → Etc/UTC (+0000)
- Добавлен контейнер Directus [1][4]

## Alternatives Considered
- Unknown (возможно, вертикальное масштабирование vs. несколько машин)

## Why This Decision Was Made
- Исчерпание ресурсов на старом сервере
- Необходимость добавления новых сервисов (Directus)
- NVMe — улучшение I/O производительности

## Trade-offs
Плюсы:
- Больше памяти для сервисов
- Быстрый диск
- UTC — стандартизация времени

Минусы:
- Увеличение стоимости хостинга
- Необходимость миграции данных

## Consequences
Новый production-сервер с расширенным стеком. Документация разделилась на ENVIRONMENT.md (старый) и SERVER_STRUCTURE.md (новый).

## Current Status
Accepted

---

# Decision: Изменение API-метода обновления workflow с PATCH на PUT

## Date
Между 2026-07-24 и 2026-07-27

## Context
В старой конфигурации использовался PATCH. В новой — PUT.

## Decision
Метод обновления воркфлоу через Public API изменён:
- Старый: PATCH `/api/v1/workflows/{id}`
- Новый: PUT `/api/v1/workflows/{id}` [1][4]
- Read-only поля дополнились полем `meta` в новой версии

## Alternatives Considered
- PATCH (было раньше) [1]

## Why This Decision Was Made
- Unknown (вероятно, изменение в поведении n8n API при обновлении версии с 2.30.x до 2.31.x, или PUT оказался более надёжным для полной замены workflow)

## Trade-offs
Плюсы:
- PUT — идемпотентная операция, полная замена состояния
- Меньше вероятности конфликтов частичного обновления

Минусы:
- Необходимость каждый раз отправлять полный workflow
- Нарушение обратной совместимости — старые скрипты с PATCH ломаются

## Consequences
Все деплой-процедуры обновлены на PUT. Read-only список расширен полем `meta`.

## Current Status
Accepted (Supersedes PATCH)

---

# Decision: Tavily как поисковый инструмент для AI-агентов

## Date
Unknown

## Context
AI-агентам в n8n требовался актуальный поиск в интернете.

## Decision
Установлен community node `@tavily/n8n-nodes-tavily` [1][4].
Используется как Tool для LangChain-агента в n8n [3][5].

## Alternatives Considered
- Serper API (используется отдельно, но не как tool для агента) [5]
- Возможно, другие search API (Brave, Google Custom Search)

## Why This Decision Was Made
- Tavily оптимизирован для AI-агентов (возвращает структурированные результаты)
- Готовый community node для n8n
- Не требует сложной постобработки результатов

## Trade-offs
Плюсы:
- Native интеграция с LangChain в n8n
- Чистые, готовые для LLM результаты

Минусы:
- Платный API (не бесплатный, в отличие от Serper free)
- Зависимость от внешнего сервиса

## Consequences
Tavily — основной поисковый инструмент для AI-агентов. Serper используется в отдельных сценариях (OSINT-поиск) с учётом ограничений free-тарифа (запрет `site:`) [5].

## Current Status
Accepted

---

# Decision: Яндекс GPT как дополнительный LLM-провайдер

## Date
Unknown

## Context
Требовался доступ к русскоязычной LLM для задач на русском языке.

## Decision
Установлен community node `n8n-nodes-yandexgpt` [1][4].

## Alternatives Considered
- Unknown

## Why This Decision Was Made
- Оптимизация под русский язык
- Российский провайдер — потенциально ниже latency
- Готовая интеграция через community node

## Trade-offs
Плюсы:
- Хорошее качество на русском
- Локальный провайдер

Минусы:
- Зависимость от санкционных рисков
- Отдельный API-ключ и биллинг

## Consequences
Два LLM-провайдера в проекте: Groq (llama-3.1-8b-instant, бесплатный тариф) и Яндекс GPT.

## Current Status
Accepted

---

# Decision: Яндекс Диск как файловое хранилище

## Date
Unknown

## Context
Требовалось облачное хранение файлов (отчёты, PDF, данные) с API-доступом из n8n.

## Decision
Установлены community nodes:
- `n8n-nodes-yandex-disk`
- `n8n-nodes-yandex-dialogs` [1][4]

## Alternatives Considered
- Unknown (возможно, Google Drive, Nextcloud, S3)

## Why This Decision Was Made
- Экосистема Яндекса
- Простое API
- Бесплатный/недорогой тариф

## Trade-offs
Плюсы:
- Интеграция через готовые ноды
- Российский сервис — нет санкционных рисков

Минусы:
- Зависимость от одного провайдера
- Меньше возможностей чем S3

## Consequences
Яндекс Диск используется для хранения файлов в воркфлоу.

## Current Status
Accepted

---

# Decision: Groq API (llama-3.1-8b-instant) как бесплатный LLM

## Date
Unknown

## Context
Требовался доступ к LLM с минимальными затратами для экспериментов и нетребовательных задач.

## Decision
Используется Groq API с моделью llama-3.1-8b-instant на бесплатном тарифе (TPD ~500 000) [5].

## Alternatives Considered
- Unknown (возможно, другие бесплатные API — Together AI, Hugging Face)

## Why This Decision Was Made
- Бесплатный тариф — нулевая стоимость
- Высокая скорость инференса (Groq LPU)
- Достаточно для прототипирования и простых задач

## Trade-offs
Плюсы:
- Бесплатно
- Быстро

Минусы:
- Жёсткий rate limit (TPD ~500 000)
- Ошибка 429 сжигает квоту при retry
- Модель 8B — ограниченное качество на сложных задачах
- Нестабильность — требует стратегии обработки ошибок (onError: "continueRegularOutput", не использовать retry) [5]

## Consequences
Разработан специальный паттерн: на 429 не делать retry, использовать `onError: "continueRegularOutput"`, обрабатывать ошибку в следующем Code-узле [5].

## Current Status
Accepted

---

# Decision: Serper API как поисковый движок для OSINT

## Date
Unknown

## Context
Требовался поиск в Google для OSINT-задач с structured output.

## Decision
Используется Serper API (free тариф) [5].

## Alternatives Considered
- Tavily (выбран для агентов)
- Возможно, Google Custom Search API

## Why This Decision Was Made
- Бесплатный тариф
- Структурированные результаты (Google Search, News, Images)
- Быстрее чем парсинг Google напрямую

## Trade-offs
Плюсы:
- Бесплатно
- Чистый JSON
- Несколько типов поиска

Минусы:
- Free-тариф: запрещён оператор `site:` в запросах → 400 ошибка
- Приходится использовать обходные формулировки: `"проектирование Москва тендер закупки"` вместо `site:.ru проектирование тендер`
- Ограниченное количество запросов

## Consequences
Разработан паттерн запросов без `site:` [5]. Serper — основной поисковый движок для OSINT-задач.

## Current Status
Accepted

---

# Decision: IMAP как триггер для email-воркфлоу

## Date
Unknown

## Context
Требовалось запускать воркфлоу по входящим письмам (OSINT-запросы, уведомления).

## Decision
Используется IMAP-триггер n8n с параметрами:
- `postProcessAction: "read"` — письма отмечаются прочитанными
- `customEmailConfig: "[\"UNSEEN\"]"` — обрабатываются только непрочитанные
- Фильтр темы: `$json.subject contains "OSINT-AI"` (не `$json.headers.subject`) [5]

## Alternatives Considered
- Webhook (отклонён для email-сценариев)
- Gmail API

## Why This Decision Was Made
- Универсальный протокол — работает с любым почтовым провайдером
- Простота настройки
- Встроенная нода n8n

## Trade-offs
Плюсы:
- Не требует внешнего webhook-сервиса
- Работает с любым IMAP-совместимым ящиком

Минусы:
- Polling, не push — задержка между проверками
- Без `postProcessAction: "read"` — зацикливание писем

## Consequences
IMAP-триггер используется для email-входов в OSINT-пайплайн.

## Current Status
Accepted

---

# Decision: Execute Workflow с fire-and-forget для пользовательских подтверждений

## Date
Unknown

## Context
Пользователь отправляет запрос → нужно сразу подтвердить получение, а обработку выполнить асинхронно.

## Decision
`waitForSubWorkflow: false` для сценариев, где подтверждение пользователю идёт сразу.
`waitForSubWorkflow: true` — только когда нужен ответ от подворкфлоу (Pinecone upsert/query) [5].

## Alternatives Considered
- Очереди сообщений
- Webhook callback

## Why This Decision Was Made
- Встроенный механизм n8n
- Простота реализации
- Нет дополнительной инфраструктуры

## Trade-offs
Плюсы:
- Быстрый ответ пользователю
- Асинхронная обработка тяжёлых задач

Минусы:
- Нет встроенного механизма уведомления пользователя о завершении (нужно отдельно через Telegram)
- При падении подворкфлоу ошибка теряется

## Consequences
Основной паттерн: main workflow → fire-and-forget → sub-workflow. Telegram-уведомления о результатах — отдельно.

## Current Status
Accepted

---

# Decision: Execution Pruning с Retention 336 часов

## Date
Unknown

## Context
База данных executions растёт неограниченно, занимая место на диске.

## Decision
Включён pruning исполнений:
- Retention: 336 часов (14 дней)
- Успешные исполнения: не сохраняются (`save successful executions: none`)
- Неуспешные: сохраняются все (`save failed executions: all`) [1][4]

## Alternatives Considered
- Хранение всех исполнений
- Ручная очистка

## Why This Decision Was Made
- Экономия дискового пространства
- Успешные исполнения не нужны для отладки
- Неуспешные — нужны для анализа ошибок

## Trade-offs
Плюсы:
- Экономия места в БД
- Автоматическая очистка

Минусы:
- Нельзя посмотреть историю успешных запусков старше 14 дней
- Аудит ограничен

## Consequences
БД не раздувается. Для детального аудита нужно логирование на уровне приложения.

## Current Status
Accepted

---

# Decision: N8N_BLOCK_ENV_ACCESS_IN_NODE=false — разрешение доступа к env из Code-узлов

## Date
Unknown

## Context
Code-узлам требовался доступ к переменным окружения (API-ключи, конфигурация).

## Decision
`N8N_BLOCK_ENV_ACCESS_IN_NODE=false` — доступ к `process.env` из Code-узлов разрешён [1][4].

## Alternatives Considered
- Передача через input/static data
- Credential store n8n

## Why This Decision Was Made
- Удобство разработки — быстрый доступ к конфигурации
- Меньше boilerplate кода в воркфлоу

## Trade-offs
Плюсы:
- Простота использования переменных окружения в коде
- Быстрая разработка

Минусы:
- **Критическая уязвимость безопасности**: любой Code-узел может прочитать `.env` целиком
- Утечка секретов возможна через любой воркфлоу с Code-нодой
- Противоречит принципу least privilege

## Consequences
Code-ноды могут читать любые переменные окружения. Требуется тщательный аудит воркфлоу перед деплоем.

## Current Status
Accepted (с осознанным риском безопасности)

---

# Decision: Ограничение Max Concurrent Executions = 5

## Date
Unknown

## Context
Сервер с ограниченными ресурсами (2 vCPU / 4 vCPU). Необходимо предотвратить перегрузку.

## Decision
`N8N_CONCURRENCY_PRODUCTION_LIMIT=5` — максимум 5 одновременных исполнений [1][4].

## Alternatives Considered
- Больше конкурентных исполнений
- Не ограничивать

## Why This Decision Was Made
- Защита VPS от исчерпания CPU/RAM
- Стабильность системы важнее пропускной способности

## Trade-offs
Плюсы:
- Система стабильна под нагрузкой
- Predictable resource usage

Минусы:
- При пиковых нагрузках — очередь исполнений
- Не подходит для high-throughput сценариев

## Consequences
При масштабировании необходимо либо увеличивать лимит (если позволяют ресурсы), либо добавлять workers.

## Current Status
Accepted

---

# Decision: Binary Data Mode = filesystem

## Date
Unknown

## Context
Бинарные данные (файлы, PDF, изображения) нужно где-то хранить.

## Decision
`N8N_BINARY_DATA_MODE=filesystem` — бинарные данные хранятся на диске, не в БД [1][4].

## Alternatives Considered
- PostgreSQL (бинарные данные в БД)
- S3

## Why This Decision Was Made
- Не раздувает БД
- Проще бэкапить (tar.gz)
- Не требует внешнего сервиса

## Trade-offs
Плюсы:
- Простота
- Файлы можно посмотреть напрямую

Минусы:
- Привязанность к серверу
- Нет репликации
- Риск заполнения диска (25→61 GB)

## Consequences
Бэкапы делаются через tar.gz вместе с БД. Дисковое пространство — критический ресурс.

## Current Status
Accepted

---

# Decision: Ручные бэкапы вместо cron

## Date
Unknown

## Context
Нужно резервное копирование данных.

## Decision
Бэкапы создаются вручную в `/opt/beget/n8n/backups`. Форматы: `.sql.gz` и `.tar.gz`.
Автоматический запуск через cron на сервере не настроен [1][4].

## Alternatives Considered
- Cron-автоматизация
- Внешний backup-сервис

## Why This Decision Was Made
- Unknown (вероятно, простота / «потом настроим»)

## Trade-offs
Плюсы:
- Полный контроль над моментом бэкапа

Минусы:
- Человеческий фактор — можно забыть
- Нет гарантии свежести бэкапа
- Не соответствует best practices

## Consequences
Риск потери данных между ручными бэкапами. Technical debt — требует автоматизации.

## Current Status
Accepted (с признанием риска)

---

# Decision: Watchtower не установлен — ручное обновление Docker-образов

## Date
Unknown

## Context
Нужно обновлять Docker-образы.

## Decision
Watchtower не установлен. Обновление контейнеров — вручную (за исключением n8n:latest, который автообновляется при пересоздании) [4].

## Alternatives Considered
- Watchtower (автоматическое обновление)
- Renovate/Dependabot

## Why This Decision Was Made
- Контроль над моментом обновления
- Предотвращение внезапных поломок от автообновления
- Ручное тестирование перед обновлением production

## Trade-offs
Плюсы:
- Предсказуемость
- Никаких сюрпризов от автоматических обновлений

Минусы:
- Ручной труд
- Можно пропустить критическое обновление безопасности

## Consequences
Обновления выполняются осознанно, но требуют дисциплины.

## Current Status
Accepted

---

# Decision: Локальная разработка на Windows 10 с Open WebUI

## Date
Unknown

## Context
Требовалась локальная среда для разработки и тестирования воркфлоу.

## Decision
Локальное окружение:
- Windows 10
- Open WebUI на `http://localhost:8080`
- Git-репозиторий: `E:\РАБОТА ДОМА\WEB\N8N BEGET\FOREIGN\DEEPSEEK\GIT`
- Валидатор: `n8n-workflow-validator` (глобально, схема n8n 2.x) [1][4]

## Alternatives Considered
- Полный Docker-стек локально
- WSL2

## Why This Decision Was Made
- Windows 10 — основная ОС разработчика
- Open WebUI — локальный интерфейс для тестирования LLM-запросов
- Валидатор перед деплоем на production

## Trade-offs
Плюсы:
- Быстрая итерация
- Не требует полного production-стека локально

Минусы:
- Не идентично production-окружению
- Валидатор только проверяет структуру — не гарантирует работоспособность в рантайме

## Consequences
Pipeline: разработка на Windows → валидация → PUT/PATCH на production → Git commit + push.

## Current Status
Accepted

---

# Decision: Git bare repositories отключены

## Date
Unknown

## Context
n8n имеет встроенную функцию Git-синхронизации.

## Decision
`N8N_GIT_REPOSITORIES_DISABLED=true` — Git bare repositories не используются [1][4].

## Alternatives Considered
- Встроенная Git-синхронизация n8n

## Why This Decision Was Made
- Контроль версий через внешний Git-репозиторий (Windows)
- Встроенная синхронизация n8n может конфликтовать с внешним workflow

## Trade-offs
Плюсы:
- Полный контроль над Git-историей
- Не зависит от поведения n8n Git

Минусы:
- Ручной commit + push после каждого деплоя
- Двойной источник истины (файлы на диске n8n и Git-репозиторий)

## Consequences
Деплой включает ручной Git commit. Риск рассинхронизации между production и Git.

## Current Status
Accepted

---

# Decision: Ограничения Sandbox — обход отсутствия Buffer и crypto

## Date
Unknown

## Context
Task Runner Sandbox в n8n не поддерживает `Buffer.from()` и `crypto.randomUUID()`.

## Decision
Разработаны обходные паттерны [5]:
- Вместо `Buffer.from()`: `this.helpers.prepareBinaryData()` с прямым текстом
- Вместо `crypto.randomUUID()`: `Date.now().toString(36) + Math.random().toString(36).slice(2)`

## Alternatives Considered
- Отключение Sandbox
- Использование внешнего сервиса для генерации UUID

## Why This Decision Was Made
- Sandbox отключить нельзя (защита production)
- Обходные паттерны достаточны для практических задач

## Trade-offs
Плюсы:
- Работает в рамках ограничений
- Безопасность Sandbox сохраняется

Минусы:
- UUID не соответствует RFC — возможны коллизии (низкая вероятность)
- `prepareBinaryData` менее удобен чем `Buffer`

## Consequences
Все Code-ноды используют эти паттерны. Разработчики знают об ограничениях.

## Current Status
Accepted

---

# Decision: Payload Limit 32 MB

## Date
Unknown

## Context
n8n позволяет ограничить максимальный размер payload.

## Decision
`N8N_PAYLOAD_SIZE_MAX=32` (MB) [1][4].

## Alternatives Considered
- Больше (64, 128 MB)
- Меньше (16 MB)
- Без ограничений

## Why This Decision Was Made
- Защита от переполнения памяти при больших файлах
- 32 MB достаточно для большинства сценариев (документы, JSON-ответы)

## Trade-offs
Плюсы:
- Predictable memory usage
- Защита от случайных огромных payload

Минусы:
- Большие PDF/изображения могут не пройти
- Приходится думать о chunking для больших данных

## Consequences
При необходимости обработки файлов >32 MB нужен внешний сервис или chunking.

## Current Status
Accepted

---

# Major Architectural Decisions

1. **n8n как центральный workflow engine** — все процессы автоматизации проходят через n8n. Это главное архитектурное решение, определяющее весь стек.

2. **Self-hosted на одном VPS** — всё работает на одной машине. Плюс: низкая стоимость. Минус: нет отказоустойчивости, нет горизонтального масштабирования.

3. **Docker Compose как единственный метод развёртывания** — нет Kubernetes, нет Swarm.

4. **PostgreSQL + pgvector как единая БД** — и реляционные данные, и векторы в одной БД.

5. **Мульти-LLM стратегия** — Groq (бесплатный) + Яндекс GPT (русский) + возможно другие через API.

6. **Git-based version control для воркфлоу** — JSON-файлы воркфлоу хранятся в Git, деплой через API.

---

# Technology Choices

| Технология | Почему выбрана |
|---|---|
| **n8n** | Low-code автоматизация, self-hosted, богатая экосистема интеграций [1][4] |
| **Docker Compose** | Простое развёртывание, воспроизводимость, автозапуск [1][4] |
| **PostgreSQL 16 + pgvector** | Одна БД для реляционных и векторных данных, зрелое расширение [1][4] |
| **Redis 6 (Alpine)** | Лёгкая очередь для n8n worker [1][4] |
| **Traefik 3.6.5** | Автоматический HTTPS, Docker-native [1][4] |
| **Gotenberg 8** | Готовый сервис HTML→PDF, Chromium-based рендеринг [1][4][5] |
| **Directus** | Headless CMS, REST/GraphQL API [4] |
| **Groq (llama-3.1-8b-instant)** | Бесплатный тариф, высокая скорость инференса [5] |
| **Яндекс GPT** | Русскоязычная LLM [1][4] |
| **Tavily Search** | Поиск, оптимизированный для AI-агентов [1][4][3] |
| **Serper API** | Бесплатный структурированный Google-поиск для OSINT [5] |
| **Яндекс Диск** | Облачное файловое хранилище [1][4] |
| **Open WebUI (локально)** | Локальный интерфейс для тестирования LLM [1][4] |
| **Git (Windows)** | Версионирование воркфлоу [1][4] |
| **n8n-workflow-validator** | Преддеплойная валидация JSON-воркфлоу [1][4] |

---

# Rejected Approaches

1. **PATCH для обновления воркфлоу** — заменён на PUT при миграции на новый сервер [1][4].
2. **Retry при ошибке 429 от Groq** — отвергнут, так как сжигает квоту. Вместо этого `onError: "continueRegularOutput"` [5].
3. **Использование `site:` в Serper-запросах** — отвергнут из-за ограничений free-тарифа (400 ошибка) [5].
4. **Automated cron-бэкапы** — не внедрены (ручные бэкапы) [1][4].
5. **Watchtower для автообновления контейнеров** — не установлен [4].
6. **Git bare repositories в n8n** — отключены в пользу внешнего Git [1][4].
7. **Использование `$now.format(...)` в Code-узлах** — не работает, заменён на `new Date().toISOString()` [5].
8. **`.item` после Loop/SplitInBatches** — не работает в n8n 2.29+, заменён на `.first()` / `.all()[index]` [5].

---

# Cost vs Quality Decisions

1. **Бесплатный Groq vs платный OpenAI/Anthropic**
   - Выбран Groq (бесплатно), но с ограничением качества (8B модель) и жёстким rate-limit [5].

2. **Serper Free vs платный Google Custom Search API**
   - Выбран Serper Free, но с ограничениями (нет `site:`, ограниченное число запросов) [5].

3. **Один VPS vs несколько серверов / Kubernetes**
   - Выбран один VPS. Экономия на инфраструктуре, но нет отказоустойчивости [1][4].

4. **PostgreSQL + pgvector vs Pinecone (managed)**
   - pgvector для базовых задач (включён в существующую БД). Pinecone используется для тяжелых векторных сценариев через API [5].

5. **Ручные бэкапы vs автоматизированные**
   - Ручные бэкапы — экономия времени на настройку, но повышенный риск [1][4].

6. **Ручное обновление Docker vs Watchtower**
   - Ручное — контроль важнее автоматизации [4].

---

# Lessons Learned

1. **n8n Sandbox имеет жёсткие ограничения**: нет `Buffer`, нет `crypto.randomUUID()`. Нужно заранее проектировать Code-ноды с учётом этих ограничений, а не сталкиваться с ошибками в production [5].

2. **Groq бесплатный тариф — палка о двух концах**: высокая скорость, но 429 при retry сжигает квоту. Стратегия обработки ошибок критически важна [5].

3. **Serper free-тариф имеет неочевидные ограничения**: `site:` вызывает 400, а не осмысленное сообщение об ошибке. Приходится методом проб и ошибок находить формат запросов [5].

4. **IMAP без `postProcessAction: "read"` = зацикливание**: письма обрабатываются повторно. Это стандартная ловушка n8n IMAP-триггера [5].

5. **После SplitInBatches/Loop в n8n 2.29+ меняется способ доступа к данным**: `.item` не работает, нужен `.first()` или `.all()[index]`. Breaking change, который ломает существующие воркфлоу [5].

6. **IF/Filter в n8n требует явного включения «Convert types where required»**: без этого фильтры могут молча не пропускать данные, что трудно отлаживать [5].

7. **Миграция с PATCH на PUT потребовала обновления всех деплой-скриптов**: изменение API-метода — не просто замена слова, нужно также обновить список read-only полей [1][4].

---

# Decision Debt

1. **Автоматизация бэкапов**: ручные бэкапы — временное решение. Требуется cron-задача или внешний сервис [1][4].

2. **Мониторинг и алертинг**: нет упоминаний о мониторинге (Prometheus, Grafana, UptimeRobot). Статус: Unknown.

3. **Graceful degradation при отказе внешних API (Groq, Serper, Tavily)**: есть паттерны обработки ошибок, но нет сквозной стратегии fallback.

4. **N8N_BLOCK_ENV_ACCESS_IN_NODE=false**: доступ к env из Code-узлов — осознанный риск. Требует либо ужесточения, либо компенсирующих мер безопасности.

5. **Ручное обновление Docker-образов**: при масштабировании или увеличении числа сервисов может стать проблемой.

6. **Один VPS — одна точка отказа**: нет плана disaster recovery, нет high availability.

7. **n8n:latest автообновление**: риск breaking changes при обновлении мажорной версии n8n. Рекомендуется зафиксировать версию.

8. **Payload limit 32 MB**: может стать узким местом при работе с большими файлами (видео, датасеты).

9. **Генерация UUID без crypto**: текущий паттерн (`Date.now() + Math.random()`) не гарантирует уникальность. При масштабировании может потребоваться правильное решение.