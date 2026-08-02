# OSINT Platform — XandAI

Автоматизированная OSINT-платформа на базе n8n для сбора, анализа и доставки бизнес-лидов, информации о компаниях и тендерах.

## Статус проекта

**DRAFT** — платформа структурно собрана, все 8 workflow задеплоены. Сквозной прогон не верифицирован. См. `PROJECT_STATE.md`.

## Быстрый старт

### Для AI-агентов
1. **Понять архитектуру:** `docs/ARCHITECTURE.md`
2. **Понять workflow:** `docs/WORKFLOW_MAP.md`
3. **Понять состояние:** `PROJECT_STATE.md`
4. **Понять протокол взаимодействия:** `AI_PROTOCOL.md`

### Для инженеров
1. **Окружение:** `docs/ENVIRONMENT.md`
2. **Сервер:** `docs/SERVER_STRUCTURE.md`
3. **Workflow JSON:** `workflows/`
4. **История ошибок:** `docs/ERROR_HISTORY_DRAFT.md`
5. **История решений:** `docs/DECISIONS_DRAFT.md`

## Структура репозитория

```
osint-platform/
├── README.md                  # этот файл
├── AI_PROTOCOL.md             # протокол взаимодействия AI-агентов
├── PROJECT_STATE.md           # текущее состояние платформы
├── docs/
│   ├── ARCHITECTURE.md        # архитектура системы
│   ├── ENVIRONMENT.md         # runtime-окружение
│   ├── SERVER_STRUCTURE.md    # инфраструктура сервера
│   ├── WORKFLOW_MAP.md        # карта всех workflow
│   ├── ERROR_HISTORY_DRAFT.md # журнал ошибок (черновик)
│   ├── DECISIONS_DRAFT.md     # журнал решений (черновик)
│   ├── templates/             # шаблоны документов
│   ├── raw/                   # исходные версии документов
│   └── standards/             # стандарты (будет заполнено)
├── workflows/                 # JSON всех 8 workflow
├── config/                    # примеры конфигураций
├── tasks/                     # активные и архивные задачи
├── escalations/               # эскалации
└── archive/                   # архив старых версий
```

## Workflow

| ID | Имя | Назначение |
|----|-----|------------|
| WF1 | OSINT_01_Core_Router | Приём запросов, классификация, маршрутизация |
| WF2 | OSINT_02_Search_Engine | Поиск частных заказчиков |
| WF3 | OSINT_03_Company_Intel | Анализ компаний |
| WF4 | OSINT_04_Tender_Intel | Поиск тендеров |
| WF5 | OSINT_05_Analyst | Скоринг сущностей |
| WF6 | OSINT_06_Report_Generator | Генерация и доставка PDF-отчётов |
| WF7 | OSINT_07_Pinecone_Memory | Векторное хранилище |
| WF8 | OSINT_08_Utilities | Служебные операции |

## Ключевые внешние сервисы

- **DeepSeek** — основной LLM (flash/pro)
- **Serper + Tavily** — поиск
- **Firecrawl** — скрейпинг (ограниченно)
- **DaData** — информация о компаниях
- **Pinecone + Jina** — векторная память
- **Gotenberg** — HTML → PDF
- **Google Sheets** — операционные данные
- **Google Drive** — архив PDF
- **Telegram + Email** — каналы доставки

## GitHub = Single Source of Truth

Все изменения существующих workflow выполняются через `n8n_workflow_manager`.

Канонический процесс:

1. Прочитать актуальный GitHub-файл workflow.
2. Провести валидацию и записать изменение.
3. Получить `workflow_id` из корневого поля `id`.
4. Сформировать очищенный update payload.
5. Выполнить `PUT https://xandai.ru/api/v1/workflows/{workflow_id}`.
6. После успешного `PUT` выполнить Git commit и push при наличии изменений.

GitHub остаётся SSOT, а успешный ответ n8n Public API подтверждает deployment на сервер.
