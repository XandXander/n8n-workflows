# DECISIONS.md

> **Status:** APPROVED  
> **Version:** 1.0  
> **Owner:** Open WebUI / AI Engineer  
> **Final approver:** ChatGPT / Principal Architect  
> **Source of truth:** GitHub repository  
> **Workflow JSON baseline:** `8420e423c98dcb1d11fa02f554e0674b9705bb81`  
> **WORKFLOW_MAP baseline:** `ad9e9b92c7d76f76154d4b322f829c70ff1597e1`  
> **ARCHITECTURE baseline:** `ef1abcf42293c67dae068efe88e8b41a15cd9059`  
> **ENVIRONMENT baseline:** `577ff1c47b192451cc4039e9c99b3daed710d8bc`  
> **Compatibility baseline:** n8n `2.32.7`  
> **Current filename:** `docs/DECISIONS_DRAFT.md`  
> **Future canonical filename:** `docs/DECISIONS.md`  
> **Last updated:** 2026-08-02

---

## Purpose

Единый журнал архитектурных и инженерных решений OSINT-платформы XandAI на базе n8n.
Каждое решение зафиксировано с контекстом, обоснованием, альтернативами и последствиями.

---

## ADR Status Legend

| Status | Meaning |
|--------|---------|
| PROPOSED | Предложено, но не принято |
| ACCEPTED | Принято и действует |
| IMPLEMENTED | Принято и полностью реализовано |
| PARTIAL | Принято, но реализовано не полностью или с отклонениями от решения |
| SUPERSEDED | Заменено другим ADR |
| REJECTED | Рассмотрено и отклонено |
| REQUIRES VERIFICATION | Статус IMPLEMENTED или PARTIAL не подтверждён актуальным evidence |
| UNKNOWN | Статус нельзя установить по текущим источникам без дополнительного evidence |

---

## Decision Index

| ID | Решение | Status | Components | Related errors |
|----|---------|--------|------------|----------------|
| ADR-001 | Модульная архитектура из 8 микро-воркфлоу | IMPLEMENTED | Все workflow | NONE |
| ADR-002 | DeepSeek как основной LLM-провайдер (flash/pro split) | IMPLEMENTED | OSINT_01, OSINT_03, OSINT_04, OSINT_05, OSINT_06 | ERR-002, ERR-016 |
| ADR-003 | Google Sheets как operational data store | IMPLEMENTED | OSINT_01, OSINT_02, OSINT_03, OSINT_04, OSINT_05, OSINT_06, OSINT_08 | ERR-001 |
| ADR-004 | Execute Workflow для межворкфлоу-коммуникации | IMPLEMENTED | Все workflow | ERR-004 |
| ADR-005 | Put Output in Field для HTTP Request внутри циклов | PARTIAL | OSINT_02 | ERR-001, ERR-009 |
| ADR-006 | Gotenberg для генерации PDF | PARTIAL | OSINT_06 | ERR-010 |
| ADR-007 | prepareBinaryData для HTML→binary (Gotenberg) | IMPLEMENTED | OSINT_06 | ERR-006, ERR-010 |
| ADR-008 | Sandbox-safe код (отказ от Buffer, crypto, $now) | IMPLEMENTED | Все Code-узлы | ERR-006 |
| ADR-009 | Public API v1 n8n вместо внутреннего REST | IMPLEMENTED | n8n_workflow_manager | ERR-012 |
| ADR-010 | PUT deployment contract для обновления workflow | IMPLEMENTED | n8n_workflow_manager | ERR-012, ERR-013 |
| ADR-011 | Retry-политика для LLM API (DeepSeek) | PARTIAL | OSINT_01, OSINT_03, OSINT_04, OSINT_05 | ERR-016 |
| ADR-012 | Отключение Firecrawl для защищённых целей | UNKNOWN | OSINT_02 | ERR-005 |
| ADR-013 | Удаление оператора site: из Serper-запросов | IMPLEMENTED | OSINT_02 | NONE |
| ADR-014 | Jina embeddings + Pinecone для векторной памяти | IMPLEMENTED | OSINT_07 | ERR-011 |
| ADR-015 | Binary Data Mode = filesystem | REQUIRES VERIFICATION | Серверная конфигурация | ERR-010 |
| ADR-016 | Always Output Data на узлах чтения Google Sheets | IMPLEMENTED | OSINT_02, OSINT_05, OSINT_06 | NONE |
| ADR-017 | IMAP postProcessAction: "read" | UNKNOWN | OSINT_01 | NONE |
| ADR-018 | Open WebUI + DeepSeek v4 Pro — главный рабочий контекст | UNKNOWN | Процесс разработки | NONE |
| ADR-019 | Manual Trigger + Code Node для тестирования sub-workflow | UNKNOWN | OSINT_02 | ERR-004 |
| ADR-020 | Запрет динамических выражений в Sheet Name Google Sheets | REJECTED | OSINT_05 | NONE |
| ADR-021 | Convert to File для HTML → Gotenberg | SUPERSEDED | OSINT_06 | ERR-010 |
| ADR-022 | Google AI Studio для доступа к Gemini-моделям | UNKNOWN | Внешние API | NONE |
| ADR-023 | Отказ от retry на 429 от Groq (continueRegularOutput) | PARTIAL | OSINT_08 | NONE |
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
Изоляция ошибок, независимый деплой, удобство отладки. Решение признано удачным и пересмотру не подлежит.

#### Alternatives Considered
- Монолитный workflow (отвергнут — неуправляемая отладка)
- Полное переписывание с нуля (отвергнуто)

#### Consequences
**Positive:** изоляция сбоев, параллельная разработка.
**Negative:** сложность сквозной отладки, необходимость строгих контрактов.
**Risks:** рассинхрон форматов данных между workflow.

#### Evidence
CONFIRMED BY JSON: восемь канонических workflow-файлов в `workflows/OSINT_*.json`.

---

### ADR-002 — DeepSeek как основной LLM-провайдер с разделением flash/pro

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_01, OSINT_03, OSINT_04, OSINT_05, OSINT_06
**Related errors:** ERR-002, ERR-016

#### Decision
- **deepseek-v4-flash** — для классификации интентов (WF1), анализа тендеров (WF4)
- **deepseek-v4-pro** — для анализа компаний (WF3), скоринга (WF5) и отчётов (WF6)

#### Rationale
Flash-модель дёшева и быстра; Pro-модель даёт качество на сложной аналитике.

#### Technical Constraints
- System prompt обязан содержать слово "json" (ERR-002)
- Таймауты: 45s flash, 120s pro (ADR-011)
- Retry: 3 попытки

#### Evidence
CONFIRMED BY JSON: все пять workflow содержат HTTP Request узлы к `api.deepseek.com/v1/chat/completions` с указанными моделями. WORKFLOW_MAP.md подтверждает распределение моделей по workflow.

---

### ADR-003 — Google Sheets как operational data store

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_01, OSINT_02, OSINT_03, OSINT_04, OSINT_05, OSINT_06, OSINT_08
**Related errors:** ERR-001

#### Decision
Использовать Google Sheets как центральную шину данных с листами `jobs`, `leads`, `companies`, `tenders`, `reports`, `logs`. WF1/2/3/4/6/8 пишут; WF5/6 читают с фильтрацией по `job_id`.

#### Consequences
**Positive:** прозрачность, zero-cost.
**Negative:** не транзакционна; риск гонки данных.
**Risks:** пробелы в `job_id` ломают фильтр; при росте нагрузки — миграция на РБД.

#### Evidence
CONFIRMED BY JSON: все Google Sheets узлы ссылаются на один document ID. WORKFLOW_MAP.md §4 детализирует writers/readers для каждого листа.

---

### ADR-004 — Execute Workflow для межворкфлоу-коммуникации

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** Все workflow

#### Decision
Все межворкфлоу-вызовы — через нативную ноду `Execute Workflow` с передачей `job_id` и контекстных данных.

#### Evidence
CONFIRMED BY JSON: 12 подтверждённых Execute Workflow connections. WORKFLOW_MAP.md §3 и ARCHITECTURE.md §7 документируют invocation contract.

---

### ADR-005 — Put Output in Field для HTTP Request внутри циклов

**Status:** PARTIAL
**Date:** 2026-07-29 – 2026-07-31
**Affected workflows/components:** OSINT_02 (Serper, Firecrawl)
**Related errors:** ERR-001, ERR-009

#### Decision
Использовать `Put Output in Field`: Serper=`"serperResult"`, Firecrawl=`"firecrawlResult"`. Контекст — из `$input`.

#### Rationale
Нативное решение n8n, исключающее ручное копирование контекста.

#### Alternatives Considered
- `$items("Loop Queries", 0, $runIndex)` — признан хрупким, технический долг (TD-01).

#### Partial Status Rationale
Решение реализовано, но код всё ещё содержит `$items(..., $runIndex)` fallback и `.item` fallback для восстановления контекста. Остаточный технический долг не устранён.

#### Evidence
CONFIRMED BY JSON: параметры `putOutputInField` присутствуют в `Serper Search` и `Firecrawl Scrape`. Fallback-паттерны подтверждены в `Extract URLs`, `Extract Contacts` и `Enrich Tender`.

---

### ADR-006 — Gotenberg для генерации PDF

**Status:** PARTIAL
**Date:** Июль 2026
**Affected workflows/components:** OSINT_06, OSINT_08
**Related errors:** ERR-010

#### Decision
Использовать Gotenberg для HTML → PDF через `/forms/chromium/convert/html`.

#### Partial Status Rationale
Внутренний URL `http://gotenberg:3000/forms/chromium/convert/html` подтверждён в каноническом JSON. Однако конкретный образ Gotenberg (image tag) не подтверждён текущим evidence — ENVIRONMENT.md фиксирует image tag как UNKNOWN.

#### Evidence
CONFIRMED BY JSON: internal URL в WF6 и WF8. ENVIRONMENT.md §4: image tag — UNKNOWN.

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

#### Evidence
CONFIRMED BY JSON: узел `Create HTML Binary` содержит вызов `this.helpers.prepareBinaryData`.

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

#### Evidence
CONFIRMED BY JSON: все Code-узлы используют разрешённые паттерны. Запрещённые вызовы отсутствуют.

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
Решение реализовано в фактическом коде `n8n_workflow_manager`. Контракт синхронизирован с ARCHITECTURE.md §12 и ENVIRONMENT.md §8.

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

#### Evidence
Контракт синхронизирован с ARCHITECTURE.md §12, ENVIRONMENT.md §8 и ADR-024.

---

### ADR-011 — Retry-политика для LLM API (DeepSeek)

**Status:** PARTIAL
**Date:** Июль 2026
**Affected workflows/components:** OSINT_01, OSINT_03, OSINT_04, OSINT_05
**Related errors:** ERR-016

#### Decision
- WF1 (flash): Retry 3×, timeout 45s, wait 1–5s
- WF3 (pro): Retry 3×, timeout 120s, wait 2s
- WF4 (flash): Retry 3×, timeout 120s, wait 2s
- WF5 (pro): Retry 3×, timeout 120s, wait 5s

#### Partial Status Rationale
Параметры retry подтверждены в каноническом JSON для всех четырёх workflow. Однако WF6 (DeepSeek Generate MD, pro) не имеет retry-конфигурации, но использует DeepSeek. Решение не охватывает WF6.

#### Evidence
CONFIRMED BY JSON: параметры `retryOnFail`, `maxTries`, `retryWaitTime` и `timeout` подтверждены в WF1, WF3, WF4, WF5. WORKFLOW_MAP.md подтверждает отсутствие retry в WF6 DeepSeek Generate MD.

---

### ADR-012 — Отключение Firecrawl для защищённых целей

**Status:** UNKNOWN
**Date:** 2026-07-31
**Affected workflows/components:** OSINT_02
**Related errors:** ERR-005

#### Decision
Firecrawl отключён для Avito, Telegram, Profi, Zakupki.gov.ru. Сниппеты Serper/Tavily → DeepSeek.

#### Unknown Status Rationale
Наличие Firecrawl-узлов в каноническом JSON подтверждено. Логика exclusion (какие URL исключаются) недоказуема статическим анализом JSON — требует runtime evidence или явного кода фильтрации. В текущем WF2 `Extract URLs` и WF4 нет явного exclusion-фильтра для перечисленных доменов.

#### Evidence
UNKNOWN: exclusion logic не подтверждена статическим JSON. Требуется runtime evidence.

---

### ADR-013 — Удаление оператора site: из Serper-запросов

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_02

#### Decision
Free-тариф Serper блокирует `site:`. Заменён на семантические ключевые слова.

#### Evidence
CONFIRMED BY JSON: query matrix в WF2 `Build Query Matrix` не содержит `site:` оператора.

---

### ADR-014 — Jina embeddings + Pinecone для векторной памяти

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_07
**Related errors:** ERR-011

#### Decision
Jina `jina-embeddings-v3`, 1024d. Pinecone: 3 namespace, операции `upsert`, `query`, `delete`.
Jina tasks: `retrieval.passage` (upsert), `retrieval.query` (query).

#### Evidence
CONFIRMED BY JSON: WF7 содержит все три операции. WORKFLOW_MAP.md §11 документирует input/output contracts и embedding-конфигурацию.

---

### ADR-015 — Binary Data Mode = filesystem

**Status:** REQUIRES VERIFICATION
**Date:** Июль 2026
**Related errors:** ERR-010

#### Decision
`N8N_BINARY_DATA_MODE=filesystem` в Docker Compose.

#### Requires Verification Rationale
WF6 использует `prepareBinaryData` + HTTP Request с `responseFormat: file`, что совместимо с filesystem mode. Однако значение `N8N_BINARY_DATA_MODE` не подтверждено текущим live evidence. ENVIRONMENT.md §11: Binary data mode — UNKNOWN.

#### Evidence
CONFIRMED BY JSON: подготовка binary data в WF6 Create HTML Binary и Gotenberg to PDF. LIVE DATA: отсутствует — глобальная конфигурация не верифицирована.

---

### ADR-016 — Always Output Data на узлах чтения Google Sheets

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_02, OSINT_05, OSINT_06

#### Decision
`alwaysOutputData: true` предотвращает тихие остановки при отсутствии данных.

#### Evidence
CONFIRMED BY JSON: параметр присутствует в `Serper Search` (WF2), `Read Entities` (WF5), `Read Qualified Entities` (WF6).

---

### ADR-017 — IMAP postProcessAction: "read"

**Status:** UNKNOWN
**Date:** 2026-07-29
**Affected workflows/components:** OSINT_01
**Related errors:** NONE

#### Decision (original)
Утверждалось: `postProcessAction: "read"` + `customEmailConfig: ["UNSEEN"]` — однократная обработка писем.

#### Unknown Status Rationale
WORKFLOW_MAP.md §5 подтверждает: `postProcessAction` не обнаружен в каноническом JSON OSINT_01. Подтверждённые IMAP параметры: `customEmailConfig: ["UNSEEN"]`, `forceReconnect: 60`. Статус решения не может быть установлен без дополнительного evidence.

#### Evidence
CONFIRMED BY JSON: `customEmailConfig: ["UNSEEN"]`, `forceReconnect: 60`. UNKNOWN: наличие `postProcessAction` на сервере после импорта.

---

### ADR-018 — Open WebUI + DeepSeek v4 Pro — главный рабочий контекст

**Status:** UNKNOWN
**Date:** 2026-08-01
**Affected workflows/components:** Процесс разработки

#### Decision
Чат Open WebUI с DeepSeek v4 Pro — главный контекст проекта. Консолидация документации — в этом чате.

#### Unknown Status Rationale
Решение процессное, не имеет JSON-артефактов для верификации. Статус не может быть подтверждён или опровергнут статическим evidence.

#### Evidence
UNKNOWN: процессное решение, неверифицируемо через SSOT.

---

### ADR-019 — Manual Trigger + Code Node для тестирования sub-workflow

**Status:** UNKNOWN
**Date:** 2026-07-31
**Affected workflows/components:** OSINT_02
**Related errors:** ERR-004

#### Decision
Использовать Manual Trigger + Code Node для тестирования sub-workflow.

#### Unknown Status Rationale
Наличие Manual Trigger в каноническом JSON OSINT_02 не подтверждено текущим evidence. WORKFLOW_MAP.md не документирует Manual Trigger как entry point WF2.

#### Evidence
UNKNOWN: требует verification через актуальный JSON и WORKFLOW_MAP.

---

### ADR-020 — Запрет динамических выражений в Sheet Name Google Sheets

**Status:** REJECTED
**Date:** Июль 2026
**Affected workflows/components:** OSINT_05
**Related errors:** NONE

#### Decision (original — REJECTED)
Sheet Name — только статические строки. Динамические выражения вызывали нестабильность.

#### Rejection Rationale
WF5 `Read Entities` и `Update Row` используют динамические выражения для sheetName:
`={{ $('Set Job Vars').first().json.entity_type === 'company' ? 'companies' : (...) }}`.
Динамические выражения в Sheet Name являются частью текущего контракта WF5.

#### Evidence
CONFIRMED BY JSON: динамические выражения в `sheetName` параметрах WF5. WORKFLOW_MAP.md §9 подтверждает dynamic sheet selection.

---

### ADR-021 — Convert to File для HTML → Gotenberg

**Status:** SUPERSEDED
**Date:** 2026-07-16
**Superseded by:** ADR-007 (prepareBinaryData)
**Affected workflows/components:** OSINT_06

---

### ADR-022 — Google AI Studio для доступа к Gemini-моделям

**Status:** UNKNOWN
**Date:** Июль 2026
**Affected workflows/components:** Внешние API

#### Decision
Google AI Studio вместо Google One AI для доступа к Gemini.

#### Unknown Status Rationale
Gemini не обнаружен в каноническом workflow JSON (базовый коммит `8420e42`). Ни один из восьми workflow не содержит HTTP Request к Gemini/Google AI Studio endpoint.

#### Evidence
UNKNOWN: отсутствие Gemini в каноническом JSON. Требуется подтверждение использования через внешние инструменты или отдельную конфигурацию.

---

### ADR-023 — Отказ от retry на 429 от Groq (continueRegularOutput)

**Status:** PARTIAL
**Date:** Июль 2026
**Affected workflows/components:** OSINT_08
**Related errors:** NONE

#### Decision
Retry при 429 сжигает квоту. `onError: "continueRegularOutput"` для Groq-узлов.

#### Partial Status Rationale
WF8 `Groq Whisper STT` не имеет явного `onError: continueRegularOutput`. Однако retry не сконфигурирован (retryOnFail отсутствует), что частично соответствует решению. WF1 использует `onError: continueRegularOutput` на Execute Workflow узлах, но не на Groq-узлах напрямую.

#### Evidence
CONFIRMED BY JSON: WF8 Groq Whisper STT не имеет retryOnFail. WORKFLOW_MAP.md §12: Groq используется только в WF8.

---

### ADR-024 — Формальные профили workflow JSON

**Status:** ACCEPTED
**Date:** 2026-08-01
**Decision owner:** Principal Architect
**Affected workflows/components:** Все workflow JSON, n8n_workflow_manager, standards
**Related ADR:** ADR-009, ADR-010
**Related errors:** ERR-012, ERR-013

#### Context
В репозитории сосуществуют несколько JSON-артефактов workflow с разными правилами полей. Фактические данные показали смешанное состояние: 64% узлов имеют `nodes[].id` (UUID), 12% имеют короткие ID, 36% не имеют `nodes[].id` вовсе. Требовалась формализация контрактов.

#### Decision

Decision status: **ACCEPTED**
Implementation scope: **COMPLETE**
Architectural block: **CLOSED**

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

##### Profile D — SERVER_RESPONSE_OR_EXPORT (REQUIRES EVIDENCE — NON-BLOCKING)

Не утверждён. Требуется `GET /api/v1/workflows/{id}` для:
- Подтверждения генерации сервером `nodes[].id` для узлов без них.
- Документирования server-managed полей в ответе.
- Сравнения server node IDs с GitHub node IDs.

**Profile D не блокирует:**
- Profile A;
- Profile C;
- текущий update pipeline;
- канонизацию журнала;
- дальнейшую инженерную работу.

#### Consequences
- **Positive:** устранение противоречий; чёткие правила для каждого профиля; документированное смешанное состояние `nodes[].id`.
- **Negative:** Profile D остаётся неподтверждённым; create-механизм не реализован.
- **Risks:** неизвестно, перезаписывает ли сервер `nodes[].id` при PUT. Если да — короткие ID в OSINT_04 могут быть заменены на UUID.

#### Implementation Evidence
- [x] `docs/standards/n8n_schema.md` — создан и синхронизирован.
- [x] `docs/standards/node_templates.md` — создан и синхронизирован.
- [x] `docs/ARCHITECTURE.md` §13 — Workflow JSON Artifact Profiles.
- [x] `docs/DECISIONS_DRAFT.md` — ADR-024 присутствует.
- [x] `workflows/OSINT_06_Report_Generator.json` — дублированный root `id` исправлен.
- [ ] Profile D server response/export evidence — NON-BLOCKING.

---

## Superseded and Deprecated Decisions

### ADR-021 — Convert to File для HTML → Gotenberg
**Status:** SUPERSEDED
**Superseded by:** ADR-007 (prepareBinaryData)

---

## Rejected Decisions

### ADR-020 — Запрет динамических выражений в Sheet Name Google Sheets
**Status:** REJECTED
Динамические выражения в Sheet Name являются частью текущего контракта WF5.

### REJ-002 — Эмуляция браузерной сессии для деплоя
**Status:** REJECTED
Заменён на ADR-009 (Public API v1).

---

## Open Decisions

1. **ADR-015 — Binary Data Mode.** Требуется live evidence значения `N8N_BINARY_DATA_MODE` на сервере n8n 2.32.7 для подтверждения или пересмотра статуса.
2. **ADR-012 — Firecrawl exclusion.** Требуется runtime evidence или явный код фильтрации для подтверждения exclusion logic.
3. **ADR-005 — Контекст в циклах.** Остаточный технический долг: `$items(..., $runIndex)` fallback и `.item` fallback требуют устранения для перехода к IMPLEMENTED.

---

## Non-Blocking Evidence Debt

Следующие ADR имеют статус UNKNOWN или REQUIRES VERIFICATION, но не блокируют текущий development и deployment pipeline:

| ADR | Статус | Что требуется | Блокирует ли pipeline |
|-----|--------|---------------|----------------------|
| ADR-012 | UNKNOWN | Runtime evidence exclusion logic | Нет |
| ADR-015 | REQUIRES VERIFICATION | Live evidence N8N_BINARY_DATA_MODE | Нет |
| ADR-017 | UNKNOWN | Актуальный JSON/server evidence postProcessAction | Нет |
| ADR-018 | UNKNOWN | Процессное решение, неверифицируемо через SSOT | Нет |
| ADR-019 | UNKNOWN | Verification Manual Trigger в JSON | Нет |
| ADR-022 | UNKNOWN | Подтверждение использования Gemini | Нет |
| ADR-024 Profile D | REQUIRES EVIDENCE | GET /api/v1/workflows/{id} | Нет — NON-BLOCKING |

---

## Technical Debt and Conflicts — Not ADRs

Перечисленные ниже пункты являются зафиксированными проблемами, а не архитектурными решениями. Они не имеют статусов ADR.

### TD-01 — $items() fallback в циклах
**Source:** ADR-005 alternatives.
**Description:** `$items("Loop Queries", 0, $runIndex)` и `.item` fallback используются для восстановления контекста.
**Status:** Зафиксирован, не исправлен.
**Affected:** WF2, WF4.

### TD-02 — WF1 → WF2 missing intent
**Source:** WORKFLOW_MAP.md §13, ARCHITECTURE.md CONFLICT-ARCH-001.
**Description:** WF1 не передаёт `intent` в WF2. WF2 defaults to `search_private`.

### TD-03 — WF1 → WF3 serialized entities
**Source:** WORKFLOW_MAP.md §13, ARCHITECTURE.md CONFLICT-ARCH-002.
**Description:** WF1 передаёт `entities` как serialized string, WF3 обращается как к объекту.

### TD-04 — WF2 Serper response path mismatch
**Source:** WORKFLOW_MAP.md §13, ARCHITECTURE.md CONFLICT-ARCH-004.
**Description:** `Serper Search` сохраняет ответ в `serperResult`, `Extract URLs` читает root-level `organic`.

### TD-05 — WF6 qualified-count semantics
**Source:** WORKFLOW_MAP.md §13, ARCHITECTURE.md CONFLICT-ARCH-005.
**Description:** `Read Qualified Entities` не фильтрует `status=qualified`. `qualified` считает все непустые сущности.

---

## Evidence Classification

| Class | Meaning |
|-------|---------|
| CONFIRMED BY JSON | Подтверждено актуальным каноническим workflow JSON |
| CONFIRMED BY LIVE DATA | Подтверждено runtime или server evidence |
| CONFIRMED BY LOGS | Подтверждено логами выполнения |
| UNKNOWN | Текущие источники не подтверждают факт |
| CONFLICT | Два подтверждённых представления несовместимы |

---

## Verification Checklist

- [x] Decision Index содержит ровно 24 записи (ADR-001 – ADR-024).
- [x] Все статусы соответствуют утверждённой матрице.
- [x] ADR-009 синхронизирован с Public API v1 contract.
- [x] ADR-010 синхронизирован с sanitized PUT contract.
- [x] ADR-024: Decision status ACCEPTED, Implementation scope COMPLETE, Architectural block CLOSED.
- [x] Profile D: NON-BLOCKING.
- [x] Исторические неподтверждённые ссылки удалены.
- [x] Три Open Decisions задокументированы.
- [x] Non-Blocking Evidence Debt задокументирован.
- [x] Technical Debt отделён от ADR.
- [x] Secret values excluded.
- [ ] Related ERR identifiers верифицированы через error journal.
- [ ] ADR-015 live evidence собрано.
- [ ] ADR-012 runtime evidence собрано.
- [ ] ADR-024 Profile D server response evidence собрано.
