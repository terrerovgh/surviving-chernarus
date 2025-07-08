#!/bin/bash

# dashboard.sh - Dashboard interactivo para la infraestructura Chernarus
# Uso: ./scripts/dashboard.sh

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables
PROJECT_DIR="/home/terrerov/surviving-chernarus"
BASE_DIR="/tmp/chernarus"

# Función para limpiar pantalla
clear_screen() {
    clear
}

# Función para mostrar header
show_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    ${WHITE}🌟 SURVIVING CHERNARUS DASHBOARD 🌟${BLUE}                  ║${NC}"
    echo -e "${BLUE}║                        ${CYAN}Infrastructure Control Center${BLUE}                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📅 $(date '+%Y-%m-%d %H:%M:%S')${NC} | ${GREEN}🖥️ $(hostname)${NC} | ${YELLOW}👤 $(whoami)${NC}"
    echo ""
}

# Función para mostrar estado de servicios
show_services_status() {
    echo -e "${WHITE}🐳 DOCKER SERVICES STATUS${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

    # Obtener información de contenedores
    if docker ps >/dev/null 2>&1; then
        local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | tail -n +2)

        if [ -n "$containers" ]; then
            echo -e "${GREEN}✅ Docker está ejecutándose${NC}"
            echo ""

            # Servicios críticos
            local critical_services=("traefik_proxy" "postgres_db" "n8n_engine" "hq_dashboard")
            for service in "${critical_services[@]}"; do
                if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
                    local status=$(docker ps --format "{{.Status}}" -f name="$service")
                    echo -e "  ${GREEN}🟢${NC} ${WHITE}$service${NC} - ${GREEN}$status${NC}"
                else
                    echo -e "  ${RED}🔴${NC} ${WHITE}$service${NC} - ${RED}NOT RUNNING${NC}"
                fi
            done

            # Servicios de proyectos web
            echo ""
            echo -e "${CYAN}📱 Web Projects:${NC}"
            local web_services=("cts_website" "hosting_manager")
            for service in "${web_services[@]}"; do
                if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
                    echo -e "  ${GREEN}🟢${NC} ${WHITE}$service${NC} - ${GREEN}Running${NC}"
                else
                    echo -e "  ${YELLOW}🟡${NC} ${WHITE}$service${NC} - ${YELLOW}Stopped${NC}"
                fi
            done
        else
            echo -e "${RED}❌ No hay contenedores ejecutándose${NC}"
        fi
    else
        echo -e "${RED}❌ Docker no está disponible${NC}"
    fi

    echo ""
}

# Función para mostrar estado de servicios web
show_web_status() {
    echo -e "${WHITE}🌐 WEB SERVICES STATUS${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

    declare -A web_services
    web_services["🏢 HQ Dashboard"]="https://terrerov.com"
    web_services["🔀 Traefik Panel"]="https://traefik.terrerov.com"
    web_services["⚙️ N8N Automation"]="https://n8n.terrerov.com"
    web_services["🎨 CTS Website"]="https://cts.terrerov.com"
    web_services["📊 Projects Manager"]="https://projects.terrerov.com"

    for service in "${!web_services[@]}"; do
        local url="${web_services[$service]}"
        if curl -s -f -k -m 5 "$url" >/dev/null 2>&1; then
            echo -e "  ${GREEN}🟢${NC} $service - ${GREEN}Online${NC} ${CYAN}($url)${NC}"
        else
            echo -e "  ${RED}🔴${NC} $service - ${RED}Offline${NC} ${CYAN}($url)${NC}"
        fi
    done

    echo ""
}

# Función para mostrar recursos del sistema
show_system_resources() {
    echo -e "${WHITE}💾 SYSTEM RESOURCES${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

    # CPU y memoria de contenedores Docker
    if docker stats --no-stream >/dev/null 2>&1; then
        echo -e "${CYAN}🖥️ Container Resources:${NC}"
        docker stats --no-stream --format "  {{.Name}}: ${GREEN}CPU {{.CPUPerc}}${NC} | ${YELLOW}RAM {{.MemUsage}}${NC}" | head -6
    fi

    echo ""

    # Espacio en disco
    echo -e "${CYAN}💿 Disk Usage:${NC}"
    local disk_usage=$(df -h "$BASE_DIR" 2>/dev/null | tail -1 | awk '{print $5 " used of " $2}' || echo "N/A")
    echo -e "  ${WHITE}Projects Directory:${NC} $disk_usage"

    local docker_disk=$(docker system df --format "{{.Type}}: {{.Size}}" 2>/dev/null | tr '\n' ', ' || echo "N/A")
    echo -e "  ${WHITE}Docker Usage:${NC} $docker_disk"

    echo ""
}

# Función para mostrar certificados SSL
show_ssl_status() {
    echo -e "${WHITE}🔐 SSL CERTIFICATES${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

    local domains=("terrerov.com" "traefik.terrerov.com" "n8n.terrerov.com")

    for domain in "${domains[@]}"; do
        local cert_info=$(echo | timeout 5 openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)

        if [ -n "$cert_info" ]; then
            local expire_date=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2)
            local days_until_expiry=$(( ($(date -d "$expire_date" +%s 2>/dev/null || echo "0") - $(date +%s)) / 86400 ))

            if [ "$days_until_expiry" -gt 30 ]; then
                echo -e "  ${GREEN}🟢${NC} ${WHITE}$domain${NC} - ${GREEN}Valid for $days_until_expiry days${NC}"
            elif [ "$days_until_expiry" -gt 7 ]; then
                echo -e "  ${YELLOW}🟡${NC} ${WHITE}$domain${NC} - ${YELLOW}Expires in $days_until_expiry days${NC}"
            else
                echo -e "  ${RED}🔴${NC} ${WHITE}$domain${NC} - ${RED}Expires soon ($days_until_expiry days)${NC}"
            fi
        else
            echo -e "  ${YELLOW}🟡${NC} ${WHITE}$domain${NC} - ${YELLOW}Cannot verify${NC}"
        fi
    done

    echo ""
}

# Función para mostrar logs recientes
show_recent_logs() {
    echo -e "${WHITE}📋 RECENT ACTIVITY${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

    # Logs de Traefik
    if [ -f "$BASE_DIR/logs/traefik/access.log" ]; then
        echo -e "${CYAN}🔀 Traefik Access (Last 3):${NC}"
        tail -3 "$BASE_DIR/logs/traefik/access.log" 2>/dev/null | while read line; do
            echo -e "  ${GREEN}•${NC} $(echo "$line" | cut -c1-80)..."
        done
    fi

    echo ""

    # Estado de último backup
    local latest_backup=$(ls -t "$BASE_DIR/backups"/chernarus_backup_*.tar.gz 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
        local backup_date=$(stat -c %Y "$latest_backup")
        local backup_age=$(( ($(date +%s) - backup_date) / 3600 ))
        echo -e "${CYAN}💾 Latest Backup:${NC}"
        echo -e "  ${GREEN}•${NC} $(basename "$latest_backup") (${backup_age}h ago)"
    else
        echo -e "${CYAN}💾 Latest Backup:${NC}"
        echo -e "  ${RED}•${NC} No backups found"
    fi

    echo ""
}

# Función para mostrar acciones rápidas
show_quick_actions() {
    echo -e "${WHITE}⚡ QUICK ACTIONS${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

    echo -e "${CYAN}Management Commands:${NC}"
    echo -e "  ${GREEN}[1]${NC} 📊 Full Health Check     ${GREEN}[2]${NC} 🔄 Restart All Services"
    echo -e "  ${GREEN}[3]${NC} 📝 View Live Logs        ${GREEN}[4]${NC} 💾 Create Backup"
    echo -e "  ${GREEN}[5]${NC} 🚀 Deploy New Project    ${GREEN}[6]${NC} 🧹 Clean Docker System"
    echo ""
    echo -e "${CYAN}Quick Links:${NC}"
    echo -e "  ${YELLOW}•${NC} HQ Dashboard: ${CYAN}https://terrerov.com${NC}"
    echo -e "  ${YELLOW}•${NC} Traefik Panel: ${CYAN}https://traefik.terrerov.com${NC}"
    echo -e "  ${YELLOW}•${NC} N8N Automation: ${CYAN}https://n8n.terrerov.com${NC}"
    echo -e "  ${YELLOW}•${NC} Projects Manager: ${CYAN}https://projects.terrerov.com${NC}"
    echo ""
}

# Función para mostrar estadísticas del footer
show_footer() {
    local uptime=$(uptime -p 2>/dev/null || echo "Unknown")
    local load=$(uptime | awk -F'load average:' '{print $2}' | xargs 2>/dev/null || echo "Unknown")

    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}📈 System: $uptime | Load: $load${NC}"
    echo -e "${MAGENTA}🌟 Surviving Chernarus Infrastructure | Built with ❤️${NC}"
    echo ""
    echo -e "${WHITE}Press [r] to refresh | [q] to quit | [1-6] for actions | [Enter] for menu${NC}"
}

# Función para manejar input del usuario
handle_user_input() {
    echo -n "chernarus> "
    read -r input

    case "$input" in
        "1")
            echo -e "${GREEN}🔍 Ejecutando health check...${NC}"
            ./scripts/health-check.sh
            echo -e "${CYAN}Presiona Enter para continuar...${NC}"
            read
            ;;
        "2")
            echo -e "${GREEN}🔄 Reiniciando servicios...${NC}"
            docker-compose restart
            echo -e "${CYAN}Presiona Enter para continuar...${NC}"
            read
            ;;
        "3")
            echo -e "${GREEN}📝 Mostrando logs en tiempo real...${NC}"
            echo -e "${YELLOW}Presiona Ctrl+C para volver al dashboard${NC}"
            sleep 2
            docker-compose logs -f
            ;;
        "4")
            echo -e "${GREEN}💾 Creando backup...${NC}"
            ./scripts/backup-chernarus.sh --config-only
            echo -e "${CYAN}Presiona Enter para continuar...${NC}"
            read
            ;;
        "5")
            echo -e "${GREEN}🚀 Deploy de nuevo proyecto${NC}"
            echo -n "Nombre del proyecto: "
            read project_name
            echo -n "Dominio (ej: proyecto.terrerov.com): "
            read project_domain
            echo -n "Tipo (astro/react/vue/nextjs/static/hugo): "
            read project_type
            ./scripts/deploy-project.sh "$project_name" "$project_domain" "$project_type"
            echo -e "${CYAN}Presiona Enter para continuar...${NC}"
            read
            ;;
        "6")
            echo -e "${GREEN}🧹 Limpiando sistema Docker...${NC}"
            docker system prune -f
            echo -e "${CYAN}Presiona Enter para continuar...${NC}"
            read
            ;;
        "r"|"R"|"")
            # Refresh - no action needed, will loop
            ;;
        "q"|"Q")
            echo -e "${GREEN}👋 ¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Opción no válida. Usa 1-6, r para refresh, q para salir.${NC}"
            echo -e "${CYAN}Presiona Enter para continuar...${NC}"
            read
            ;;
    esac
}

# Función principal del dashboard
main_dashboard() {
    while true; do
        clear_screen
        show_header
        show_services_status
        show_web_status
        show_system_resources
        show_ssl_status
        show_recent_logs
        show_quick_actions
        show_footer

        handle_user_input
    done
}

# Verificar dependencias
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo -e "${RED}❌ No se encuentra docker-compose.yml en $PROJECT_DIR${NC}"
    echo -e "${YELLOW}Ejecuta este script desde el directorio del proyecto${NC}"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está instalado o no está en PATH${NC}"
    exit 1
fi

# Cambiar al directorio del proyecto
cd "$PROJECT_DIR"

# Iniciar dashboard
main_dashboard
