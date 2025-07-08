#!/bin/bash

# health-check.sh - Sistema de verificación de salud y alertas para Chernarus
# Uso: ./scripts/health-check.sh [--alert] [--email user@domain.com] [--webhook url]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables de configuración
BASE_DIR="/tmp/chernarus"
PROJECT_DIR="/home/terrerov/surviving-chernarus"
HEALTH_REPORT_FILE="$BASE_DIR/health_report_$(date +%Y%m%d_%H%M%S).json"
ALERT_MODE=false
EMAIL_ALERT=""
WEBHOOK_URL=""

# Umbrales de alerta
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90
RESPONSE_TIME_THRESHOLD=5000  # 5 segundos en ms

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --alert)
            ALERT_MODE=true
            shift
            ;;
        --email)
            EMAIL_ALERT="$2"
            shift 2
            ;;
        --webhook)
            WEBHOOK_URL="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 [--alert] [--email user@domain.com] [--webhook url]"
            exit 1
            ;;
    esac
done

# Función para logging con colores
log() {
    echo -e "${GREEN}[HEALTH]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

title() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🏥 CHERNARUS HEALTH CHECK${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Función para verificar servicios Docker
check_docker_services() {
    local services_status=()
    local critical_services=("traefik_proxy" "postgres_db" "n8n_engine" "hq_dashboard")

    log "🐳 Verificando servicios Docker..."

    for service in "${critical_services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            local status=$(docker inspect "${service}" --format="{{.State.Status}}")
            local health=$(docker inspect "${service}" --format="{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health-check{{end}}")

            if [ "$status" = "running" ]; then
                services_status+=("{\"service\": \"$service\", \"status\": \"healthy\", \"docker_status\": \"$status\", \"health_check\": \"$health\"}")
                log "✅ $service está ejecutándose correctamente"
            else
                services_status+=("{\"service\": \"$service\", \"status\": \"critical\", \"docker_status\": \"$status\", \"health_check\": \"$health\"}")
                error "❌ $service no está ejecutándose (Estado: $status)"
            fi
        else
            services_status+=("{\"service\": \"$service\", \"status\": \"missing\", \"docker_status\": \"not_found\", \"health_check\": \"none\"}")
            error "❌ $service no encontrado"
        fi
    done

    echo "${services_status[@]}"
}

# Función para verificar conectividad HTTP/HTTPS
check_web_services() {
    local web_status=()
    declare -A web_services
    web_services[traefik]="https://traefik.terrerov.com"
    web_services[hq]="https://terrerov.com"
    web_services[n8n]="https://n8n.terrerov.com"
    web_services[cts]="https://cts.terrerov.com"
    web_services[projects]="https://projects.terrerov.com"

    log "🌐 Verificando servicios web..."

    for service in "${!web_services[@]}"; do
        local url="${web_services[$service]}"
        local start_time=$(date +%s%3N)

        if curl -s -f -k -m 10 "$url" >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            local response_time=$((end_time - start_time))

            if [ "$response_time" -lt "$RESPONSE_TIME_THRESHOLD" ]; then
                web_status+=("{\"service\": \"$service\", \"url\": \"$url\", \"status\": \"healthy\", \"response_time\": $response_time}")
                log "✅ $service responde correctamente (${response_time}ms)"
            else
                web_status+=("{\"service\": \"$service\", \"url\": \"$url\", \"status\": \"slow\", \"response_time\": $response_time}")
                warn "⚠️ $service responde lentamente (${response_time}ms > ${RESPONSE_TIME_THRESHOLD}ms)"
            fi
        else
            web_status+=("{\"service\": \"$service\", \"url\": \"$url\", \"status\": \"critical\", \"response_time\": null}")
            error "❌ $service no responde ($url)"
        fi
    done

    echo "${web_status[@]}"
}

# Función para verificar uso de recursos
check_system_resources() {
    log "💾 Verificando recursos del sistema..."

    # CPU Usage
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" | sed 's/%//' | awk '{sum+=$1} END {print int(sum)}')

    # Memory Usage
    local memory_stats=$(docker stats --no-stream --format "{{.MemUsage}}" | head -1)
    local memory_used=$(echo "$memory_stats" | cut -d'/' -f1 | sed 's/[^0-9.]//g')
    local memory_total=$(echo "$memory_stats" | cut -d'/' -f2 | sed 's/[^0-9.]//g')
    local memory_percentage=$(echo "scale=0; $memory_used * 100 / $memory_total" | bc -l 2>/dev/null || echo "0")

    # Disk Usage
    local disk_usage=$(df "$BASE_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')

    # Network connectivity
    local network_status="healthy"
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        network_status="critical"
        error "❌ Sin conectividad a Internet"
    fi

    # Verificar umbrales
    local resource_alerts=()

    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        resource_alerts+=("CPU usage high: ${cpu_usage}%")
        warn "⚠️ Uso de CPU alto: ${cpu_usage}% (umbral: ${CPU_THRESHOLD}%)"
    fi

    if [ "$memory_percentage" -gt "$MEMORY_THRESHOLD" ]; then
        resource_alerts+=("Memory usage high: ${memory_percentage}%")
        warn "⚠️ Uso de memoria alto: ${memory_percentage}% (umbral: ${MEMORY_THRESHOLD}%)"
    fi

    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        resource_alerts+=("Disk usage high: ${disk_usage}%")
        warn "⚠️ Uso de disco alto: ${disk_usage}% (umbral: ${DISK_THRESHOLD}%)"
    fi

    local resource_status
    if [ ${#resource_alerts[@]} -eq 0 ]; then
        resource_status="healthy"
        log "✅ Recursos del sistema en niveles normales"
    else
        resource_status="warning"
    fi

    cat << EOF
{
    "cpu_usage": $cpu_usage,
    "cpu_threshold": $CPU_THRESHOLD,
    "memory_usage": $memory_percentage,
    "memory_threshold": $MEMORY_THRESHOLD,
    "disk_usage": $disk_usage,
    "disk_threshold": $DISK_THRESHOLD,
    "network_status": "$network_status",
    "status": "$resource_status",
    "alerts": [$(IFS=,; echo "\"${resource_alerts[*]//,/\",\"}\"")]
}
EOF
}

# Función para verificar certificados SSL
check_ssl_certificates() {
    log "🔐 Verificando certificados SSL..."

    local cert_status=()
    local domains=("terrerov.com" "traefik.terrerov.com" "n8n.terrerov.com" "cts.terrerov.com" "projects.terrerov.com")

    for domain in "${domains[@]}"; do
        local cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)

        if [ -n "$cert_info" ]; then
            local expire_date=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2)
            local expire_timestamp=$(date -d "$expire_date" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local days_until_expiry=$(( (expire_timestamp - current_timestamp) / 86400 ))

            if [ "$days_until_expiry" -gt 30 ]; then
                cert_status+=("{\"domain\": \"$domain\", \"status\": \"healthy\", \"days_until_expiry\": $days_until_expiry}")
                log "✅ Certificado de $domain válido por $days_until_expiry días"
            elif [ "$days_until_expiry" -gt 7 ]; then
                cert_status+=("{\"domain\": \"$domain\", \"status\": \"warning\", \"days_until_expiry\": $days_until_expiry}")
                warn "⚠️ Certificado de $domain expira en $days_until_expiry días"
            else
                cert_status+=("{\"domain\": \"$domain\", \"status\": \"critical\", \"days_until_expiry\": $days_until_expiry}")
                error "❌ Certificado de $domain expira pronto ($days_until_expiry días)"
            fi
        else
            cert_status+=("{\"domain\": \"$domain\", \"status\": \"error\", \"days_until_expiry\": null}")
            error "❌ No se pudo verificar certificado de $domain"
        fi
    done

    echo "${cert_status[@]}"
}

# Función para verificar backups
check_backup_status() {
    log "💾 Verificando estado de backups..."

    local backup_dir="$BASE_DIR/backups"
    local backup_status="healthy"
    local latest_backup=""
    local backup_age=999

    if [ -d "$backup_dir" ]; then
        latest_backup=$(ls -t "$backup_dir"/chernarus_backup_*.tar.gz 2>/dev/null | head -1)

        if [ -n "$latest_backup" ]; then
            local backup_date=$(stat -c %Y "$latest_backup")
            local current_date=$(date +%s)
            backup_age=$(( (current_date - backup_date) / 86400 ))

            if [ "$backup_age" -le 7 ]; then
                log "✅ Backup reciente encontrado (${backup_age} días)"
            elif [ "$backup_age" -le 30 ]; then
                backup_status="warning"
                warn "⚠️ Último backup tiene ${backup_age} días"
            else
                backup_status="critical"
                error "❌ Último backup muy antiguo (${backup_age} días)"
            fi
        else
            backup_status="critical"
            error "❌ No se encontraron backups"
        fi
    else
        backup_status="critical"
        error "❌ Directorio de backups no existe"
    fi

    cat << EOF
{
    "status": "$backup_status",
    "latest_backup": "$(basename "$latest_backup" 2>/dev/null || echo "none")",
    "backup_age_days": $backup_age,
    "backup_directory": "$backup_dir"
}
EOF
}

# Función para generar reporte de salud
generate_health_report() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local docker_services=$(check_docker_services)
    local web_services=$(check_web_services)
    local system_resources=$(check_system_resources)
    local ssl_certificates=$(check_ssl_certificates)
    local backup_status=$(check_backup_status)

    # Calcular estado general
    local overall_status="healthy"

    # Verificar si hay servicios críticos
    if echo "$docker_services" | grep -q '"status": "critical"' || echo "$docker_services" | grep -q '"status": "missing"'; then
        overall_status="critical"
    elif echo "$web_services" | grep -q '"status": "critical"'; then
        overall_status="critical"
    elif echo "$system_resources" | grep -q '"status": "warning"' || echo "$ssl_certificates" | grep -q '"status": "warning"'; then
        overall_status="warning"
    fi

    cat > "$HEALTH_REPORT_FILE" << EOF
{
    "timestamp": "$timestamp",
    "overall_status": "$overall_status",
    "infrastructure": "Surviving Chernarus",
    "checks": {
        "docker_services": [$(echo "$docker_services" | tr ' ' ',')],
        "web_services": [$(echo "$web_services" | tr ' ' ',')],
        "system_resources": $system_resources,
        "ssl_certificates": [$(echo "$ssl_certificates" | tr ' ' ',')],
        "backup_status": $backup_status
    }
}
EOF

    log "📋 Reporte de salud generado: $HEALTH_REPORT_FILE"
    echo "$overall_status"
}

# Función para enviar alertas
send_alerts() {
    local health_status="$1"

    if [ "$ALERT_MODE" = true ] && [ "$health_status" != "healthy" ]; then
        log "🚨 Enviando alertas..."

        local alert_message="CHERNARUS HEALTH ALERT: Sistema en estado $health_status - $(date)"

        # Email alert
        if [ -n "$EMAIL_ALERT" ]; then
            if command -v mail >/dev/null 2>&1; then
                echo "Reporte de salud adjunto" | mail -s "Chernarus Health Alert" -A "$HEALTH_REPORT_FILE" "$EMAIL_ALERT"
                log "📧 Alerta enviada por email a $EMAIL_ALERT"
            else
                warn "⚠️ Comando 'mail' no disponible para envío de email"
            fi
        fi

        # Webhook alert
        if [ -n "$WEBHOOK_URL" ]; then
            curl -s -X POST "$WEBHOOK_URL" \
                -H "Content-Type: application/json" \
                -d "{\"text\": \"$alert_message\", \"status\": \"$health_status\"}" >/dev/null
            log "🔗 Alerta enviada via webhook"
        fi

        # N8N webhook (si está disponible)
        if curl -s -f "https://n8n.terrerov.com" >/dev/null 2>&1; then
            # Aquí podrías enviar a un webhook de N8N para automatización adicional
            log "💡 Considera configurar un webhook de N8N para automatización de alertas"
        fi
    fi
}

# Función principal
main() {
    title

    local start_time=$(date +%s)

    log "🚀 Iniciando verificación de salud del sistema..."

    # Crear directorio para reportes si no existe
    mkdir -p "$(dirname "$HEALTH_REPORT_FILE")"

    # Ejecutar verificaciones y generar reporte
    local health_status=$(generate_health_report)

    local end_time=$(date +%s)
    local check_duration=$((end_time - start_time))

    # Mostrar resumen
    echo ""
    log "📊 Resumen de verificación:"
    log "   Estado general: $([ "$health_status" = "healthy" ] && echo "🟢 SALUDABLE" || ([ "$health_status" = "warning" ] && echo "🟡 ADVERTENCIAS" || echo "🔴 CRÍTICO"))"
    log "   Duración: ${check_duration}s"
    log "   Reporte: $HEALTH_REPORT_FILE"

    # Enviar alertas si es necesario
    send_alerts "$health_status"

    # Mostrar recomendaciones
    if [ "$health_status" != "healthy" ]; then
        echo ""
        warn "🔧 Recomendaciones:"
        warn "   1. Revisar el reporte detallado: cat $HEALTH_REPORT_FILE"
        warn "   2. Verificar logs de servicios: docker-compose logs"
        warn "   3. Reiniciar servicios problemáticos si es necesario"
        warn "   4. Contactar al administrador si persisten los problemas"
    fi

    # Retornar código de salida basado en el estado
    case "$health_status" in
        "healthy") exit 0 ;;
        "warning") exit 1 ;;
        "critical") exit 2 ;;
    esac
}

# Verificar dependencias
if ! command -v docker >/dev/null 2>&1; then
    error "❌ Docker no está instalado o no está en PATH"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    error "❌ curl no está instalado"
    exit 1
fi

# Ejecutar función principal
main
