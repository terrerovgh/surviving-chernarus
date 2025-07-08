#!/bin/bash

# monitor-services.sh - Monitor y verificar el estado de todos los servicios
# Uso: ./scripts/monitor-services.sh [--json] [--watch]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
COMPOSE_FILE="/home/terrerov/surviving-chernarus/docker-compose.yml"
BASE_DIR="/tmp/chernarus"
JSON_OUTPUT=false
WATCH_MODE=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --watch)
            WATCH_MODE=true
            shift
            ;;
        *)
            echo "Uso: $0 [--json] [--watch]"
            exit 1
            ;;
    esac
done

# Función para logging con colores
log() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

warn() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

error() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

title() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BLUE}================================${NC}"
        echo -e "${BLUE}📊 CHERNARUS SERVICES MONITOR${NC}"
        echo -e "${BLUE}================================${NC}"
    fi
}

# Función para verificar estado HTTP
check_http_service() {
    local url="$1"
    local name="$2"
    local timeout=5

    if curl -s -f -m $timeout "$url" >/dev/null 2>&1; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${GREEN}✅ $name${NC} - HTTP OK ($url)"
        fi
        return 0
    else
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${RED}❌ $name${NC} - HTTP Error ($url)"
        fi
        return 1
    fi
}

# Función para verificar estado HTTPS
check_https_service() {
    local url="$1"
    local name="$2"
    local timeout=5

    if curl -s -f -k -m $timeout "$url" >/dev/null 2>&1; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${GREEN}✅ $name${NC} - HTTPS OK ($url)"
        fi
        return 0
    else
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${RED}❌ $name${NC} - HTTPS Error ($url)"
        fi
        return 1
    fi
}

# Función para obtener información del contenedor
get_container_info() {
    local container_name="$1"

    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$container_name"; then
        local status=$(docker ps --format "{{.Status}}" -f name="$container_name")
        local ports=$(docker ps --format "{{.Ports}}" -f name="$container_name")
        local image=$(docker ps --format "{{.Image}}" -f name="$container_name")

        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "    ${CYAN}Container:${NC} $container_name"
            echo -e "    ${CYAN}Status:${NC} $status"
            echo -e "    ${CYAN}Image:${NC} $image"
            echo -e "    ${CYAN}Ports:${NC} $ports"
        fi
        return 0
    else
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "    ${RED}Container:${NC} $container_name (Not found or stopped)"
        fi
        return 1
    fi
}

# Función principal de monitoreo
monitor_services() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ "$JSON_OUTPUT" = true ]; then
        echo "{"
        echo "  \"timestamp\": \"$timestamp\","
        echo "  \"services\": ["
    else
        title
        echo -e "${CYAN}📅 Timestamp:${NC} $timestamp"
        echo ""
    fi

    # Servicios a verificar
    declare -A services
    services[traefik_proxy]="https://traefik.terrerov.com"
    services[hq_dashboard]="https://terrerov.com"
    services[n8n_engine]="https://n8n.terrerov.com"
    services[cubatattoostudio_website]="https://cts.terrerov.com"
    services[hosting_manager]="https://projects.terrerov.com"

    local first=true
    local total_services=0
    local healthy_services=0

    for container in "${!services[@]}"; do
        total_services=$((total_services + 1))
        url="${services[$container]}"

        if [ "$JSON_OUTPUT" = true ]; then
            if [ "$first" = false ]; then
                echo ","
            fi
            echo -n "    {"
            echo -n "\"container\": \"$container\", "
            echo -n "\"url\": \"$url\", "
        else
            echo -e "${BLUE}🔍 Verificando servicio: $container${NC}"
        fi

        # Verificar contenedor Docker
        local container_status="stopped"
        if get_container_info "$container" >/dev/null 2>&1; then
            container_status="running"
        fi

        # Verificar HTTP/HTTPS
        local http_status="error"
        if check_https_service "$url" "$container" >/dev/null 2>&1; then
            http_status="ok"
            healthy_services=$((healthy_services + 1))
        fi

        if [ "$JSON_OUTPUT" = true ]; then
            echo -n "\"container_status\": \"$container_status\", "
            echo -n "\"http_status\": \"$http_status\""
            echo -n "}"
            first=false
        else
            get_container_info "$container"
            if [ "$http_status" = "ok" ]; then
                check_https_service "$url" "$container"
            else
                check_https_service "$url" "$container"
            fi
            echo ""
        fi
    done

    # Verificar estado general de Docker Compose
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BLUE}🐳 Estado general de Docker Compose:${NC}"
        docker-compose -f "$COMPOSE_FILE" ps 2>/dev/null || echo "Error al obtener estado de docker-compose"
        echo ""
    fi

    # Verificar uso de recursos
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BLUE}💾 Uso de recursos:${NC}"

        # Disk usage
        echo -e "${CYAN}Espacio en disco (proyectos):${NC}"
        du -sh "$BASE_DIR" 2>/dev/null || echo "No se pudo obtener información de disco"

        # Docker containers resource usage
        echo -e "${CYAN}Uso de recursos de contenedores:${NC}"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No se pudo obtener estadísticas de Docker"
        echo ""
    fi

    # Resumen final
    local health_percentage=$((healthy_services * 100 / total_services))

    if [ "$JSON_OUTPUT" = true ]; then
        echo ""
        echo "  ],"
        echo "  \"summary\": {"
        echo "    \"total_services\": $total_services,"
        echo "    \"healthy_services\": $healthy_services,"
        echo "    \"health_percentage\": $health_percentage"
        echo "  }"
        echo "}"
    else
        echo -e "${BLUE}📊 Resumen del sistema:${NC}"
        echo -e "  ${CYAN}Servicios totales:${NC} $total_services"
        echo -e "  ${CYAN}Servicios saludables:${NC} $healthy_services"

        if [ "$health_percentage" -eq 100 ]; then
            echo -e "  ${GREEN}Estado general: 🟢 EXCELENTE ($health_percentage%)${NC}"
        elif [ "$health_percentage" -ge 80 ]; then
            echo -e "  ${YELLOW}Estado general: 🟡 BUENO ($health_percentage%)${NC}"
        else
            echo -e "  ${RED}Estado general: 🔴 PROBLEMAS ($health_percentage%)${NC}"
        fi
        echo ""
    fi
}

# Función para modo watch
watch_services() {
    while true; do
        clear
        monitor_services
        echo -e "${CYAN}🔄 Actualizando en 30 segundos... (Ctrl+C para salir)${NC}"
        sleep 30
    done
}

# Ejecutar función principal
if [ "$WATCH_MODE" = true ]; then
    watch_services
else
    monitor_services
fi
