# Справочник шаблонов нод для n8n

В этом документе содержатся эталонные структуры параметров для часто используемых узлов. Используй их как основу при генерации воркфлоу.

⚠️ **Общее правило для DeepSeek**: Координаты `"position"` всегда заменяй на реальные числа (например, `[300, 400]`), соответствующие шагу сетки. Поле `"id"` внутри узлов генерировать строго запрещено.

---

## 1. HTTP Request (POST запрос)
```json
{
  "name": "HTTP Request POST",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [300, 400],
  "parameters": {
    "method": "POST",
    "url": "https://api.example.com/endpoint",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "{\n  \"key\": \"value\"\n}",
    "options": {}
  }
}


## 2. Telegram (Отправка сообщения)
{
  "name": "Telegram Send Message",
  "type": "n8n-nodes-base.telegram",
  "typeVersion": 1.2,
  "position": [300, 500],
  "parameters": {
    "resource": "message",
    "operation": "sendMessage",
    "chatId": "123456789",
    "text": "={{ $json.text }}"
  }
}
⚠️ text начинается с = — выражение n8n.


## 3. Google Sheets (Добавление строки)
{
  "name": "Google Sheets Append",
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.5,
  "position": [300, 600],
  "parameters": {
    "resource": "spreadsheet",
    "operation": "append",
    "spreadsheetId": {
      "__rl": true,
      "value": "ID_ТАБЛИЦЫ",
      "mode": "id"
    },
    "sheetName": {
      "__rl": true,
      "value": "Лист1",
      "mode": "name"
    },
    "options": {}
  }
}
⚠️ spreadsheetId и sheetName — объекты с "__rl": true.


## 4. Code (JavaScript)
{
  "name": "JavaScript Code",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [300, 600],
  "parameters": {
    "jsCode": "// Обработка входящего массива\nfor (const item of $input.all()) {\n  item.json.processed = true;\n}\nreturn $input.all();"
  }
}
⚠️ Используй $input.all() без экранирования.

## 5. IF (Условное ветвление)
{
  "name": "IF Condition",
  "type": "n8n-nodes-base.if",
  "typeVersion": 2.2,
  "position": [300, 800],
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "leftValue": "",
        "type": "string"
      },
      "conditions": [
        {
          "leftValue": "={{ $json.field }}",
          "rightValue": "value",
          "operator": {
            "type": "string",
            "operation": "equals"
          }
        }
      ],
      "combinator": "and"
    }
  }
}


## Switch (Маршрутизация на множество потоков)
{
  "name": "Switch Router",
  "type": "n8n-nodes-base.switch",
  "typeVersion": 3.2,
  "position": [300, 900],
  "parameters": {
    "rules": {
      "values": [
        {
          "conditions": {
            "conditions": [
              {
                "leftValue": "={{ $json.field }}",
                "rightValue": "value1",
                "operator": {
                  "type": "string",
                  "operation": "equals"
                }
              }
            ]
          },
          "renameOutput": true,
          "outputKey": "branch1"
        }
      ]
    }
  }
}


## 7. Webhook (Входной триггер)
{
  "name": "Webhook Trigger",
  "type": "n8n-nodes-base.webhook",
  "typeVersion": 1,
  "position": [300, 1000],
  "parameters": {
    "path": "my-unique-webhook-path",
    "responseMode": "onReceived",
    "responseData": "allEntries",
    "options": {}
  }
}
⚠️ path должен быть уникальным.

## 8. AI Agent (LangChain)
{
  "name": "AI Agent",
  "type": "@n8n/n8n-nodes-langchain.agent",
  "typeVersion": 3.1,
  "position": [300, 1100],
  "parameters": {
    "promptType": "define",
    "text": "={{ $json.query }}",
    "options": {
      "systemMessage": "Ты — полезный ассистент."
    }
  }
}


## 9. Tavily Search (Инструмент для AI-Агента)
{
  "name": "Tavily Search Tool",
  "type": "@tavily/n8n-nodes-tavily.tavilyTool",
  "typeVersion": 1,
  "position": [300, 1200],
  "parameters": {
    "descriptionType": "manual",
    "toolDescription": "Поиск актуальной информации в интернете",
    "query": "={{ $json.query }}"
  }
}