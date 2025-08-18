#!/bin/bash
sudo tee /mnt/usbdata/docker_volumes/n8n/workflows/WebhookTester.json > /dev/null <<'EOF'
{
  "name": "Webhook Tester",
  "nodes": [
    {
      "parameters": {},
      "id": "f1a7f2f5-3e9a-4f8f-a52b-7f8a9b3c2d1e",
      "name": "When webhook is called",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [
        -820,
        -20
      ],
      "webhookId": "test-webhook"
    },
    {
      "parameters": {
        "options": {
          "response": {
            "body": "={{ $json }}"
          }
        }
      },
      "id": "a2b3c4d5-e6f7-8g9h-0i1j-k2l3m4n5o6p7",
      "name": "Respond with received data",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [
        -580,
        -20
      ]
    }
  ],
  "connections": {
    "When webhook is called": {
      "main": [
        [
          {
            "node": "Respond with received data",
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
  "id": "WebhookTester"
}
EOF
sudo chown terrerov:terrerov /mnt/usbdata/docker_volumes/n8n/workflows/WebhookTester.json