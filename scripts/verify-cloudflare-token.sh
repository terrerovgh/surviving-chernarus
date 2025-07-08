#!/bin/bash

echo "🔍 Verificación de Token de Cloudflare"
echo "====================================="
echo

# Leer variables del .env
source .env

echo "📊 Información del Token:"
echo "CLOUDFLARE_EMAIL: $CLOUDFLARE_EMAIL"
echo "Token Length: ${#CLOUDFLARE_API_TOKEN} caracteres"
echo "Token Format: ${CLOUDFLARE_API_TOKEN:0:10}..."
echo

echo "🌐 Testeando conectividad con Cloudflare API..."

# Test básico con curl
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    https://api.cloudflare.com/client/v4/user/tokens/verify)

echo "HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Token válido"

    # Obtener información del token
    echo
    echo "📋 Información del token:"
    curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
         -H "Content-Type: application/json" \
         https://api.cloudflare.com/client/v4/user/tokens/verify | jq '.'

    # Verificar si puede acceder a las zonas
    echo
    echo "🌍 Zonas disponibles:"
    curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
         -H "Content-Type: application/json" \
         https://api.cloudflare.com/client/v4/zones | jq '.result[] | {name: .name, id: .id, status: .status}'

elif [ "$HTTP_STATUS" = "401" ]; then
    echo "❌ Token inválido o sin permisos"
    echo
    echo "🔧 Soluciones:"
    echo "1. Verificar que el token sea correcto"
    echo "2. Asegurar que tenga permisos Zone:Read y DNS:Edit"
    echo "3. Verificar que no haya expirado"

elif [ "$HTTP_STATUS" = "403" ]; then
    echo "❌ Token válido pero sin permisos suficientes"
    echo
    echo "🔧 Necesitas estos permisos:"
    echo "- Zone:Read"
    echo "- DNS:Edit"
    echo "- Zone:Zone:Read"

else
    echo "❌ Error de conectividad (Status: $HTTP_STATUS)"
    echo
    echo "🔧 Verificar:"
    echo "1. Conexión a internet"
    echo "2. Formato del token"
    echo "3. Configuración de proxy/firewall"
fi

echo
echo "📖 Para crear un nuevo token:"
echo "1. Ve a https://dash.cloudflare.com/profile/api-tokens"
echo "2. Crea un token personalizado con permisos:"
echo "   - Zone:Zone:Read"
echo "   - Zone:DNS:Edit"
echo "3. Incluye tu dominio en 'Zone Resources'"
