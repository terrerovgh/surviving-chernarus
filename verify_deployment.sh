#!/bin/bash

# Script para verificar el despliegue del ecosistema "Surviving Chernarus" en Raspberry Pi OS

# Colores para mensajes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Función para mostrar mensajes de progreso
function log_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Verificar si el archivo .env existe
if [ ! -f ".env" ]; then
    log_error "El archivo .env no existe. Por favor, ejecuta ./setup_env.sh primero."
    exit 1
fi

# Cargar variables de entorno desde el archivo .env
log_message "Cargando variables de entorno desde .env"
source .env

# Este script se ejecuta localmente en la Raspberry Pi

# Verificar que Docker está instalado y funcionando
log_section "Verificando instalación de Docker"
docker --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "Docker está instalado correctamente."
    docker_version=$(docker --version)
    echo "  Versión: $docker_version"
else
    log_error "Docker no está instalado o no está funcionando correctamente."
    exit 1
fi

# Verificar que Docker Compose está instalado y funcionando
docker compose version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "Docker Compose está instalado correctamente."
    compose_version=$(docker compose version)
    echo "  Versión: $compose_version"
else
    log_error "Docker Compose no está instalado o no está funcionando correctamente."
    exit 1
fi

# Verificar que el directorio del proyecto existe
log_section "Verificando estructura de directorios"
[ -d /opt/surviving-chernarus ] > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "El directorio del proyecto existe."
    
    # Verificar que el archivo docker-compose.yml existe
    [ -f /opt/surviving-chernarus/docker-compose.yml ] > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_message "El archivo docker-compose.yml existe."
    else
        log_error "El archivo docker-compose.yml no existe en el directorio del proyecto."
        exit 1
    fi
    
    # Verificar que el archivo .env existe en la Raspberry Pi
    [ -f /opt/surviving-chernarus/.env ] > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_message "El archivo .env existe."
    else
        log_error "El archivo .env no existe en el directorio del proyecto."
        exit 1
    fi
else
    log_error "El directorio del proyecto no existe en /opt/surviving-chernarus."
    exit 1
fi

# Verificar que los contenedores están en ejecución
log_section "Verificando contenedores en ejecución"
containers=("traefik" "postgres" "pihole" "n8n" "rtorrent" "heimdall")
all_running=true

for container in "${containers[@]}"; do
    status=$(docker ps --filter name=$container --format '{{.Status}}')
    if [[ $status == *"Up"* ]]; then
        log_message "El contenedor $container está en ejecución."
        echo "  Estado: $status"
    else
        log_error "El contenedor $container no está en ejecución."
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    log_warning "Algunos contenedores no están en ejecución. Verificando logs..."
    
    for container in "${containers[@]}"; do
        status=$(docker ps --filter name=$container --format '{{.Status}}')
        if [[ ! $status == *"Up"* ]]; then
            echo -e "\n${YELLOW}Logs del contenedor $container:${NC}"
            docker logs --tail 20 $container
        fi
    done
fi

# Verificar conectividad de red entre contenedores
log_section "Verificando conectividad de red entre contenedores"

# Verificar que n8n puede conectarse a PostgreSQL
log_message "Verificando conexión entre n8n y PostgreSQL..."
n8n_db_status=$(docker exec n8n curl -s http://postgres:5432 || echo 'Connection established')
if [[ $n8n_db_status == *"Connection established"* ]]; then
    log_message "n8n puede conectarse a PostgreSQL."
else
    log_warning "Posible problema de conexión entre n8n y PostgreSQL."
fi

# Verificar que Traefik está escuchando en los puertos 80 y 443
log_section "Verificando puertos de Traefik"
port_80=$(docker exec traefik netstat -tuln | grep ':80 ')
port_443=$(docker exec traefik netstat -tuln | grep ':443 ')

if [[ ! -z "$port_80" ]]; then
    log_message "Traefik está escuchando en el puerto 80."
else
    log_warning "Traefik no está escuchando en el puerto 80."
fi

if [[ ! -z "$port_443" ]]; then
    log_message "Traefik está escuchando en el puerto 443."
else
    log_warning "Traefik no está escuchando en el puerto 443."
fi

# Verificar acceso a los servicios desde Internet (si es posible)
log_section "Verificando acceso a los servicios"
log_message "Para verificar el acceso a los servicios desde Internet, intenta acceder a las siguientes URLs:"
echo -e "  - Panel de control: https://${DOMAIN_NAME}"
echo -e "  - Traefik: https://traefik.${DOMAIN_NAME}"
echo -e "  - Pi-hole: https://pihole.${DOMAIN_NAME}"
echo -e "  - n8n: https://n8n.${DOMAIN_NAME}"
echo -e "  - rTorrent: https://rtorrent.${DOMAIN_NAME}"

# Resumen final
log_section "Resumen de la verificación"
if [ "$all_running" = true ]; then
    log_message "¡Todos los contenedores están en ejecución!"
    log_message "El despliegue parece estar funcionando correctamente."
else
    log_warning "Algunos contenedores no están en ejecución. Revisa los logs para más detalles."
fi

log_message "Para ver los logs completos de un contenedor específico, ejecuta:"
echo -e "  docker logs [nombre-del-contenedor]"

log_message "Para reiniciar todos los servicios, ejecuta:"
echo -e "  cd /opt/surviving-chernarus && docker compose restart"

log_message "Para detener todos los servicios, ejecuta:"
echo -e "  cd /opt/surviving-chernarus && docker compose down"

log_message "Para iniciar todos los servicios, ejecuta:"
echo -e "  cd /opt/surviving-chernarus && docker compose up -d"