#!/bin/bash
sudo tee /mnt/usbdata/docker_volumes/n8n/workflows/DailyBriefing.json > /dev/null <<'EOF'
{
  "name": "Briefing Diario de Stalker",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": {
                "type": "number",
                "value": 1
              },
              "unit": "days",
              "triggerAt": {
                "hour": 7,
                "minute": 0
              }
            }
          ]
        }
      },
      "id": "5a22339c-93e9-4911-8819-8a83551a225b",
      "name": "Todos los días a las 7am",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.1,
      "position": [
        -1000,
        -20
      ]
    },
    {
      "parameters": {
        "url": "http://wttr.in/Denver?format=j1",
        "options": {}
      },
      "id": "92a534e2-a077-412c-af83-20509a07d53a",
      "name": "Obtener Clima",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [
        -760,
        -160
      ]
    },
    {
      "parameters": {
        "url": "http://feeds.bbci.co.uk/news/world/rss.xml",
        "options": {}
      },
      "id": "3f5d305c-3f1c-4e3d-a1f1-42e1221071e1",
      "name": "Obtener Noticias (BBC)",
      "type": "n8n-nodes-base.rssFeedRead",
      "typeVersion": 1,
      "position": [
        -760,
        120
      ]
    },
    {
      "parameters": {
        "model": "gemini-pro",
        "prompt": "Eres Stalker, un asistente de IA conciso y directo. Tu operador necesita su briefing diario. Sintetiza la siguiente información en un reporte breve, útil y ligeramente motivacional. No incluyas saludos ni despedidas. Sé directo.\n\n**Datos del Clima:**\n{{ JSON.stringify($(\"Obtener Clima\").item.json.current_condition[0]) }}\\n\n**Titulares de Noticias (máximo 3):**\n1. {{ $(\"Obtener Noticias (BBC)\").item.json.items[0].title }}\\n2. {{ $(\"Obtener Noticias (BBC)\").item.json.items[1].title }}\\n3. {{ $(\"Obtener Noticias (BBC)\").item.json.items[2].title }}"
      },
      "id": "8b50c2e1-f41e-4a3e-8a6e-2211731881e2",
      "name": "Procesar con Gemini",
      "type": "n8n-nodes-base.googleGemini",
      "typeVersion": 1,
      "position": [
        -480,
        -20
      ],
      "credentials": {
        "googleGeminiApi": {
          "id": "GEMINI_CREDENTIALS",
          "name": "Gemini API"
        }
      }
    },
    {
      "parameters": {
        "chatId": "{{ secrets.TELEGRAM_TO }}",
        "text": "{{ $(\"Procesar con Gemini\").item.json.response }}",
        "additionalFields": {}
      },
      "id": "d9e8f7a6-5b3c-4f2a-8e7d-1a2b3c4d5e6f",
      "name": "Enviar a Telegram",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1,
      "position": [
        -220,
        -20
      ],
      "credentials": {
        "telegramApi": {
          "id": "TELEGRAM_CREDENTIALS",
          "name": "Telegram Bot"
        }
      }
    }
  ],
  "connections": {
    "Todos los días a las 7am": {
      "main": [
        [
          {
            "node": "Obtener Clima",
            "type": "main",
            "index": 0
          },
          {
            "node": "Obtener Noticias (BBC)",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Obtener Clima": {
      "main": [
        [
          {
            "node": "Procesar con Gemini",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Obtener Noticias (BBC)": {
      "main": [
        [
          {
            "node": "Procesar con Gemini",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Procesar con Gemini": {
      "main": [
        [
          {
            "node": "Enviar a Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "id": "DailyBriefing"
}
EOF
sudo chown terrerov:terrerov /mnt/usbdata/docker_volumes/n8n/workflows/DailyBriefing.json
