#!/bin/bash

# Script para testear la configuración de Cloudflare
echo "🧪 Testeando configuración de Cloudflare..."

# Verificar que las variables estén configuradas
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "❌ Variable CLOUDFLARE_API_TOKEN no configurada"
    echo "Configura con: export CLOUDFLARE_API_TOKEN='tu_token_aqui'"
    exit 1
fi

if [ -z "$CLOUDFLARE_EMAIL" ]; then
    echo "❌ Variable CLOUDFLARE_EMAIL no configurada"
    echo "Configura con: export CLOUDFLARE_EMAIL='contacto@terrerov.com'"
    exit 1
fi

echo "📧 Email: $CLOUDFLARE_EMAIL"
echo "🔑 Token: ${CLOUDFLARE_API_TOKEN:0:10}..."

# Testear la conexión con Cloudflare API
echo "🌐 Testeando conexión con Cloudflare API..."
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

if echo "$response" | grep -q '"success":true'; then
    echo "✅ Token válido y funcionando"

    # Obtener información de las zonas
    echo "📋 Obteniendo zonas disponibles..."
    zones=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json")

    if echo "$zones" | grep -q "terrerov.com"; then
        echo "✅ Zona terrerov.com encontrada"
    else
        echo "⚠️  Zona terrerov.com no encontrada en tu cuenta"
        echo "Zonas disponibles:"
        echo "$zones" | jq -r '.result[]?.name // empty' 2>/dev/null || echo "No se pudieron listar las zonas"
    fi
else
    echo "❌ Error en el token de Cloudflare:"
    echo "$response" | jq '.errors[]?.message // .message // .' 2>/dev/null || echo "$response"
    exit 1
fi

echo ""
echo "🚀 Si todo está correcto, ejecuta:"
echo "./scripts/configure-cloudflare-ssl.sh"
