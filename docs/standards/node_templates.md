# n8n Node Templates Standard

**Status:** APPROVED
**Compatibility baseline:** n8n 2.32.7
**Related ADR:** ADR-024

## Existing GitHub canonical workflow

```json
{
  "id": "<existing-workflow-id>",
  "name": "<workflow-name>",
  "nodes": [
    {
      "parameters": {},
      "name": "<node-name>",
      "type": "<node-type>",
      "typeVersion": 1,
      "position": [0, 0]
    },
    {
      "parameters": {},
      "name": "<node-with-existing-id>",
      "type": "<node-type>",
      "typeVersion": 1,
      "position": [240, 0],
      "id": "<preserved-opaque-node-id>"
    }
  ],
  "connections": {},
  "settings": {
    "executionOrder": "v1"
  }
}
```

**Правила для Profile A (GitHub canonical):**

- root `id` обязателен для существующего workflow;
- `nodes[].id` не обязателен универсально;
- существующий node ID сохраняется;
- короткий ID допустим;
- отсутствующий node ID не генерируется автоматически;
- credentials в реальном workflow сохраняются без изменения.

## Update payload

```json
{
  "name": "<workflow-name>",
  "nodes": [
    {
      "parameters": {},
      "name": "<node-name>",
      "type": "<node-type>",
      "typeVersion": 1,
      "position": [0, 0]
    },
    {
      "parameters": {},
      "name": "<node-with-existing-id>",
      "type": "<node-type>",
      "typeVersion": 1,
      "position": [240, 0],
      "id": "<preserved-opaque-node-id>"
    }
  ],
  "connections": {},
  "settings": {
    "executionOrder": "v1"
  }
}
```

**Правила для Profile C (update payload):**

- root поля `id`, `versionId`, `active`, `createdAt`, `updatedAt`, `shared`, `tags`, `triggerCount`, `pinData`, `meta` удалены из body;
- `nodes[].id` сохранён, если был в canonical workflow;
- credentials сохранены;
- `connections` и `settings` сохранены.

## Create payload

```text
CREATE PAYLOAD — NOT IMPLEMENTED.
Requires a separate ADR and verified POST implementation.
```

## Server response/export

```text
SERVER RESPONSE / EXPORT — REQUIRES EVIDENCE ON n8n 2.32.7.
```
