#!/bin/bash

# Carga las variables de entorno desde el archivo .env
source /home/terrerov/.env

# --- Configuración ---
# Único subdominio a actualizar.
SUBDOMAIN="rpi"
RECORD_NAME="${SUBDOMAIN}.${DOMAIN}"
ZONE_ID="${CF_ZONE_ID}"

# --- Lógica del Script ---
echo "=============================================="
echo "Iniciando actualización de DDNS para ${RECORD_NAME}..."
echo "Fecha: $(date)"
echo "=============================================="

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
echo "IP pública actual detectada: ${CURRENT_IP}"

# Obtener la información del registro DNS
DNS_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json")

RECORD_IP=$(echo $DNS_RECORD | jq -r '.result[0].content')
RECORD_ID=$(echo $DNS_RECORD | jq -r '.result[0].id')

# Si el registro no existe, lo creamos.
if [ "${RECORD_ID}" == "null" ]; then
  echo "El registro A no existe. Creándolo..."
  CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"${RECORD_NAME}"'","content":"'"${CURRENT_IP}"'","ttl":120,"proxied":false}')

  if [ "$(echo "${CREATE_RESPONSE}" | jq -r '.success')" == "true" ]; then
    echo "¡Éxito! Registro creado con la IP ${CURRENT_IP}."
  else
    echo "Error: La creación del registro falló."
    echo "Respuesta de Cloudflare: $(echo ${CREATE_RESPONSE} | jq .errors)"
  fi
# Si el registro existe, comparamos la IP.
elif [ "${CURRENT_IP}" != "${RECORD_IP}" ]; then
  echo "La IP registrada (${RECORD_IP}) es diferente. Actualizando..."
  UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"${RECORD_NAME}"'","content":"'"${CURRENT_IP}"'","ttl":120,"proxied":false}')

  if [ "$(echo "${UPDATE_RESPONSE}" | jq -r '.success')" == "true" ]; then
    echo "¡Éxito! Registro actualizado a ${CURRENT_IP}."
  else
    echo "Error: La actualización del registro falló."
    echo "Respuesta de Cloudflare: $(echo ${UPDATE_RESPONSE} | jq .errors)"
  fi
else
  echo "La IP registrada (${RECORD_IP}) es correcta. No se necesita actualización."
fi

echo "=============================================="
echo "Actualización de DDNS finalizada."