# DECISIONS.md

## Purpose
Единый журнал архитектурных и инженерных решений OSINT-платформы XandAI на базе n8n. Каждое решение зафиксировано с контекстом, обоснованием, альтернативами и последствиями.

## ADR Status Legend
| Status | Meaning |
|--------|---------|
| PROPOSED | Предложено, но не принято |
| ACCEPTED | Принято и действует |
| IMPLEMENTED | Принято и полностью реализовано |
| SUPERSEDED | Заменено другим ADR |
| REJECTED | Рассмотрено и отклонено |
| DEPRECATED | Больше не должно использоваться |
| UNCERTAIN | Статус нельзя установить по источникам |

## Decision Index
| ID | Решение | Status | Components | Related errors |
|----|---------|--------|------------|----------------|
| ADR-001 | Модульная архитектура из 8 микро-воркфлоу | IMPLEMENTED | Все workflow | NONE |
| ADR-002 | DeepSeek как основной LLM-провайдер (flash/pro split) | IMPLEMENTED | OSINT_01, OSINT_05, OSINT_06 | ERR-002, ERR-016 |
| ADR-003 | Google Sheets как operational data store | IMPLEMENTED | OSINT_02, OSINT_05, OSINT_06 | ERR-001 |
| ADR-004 | Execute Workflow для межворкфлоу-коммуникации | IMPLEMENTED | Все workflow | ERR-004 |
| ADR-005 | Put Output in Field для HTTP Request внутри циклов | IMPLEMENTED | OSINT_02 | ERR-001, ERR-009 |
| ADR-006 | Gotenberg 8 для генерации PDF | IMPLEMENTED | OSINT_06 | ERR-010 |
| ADR-007 | prepareBinaryData для HTML→binary (Gotenberg) | IMPLEMENTED | OSINT_06 | ERR-006, ERR-010 |
| ADR-008 | Sandbox-safe код (отказ от Buffer, crypto, $now) | IMPLEMENTED | Все Code-узлы | ERR-006 |
| ADR-009 | Public API v1 n8n вместо внутреннего REST | IMPLEMENTED | n8n_workflow_manager | ERR-012 |
| ADR-010 | PUT deployment contract для обновления workflow | IMPLEMENTED | n8n_workflow_manager | ERR-012, ERR-013 |
| ADR-011 | Retry-политика для LLM API (DeepSeek) | IMPLEMENTED | OSINT_01, OSINT_05 | ERR-016 |
| ADR-012 | Отключение Firecrawl для защищённых целей | IMPLEMENTED | OSINT_02 | ERR-005 |
| ADR-013 | Удаление оператора site: из Serper-запросов | IMPLEMENTED | OSINT_02 | NONE |
| ADR-014 | Jina embeddings + Pinecone для векторной памяти | IMPLEMENTED | OSINT_07 | ERR-011 |
| ADR-015 | Binary Data Mode = filesystem | IMPLEMENTED | Серверная конфигурация | ERR-010 |
| ADR-016 | Always Output Data на узлах чтения Google Sheets | IMPLEMENTED | OSINT_05, OSINT_06 | NONE |
| ADR-017 | IMAP postProcessAction: "read" | IMPLEMENTED | OSINT_01 | NONE |
| ADR-018 | Open WebUI + DeepSeek v4 Pro — главный рабочий контекст | ACCEPTED | Процесс разработки | NONE |
| ADR-019 | Manual Trigger + Code Node для тестирования sub-workflow | IMPLEMENTED | OSINT_02 | ERR-004 |
| ADR-020 | Запрет динамических выражений в Sheet Name Google Sheets | IMPLEMENTED | OSINT_02, OSINT_05 | NONE |
| ADR-021 | Convert to File для HTML → Gotenberg | SUPERSEDED | OSINT_06 | ERR-010 |
| ADR-022 | Google AI Studio для доступа к Gemini-моделям | IMPLEMENTED | Внешние API | NONE |
| ADR-023 | Отказ от retry на 429 от Groq (continueRegularOutput) | IMPLEMENTED | OSINT_01, OSINT_03 | NONE |
| ADR-024 | Формальные профили workflow JSON | ACCEPTED | Workflow JSON, n8n_workflow_manager, standards | ERR-012, ERR-013 |

---

## Active Decisions

### ADR-001 — Модульная архитектура из 8 микро-воркфлоу

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Decision owner:** Joint
**Affected workflows/components:** OSINT_01–OSINT_08 (все)
**Related errors:** NONE

#### Context
OSINT-пайплайн требовал выполнения разнородных задач. Монолитный workflow был бы неуправляемым.

#### Decision
Логика разбита на 8 независимых workflow с чёткой зоной ответственности. Взаимодействие — через Execute Workflow и Google Sheets.

#### Rationale
Изоляция ошибок, независимый деплой, удобство отладки. Решение признано удачным и пересмотру не подлежит [6].

#### Alternatives Considered
- Монолитный workflow (отвергнут — неуправляемая отладка)
- Полное переписывание с нуля (отвергнуто) [7]

#### Consequences
**Positive:** изоляция сбоев, параллельная разработка.
**Negative:** сложность сквозной отладки, необходимость строгих контрактов.
**Risks:** рассинхрон форматов данных между workflow.

---

### ADR-002 — DeepSeek как основной LLM-провайдер с разделением flash/pro

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_01, OSINT_05, OSINT_06
**Related errors:** ERR-002, ERR-016

#### Decision
- **deepseek-v4-flash** — для классификации интентов (WF1) [9]
- **deepseek-v4-pro** — для скоринга, аналитики и отчётов (WF5, WF6)

#### Rationale
Flash-модель дёшева и быстра; Pro-модель даёт качество на сложной аналитике [9].

#### Technical Constraints
- System prompt обязан содержать слово "json" (ERR-002)
- Таймауты: 45s flash, 120s pro (ADR-011)
- Retry: 3 попытки

---

### ADR-003 — Google Sheets как operational data store

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_02, OSINT_05, OSINT_06
**Related errors:** ERR-001

#### Decision
Использовать Google Sheets как центральную шину данных с листами `jobs`, `leads`, `companies`, `tenders`, `reports`, `logs`. WF2 пишет с `job_id`, WF5 читает с фильтрацией по `job_id` [9].

#### Consequences
**Positive:** прозрачность, zero-cost.
**Negative:** не транзакционна; риск гонки данных.
**Risks:** пробелы в `job_id` ломают фильтр; при росте нагрузки — миграция на РБД.

---

### ADR-004 — Execute Workflow для межворкфлоу-коммуникации

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** Все workflow

#### Decision
Все межворкфлоу-вызовы — через нативную ноду `Execute Workflow` с передачей `job_id` и контекстных данных.

---

### ADR-005 — Put Output in Field для HTTP Request внутри циклов

**Status:** IMPLEMENTED
**Date:** 2026-07-29 – 2026-07-31
**Affected workflows/components:** OSINT_02 (Serper, Firecrawl)
**Related errors:** ERR-001, ERR-009

#### Decision
Использовать `Put Output in Field`: Serper=`"serperResult"`, Firecrawl=`"firecrawlResult"`. Контекст — из `$input`.

#### Rationale
Нативное решение n8n, исключающее ручное копирование контекста.

#### Alternatives Considered
- `$items("Loop Queries", 0, $runIndex)` — признан хрупким, технический долг (TD-01) [6].

---

### ADR-006 — Gotenberg 8 для генерации PDF

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_06
**Related errors:** ERR-010

#### Decision
Docker-контейнер `gotenberg/gotenberg:8` на сервере Beget. HTML → PDF через `/forms/chromium/convert/html`.

---

### ADR-007 — prepareBinaryData для HTML→binary (Gotenberg)

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_06
**Related errors:** ERR-006, ERR-010

#### Decision
`await this.helpers.prepareBinaryData(html, 'index.html', 'text/html')` в Code-узле `Create HTML Binary`.

#### Supersedes
ADR-021 (Convert to File)

---

### ADR-008 — Sandbox-safe код (отказ от Buffer, crypto, $now)

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** Все Code-узлы
**Related errors:** ERR-006

#### Decision
- `Buffer.from()` → `prepareBinaryData`
- `crypto.randomUUID()` → `Math.random`
- `$now.format()` → `new Date().toISOString()`

---

### ADR-009 — Public API v1 n8n вместо внутреннего REST

**Status:** IMPLEMENTED
**Affected workflows/components:** `n8n_workflow_manager`
**Related errors:** ERR-012

#### Decision
Для программного обновления workflow использовать n8n Public API v1:

`PUT https://xandai.ru/api/v1/workflows/{workflow_id}`

Авторизация выполняется существующим заголовком `X-N8N-API-KEY`. Внутренний маршрут `/rest/workflows` в deployment pipeline не используется.

#### Implementation Evidence
Решение реализовано в фактическом коде `n8n_workflow_manager`.

---

### ADR-010 — PUT deployment contract для обновления workflow

**Status:** IMPLEMENTED
**Affected workflows/components:** `n8n_workflow_manager`
**Related errors:** ERR-012, ERR-013

#### Context
GitHub-файл workflow содержит корневой `id`, необходимый для определения существующего workflow на сервере. Серверные и read-only поля не должны входить в update payload.

#### Decision
Для обновления существующего workflow:

1. Прочитать `workflow_id` из корневого поля `id` GitHub-файла.
2. При отсутствии `id` прекратить deployment с ошибкой.
3. Сформировать endpoint `https://xandai.ru/api/v1/workflows/{workflow_id}`.
4. Создать update payload и удалить из его корня:
   `id`, `versionId`, `active`, `createdAt`, `updatedAt`, `shared`, `tags`, `triggerCount`, `pinData`, `meta`.
5. Выполнить HTTP `PUT`.
6. Только после успешного `PUT` выполнить `git add`, commit и push при наличии изменений.

#### Scope
ADR не изменяет API-ключи, credential IDs, автоматическую подстановку credentials или autofix-механику `n8n_workflow_manager`.

#### Consequences
- GitHub-файл существующего workflow должен сохранять корневой `id`.
- Корневой `id` используется в URL, но не входит в тело `PUT`.
- Git commit не является доказательством успешного deployment без успешного ответа n8n API.

---

### ADR-011 — Retry-политика для LLM API (DeepSeek)

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_01, OSINT_05
**Related errors:** ERR-016

#### Decision
- WF1 (flash): Retry 3×, timeout 45s, wait 1–5s
- WF5 (pro): Retry 3×, timeout 120s, wait 5s [6]

---

### ADR-012 — Отключение Firecrawl для защищённых целей

**Status:** IMPLEMENTED
**Date:** 2026-07-31
**Affected workflows/components:** OSINT_02
**Related errors:** ERR-005

#### Decision
Firecrawl отключён для Avito, Telegram, Profi, Zakupki.gov.ru. Сниппеты Serper/Tavily → DeepSeek.

---

### ADR-013 — Удаление оператора site: из Serper-запросов

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_02

#### Decision
Free-тариф Serper блокирует `site:`. Заменён на семантические ключевые слова.

---

### ADR-014 — Jina embeddings + Pinecone для векторной памяти

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_07
**Related errors:** ERR-011

#### Decision
Jina `jina-embeddings-v3`, 1024d. Pinecone: 3 namespace, `/vectors/upsert`.

---

### ADR-015 — Binary Data Mode = filesystem

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Related errors:** ERR-010

#### Decision
`N8N_BINARY_DATA_MODE=filesystem` в Docker Compose.

---

### ADR-016 — Always Output Data на узлах чтения Google Sheets

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_05, OSINT_06

#### Decision
`alwaysOutputData: true` предотвращает тихие остановки при отсутствии данных.

---

### ADR-017 — IMAP postProcessAction: "read"

**Status:** IMPLEMENTED
**Date:** 2026-07-29
**Affected workflows/components:** OSINT_01

#### Decision
`postProcessAction: "read"` + `customEmailConfig: ["UNSEEN"]` — однократная обработка писем.

---

### ADR-018 — Open WebUI + DeepSeek v4 Pro — главный рабочий контекст

**Status:** ACCEPTED
**Date:** 2026-08-01

#### Decision
Чат Open WebUI с DeepSeek v4 Pro — главный контекст проекта. Консолидация документации — в этом чате.

---

### ADR-019 — Manual Trigger + Code Node для тестирования sub-workflow

**Status:** IMPLEMENTED
**Date:** 2026-07-31
**Affected workflows/components:** OSINT_02
**Related errors:** ERR-004

---

### ADR-020 — Запрет динамических выражений в Sheet Name Google Sheets

**Status:** IMPLEMENTED
**Date:** Июль 2026

#### Decision
Sheet Name — только статические строки. Динамические выражения вызывали нестабильность.

---

### ADR-021 — Convert to File для HTML → Gotenberg

**Status:** SUPERSEDED
**Date:** 2026-07-16
**Superseded by:** ADR-007

---

### ADR-022 — Google AI Studio для доступа к Gemini-моделям

**Status:** IMPLEMENTED
**Date:** Июль 2026

#### Decision
Google AI Studio вместо Google One AI для доступа к Gemini [3].

---

### ADR-023 — Отказ от retry на 429 от Groq

**Status:** IMPLEMENTED
**Date:** Июль 2026

#### Decision
Retry при 429 сжигает квоту. `onError: "continueRegularOutput"` для Groq-узлов.

---

### ADR-024 — Формальные профили workflow JSON

**Status:** ACCEPTED
**Date:** 2026-08-01
**Decision owner:** Principal Architect
**Affected workflows/components:** Все workflow JSON, n8n_workflow_manager, n8n_schema.md, node_templates.md
**Related ADR:** ADR-009, ADR-010
**Related errors:** ERR-012, ERR-013
**Implementation status:** NOT IMPLEMENTED (ожидается обновление стандартов и исправление дублированного `id`)

#### Context
В репозитории сосуществуют несколько JSON-артефактов workflow с разными правилами полей. Фактические данные показали смешанное состояние: 64% узлов имеют `nodes[].id` (UUID), 12% имеют короткие ID, 36% не имеют `nodes[].id` вовсе. Документация `n8n_schema.md` содержала утверждения, противоречащие GitHub-файлам. Требуется формализация контрактов.

#### Decision

##### Profile A — GITHUB_CANONICAL_WORKFLOW (APPROVED)

Для **существующего** workflow:
- Корневой `id`: **REQUIRED** — используется `n8n_workflow_manager` для формирования update endpoint.
- Корневой ключ `id` встречается **ровно один раз**. Дублированные JSON-ключи запрещены.
- `nodes[].id`: **PRESERVE IF PRESENT**.
- При наличии `nodes[].id` должен быть непустым и уникальным в пределах workflow.
- Node ID — непрозрачная строка. UUID и минимальная длина не требуются.
- Connections используют `name` узла, не `id`.
- Server-managed поля (`createdAt`, `updatedAt`, `shared`, `triggerCount`) не сохраняются в GitHub.
- `active`, `versionId`, `pinData`, `meta`, `tags`, `nodeGroups` — сохраняются при наличии.
- Перед update требуется sanitation (см. Profile C).
- Для **нового** workflow (до первого создания): корневой `id` отсутствует. Создание выполняется вручную через UI с последующим экспортом.

##### Profile B — CREATE_PAYLOAD (NOT IMPLEMENTED)

POST-механизм отсутствует. Состав payload не определяется. Новый workflow создаётся вручную через n8n UI → экспорт → добавление в GitHub.

##### Profile C — UPDATE_PAYLOAD (APPROVED)

- HTTP method: `PUT`.
- Endpoint: `https://xandai.ru/api/v1/workflows/{workflow_id}`.
- `workflow_id` читается из корневого `id` Profile A (GitHub-файл).
- Корневой `id` удаляется из тела запроса.
- Blacklist корневых полей (удаляются перед PUT):
  `id`, `versionId`, `active`, `createdAt`, `updatedAt`, `shared`, `tags`, `triggerCount`, `pinData`, `meta`.
- `nodes[].id`: **НЕ УДАЛЯЕТСЯ**. Сохраняется, если присутствует.
- Credentials: автоматическая подстановка до PUT, не затрагивается sanitation.
- `settings`, `connections`, `name`, `nodeGroups` — сохраняются в теле.
- GitHub canonical JSON не является готовым update payload без sanitation.

##### Profile D — SERVER_RESPONSE_OR_EXPORT (REQUIRES EVIDENCE)

Не утверждён. Требуется `GET /api/v1/workflows/{id}` для:
- Подтверждения генерации сервером `nodes[].id` для узлов без них.
- Документирования server-managed полей в ответе.
- Сравнения server node IDs с GitHub node IDs.

#### Consequences
- **Positive:** устранение противоречий; чёткие правила для каждого профиля; документированное смешанное состояние `nodes[].id`.
- **Negative:** Profile D остаётся неподтверждённым; create-механизм не реализован.
- **Risks:** неизвестно, перезаписывает ли сервер `nodes[].id` при PUT. Если да — короткие ID в OSINT_04 могут быть заменены на UUID.

#### Implementation Checklist
- [ ] Обновить `n8n_schema.md` — исправить blacklist и правила `nodes[].id`.
- [ ] Обновить `node_templates.md` — правило `nodes[].id`.
- [ ] Обновить `docs/ARCHITECTURE.md` — строка о JSON profiles.
- [ ] Добавить ADR-024 в `docs/DECISIONS_DRAFT.md`.
- [ ] Исправить дублированный корневой `id` в `OSINT_06_Report_Generator.json`.
- [ ] Выполнить `GET /api/v1/workflows/{id}` для Profile D или исключить из scope.
- [ ] Статус `IMPLEMENTED` после выполнения всех пунктов.

---

## Superseded and Deprecated Decisions

### ADR-021 — Convert to File для HTML → Gotenberg
**Status:** SUPERSEDED
**Superseded by:** ADR-007 (prepareBinaryData)

---

## Rejected Decisions

### REJ-001 — $items() как основной метод сохранения контекста в циклах
**Status:** REJECTED
Признан хрупким паттерном (TD-01).

### REJ-002 — Эмуляция браузерной сессии для деплоя
**Status:** REJECTED
Заменён на ADR-009 (Public API v1).

### REJ-003 — Полное переписывание всех workflow с нуля
**Status:** REJECTED
Слишком рискованно и трудозатратно.

---

## Decision Conflicts

### DC-01: Метод сохранения контекста в WF2
- ADR-005: `putOutputInField`.
- REJ-001: `$items()`.
- Разрешение: ADR-005 принято, $items() — технический долг.

### DC-02: PUT vs PATCH для деплоя — RESOLVED

- **Подтверждённый источник:** фактический код `n8n_workflow_manager`.
- **Решение:** `PUT https://xandai.ru/api/v1/workflows/{workflow_id}`.
- **ADR:** ADR-010 — IMPLEMENTED.
- Упоминания `PATCH` удалены из актуальной документации.

### DC-03: HTML в бинарный файл для Gotenberg
- ADR-021: Convert to File.
- ADR-007: prepareBinaryData.
- Разрешение: ADR-007 заменил ADR-021.

---

## Decisions Requiring Verification

1. ADR-005: сквозной прогон OSINT_02 до Append Lead.
2. ADR-012: calibration dataset для качества скоринга по сниппетам.
3. ADR-011: regression test с симуляцией сетевого сбоя.
4. ADR-022: фактическое использование Gemini в пайплайне.

---

## Missing Decisions

1. Выбор конкретной embedding-модели Jina и размерности 1024.
2. Выбор Tavily как дополнительного поисковика.
3. Политика логирования `Save Successful: none`.
4. Input/output contracts для всех 8 workflow.
5. Определение статусов job (completed/partial/no_results/failed).
