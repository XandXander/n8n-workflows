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
| ADR-009 | Public API v1 n8n вместо внутреннего REST | IMPLEMENTED | n8n_git_manager | ERR-012 |
| ADR-010 | PUT метод для деплоя workflow | IMPLEMENTED | n8n_git_manager | ERR-012, ERR-013 |
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
**Date:** Июль 2026
**Affected workflows/components:** n8n_git_manager
**Related errors:** ERR-012

#### Decision
Маршруты: `/rest/workflows` → `/api/v1/workflows/{id}`. Авторизация: `X-N8N-API-KEY` [20].

#### Alternatives Considered
- Эмуляция браузерной сессии (REJ-002) [20].

---

### ADR-010 — PUT метод для деплоя workflow

**Status:** IMPLEMENTED
**Date:** Июль 2026
**Affected workflows/components:** n8n_git_manager
**Related errors:** ERR-012, ERR-013

#### Decision
PUT для полного обновления схемы. Чёрный список полей: `id, versionId, active, createdAt, updatedAt, shared, tags, triggerCount, pinData, meta`.

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

### DC-02: PUT vs PATCH для деплоя
- ENVIRONMENT.md: PATCH.
- DECISIONS7.md: PUT (ADR-010).
- Разрешение: PUT — текущий метод.

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
