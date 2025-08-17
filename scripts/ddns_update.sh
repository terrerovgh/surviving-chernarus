#!/bin/bash

# Carga las variables de entorno desde el archivo .env
source /home/terrerov/.env

# --- Configuración ---
RECORD_NAME="rpi.${DOMAIN}"
ZONE_ID="${CF_ZONE_ID}"

# --- Lógica del Script ---
echo "Iniciando actualización de DDNS para ${RECORD_NAME}..."

if [ -z "${ZONE_ID}" ]; then
  echo "Error: La variable CF_ZONE_ID no está configurada en ~/.env."
  exit 1
fi

# Obtener la IP pública actual de la máquina
CURRENT_IP=$(curl -s https://api.ipify.org)
if [ -z "${CURRENT_IP}" ]; then
  echo "Error: No se pudo obtener la IP pública actual."
  exit 1
fi
echo "IP pública actual: ${CURRENT_IP}"

# Obtener la información del registro DNS, incluyendo su IP actual
DNS_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json")

RECORD_IP=$(echo $DNS_RECORD | jq -r '.result[0].content')
RECORD_ID=$(echo $DNS_RECORD | jq -r '.result[0].id')

echo "IP registrada en Cloudflare: ${RECORD_IP}"

# Si el registro no existe, RECORD_ID será null. En ese caso, lo creamos.
if [ "${RECORD_ID}" == "null" ]; then
  echo "El registro A para ${RECORD_NAME} no existe. Creándolo..."
  CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"${RECORD_NAME}"'","content":"'"${CURRENT_IP}"'","ttl":120,"proxied":false}')

  if [ "$(echo "${CREATE_RESPONSE}" | jq -r '.success')" == "true" ]; then
    echo "¡Éxito! El registro DNS ha sido creado con la IP ${CURRENT_IP}."
    exit 0
  else
    echo "Error: La creación del registro DNS falló."
    echo "Respuesta de Cloudflare: $(echo ${CREATE_RESPONSE} | jq .errors)"
    exit 1
  fi
fi

# Comparar la IP actual con la registrada y actualizar si es necesario
if [ "${CURRENT_IP}" == "${RECORD_IP}" ]; then
  echo "Las IPs coinciden. No se necesita actualización."
  exit 0
fi

echo "Las IPs son diferentes. Actualizando el registro DNS en Cloudflare..."

UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"'"${RECORD_NAME}"'","content":"'"${CURRENT_IP}"'","ttl":120,"proxied":false}')

if [ "$(echo "${UPDATE_RESPONSE}" | jq -r '.success')" == "true" ]; then
  echo "¡Éxito! El registro DNS ha sido actualizado a ${CURRENT_IP}."
else
  echo "Error: La actualización del registro DNS falló."
  echo "Respuesta de Cloudflare: $(echo ${UPDATE_RESPONSE} | jq .errors)"
  exit 1
fi