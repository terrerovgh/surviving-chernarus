#!/bin/bash

# Script para actualizar subdominios de Cloudflare con IP dinámica
# Este script se ejecutará como CronJob en Kubernetes

set -e

# Variables de configuración
ZONE_NAME="terrerov.com"
SUBDOMINIOS=("terrerov.com" "hq" "n8n" "traefik" "pihole" "api")

# Verificar variables de entorno requeridas
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_EMAIL" ]; then
    echo "Error: Variables CLOUDFLARE_API_TOKEN y CLOUDFLARE_EMAIL son requeridas"
    exit 1
fi

# Obtener IP pública actual
echo "🌐 Obteniendo IP pública actual..."
CURRENT_IP=$(curl -s https://ipv4.icanhazip.com/ || curl -s https://api.ipify.org/ || curl -s https://checkip.amazonaws.com/)

if [ -z "$CURRENT_IP" ]; then
    echo "❌ Error: No se pudo obtener la IP pública"
    exit 1
fi

echo "📍 IP pública actual: $CURRENT_IP"

# Obtener Zone ID de Cloudflare
echo "🔍 Obteniendo Zone ID para $ZONE_NAME..."
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" | \
    jq -r '.result[0].id')

if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
    echo "❌ Error: No se pudo obtener el Zone ID para $ZONE_NAME"
    exit 1
fi

echo "✅ Zone ID obtenido: $ZONE_ID"

# Función para actualizar un registro DNS
update_dns_record() {
    local subdomain=$1
    local record_name

    if [ "$subdomain" = "$ZONE_NAME" ]; then
        record_name="$ZONE_NAME"
    else
        record_name="$subdomain.$ZONE_NAME"
    fi

    echo "🔄 Actualizando $record_name..."

    # Obtener record ID existente
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$record_name&type=A" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" | \
        jq -r '.result[0].id')

    if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
        # Crear nuevo registro
        echo "📝 Creando nuevo registro A para $record_name"
        RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$CURRENT_IP\",\"ttl\":300}")
    else
        # Actualizar registro existente
        echo "🔄 Actualizando registro A existente para $record_name"
        RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$CURRENT_IP\",\"ttl\":300}")
    fi

    # Verificar respuesta
    if echo "$RESPONSE" | jq -r '.success' | grep -q true; then
        echo "✅ $record_name actualizado correctamente"
    else
        echo "❌ Error actualizando $record_name:"
        echo "$RESPONSE" | jq -r '.errors[]?.message // .message'
    fi
}

# Actualizar todos los subdominios
echo "🚀 Iniciando actualización de subdominios..."
for subdomain in "${SUBDOMINIOS[@]}"; do
    update_dns_record "$subdomain"
    sleep 1  # Evitar rate limiting
done

echo "🎉 Actualización de DNS completada!"

# Verificar algunos registros
echo "🔍 Verificando registros DNS..."
for subdomain in "${SUBDOMINIOS[@]}"; do
    if [ "$subdomain" = "$ZONE_NAME" ]; then
        record_name="$ZONE_NAME"
    else
        record_name="$subdomain.$ZONE_NAME"
    fi

    resolved_ip=$(nslookup "$record_name" 8.8.8.8 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}' || echo "No resuelve")
    echo "📍 $record_name -> $resolved_ip"
done
