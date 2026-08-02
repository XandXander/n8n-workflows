# n8n Workflow JSON Schema Standard

**Status:** APPROVED
**Compatibility baseline:** n8n 2.32.7
**Related ADR:** ADR-024

## Artifact Profiles

### Profile A — GitHub canonical workflow

Для существующего workflow:

- root `id`: REQUIRED;
- root `id` должен встречаться ровно один раз;
- duplicate JSON keys: FORBIDDEN;
- `nodes[].id`: PRESERVE IF PRESENT;
- отсутствующий `nodes[].id`: ALLOWED;
- имеющийся `nodes[].id`: непустой и уникальный внутри workflow;
- node ID является opaque string;
- UUID и минимальная длина не требуются;
- credentials и credential IDs сохраняются;
- canonical workflow требует sanitation перед update API.

### Profile B — create payload

Status: NOT IMPLEMENTED.

POST/create contract не определён. Profile C запрещено использовать как create payload без отдельного ADR.

### Profile C — update payload

- method: PUT;
- endpoint: `/api/v1/workflows/{workflow_id}`;
- workflow ID берётся из root `id` Profile A;
- root `id` передаётся в endpoint и удаляется из body;
- из корня body удаляются:
  `id`, `versionId`, `active`, `createdAt`, `updatedAt`,
  `shared`, `tags`, `triggerCount`, `pinData`, `meta`;
- `nodes[].id` sanitation не удаляет;
- credentials не удаляются;
- автоматическая credential substitution не изменяется.

### Profile D — server response/export

Status: REQUIRES EVIDENCE.

Должен проверяться read-only способом на n8n 2.32.7. Не блокирует Profile A и Profile C.

## Validation Rules

Profile A:

1. Валидный JSON.
2. Отсутствуют duplicate keys.
3. Root `id` встречается ровно один раз.
4. Root `id` — непустая строка.
5. `nodes` — массив.
6. `connections` — объект.
7. Присутствующие `nodes[].id` — непустые строки.
8. Присутствующие node IDs уникальны внутри workflow.
9. Отсутствующие node IDs допустимы.
10. Короткие и non-UUID IDs допустимы.

Profile C:

1. Root blacklist отсутствует в body.
2. `nodes[].id` сохраняются, если присутствуют.
3. Credentials сохраняются.
4. Неизвестные поля не удаляются без evidence.

## Unknown Fields

`parentFolderId`, `activeVersionId`, `nodeGroups` и иные новые/server-managed поля имеют статус UNKNOWN до получения evidence на n8n 2.32.7.
