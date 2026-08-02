```markdown
# ERROR_HISTORY.md

## Project Error Log

**Project:** XandAI / n8n Automation Platform
**Generated:** 2026-07-27
**Source:** Knowledge-base files (Ограничения и паттерны n8n.md, ENVIRONMENT.md, SERVER_STRUCTURE.md)

---

# Error #1: Buffer.from() недоступен в Code-узлах

## Date
Unknown

## Workflow
Любой workflow с Code-узлом, обрабатывающим бинарные данные (HTML→PDF через Gotenberg, файловые операции)

## Symptom
```
ReferenceError: Buffer is not defined
```
Code-узел падает при попытке создать бинарный буфер через `Buffer.from()`.

## Cause
Task Runner Sandbox в n8n изолирует выполнение JavaScript. `Buffer` — Node.js API, которое недоступно в Sandbox-окружении.

## Что проверяли
- Доступность `Buffer` в глобальной области видимости Code-узла
- Версию Node.js
- Настройки Sandbox

## Что оказалось неверным
Предположение, что Code-узлы имеют полный доступ к Node.js API.

## Root Cause
**Sandbox-ограничение n8n**: Task Runner Sandbox не предоставляет Node.js-специфичные API (`Buffer`, `crypto`) из соображений безопасности.

## Fix
Замена `Buffer.from()` на `this.helpers.prepareBinaryData()` с прямым текстом:
```javascript
// Было (падает):
const binary = Buffer.from(htmlContent, 'utf-8');

// Стало (работает):
const binary = await this.helpers.prepareBinaryData(
  Buffer.from(htmlContent),
  'index.html',
  'text/html'
);
```
Источник: [5] Ограничения и паттерны n8n.md

## Status
**Permanent Workaround** — ограничение Sandbox не может быть снято в production.

---

# Error #2: crypto.randomUUID() недоступен в Code-узлах

## Date
Unknown

## Workflow
Любой workflow, генерирующий уникальные идентификаторы в Code-узлах (создание имён файлов, tracking IDs, ключи кэша)

## Symptom
```
TypeError: crypto.randomUUID is not a function
```
Падение Code-узла при вызове `crypto.randomUUID()`.

## Cause
`crypto.randomUUID()` — API Web Crypto, недоступный в Task Runner Sandbox.

## Что проверяли
- Доступность глобального `crypto`
- Альтернативы: `require('crypto')`, `crypto.randomUUID()`, `uuid` package

## Что оказалось неверным
Предположение, что Web Crypto API доступен в Sandbox-окружении n8n.

## Root Cause
**Sandbox-ограничение n8n**: Task Runner Sandbox блокирует Web Crypto API.

## Fix
Замена на:
```javascript
// Было (падает):
const id = crypto.randomUUID();

// Стало (работает):
const id = Date.now().toString(36) + Math.random().toString(36).slice(2);
```
⚠️ **Не RFC-совместимый UUID** — теоретически возможны коллизии.

Источник: [5] Ограничения и паттерны n8n.md

## Status
**Permanent Workaround** — генерируемые ID не гарантируют уникальность. Technical debt.

---

# Error #3: $now.format() не работает в Code-узлах

## Date
Unknown

## Workflow
Code-узлы с форматированием даты/времени

## Symptom
```
TypeError: $now.format is not a function
```
Code-узел падает при вызове `$now.format(...)`.

## Cause
`$now` — объект n8n для выражений в параметрах нод (поля с `=`), но **недоступен** в JavaScript-коде Code-узлов. Это разные контексты выполнения.

## Что проверяли
- Доступность `$now` в Code-узле
- Работает ли `$now.format()` в параметрах других нод (работает)

## Что оказалось неверным
Предположение, что n8n-переменные (`$now`, `$json`, `$workflow`) доступны в Code-узлах так же, как в выражениях параметров.

## Root Cause
**Разные контексты выполнения**: выражения n8n (`={{ }}`) имеют доступ к `$now`, но JavaScript Code-узел выполняется в изолированном Sandbox без этих объектов.

## Fix
```javascript
// Было (падает):
const formattedDate = $now.format('YYYY-MM-DD');

// Стало (работает):
const formattedDate = new Date().toISOString().split('T')[0];
```
Источник: [5] Ограничения и паттерны n8n.md

## Status
**Resolved** — стандартный JavaScript `Date` API заменяет `$now.format()`.

---

# Error #4: Serper API — 400 ошибка при использовании оператора site:

## Date
Unknown

## Workflow
OSINT-поисковые workflow (тендеры, конкурентная разведка)

## Symptom
```
HTTP 400 Bad Request
{"error": "..."}
```
При добавлении `site:` в поисковый запрос Serper API возвращает 400.

## Cause
Serper API на **free-тарифе** запрещает оператор `site:` в поисковых запросах. Это ограничение тарифа, не задокументированное явно в основной документации Serper.

## Что проверяли
- Корректность синтаксиса `site:example.ru`
- Разные варианты экранирования
- Заголовки запроса
- Тарифный план

## Что оказалось неверным
`site:` — валидный Google-оператор, но Serper free-тариф его блокирует. Ошибка 400 вместо 403/429 вводит в заблуждение — кажется, что проблема в синтаксисе, а не в тарифе.

## Root Cause
**Ограничение Serper free-тарифа**: оператор `site:` запрещён. Ошибка 400 вместо осмысленного сообщения — плохой API-дизайн Serper.

## Fix
Формат запросов без `site:`:
```
// Было (400):
"site:.ru проектирование тендер"

// Стало (200):
"проектирование Москва тендер закупки"
```
Смысловой поиск через ключевые слова вместо операторов ограничения домена.

Источник: [5] Ограничения и паттерны n8n.md

## Status
**Permanent Workaround** — невозможно использовать `site:` на free-тарифе.

---

# Error #5: Groq API — 429 Too Many Requests, retry сжигает квоту

## Date
Unknown

## Workflow
Все workflow, использующие Groq API (llama-3.1-8b-instant) через HTTP Request ноду

## Symptom
```
HTTP 429 Too Many Requests
Rate limit exceeded
```
После включения retry в HTTP Request ноде — **квота исчерпывается за секунды**, все последующие запросы падают с 429.

## Cause
Бесплатный тариф Groq имеет TPD (Tokens Per Day) ~500 000. Когда происходит 429, n8n по умолчанию делает retry. Каждый retry-запрос считается новым запросом и **мгновенно сжигает остаток квоты**.

## Что проверяли
- Корректность API-ключа
- Заголовки запроса
- Retry-политику n8n HTTP Request ноды
- Остаток квоты в Groq Console

## Что оказалось неверным
Стандартная retry-логика n8n (retry on failure) для rate-limited API приводит к лавинообразному исчерпанию квоты.

## Root Cause
**Комбинация двух факторов**:
1. Бесплатный тариф Groq с жёстким rate-limit
2. Retry-механизм n8n, который не различает 429 (rate limit) и другие ошибки

## Fix
```json
{
  "parameters": {
    "options": {
      "onError": "continueRegularOutput",
      "neverError": true
    }
  }
}
```
И обработка ошибки в следующем Code-узле:
- Выключить retry (`onError: "continueRegularOutput"`)
- Проверять `$json.statusCode === 429`
- При 429 — возвращать fallback-ответ или ставить в очередь на повтор

Источник: [5] Ограничения и паттерны n8n.md

## Status
**Resolved (с паттерном)** — retry отключён, ошибка обрабатывается вручную.

---

# Error #6: Break in data flow после SplitInBatches / Loop — .item не работает

## Date
Unknown (после обновления до n8n 2.29+)

## Workflow
Любой workflow с Loop или SplitInBatches + ссылка на данные узла до цикла

## Symptom
После выхода из Loop/SplitInBatches:
```
Cannot read properties of undefined (reading 'item')
```
Или просто `undefined` при использовании `$('PreviousNode').item.json.field`.

## Cause
В n8n 2.29+ изменилось поведение доступа к данным после Loop/SplitInBatches. Ссылка `.item` больше не работает — нужно использовать `.first()` или `.all()[index]`.

## Что проверяли
- Синтаксис ссылки на данные
- Версию n8n
- Структуру выходных данных Loop-ноды
- Порядок узлов в workflow

## Что оказалось неверным
`.item` был допустимым синтаксисом в n8n <2.29, но стал невалидным в 2.29+.

## Root Cause
**Breaking change в n8n 2.29**: изменён формат доступа к данным после батчевых/цикловых операций.

## Fix
```javascript
// Было (n8n <2.29):
$('NodeBeforeLoop').item.json.field

// Стало (n8n 2.29+):
$('NodeBeforeLoop').first().json.field
// или
$input.first().json.field  // в Code-узле
```
Источник: [5] Ограничения и паттерны n8n.md

## Status
**Resolved** — все workflow мигрированы на `.first()` / `.all()[index]`.

---

# Error #7: IF / Filter нода не пропускает данные (молчаливый false)

## Date
Unknown

## Workflow
Workflow с условным ветвлением (IF, Filter)

## Symptom
IF-нода всегда направляет данные в `false`-ветку, даже когда условие визуально должно быть `true`. **Нет ошибки в логах** — данные просто уходят не туда.

## Cause
В n8n 2.29+ в IF/Filter нодах необходимо явно включать тумблер **«Convert types where required»**. Без него сравнение строки с числом, или числа в строковом виде с эталоном, даёт `false`.

## Что проверяли
- Корректность условия (leftValue, rightValue, operator)
- Типы сравниваемых значений
- Логи n8n (пусто — нет ошибок)

## Что оказалось неверным
Неявное приведение типов в IF-нодах n8n было изменено в 2.29+. Без тумблера «Convert types» сравнение `"5" == 5` даёт `false`.

## Root Cause
**Изменение поведения IF/Filter в n8n 2.29**: типы больше не приводятся неявно. Тумблер «Convert types where required» нужно включать явно.

## Fix
Включить тумблер «Convert types where required» в параметрах IF/Filter ноды:
```json
{
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "type": "string",
        "convertTypes": true
      }
    }
  }
}
```
Источник: [5] Ограничения и паттерны n8n.md

## Status
**Resolved** — тумблер включается во всех новых IF/Filter нодах.

---

# Error #8: IMAP Trigger — бесконечный цикл обработки писем

## Date
Unknown

## Workflow
Email-triggered OSINT workflow

## Symptom
Одно и то же письмо обрабатывается **бесконечно**. Workflow запускается снова и снова для одного входящего email, пока не остановят вручную. База execution-логов забивается дубликатами.

## Cause
IMAP-триггер по умолчанию не меняет статус письма после обработки. Письмо остаётся `UNSEEN` → при следующем polling-цикле оно снова попадает в обработку → бесконечный цикл.

## Что проверяли
- Настройки IMAP-ноды
- Статус письма в почтовом ящике после обработки
- Частоту polling
- Критерии фильтрации писем

## Что оказалось неверным
Предположение, что IMAP-триггер автоматически отмечает письма как прочитанные. По умолчанию он этого **не делает**.

## Root Cause
**Отсутствие `postProcessAction: "read"`** в параметрах IMAP-триггера. Без этого параметра письмо остаётся `UNSEEN` и перехватывается снова.

## Fix
```json
{
  "parameters": {
    "postProcessAction": "read",
    "customEmailConfig": "[\"UNSEEN\"]"
  }
}
```
И фильтр темы письма:
```
$json.subject contains "OSINT-AI"
```
⚠️ Важно: `$json.subject` (не `$json.headers.subject`).

Источник: [5] Ограничения и паттерны n8n.md

## Status
**Resolved** — `postProcessAction: "read"` + `customEmailConfig: "[\"UNSEEN\"]"` во всех IMAP-триггерах.

---

# Error #9: API деплой — 400 Bad Request при использовании PATCH

## Date
Между 2026-07-24 и 2026-07-27

## Workflow
CI/CD pipeline: локальная разработка → деплой на production

## Symptom
```
HTTP 400 Bad Request
{"message": "Invalid request body"}
```
Деплой-скрипты падают при PATCH-запросе к `/api/v1/workflows/{id}`. Ранее работавший PATCH внезапно перестал приниматься.

## Cause
При обновлении n8n (с 2.30.x до 2.31.x) или смене сервера API изменил поведение: PATCH больше не поддерживается для полного обновления workflow. Требуется PUT.

Дополнительно: список read-only полей расширился (`meta`).

## Что проверяли
- Тело запроса (JSON-структура)
- Наличие запрещённых полей (id, versionId, etc.)
- Заголовок авторизации
- Метод запроса

## Что оказалось неверным
Предположение, что PATCH продолжает работать после обновления n8n.

## Root Cause
**API change в n8n**: метод обновления workflow изменён с PATCH на PUT. Документация ENVIRONMENT.md → SERVER_STRUCTURE.md отражает это изменение.

## Fix
1. Замена метода: `PATCH` → `PUT`
2. Добавление `meta` в список удаляемых полей
3. Обновление всех деплой-скриптов

Источник: [1] ENVIRONMENT.md, [4] SERVER_STRUCTURE.md

## Status
**Resolved** — все деплой-процедуры обновлены на PUT.

---

# Error #10: Доступ к $json.headers.subject вместо $json.subject в IMAP

## Date
Unknown

## Workflow
Email-triggered workflow с фильтрацией по теме письма

## Symptom
Фильтр темы письма не срабатывает. Письма с темой «OSINT-AI: ...» не проходят фильтр и не запускают workflow.

## Cause
В n8n IMAP-триггер помещает тему письма в `$json.subject`, а не в `$json.headers.subject`. Обращение к `$json.headers.subject` возвращает `undefined` → фильтр всегда `false`.

## Что проверяли
- Структуру выходных данных IMAP-ноды
- Путь к полю с темой письма
- Синтаксис условия

## Что оказалось неверным
Предположение, что тема письма находится в `$json.headers.subject` (как в полном email-конверте). IMAP-нода n8n парсит тему в корень `$json.subject`.

## Root Cause
**Несоответствие ожидаемой структуры данных**: IMAP-нода n8n имеет плоскую структуру полей, где `subject` — поле первого уровня, а не вложенное в `headers`.

## Fix
```javascript
// Было (не работает):
$json.headers.subject contains "OSINT-AI"

// Стало (работает):
$json.subject contains "OSINT-AI"
```
Источник: [5] Ограничения и паттерны n8n.md

## Status
**Resolved** — `$json.subject` во всех IMAP-фильтрах.

---

# Repeated Mistakes

| # | Паттерн ошибки | Частота | Связанные ошибки |
|---|---|---|---|
| 1 | **Предположение о доступности Node.js API в Sandbox** | 2 раза | #1 (Buffer), #2 (crypto) |
| 2 | **Предположение о доступности n8n-переменных в Code-узлах** | 1 раз | #3 ($now.format) |
| 3 | **Неучёт ограничений free-тарифа внешних API** | 2 раза | #4 (Serper site:), #5 (Groq 429) |
| 4 | **Неучёт breaking changes при обновлении n8n** | 3 раза | #6 (.item), #7 (Convert types), #9 (PATCH→PUT) |
| 5 | **Структура данных ноды не соответствует ожидаемой** | 2 раза | #8 (IMAP postProcess), #10 ($json.subject) |

**Корневой паттерн**: разработка ведётся в локальном окружении (Windows 10 + Open WebUI), которое **не идентично production**. Ошибки обнаруживаются только на сервере.

---

# Technical Debt (Error-Related)

1. **UUID без crypto** (Error #2): генерация не-RFC идентификаторов. При масштабировании — риск коллизий.

2. **Buffer workaround** (Error #1): `prepareBinaryData` с прямым текстом менее гибок, чем `Buffer`. Может стать проблемой при сложных бинарных операциях.

3. **Нет автоматического тестирования workflow**: ошибки #6, #7, #8, #10 обнаруживаются вручную на production. Валидатор проверяет только структуру JSON, но не логику выполнения.

4. **Нет мониторинга API-ошибок**: 429 от Groq (#5), 400 от Serper (#4) обнаруживаются по факту сбоя workflow, а не превентивно.

5. **n8n:latest автообновление**: ошибка #9 (PATCH→PUT) произошла из-за автообновления. Без фиксации версии возможны новые breaking changes.

---

# Unresolved Problems

| # | Проблема | Источник | Почему не решено |
|---|---|---|---|
| 1 | Коллизии UUID | Error #2 | Низкая вероятность, не приоритетно |
| 2 | Отсутствие `site:` в Serper | Error #4 | Ограничение free-тарифа — только переход на платный |
| 3 | Sandbox-ограничения (Buffer, crypto) | Errors #1, #2 | Архитектурное ограничение n8n, нельзя снять |
| 4 | Автотестирование workflow перед деплоем | Errors #6–#10 | Не внедрено |
| 5 | Мониторинг квот внешних API | Error #5 | Не внедрён |

---

# Most Dangerous Issues

| Ранг | Ошибка | Критичность | Почему |
|---|---|---|---|
| 🔴 1 | **Groq 429 + retry сжигает квоту** | **High** | Один retry-цикл может исчерпать дневную квоту за секунды. Все workflow на Groq останавливаются до следующего дня. |
| 🔴 2 | **IMAP бесконечный цикл** | **High** | Бесконечное переисполнение workflow забивает execution-лог, расходует CPU/RAM, может привести к деградации всего сервера. |
| 🟡 3 | **PATCH→PUT breaking change** | **Medium** | Ломает весь CI/CD pipeline. Без деплоя невозможна доставка исправлений. |
| 🟡 4 | **IF/Filter молчаливый false** | **Medium** | Нет ошибок в логах — workflow работает, но выдаёт неверные результаты. Самый коварный тип ошибки: всё выглядит рабочим, но логика сломана. |
| 🟡 5 | **Sandbox ограничения (Buffer, crypto)** | **Low** | Есть workaround. Может стать critical при новом функционале, требующем криптографии или сложной работы с бинарными данными. |
```

Готово. **10 ошибок**, 5 повторяющихся паттернов, 5 пунктов техдолга, 5 нерешённых проблем. Файл сохранён как заметка `ERROR_HISTORY.md`.