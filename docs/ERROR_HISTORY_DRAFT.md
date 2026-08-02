# ERROR_HISTORY.md

## Purpose
Единый журнал всех подтверждённых инцидентов, расследований, исправлений и результатов проверки OSINT-платформы XandAI на базе n8n. Этот документ — единственный источник истины (Single Source of Truth) для истории ошибок проекта.

## Status Legend
| Status | Meaning |
|--------|---------|
| CONFIRMED | Причина подтверждена логами или успешным исправлением |
| PROBABLE | Наиболее вероятная причина, подтверждение неполное |
| UNRESOLVED | Причина не установлена |
| OBSOLETE | Ошибка относилась к старой версии системы / более неактуальна |
| REGRESSION | Ранее исправленная ошибка повторилась |

## Severity Legend
| Severity | Meaning |
|----------|---------|
| CRITICAL | Полная остановка пайплайна, потеря данных, недоставка отчётов клиенту |
| HIGH | Частичная потеря данных, блокировка ключевой ветки, требует немедленного исправления |
| MEDIUM | Деградация функциональности, обходной путь существует |
| LOW | Косметический дефект, не влияет на core-функциональность |

## Incident Index
| ID | Название | Workflow | Severity | Status |
|----|----------|----------|----------|--------|
| ERR-001 | Потеря контекста итерации (query/job_id/source_platform) при прохождении HTTP Request узлов | OSINT_02 | CRITICAL | CONFIRMED |
| ERR-002 | DeepSeek возвращает intent:error из-за отсутствия слова "json" в system prompt | OSINT_01, OSINT_06 | HIGH | CONFIRMED |
| ERR-003 | Сбой классификатора из-за префикса "OSINT-AI:" в сообщении пользователя | OSINT_01 | MEDIUM | CONFIRMED |
| ERR-004 | Невозможность ручного тестирования Sub-workflow через Execute Workflow Trigger | OSINT_02 | LOW | CONFIRMED |
| ERR-005 | Firecrawl возвращает "Access Denied" для защищённых ресурсов (Avito, Telegram, Zakupki) | OSINT_02 | HIGH | CONFIRMED |
| ERR-006 | Buffer.from() недоступен в Code-узлах (Task Runner Sandbox) | Любой workflow с Code | MEDIUM | CONFIRMED |
| ERR-007 | Доступ к $json.headers.subject вместо $json.subject в IMAP-триггере | Email-triggered workflow | MEDIUM | CONFIRMED |
| ERR-008 | Filter Empty блокирует все URL после Extract URLs | OSINT_02 | HIGH | CONFIRMED |
| ERR-009 | $('Node').item после SplitInBatches возвращает пустой объект | OSINT_02 | HIGH | CONFIRMED |
| ERR-010 | Gotenberg: несовместимый формат данных — ожидает binary index.html, получает json.html | OSINT_06 | HIGH | CONFIRMED |
| ERR-011 | Pinecone upsert возвращает 404/400 | OSINT_07 (ранняя версия) | HIGH | CONFIRMED |
| ERR-012 | Unauthorized при вызове внутреннего API n8n (/rest/workflows) | n8n_git_manager (деплой) | CRITICAL | CONFIRMED |
| ERR-013 | 400 Bad Request: запрещённые поля и ID узлов в генерируемом JSON | Все workflow (деплой) | HIGH | CONFIRMED |
| ERR-014 | Массовый сбой после импорта LLM-сгенерированных JSON (несовместимость с n8n 2.29.10) | WF2, WF3, WF4, WF5, WF6 | CRITICAL | OBSOLETE |
| ERR-015 | Paired item data is unavailable после Loop (SplitInBatches) | OSINT_04 | MEDIUM | CONFIRMED |
| ERR-016 | DeepSeek API: ECONNRESET / ECONNABORTED (timeout) | OSINT_01, OSINT_05 | HIGH | CONFIRMED |

---

## Confirmed Incidents

### ERR-001 — Потеря контекста итерации (query/job_id/source_platform) при прохождении HTTP Request узлов

**Status:** CONFIRMED
**Date:** 2026-07-29 – 2026-07-31
**Affected workflow:** OSINT_02_Search_Engine
**Affected nodes/components:** `Loop Queries` → `Serper Search` → `Extract URLs` → `Loop URLs` → `Firecrawl Scrape` → `Extract Contacts`
**Environment/version:** n8n 2.29.10 – 2.31.6
**Severity:** CRITICAL

#### Symptom
Таблица `leads` оставалась пустой. Узел `Extract URLs` записывал `source_platform: "unknown"`, `query: ""`. Затирался `job_id`. После Firecrawl узел `Extract Contacts` выдавал `No output data`; `Append Lead` получал 0 items.

#### Evidence
- Логи `Extract URLs`: поля `source_platform` = `"unknown"`, `query` = `""`
- `Append Lead`: 0 rows written to `leads` sheet
- Пример job_id: `job_ms7vw2on_eccp5jut`
- Serper возвращал 5 реальных organic-результатов, но контекст терялся

#### Investigation
Проверяли:
- Использование `$('Loop Queries').context.currentItem`
- Замену на `$('Loop Queries').first()?.json`
- `$('Loop URLs').first()?.json`
- Деплой настройки `putOutputInField` через Git
- Использование `staticData`
- `$items("Loop Queries", 0, $runIndex)[0].json`

#### Wrong Assumptions
- Текущий item цикла можно получить через `$('Loop Queries').context.currentItem`
- `.first()?.json` восстановит контекст
- `.all()[0]` вернёт данные текущей итерации (возвращал пустые объекты или смешанный контекст)
- `putOutputInField` надёжно сохраняется — ручное переподключение узлов в UI n8n затирало эту настройку в базе
- `staticData` безопасен — отвергнут из-за риска Race Condition

#### Root Cause
Дефолтное поведение узла HTTP Request в n8n — полная замена `item.json` телом ответа API. При вызове Serper и Firecrawl входящий `$json` (содержащий `job_id`, `query`, `source_platform`) полностью перезаписывался ответом поискового API.

#### Fix
**Принятое решение (ADR-005):** Использовать встроенную настройку HTTP Request `Put Output in Field`:
- Serper Search: `putOutputInField` = `"serperResult"`
- Firecrawl Scrape: `putOutputInField` = `"scrapeResult"` (также упоминается как `"firecrawlResult"`)
- Downstream Code-узлы читают ответ из вложенного поля, контекст — из корня `$input`

**Примечание:** В коде также присутствует конструкция `$items("Loop Queries", 0, $runIndex)[0].json` как legacy-паттерн (TD-01).

#### Verification
Частично. Успешный сквозной прогон до `Append Lead` на момент фиксации не был подтверждён. Отдельные компоненты работают.

#### Prevention Rule
Все HTTP Request узлы внутри циклов (SplitInBatches/Loop) должны использовать `Put Output in Field` для сохранения исходного контекста итерации.

#### Regression Test
Запустить сквозной прогон OSINT_02 с тестовым job_id; проверить, что `source_platform`, `query`, `job_id` корректно записаны в Google Sheets `leads` во всех строках.

#### Related ADR
ADR-005 — Put Output in Field

#### Related Files
- `OSINT_02_Search_Engine.json`
- Google Sheets: `leads`

#### Source Notes
ERROR_HISTORY.md (id=1), ERROR_HISTORY5.md (id=15), ERROR_HISTORY3.md (id=20), ERROR_HISTORY6.md (id=11), ERROR_HISTORY7.md (id=10), ERROR_HISTORY (1).md (id=24), DECISIONS3.md (id=16), DECISIONS4.md (id=12), DECISIONS (1).md (id=23)

---

### ERR-002 — DeepSeek возвращает intent:error из-за отсутствия слова "json" в system prompt

**Status:** CONFIRMED
**Date:** 2026-07-28
**Affected workflow:** OSINT_01 (DeepSeek Intent Classifier), OSINT_06 (DeepSeek Generate MD)
**Affected nodes/components:** HTTP Request → DeepSeek API (`/v1/chat/completions`)
**Environment/version:** DeepSeek API (v4-flash, v4-pro)
**Severity:** HIGH

#### Symptom
`400 Bad Request` от DeepSeek API с сообщением: `Prompt must contain the word 'json' in some form to use 'response_format' of type 'json_object'`. Пайплайн падал на этапе классификации интента.

#### Evidence
HTTP 400: `"Prompt must contain the word 'json' in some form to use 'response_format' of type 'json_object'"`

#### Root Cause
DeepSeek API требует буквального наличия слова "json" (в любой форме) в system prompt при использовании `response_format: { type: "json_object" }`.

#### Fix
В начало system prompt добавлена фраза `You must respond with a JSON object.`

#### Verification
Запросы к DeepSeek с обновлённым system prompt возвращают корректный JSON без ошибки 400.

#### Prevention Rule
Все system prompt'ы для DeepSeek с `response_format: json_object` должны содержать слово "json" в явном виде.

#### Related ADR
NONE

---

### ERR-003 — Сбой классификатора из-за префикса "OSINT-AI:" в сообщении пользователя

**Status:** CONFIRMED
**Date:** 2026-07-31
**Affected workflow:** OSINT_01 (Parse Intent)
**Severity:** MEDIUM

#### Symptom
Telegram-бот прислал Alert: `intent: error, entities: ОШИБКА`. Классификатор не мог определить intent при наличии префикса "OSINT-AI:" в сообщении.

#### Root Cause
Модель deepseek-v4-flash запуталась из-за нестандартного префикса "OSINT-AI:" в сочетании со строгими фолбэками в коде ноды `Parse Intent`.

#### Fix
Дополнен System Prompt: добавлено указание игнорировать префиксы и обращения при классификации интента.

#### Verification
Запрос с префиксом "OSINT-AI:" обработан корректно.

---

### ERR-004 — Невозможность ручного тестирования Sub-workflow через Execute Workflow Trigger

**Status:** CONFIRMED
**Date:** 2026-07-31
**Affected workflow:** OSINT_02
**Severity:** LOW

#### Symptom
При запуске изолированного теста через Execute Workflow Trigger все поля возвращали `null`.

#### Root Cause
Баг/особенность версии n8n 2.31.6 при мокировании входящих данных для sub-workflow.

#### Fix
Временное добавление ноды `Manual Trigger` и `Code Node` с хардкодом тестового JSON-объекта.

#### Verification
Изолированный тест с Manual Trigger + Code Node — данные передаются корректно [19].

---

### ERR-005 — Firecrawl возвращает "Access Denied" для защищённых ресурсов

**Status:** CONFIRMED
**Date:** 2026-07-31
**Affected workflow:** OSINT_02
**Severity:** HIGH

#### Symptom
Для ресурсов Avito, Telegram, Profi.ru, Zakupki.gov.ru Firecrawl возвращал "Access Denied" или Cloudflare-капчу. LLM галлюцинировал контактные данные.

#### Root Cause
Целевые платформы используют Enterprise/Gov-level антибот-защиту (Cloudflare, GOST-шифрование).

#### Fix
Firecrawl отключён для защищённых платформ. Данные передаются через title+snippet от Serper/Tavily.

#### Related ADR
ADR-012

---

### ERR-006 — Buffer.from() недоступен в Code-узлах (Task Runner Sandbox)

**Status:** CONFIRMED
**Date:** Июль 2026
**Affected workflow:** Любой workflow с Code
**Severity:** MEDIUM

#### Symptom
`ReferenceError: Buffer is not defined`

#### Root Cause
Task Runner Sandbox изолирует выполнение JavaScript. `Buffer` — Node.js API, недоступное в Sandbox.

#### Fix
Замена на `this.helpers.prepareBinaryData`. Отказ от `crypto.randomUUID()` в пользу `Math.random`.

#### Related ADR
ADR-008

---

### ERR-007 — Доступ к $json.headers.subject вместо $json.subject в IMAP-триггере

**Status:** CONFIRMED
**Date:** Июль 2026
**Severity:** MEDIUM

#### Symptom
Фильтр темы письма не срабатывает. Письма с темой «OSINT-AI: ...» не запускают workflow.

#### Root Cause
IMAP-нода n8n парсит тему в корень `$json.subject`, а не в `$json.headers.subject`.

#### Fix
`$json.subject contains "OSINT-AI"` [11].

---

### ERR-008 — Filter Empty блокирует все URL после Extract URLs

**Status:** CONFIRMED
**Date:** 2026-07-18
**Affected workflow:** OSINT_02
**Severity:** HIGH

#### Symptom
`Filter Empty` отсеивает все элементы, несмотря на наличие поля `url` в логах.

#### Fix
Включён `looseTypeValidation` в Filter Empty.

---

### ERR-009 — $('Node').item после SplitInBatches возвращает пустой объект

**Status:** CONFIRMED
**Date:** 2026-07-18 – 2026-07-20
**Affected workflow:** OSINT_02
**Severity:** HIGH

#### Symptom
В Code-узлах переменная `cur` получалась пустой (`{}`), терялись `job_id`, `query`, `source_platform`.

#### Root Cause
После `SplitInBatches` контекст pairedItem теряется в n8n 2.31.6.

#### Fix
Использовать `$input.first()?.json` вместо `$('Node').item.json`.

---

### ERR-010 — Gotenberg: несовместимый формат данных

**Status:** CONFIRMED
**Date:** 2026-06-28 – 2026-07-30
**Affected workflow:** OSINT_06
**Severity:** HIGH

#### Symptom
`This operation expects the node's input data to contain a binary file 'index.html', but none was found [item 0]`.

#### Root Cause
Gotenberg ожидает multipart/form-data с бинарным файлом `index.html` (MIME `text/html`), а `MD to HTML` отдаёт строку в `json.html`.

#### Fix
Создан Code-узел `Create HTML Binary` с `prepareBinaryData`.

#### Related ADR
ADR-006, ADR-007

---

### ERR-011 — Pinecone upsert возвращает 404/400

**Status:** CONFIRMED
**Date:** 2026-07-02
**Affected workflow:** OSINT_07
**Severity:** HIGH

#### Symptom
POST на Pinecone endpoint возвращал 404.

#### Root Cause
Неправильный endpoint (`/vectors` вместо `/vectors/upsert`) и некорректная структура тела запроса.

#### Fix
Endpoint изменён на `/vectors/upsert`. Namespace: `osint-knowledge`. Размер вектора: 768 (позднее 1024).

---

### ERR-012 — Unauthorized при вызове внутреннего API n8n (/rest/workflows)

**Status:** CONFIRMED
**Date:** Июль 2026
**Affected workflow:** n8n_git_manager
**Severity:** CRITICAL

#### Symptom
`{"status":"error","message":"Unauthorized"}` при запросе к `/rest/workflows`.

#### Root Cause
Использовался внутренний REST-интерфейс n8n, требующий куки сессии, с публичным API-ключом.

#### Fix
Переход на Public API v1: `/api/v1/workflows/{id}`. Метод: PUT [20].

#### Related ADR
ADR-009, ADR-010

---

### ERR-013 — 400 Bad Request: запрещённые поля и ID узлов в генерируемом JSON

**Status:** CONFIRMED
**Date:** Июль 2026
**Affected workflow:** Все workflow (деплой)
**Severity:** HIGH

#### Symptom
Сервер n8n отвергал JSON при деплое.

#### Root Cause
JSON содержал поля `id`, `active`, `versionId`, `createdAt` и ID узлов.

#### Fix
Чёрный список полей для удаления перед деплоем.

---

### ERR-014 — Массовый сбой после импорта LLM-сгенерированных JSON

**Status:** OBSOLETE
**Date:** 2026-07-18
**Severity:** CRITICAL

#### Symptom
После импорта "исправленных" JSON система полностью перестала работать.

#### Root Cause
LLM-сгенерированные JSON содержали параметры, несовместимые с n8n 2.29.10.

#### Fix
Ручное исправление каждого workflow.

---

### ERR-015 — Paired item data is unavailable после Loop (SplitInBatches)

**Status:** CONFIRMED
**Date:** 2026-07-29
**Affected workflow:** OSINT_04
**Severity:** MEDIUM

#### Symptom
`ExpressionError: Paired item data ... is unavailable` при вызове `$('Config').item.json.job_id`.

#### Fix
Заменено на `$('Config').first().json.job_id` [15].

---

### ERR-016 — DeepSeek API: ECONNRESET / ECONNABORTED (timeout)

**Status:** CONFIRMED
**Date:** Июль 2026
**Affected workflow:** OSINT_01, OSINT_05
**Severity:** HIGH

#### Symptom
Узел DeepSeek систематически падал с `ECONNRESET` (WF1) или `ECONNABORTED` (WF5).

#### Root Cause
Нестабильность сетевого соединения и недостаточные таймауты.

#### Fix
Retry On Fail: 3 попытки. Timeout: 45s (flash), 120s (pro) [6].

#### Related ADR
ADR-011

---

## Unresolved Incidents

На момент консолидации неразрешённых инцидентов с подтверждёнными симптомами не зафиксировано.

---

## Repeated Failure Patterns

### RFP-01: Использование `.first()` / `.item` для получения контекста итерации
- ERR-001, ERR-009, ERR-015
- Правило: после SplitInBatches/Loop использовать `$input`, для HTTP Request — `Put Output in Field`.

### RFP-02: Стандартные скрейперы для защищённых ресурсов
- ERR-005
- Правило: проверять домен на антибот-защиту перед использованием.

### RFP-03: Доверие к UI-настройкам n8n внутри циклов
- ERR-001, ERR-004
- Правило: фиксировать критические настройки в JSON и деплоить через Git.

---

## Conflicting Evidence

### CE-01: Метод сохранения контекста в WF2 (ERR-001)
- Версия A (DECISIONS3.md, ADR-005): `putOutputInField`.
- Версия B (DECISIONS4.md): `$items()`.
- Разрешение: `putOutputInField` — принятое решение. `$items()` — технический долг (TD-01).

### CE-02: Метод HTTP для деплоя — PUT vs PATCH
- ENVIRONMENT.md: PATCH.
- DECISIONS7.md, ERROR_HISTORY4.md: PUT.
- Разрешение: PUT (ADR-010) — текущий метод.

---

## Missing Evidence

1. Execution logs для ERR-001 (сквозной прогон).
2. Execution logs для ERR-008 (Filter Empty).
3. Точная схема Pinecone (размерность, embedding model, retention).
4. Calibration dataset для скоринга тендеров.
5. Точные версии n8n для каждого инцидента.

---

## Technical Debt Derived from Incidents

| ID | Описание | Severity | Источник |
|----|----------|----------|----------|
| TD-01 | $items() legacy-паттерн в WF2/WF4 | HIGH | ERR-001 |
| TD-02 | Пустые PDF-отчёты при total_found==0 | MEDIUM | ERR-005 |
| TD-03 | Save Successful Executions: none | MEDIUM | ENVIRONMENT.md |
| TD-04 | Отсутствие валидации схем между workflow | MEDIUM | ERR-001 |
| TD-05 | Смешение логики в Extract Contacts | LOW | ERR-001 |
| TD-06 | Отсутствие cron-бэкапов | MEDIUM | ERR-012 |
| TD-07 | Отсутствие Watchtower | LOW | ERR-012 |
