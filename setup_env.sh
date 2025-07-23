#!/bin/bash

# Script para configurar el archivo .env para el proyecto "Surviving Chernarus"

# Colores para mensajes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${GREEN}=== Configuración del archivo .env para Surviving Chernarus ===${NC}\n"
echo -e "Este script te ayudará a configurar el archivo .env con tus propios valores.\n"

# Verificar si el archivo .env ya existe
if [ -f ".env" ]; then
    echo -e "${YELLOW}ADVERTENCIA: El archivo .env ya existe.${NC}"
    read -p "¿Deseas sobrescribirlo? (s/n): " overwrite
    if [[ $overwrite != "s" && $overwrite != "S" ]]; then
        echo -e "\n${BLUE}Operación cancelada. El archivo .env no ha sido modificado.${NC}"
        exit 0
    fi
fi

# Función para solicitar un valor con un valor predeterminado
function ask_value() {
    local prompt=$1
    local default=$2
    local var_name=$3
    local is_password=$4
    
    if [ "$is_password" = true ]; then
        read -p "$prompt [$default]: " -s temp_value
        echo ""
    else
        read -p "$prompt [$default]: " temp_value
    fi
    
    if [ -z "$temp_value" ]; then
        eval $var_name="$default"
    else
        eval $var_name="$temp_value"
    fi
}

# Obtener valores para el archivo .env
echo -e "\n${BLUE}Configuración de usuario y grupo:${NC}"
echo "Ejecuta 'id -u' y 'id -g' en tu Raspberry Pi para obtener estos valores."
ask_value "PUID (ID de usuario)" "1000" PUID false
ask_value "PGID (ID de grupo)" "1000" PGID false

echo -e "\n${BLUE}Configuración de zona horaria:${NC}"
ask_value "TZ (Zona horaria)" "Europe/Madrid" TZ false

echo -e "\n${BLUE}Configuración de dominio y Cloudflare:${NC}"
ask_value "DOMAIN_NAME (Nombre de dominio)" "terrerov.com" DOMAIN_NAME false
ask_value "HOST_NAME (Nombre del host)" "rpi.terrerov.com" HOST_NAME false
ask_value "CLOUDFLARE_EMAIL (Email de Cloudflare)" "user@example.com" CLOUDFLARE_EMAIL false
ask_value "CLOUDFLARE_API_TOKEN (Token de API de Cloudflare)" "your_cloudflare_api_token" CLOUDFLARE_API_TOKEN true

echo -e "\n${BLUE}Configuración de PostgreSQL:${NC}"
ask_value "POSTGRES_DB (Nombre de la base de datos)" "n8n_chernarus" POSTGRES_DB false
ask_value "POSTGRES_USER (Usuario de PostgreSQL)" "chernarus_admin" POSTGRES_USER false
ask_value "POSTGRES_PASSWORD (Contraseña de PostgreSQL)" "StrongPasswordHere123!" POSTGRES_PASSWORD true

echo -e "\n${BLUE}Configuración de Pi-hole:${NC}"
ask_value "PIHOLE_PASSWORD (Contraseña de Pi-hole)" "SecurePiholePassword123!" PIHOLE_PASSWORD true

echo -e "\n${BLUE}Configuración de Traefik:${NC}"
echo "La contraseña para el dashboard de Traefik:"
ask_value "TRAEFIK_USER (Usuario para el dashboard de Traefik)" "admin" TRAEFIK_USER false
ask_value "TRAEFIK_PASSWORD (Contraseña para el dashboard de Traefik)" "secure_password" TRAEFIK_PASSWORD true

# Generar hash de contraseña para Traefik
echo "Generando hash de contraseña para Traefik..."
if command -v htpasswd > /dev/null 2>&1; then
    HASHED_PASSWORD="$(htpasswd -nb $TRAEFIK_USER $TRAEFIK_PASSWORD)"
else
    echo "${YELLOW}ADVERTENCIA: htpasswd no está instalado. Se usará un hash predeterminado.${NC}"
    echo "${YELLOW}Se recomienda instalar apache2-utils y regenerar el hash más tarde.${NC}"
    # Hash predeterminado para admin:secure_password (cambiar manualmente después)
    HASHED_PASSWORD="$TRAEFIK_USER:\$apr1\$ruca84Hq\$mbjdMZBAG.KWn7vfN/SNK/"
fi

echo -e "\n${BLUE}Configuración de red:${NC}"
ask_value "RPI_IP (IP de la Raspberry Pi)" "192.168.0.2/25" RPI_IP false
ask_value "RPI_GATEWAY (Gateway de la Raspberry Pi)" "192.168.0.1" RPI_GATEWAY false
ask_value "RPI_DNS (DNS primario de la Raspberry Pi)" "1.1.1.1" RPI_DNS1 false
ask_value "RPI_DNS2 (DNS secundario de la Raspberry Pi)" "127.0.0.1" RPI_DNS2 false
ask_value "RPI_USER (Usuario de la Raspberry Pi)" "terrerov" RPI_USER false

# Crear el archivo .env
cat > .env << EOF
# Variables de entorno para el proyecto "Surviving Chernarus"
# Generado automáticamente por setup_env.sh

# IDs de usuario y grupo para permisos de archivos
PUID=$PUID
PGID=$PGID

# Zona horaria
TZ=$TZ

# Configuración de dominio y Cloudflare
DOMAIN_NAME=$DOMAIN_NAME
HOST_NAME=$HOST_NAME
CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Configuración de PostgreSQL
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Configuración de Traefik
TRAEFIK_USER=$TRAEFIK_USER
TRAEFIK_PASSWORD=$TRAEFIK_PASSWORD

# Contraseña para Pi-hole
PIHOLE_PASSWORD=$PIHOLE_PASSWORD

# Contraseña hasheada para Traefik Dashboard
HASHED_PASSWORD=$HASHED_PASSWORD

# Configuración de red de la Raspberry Pi
RPI_IP=$RPI_IP
RPI_GATEWAY=$RPI_GATEWAY
RPI_DNS1=$RPI_DNS1
RPI_DNS2=$RPI_DNS2
RPI_USER=$RPI_USER
EOF

echo -e "\n${GREEN}¡Archivo .env creado con éxito!${NC}"
echo -e "Ahora puedes ejecutar ./deploy.sh para desplegar el ecosistema en tu Raspberry Pi.\n"
echo -e "${YELLOW}NOTA:${NC} Este script ha sido configurado con los valores proporcionados para tu Raspberry Pi OS."
echo -e "Asegúrate de que la configuración de red es correcta antes de continuar.\n"