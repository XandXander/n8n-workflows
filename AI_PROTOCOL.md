# AI_PROTOCOL.md

## Purpose
Протокол взаимодействия двух AI-агентов в проекте OSINT Platform: ChatGPT (Главный Архитектор) и Open WebUI / DeepSeek V4 Pro (AI-Инженер).

## Roles

### Principal Architect (ChatGPT)
- Принимает финальные архитектурные решения.
- Утверждает DECISIONS.md и ARCHITECTURE.md.
- Проводит аудит DRAFT-документов перед их утверждением.
- Разрешает конфликты между источниками.
- Утверждает критические изменения workflow.

### AI Engineer (Open WebUI / DeepSeek V4 Pro)
- Создаёт и модифицирует JSON workflow.
- Деплоит на сервер xandai.ru.
- Ведёт оперативную документацию.
- Выполняет отладку и исправление ошибок.
- Консолидирует документацию из разных чатов.

## Source of Truth

1. **GitHub-репозиторий** — единственный источник истины (SSOT).
2. Приоритет источников: актуальный JSON → execution logs → ENVIRONMENT.md → ARCHITECTURE.md → история чата.
3. При конфликте JSON и документации — JSON является истиной.

## Document Lifecycle

### DRAFT → APPROVED
1. AI Engineer создаёт `*_DRAFT.md`.
2. Principal Architect проводит аудит.
3. После утверждения `_DRAFT` удаляется из имени.
4. Старая версия перемещается в `archive/documentation/`.

### Templates
- `docs/templates/ADR_TEMPLATE.md` — шаблон архитектурного решения.
- `docs/templates/ERROR_TEMPLATE.md` — шаблон инцидента.
- `docs/templates/TASK_TEMPLATE.md` — шаблон задачи.
- `docs/templates/ESCALATION_TEMPLATE.md` — шаблон эскалации.

## Change Process

### Изменение workflow
1. AI Engineer читает актуальный JSON через `read_workflow_file`.
2. Вносит изменения в JSON.
3. Записывает через `write_workflow_file`.
4. Деплоит через `deploy_workflow` (PUT на сервер + Git commit + push).
5. Обновляет WORKFLOW_MAP.md при изменении структуры.

### Создание документа
1. AI Engineer создаёт документ.
2. Указывает статус DRAFT, Version, Owner, Last updated.
3. Principal Architect утверждает.

## Communication Rules

1. **Статусы:** VERIFIED, PRESENT, PARTIAL, BROKEN, UNKNOWN, DEPRECATED.
2. **Доказательства:** VERIFIED требует execution ID или даты.
3. **Секреты:** никогда не включать API-ключи, токены, пароли, credential ID.
4. **Конфликты:** не разрешать самостоятельно — эскалировать Главному Архитектору.
5. **Предположения:** явно помечать как предположение, не выдавать за факт.

## File Naming

- Документация: `UPPER_CASE.md`
- Шаблоны: `UPPER_CASE_TEMPLATE.md`
- JSON workflow: `OSINT_XX_Name.json`
- Задачи: `TASK-XXX.md`
- Эскалации: `ESC-XXX.md`
