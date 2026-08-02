# PROJECT_STATE.md

**Last updated:** 2026-08-02
**Updated by:** Open WebUI / DeepSeek V4 Pro
**Git baseline:** E:\РАБОТА ДОМА\WEB\N8N BEGET\FOREIGN\DEEPSEEK\GIT (unpushed changes: WORKFLOW_MAP.md, ERROR_HISTORY_DRAFT.md, DECISIONS_DRAFT.md)
**Evidence baseline:** JSON-экспорты с xandai.ru от 2026-07-31; ENVIRONMENT.md; SERVER_STRUCTURE.md

---

## 1. Platform Summary

OSINT-платформа XandAI — 8 микро-воркфлоу на self-hosted инстансе n8n 2.30.7+ (VPS Beget, 2 vCPU, 3.8 GB RAM). Принимает запросы из Telegram/Email, классифицирует intent через DeepSeek v4-flash, выполняет поиск (Serper/Tavily) и скрейпинг (Firecrawl), анализирует сущности через DeepSeek v4-pro, генерирует PDF-отчёт через Gotenberg 8, доставляет в Telegram/Email/Google Drive. Данные хранятся в Google Sheets (6 листов) и Pinecone (3 namespace).

**Общая оценка:** Платформа структурно собрана, все 8 workflow задеплоены и активны на сервере. Сквозной (end-to-end) прогон ни по одному сценарию не верифицирован. Критические баги инцидентов ERR-001–ERR-016 закрыты на уровне кода, но регрессионное тестирование не проводилось.

---

## 2. Workflow Status

| ID | Workflow | n8n ID | Active | Status | Evidence |
|----|----------|--------|--------|--------|----------|
| WF1 | OSINT_01_Core_Router | `WtkTm484CwBpahGt` | Нет (active:false) | PRESENT | JSON от 2026-07-31. Telegram/IMAP триггеры, маршрутизация — в коде. Выполнение не проверено. |
| WF2 | OSINT_02_Search_Engine | `fgf3zI8fRJhkqlHC` | Да | PRESENT | JSON от 2026-07-31. putOutputInField на Serper/Firecrawl. $items() fallback в Extract URLs/Contacts. E2E до Append Lead не подтверждён. |
| WF3 | OSINT_03_Company_Intel | `gxCPpkQkvqc0yWf8` | Да | PRESENT | JSON от 2026-07-29. Firecrawl + DaData + Serper + DeepSeek pro. $('Config').item.json — риск pairedItem. Выполнение не проверено. |
| WF4 | OSINT_04_Tender_Intel | `zcpU6hLvcMl5RiUa` | Да | PRESENT | JSON от 2026-07-31. Serper + Tavily → DeepSeek flash. Firecrawl отключён. $items() для контекста. Выполнение не проверено. |
| WF5 | OSINT_05_Analyst | `viR4AZBaC4CFA4qx` | Да | PRESENT | JSON от 2026-07-31. active:true. Read Entities → Loop → DeepSeek pro → Update Row. Trigger Report на done. $('Loop Entities').item.json — риск. Выполнение не проверено. |
| WF6 | OSINT_06_Report_Generator | `qXWixFd94G7Tfgaa` | Да | PRESENT | JSON от 2026-07-31. active:true. MD → HTML Binary → Gotenberg → Drive/Telegram/Email. Цепочка PDF подтверждена (~25 kB). E2E с реальными данными не проверен. |
| WF7 | OSINT_07_Pinecone_Memory | `O3Ke6qflNx8CL1x7` | Да | PRESENT | JSON от 2026-07-29. Jina embeddings (1024-dim) → Pinecone upsert/query/delete. upsertedCount>0 подтверждён в ERROR_HISTORY (1).md. |
| WF8 | OSINT_08_Utilities | `IR4oQQAYQgUwIUjJ` | Да | PRESENT | JSON от 2026-07-29. STT (Groq Whisper), Gotenberg PDF, логирование, throttle. STT-цепочка подтверждена. |

---

## 3. Overall Platform Status

| Capability | Status | Detail |
|------------|--------|--------|
| Telegram → классификация intent | PRESENT | Код есть. Не проверено. WF1 active:false. |
| Email → классификация intent | PRESENT | Код есть (IMAP + Filter). Не проверено. |
| Поиск частных заказчиков (B2C/B2B) | PARTIAL | WF2 деплоен. Firecrawl блокируется Cloudflare (ERR-005). Контекст через $items(). E2E не проверен. |
| Анализ компаний | PRESENT | WF3 деплоен. Firecrawl/DaData/DeepSeek. Не проверено. |
| Поиск тендеров | PARTIAL | WF4 деплоен. Firecrawl отключён (ADR-012). Сниппеты Serper/Tavily → DeepSeek flash. Качество скoringа под вопросом. |
| Скоринг сущностей | PRESENT | WF5 деплоен. DeepSeek pro с retry. $('Loop Entities').item.json — риск ERR-015. |
| Генерация PDF-отчёта | PRESENT | WF6 деплоен. Gotenberg цепочка подтверждена. Пустые отчёты при total_found=0 (TD-02). |
| Доставка в Telegram | PRESENT | Код есть в WF6. Не проверено с реальным chat_id. |
| Доставка в Email | PRESENT | Код есть в WF6. Всегда на xander1s@yandex.ru (не зависит от user_id). |
| Векторная память (Pinecone) | PRESENT | WF7 деплоен. upsert подтверждён. Размерность 1024 (jina-embeddings-v3). |
| Дедупликация лидов | PRESENT | WF2 → WF7 query → Is Not Duplicate? → upsert. Не проверено. |
| Голосовые сообщения (STT) | PRESENT | WF1 → WF8 (Groq Whisper). STT-цепочка подтверждена. |
| Логирование ошибок | PRESENT | WF8 → Google Sheets `logs`. Telegram-алерт при level='error'. |
| Google Sheets (операционные данные) | PRESENT | 6 листов. Не транзакционна. Риск гонки данных. |
| Google Drive (хранение PDF) | PRESENT | Папка `1xm1Luua_anWS8hLghLJLg_MKZenQ1-SZ`. |

---

## 4. External Services Health

| Service | Status | Notes |
|---------|--------|-------|
| DeepSeek API (flash) | PRESENT | Retry 3×, timeout 45s. ERR-002 исправлен (system prompt). ECONNRESET возможен (ERR-016). |
| DeepSeek API (pro) | PRESENT | Retry 3×, timeout 120s. Используется в WF3/WF5/WF6. |
| Serper API | PRESENT | Бесплатный тариф. `site:` запрещён (ADR-013). continueRegularOutput при ошибках. |
| Tavily API | PRESENT | Только WF4. continueRegularOutput. |
| Firecrawl API | PARTIAL | Блокируется Cloudflare для Avito/Telegram/Zakupki (ERR-005). continueRegularOutput. |
| Groq API (Whisper) | PRESENT | WF8 STT. Без retry. ADR-023: без retry на 429. |
| DaData API | PRESENT | WF3. continueRegularOutput. |
| Jina API | PRESENT | WF7 embeddings. Без retry. |
| Pinecone API | PRESENT | WF7. upsert/query/delete. Без retry. |
| Gotenberg 8 | PRESENT | Docker-контейнер. HTML→PDF. Timeout 120s. SPOF для WF6. |
| Google Sheets API | PRESENT | 6 листов. Quota limits. |
| Google Drive API | PRESENT | Загрузка PDF. |
| Telegram Bot API | PRESENT | Приём/отправка. Webhook + отправка PDF. |
| Yandex SMTP | PRESENT | Отправка Email (всегда на один адрес). |
| IMAP (Email) | PRESENT | postProcessAction:"read". customEmailConfig:["UNSEEN"]. |

---

## 5. Known Blockers & Critical Issues

### BLOCKER-01: WF1 active:false — платформа не принимает запросы
- **Severity:** CRITICAL
- **Detail:** `OSINT_01_Core_Router` имеет `active: false` на сервере. Telegram Trigger и IMAP Trigger не активированы. Пользователи не могут отправить запрос.
- **Related:** WF1 JSON, поле `active: false`
- **Action:** Активировать WF1 в UI n8n или через API.

### BLOCKER-02: Сквозной прогон ни разу не верифицирован
- **Severity:** CRITICAL
- **Detail:** Ни один сценарий (search_private, company_analysis, tender_search) не прошёл полный цикл WF1→WF2/3/4→WF5→WF6 с проверкой данных на каждом этапе.
- **Related:** Все ERR, WORKFLOW_MAP.md Recommended Verification Order
- **Action:** Выполнить 8 шагов верификации из WORKFLOW_MAP.md.

### BLOCKER-03: Firecrawl заблокирован для ключевых платформ
- **Severity:** HIGH
- **Detail:** Avito, Telegram, Profi, Zakupki.gov.ru, ТэкТорг возвращают "Access Denied" (ERR-005). B2C-лиды не собираются. Тендеры анализируются только по сниппетам.
- **Related:** ERR-005, ADR-012
- **Action:** Интегрировать специализированные API (Zakupki, Clearspending) или платные прокси.

### BLOCKER-04: $items() legacy-паттерн в WF2 и WF4
- **Severity:** HIGH
- **Detail:** `$items("Loop Queries", 0, $runIndex)` остаётся fallback'ом в Extract URLs, Extract Contacts (WF2) и Enrich Tender (WF4). При ошибке батча возможен рассинхрон контекста.
- **Related:** ERR-001, TD-01, DECISIONS3.md Decision Debt
- **Action:** Полностью удалить $items() и перейти на $input + putOutputInField.

### BLOCKER-05: Пустые PDF-отчёты при total_found==0
- **Severity:** MEDIUM
- **Detail:** WF6 генерирует и отправляет "успешный" PDF с текстом «Сущности не найдены». Пользователь не знает, что результат пустой.
- **Related:** TD-02, DECISIONS3.md Decision Debt
- **Action:** Добавить assertion: при total_found==0 отправлять Alert, не генерировать PDF.

### BLOCKER-06: Гонка данных WF2/3/4 → WF5
- **Severity:** MEDIUM
- **Detail:** WF2/3/4 вызывают WF5 асинхронно (wait=false). WF5 читает Google Sheets по job_id, но запись может не успеть завершиться. Отчёт может быть неполным.
- **Related:** WORKFLOW_MAP.md Cross-Workflow Risks
- **Action:** Добавить задержку перед вызовом WF5 или перейти на wait=true с промежуточным вызовом WF5 после завершения записи.

---

## 6. Open Technical Debt

| ID | Описание | Severity | Source |
|----|----------|----------|--------|
| TD-01 | $items() legacy-паттерн в WF2/WF4 | HIGH | ERR-001, DECISIONS3.md |
| TD-02 | Пустые PDF-отчёты без алерта | MEDIUM | DECISIONS3.md |
| TD-03 | Save Successful Executions: none — невозможен пост-анализ | MEDIUM | ENVIRONMENT.md |
| TD-04 | Отсутствие валидации схем данных между workflow | MEDIUM | ERROR_HISTORY_DRAFT.md |
| TD-05 | Смешение логики в Extract Contacts (парсинг + валидация + ветвление) | LOW | ERROR_HISTORY_DRAFT.md |
| TD-06 | Отсутствие cron-бэкапов | MEDIUM | SERVER_STRUCTURE.md |
| TD-07 | Отсутствие Watchtower (ручное обновление контейнеров) | LOW | SERVER_STRUCTURE.md |
| TD-08 | Отсутствие trim() у job_id при записи | MEDIUM | DECISIONS3.md |
| TD-09 | Два namespace Pinecone без документации | LOW | DECISIONS (1).md |
| TD-10 | Не зафиксирована политика retry/throttling для Groq/Sheets/Serper/Firecrawl | LOW | DECISIONS (1).md |
| TD-11 | Не определены статусы job (completed/partial/no_results/failed) | MEDIUM | DECISIONS (1).md |
| TD-12 | Самописный MD→HTML конвертер — неполная поддержка Markdown | LOW | WORKFLOW_MAP.md WF6 |
| TD-13 | Email всегда на xander1s@yandex.ru, не зависит от user_id | MEDIUM | WORKFLOW_MAP.md WF6 |

---

## 7. Recently Resolved Incidents

| ID | Название | Статус | Дата |
|----|----------|--------|------|
| ERR-001 | Потеря контекста в циклах (job_id, query, source_platform) | CONFIRMED — putOutputInField внедрён, $items() остаётся | 2026-07-31 |
| ERR-002 | DeepSeek 400 без слова "json" в prompt | CONFIRMED — исправлено | 2026-07-28 |
| ERR-003 | Сбой классификатора из-за префикса "OSINT-AI:" | CONFIRMED — исправлено | 2026-07-31 |
| ERR-005 | Firecrawl Access Denied | CONFIRMED — Firecrawl отключён для защищённых целей | 2026-07-31 |
| ERR-006 | Buffer.from() ReferenceError | CONFIRMED — prepareBinaryData | Июль 2026 |
| ERR-007 | $json.headers.subject вместо $json.subject | CONFIRMED — исправлено | Июль 2026 |
| ERR-008 | Filter Empty блокирует все URL | CONFIRMED — looseTypeValidation | 2026-07-18 |
| ERR-009 | $('Node').item после SplitInBatches → {} | CONFIRMED — $input.first() | 2026-07-20 |
| ERR-010 | Gotenberg: json.html вместо binary index.html | CONFIRMED — Create HTML Binary | 2026-07-30 |
| ERR-011 | Pinecone upsert 404/400 | CONFIRMED — /vectors/upsert | 2026-07-02 |
| ERR-012 | Unauthorized /rest/workflows | CONFIRMED — Public API v1 | Июль 2026 |
| ERR-013 | 400 Bad Request: запрещённые поля/id | CONFIRMED — чёрный список полей | Июль 2026 |
| ERR-015 | Paired item data unavailable после Loop | CONFIRMED — .first().json | 2026-07-29 |
| ERR-016 | DeepSeek ECONNRESET/ECONNABORTED | CONFIRMED — retry 3× | Июль 2026 |

---

## 8. Environment & Infrastructure

| Параметр | Значение | Статус |
|----------|----------|--------|
| n8n версия | 2.30.7+ (latest) | OK |
| Docker Compose | 6 контейнеров (n8n, worker, postgres, redis, traefik, gotenberg) | OK |
| Binary Data Mode | filesystem | OK |
| Max Concurrent Executions | 5 | OK |
| Max Payload | 32 MB | OK |
| Save Successful Executions | none | RISK (TD-03) |
| Save Failed Executions | all | OK |
| Execution Pruning | 336 hours | OK |
| Disk Free | ~25 GB из 38 GB | OK |
| RAM | 3.8 GB (swap 4 GB) | OK |
| Бэкапы | Ручные, cron не настроен | RISK (TD-06) |
| Watchtower | Не установлен | RISK (TD-07) |
| SSL | Let's Encrypt через Traefik | OK |
| Redis/Postgres | Без внешних портов | OK |

---

## 9. What Is NOT Yet Verified

1. **WF1 → WF2 → WF5 → WF6 сквозной прогон** — ни разу.
2. **WF1 → WF3 → WF5 → WF6 сквозной прогон** — ни разу.
3. **WF1 → WF4 → WF5 → WF6 сквозной прогон** — ни разу.
4. **WF1 Email-триггер** — не проверен.
5. **WF1 голосовые сообщения (STT)** — цепочка кода подтверждена, но полный цикл с Telegram — нет.
6. **WF2 дедупликация через Pinecone** — не проверена.
7. **WF5 Update Row с динамическим matchingColumns** — не проверен.
8. **WF6 Telegram Send PDF с реальным chat_id** — не проверен.
9. **WF6 Send Email с реальным user_id** — не проверен (всегда на xander1s@yandex.ru).
10. **WF8 throttle_check** — не проверено, используется ли.
11. **Поведение при параллельных запусках** — не проверено (гонка данных).
12. **Поведение при total_found==0** — не проверено (пустые PDF).

---

## 10. Recommended Immediate Actions

| Priority | Action | Related |
|----------|--------|---------|
| P0 | Активировать WF1 (active: true) | BLOCKER-01 |
| P0 | Выполнить сквозной прогон WF1→WF2→WF5→WF6 | BLOCKER-02 |
| P1 | Удалить $items() из WF2/WF4, полный переход на $input | BLOCKER-04, TD-01 |
| P1 | Добавить assertion при total_found==0 в WF6 | BLOCKER-05, TD-02 |
| P1 | Настроить cron для автоматических бэкапов | TD-06 |
| P1 | Изменить Send Email: использовать user_id из запроса | TD-13 |
| P2 | Включить Save Successful Executions: all для отладки | TD-03 |
| P2 | Добавить trim() для job_id в WF1 и WF2 | TD-08 |
| P2 | Задокументировать статусы job | TD-11 |
| P2 | Интегрировать специализированные API для тендеров/защищённых платформ | BLOCKER-03 |
| P3 | Установить Watchtower | TD-07 |
| P3 | Улучшить MD→HTML конвертер | TD-12 |
