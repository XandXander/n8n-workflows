# Спецификация JSON-воркфлоу n8n

## 1. Корневая структура
Каждый файл воркфлоу — JSON-объект с полями:
- `name` (string) — название
- `nodes` (array) — массив узлов
- `connections` (object) — связи между узлами
- `settings` (object) — настройки выполнения

⚠️ **ЧЕРНЫЙ СПИСОК КОРНЕВЫХ ПОЛЕЙ** (запрещено генерировать):
`id`, `versionId`, `active`, `createdAt`, `updatedAt`, `shared`, `tags`, `triggerCount`, `pinData`

---

## 2. Формат узла (Node)
Каждый узел в массиве `nodes` **НЕ ДОЛЖЕН** содержать поле `id`. Сервер n8n генерирует его автоматически. Узлы идентифицируются по полю `name`.

Обязательные поля узла:
- `name` (string) — отображаемое имя (должно быть уникальным в рамках воркфлоу)
- `type` (string) — тип ноды, например `n8n-nodes-base.httpRequest`
- `typeVersion` (number) — версия типа
- `position` (array) — [x, y] координаты на холсте
- `parameters` (object) — параметры ноды

Пример:
```json
{
  "name": "HTTP Request",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [300, 400],
  "parameters": { ... }
}