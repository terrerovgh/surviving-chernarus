#!/bin/bash

# Script unificado para el proyecto "Surviving Chernarus" - Versión Producción
# Este script combina todas las funcionalidades de setup_env.sh, setup_network.sh y deploy.sh
# con una interfaz mejorada usando whiptail y mejoras de seguridad para producción
#
# Versión: 2.1.0
# Fecha: $(date +%Y-%m-%d)
# Autor: Surviving Chernarus Team
# Licencia: MIT
#
# Uso:
#   ./deploy.sh                    # Modo interactivo (por defecto)
#   ./deploy.sh --silent           # Modo silencioso con valores por defecto
#   ./deploy.sh --silent --config  # Modo silencioso con archivo de configuración
#   ./deploy.sh --help             # Mostrar ayuda

# Variables para modo silencioso
SILENT_MODE=false
USE_CONFIG_FILE=false
CONFIG_FILE="silent_config.env"

# Configuración de logging
LOG_FILE="/var/log/surviving-chernarus-install.log"
BACKUP_DIR="/opt/surviving-chernarus/backups/$(date +%Y%m%d_%H%M%S)"
ROLLBACK_FILE="/opt/surviving-chernarus/rollback_info.json"

# Valores por defecto para modo silencioso
DEFAULT_PUID=$(id -u)
DEFAULT_PGID=$(id -g)
DEFAULT_TZ="Europe/Madrid"
DEFAULT_DOMAIN="example.com"
DEFAULT_CLOUDFLARE_EMAIL="user@example.com"
DEFAULT_POSTGRES_DB="n8n"
DEFAULT_POSTGRES_USER="n8n"
DEFAULT_TRAEFIK_USER="admin"
DEFAULT_RPI_IP="192.168.1.2"

# Colores para mensajes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Configuración de logging a archivo
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Variables globales de seguridad
MIN_DISK_SPACE=5000000  # 5GB en KB
MIN_RAM=1000000         # 1GB en KB
REQUIRED_ARCH=("aarch64" "armv7l" "x86_64")
SUPPORTED_OS=("debian" "ubuntu" "raspbian")

# Función para mostrar mensajes de progreso
function log_message() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

function log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    create_rollback_point "error_occurred" "$1"
    exit 1
}

function log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# Función para mostrar ayuda
function show_help() {
    cat << EOF
Surviving Chernarus - Instalador Unificado v2.1.0

Uso: $0 [OPCIONES]

OPCIONES:
    --silent           Ejecutar en modo silencioso con valores por defecto
    --config           Usar archivo de configuración (requiere --silent)
    --help             Mostrar esta ayuda
    --debug            Habilitar modo debug

MODO SILENCIOSO:
    En modo silencioso, el script utilizará valores por defecto o los valores
    del archivo de configuración 'silent_config.env' si se especifica --config.

    Ejemplo de archivo silent_config.env:
        DOMAIN_NAME=midominio.com
        CLOUDFLARE_EMAIL=mi@email.com
        CLOUDFLARE_API_TOKEN=mi_token_cloudflare
        POSTGRES_PASSWORD=mi_password_seguro
        PIHOLE_PASSWORD=mi_password_pihole
        TRAEFIK_PASSWORD=mi_password_traefik
        RPI_IP=192.168.1.100
        TZ=America/Mexico_City

EJEMPLOS:
    $0                              # Modo interactivo
    $0 --silent                     # Modo silencioso con valores por defecto
    $0 --silent --config            # Modo silencioso con archivo de configuración
    $0 --help                       # Mostrar ayuda

EOF
}

# Función para procesar argumentos de línea de comandos
function process_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --silent)
                SILENT_MODE=true
                shift
                ;;
            --config)
                USE_CONFIG_FILE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            *)
                echo "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validar combinaciones de argumentos
    if [[ "$USE_CONFIG_FILE" == "true" && "$SILENT_MODE" == "false" ]]; then
        log_error "La opción --config requiere --silent"
    fi
}

# Función para cargar configuración desde archivo
function load_config_file() {
    if [[ "$USE_CONFIG_FILE" == "true" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            log_message "Cargando configuración desde $CONFIG_FILE"
            source "$CONFIG_FILE"
        else
            log_warning "Archivo de configuración $CONFIG_FILE no encontrado. Usando valores por defecto."
        fi
    fi
}

# Función para generar archivo de configuración de ejemplo
function generate_example_config() {
    cat > "${CONFIG_FILE}.example" << EOF
# Archivo de configuración para modo silencioso
# Copia este archivo a '$CONFIG_FILE' y modifica los valores según tus necesidades

# Configuración de dominio y Cloudflare (REQUERIDO)
DOMAIN_NAME=midominio.com
CLOUDFLARE_EMAIL=mi@email.com
CLOUDFLARE_API_TOKEN=mi_token_cloudflare_de_40_caracteres_minimo

# Contraseñas (se generarán automáticamente si no se especifican)
# POSTGRES_PASSWORD=mi_password_postgres_seguro
# PIHOLE_PASSWORD=mi_password_pihole
# TRAEFIK_PASSWORD=mi_password_traefik

# Configuración de red
RPI_IP=192.168.1.100

# Zona horaria
TZ=America/Mexico_City

# Configuración de base de datos (opcional)
# POSTGRES_DB=n8n
# POSTGRES_USER=n8n

# Usuario de Traefik (opcional)
# TRAEFIK_USER=admin
EOF
    log_message "Archivo de configuración de ejemplo generado: ${CONFIG_FILE}.example"
}

# Función para crear puntos de rollback
function create_rollback_point() {
    local action="$1"
    local description="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$(dirname "$ROLLBACK_FILE")"
    
    cat > "$ROLLBACK_FILE" << EOF
{
    "timestamp": "$timestamp",
    "action": "$action",
    "description": "$description",
    "backup_dir": "$BACKUP_DIR",
    "system_info": {
        "hostname": "$(hostname)",
        "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')",
        "arch": "$(uname -m)",
        "kernel": "$(uname -r)"
    }
}
EOF
    log_debug "Punto de rollback creado: $action"
}

# Función para validar requisitos del sistema
function validate_system_requirements() {
    log_message "Validando requisitos del sistema..."
    
    # Verificar arquitectura
    local current_arch=$(uname -m)
    local arch_supported=false
    for arch in "${REQUIRED_ARCH[@]}"; do
        if [[ "$current_arch" == "$arch" ]]; then
            arch_supported=true
            break
        fi
    done
    
    if [[ "$arch_supported" == "false" ]]; then
        log_warning "Arquitectura $current_arch no está oficialmente soportada. Arquitecturas soportadas: ${REQUIRED_ARCH[*]}"
        if ! whiptail --title "Arquitectura no soportada" \
                     --yesno "Tu arquitectura ($current_arch) no está oficialmente soportada.\n\n¿Deseas continuar bajo tu propio riesgo?" 10 78; then
            log_error "Instalación cancelada por arquitectura no soportada"
        fi
    fi
    
    # Verificar espacio en disco
    local available_space=$(df / | tail -1 | awk '{print $4}')
    if [[ $available_space -lt $MIN_DISK_SPACE ]]; then
        log_error "Espacio insuficiente en disco. Requerido: ${MIN_DISK_SPACE}KB, Disponible: ${available_space}KB"
    fi
    
    # Verificar RAM
    local available_ram=$(free | grep '^Mem:' | awk '{print $2}')
    if [[ $available_ram -lt $MIN_RAM ]]; then
        log_warning "RAM insuficiente. Recomendado: ${MIN_RAM}KB, Disponible: ${available_ram}KB"
        if ! whiptail --title "RAM Insuficiente" \
                     --yesno "Tu sistema tiene menos RAM de la recomendada.\n\nRecomendado: $(($MIN_RAM/1024))MB\nDisponible: $(($available_ram/1024))MB\n\n¿Deseas continuar?" 12 78; then
            log_error "Instalación cancelada por RAM insuficiente"
        fi
    fi
    
    # Verificar sistema operativo
    local os_id="unknown"
    if [[ -f /etc/os-release ]]; then
        os_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    fi
    
    local os_supported=false
    for os in "${SUPPORTED_OS[@]}"; do
        if [[ "$os_id" == "$os" ]]; then
            os_supported=true
            break
        fi
    done
    
    if [[ "$os_supported" == "false" ]]; then
        log_warning "Sistema operativo $os_id no está oficialmente soportado. Sistemas soportados: ${SUPPORTED_OS[*]}"
    fi
    
    # Verificar conectividad a internet
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error "No hay conectividad a Internet. Verifica tu conexión de red."
    fi
    
    # Verificar si Docker ya está instalado
    if command -v docker &> /dev/null; then
        log_warning "Docker ya está instalado. Versión: $(docker --version)"
    fi
    
    log_message "Validación del sistema completada exitosamente"
}

# Función para crear backup de archivos críticos
function create_backup() {
    local file_path="$1"
    local backup_name="$2"
    
    if [[ -f "$file_path" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file_path" "$BACKUP_DIR/${backup_name}.backup"
        log_debug "Backup creado: $file_path -> $BACKUP_DIR/${backup_name}.backup"
    fi
}

# Función mejorada para ejecutar comandos con manejo de errores
function exec_cmd() {
    local cmd="$1"
    local description="$2"
    local allow_failure="${3:-false}"
    
    log_debug "Ejecutando: $cmd"
    
    if [[ -n "$description" ]]; then
        log_message "$description"
    fi
    
    if eval "$cmd"; then
        log_debug "Comando ejecutado exitosamente: $cmd"
        return 0
    else
        local exit_code=$?
        log_error "Error al ejecutar comando: $cmd (código de salida: $exit_code)"
        
        if [[ "$allow_failure" == "true" ]]; then
            log_warning "Comando falló pero se permite continuar"
            return $exit_code
        else
            if whiptail --title "Error de comando" \
                       --yesno "Error al ejecutar: $cmd\n\nCódigo de salida: $exit_code\n\n¿Deseas continuar de todos modos?" 12 78; then
                log_warning "Usuario decidió continuar después del error"
                return $exit_code
            else
                log_error "Operación cancelada por el usuario después del error"
            fi
        fi
    fi
}

# Procesar argumentos de línea de comandos
process_arguments "$@"

# Cargar configuración si está en modo silencioso
if [[ "$SILENT_MODE" == "true" ]]; then
    load_config_file
    generate_example_config
fi

# Verificar si whiptail está instalado (solo en modo interactivo)
if [[ "$SILENT_MODE" == "false" ]] && ! command -v whiptail &> /dev/null; then
    log_message "whiptail no está instalado. Instalándolo..."
    if command -v apt-get &> /dev/null; then
        exec_cmd "sudo apt-get update && sudo apt-get install -y whiptail" "Instalando whiptail"
    elif command -v yum &> /dev/null; then
        exec_cmd "sudo yum install -y newt" "Instalando newt (whiptail)"
    else
        log_error "No se pudo instalar whiptail. Por favor, instálalo manualmente."
    fi
fi

# Validar requisitos del sistema antes de continuar
validate_system_requirements

# Ejecutar en modo silencioso o interactivo
if [[ "$SILENT_MODE" == "true" ]]; then
    log_message "Ejecutando en modo silencioso..."
    
    # Ejecutar todas las funciones automáticamente
    setup_env_silent
    
    # Solo configurar red si se ejecuta como root
    if [ "$(id -u)" -eq 0 ]; then
        setup_network_silent
    else
        log_warning "Saltando configuración de red (requiere sudo)"
    fi
    
    # Desplegar servicios
    deploy_services_silent
    
    log_message "Instalación silenciosa completada exitosamente."
    exit 0
else
    # Mensaje de bienvenida
    whiptail --title "Surviving Chernarus - Instalador Unificado" \
             --msgbox "Bienvenido al instalador unificado de Surviving Chernarus.\n\nEste asistente te guiará a través de todo el proceso de configuración y despliegue del proyecto." 12 78
    
    # Menú principal
    while true; do
        OPCION=$(whiptail --title "Surviving Chernarus - Menú Principal" \
                         --menu "Selecciona una opción:" 18 78 7 \
                         "1" "Configurar variables de entorno (.env)" \
                         "2" "Configurar red (requiere sudo)" \
                         "3" "Desplegar servicios" \
                         "4" "Ver documentación" \
                         "5" "Rollback del sistema" \
                         "6" "Plan de recuperación ante desastres" \
                         "7" "Salir" 3>&1 1>&2 2>&3)
        
        # Salir si se presiona Cancelar
        if [ $? -ne 0 ]; then
            log_message "Operación cancelada por el usuario."
            exit 0
        fi
        
        case $OPCION in
            1)
                # Configurar variables de entorno
                setup_env
                ;;
            2)
                # Configurar red
                if [ "$(id -u)" -ne 0 ]; then
                    whiptail --title "Error" \
                             --msgbox "Este script debe ejecutarse con privilegios de superusuario (sudo)." 8 78
                else
                    setup_network
                fi
                ;;
            3)
                # Desplegar servicios
                deploy_services
                ;;
        4)
            # Ver documentación
            show_documentation
            ;;
        5)
            # Rollback del sistema
            if [ "$(id -u)" -ne 0 ]; then
                whiptail --title "Error" \
                         --msgbox "El rollback del sistema requiere privilegios de superusuario (sudo)." 8 78
            else
                rollback_system
            fi
            ;;
        6)
            # Plan de recuperación ante desastres
            show_disaster_recovery
            ;;
        7)
            # Salir
            log_message "Saliendo del instalador."
            exit 0
            ;;
    esac
done
fi

# Función para generar contraseñas seguras
function generate_secure_password() {
    local length="${1:-32}"
    local password
    
    # Intentar diferentes métodos para generar contraseñas seguras
    if command -v openssl &> /dev/null; then
        password=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-$length)
    elif command -v /dev/urandom &> /dev/null; then
        password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c $length)
    else
        # Fallback menos seguro
        password=$(date +%s | sha256sum | base64 | head -c $length)
        log_warning "Usando método de generación de contraseñas menos seguro"
    fi
    
    echo "$password"
}

# Función para validar entrada de email
function validate_email() {
    local email="$1"
    local email_regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    
    if [[ $email =~ $email_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Función para validar dominio
function validate_domain() {
    local domain="$1"
    local domain_regex="^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"
    
    if [[ $domain =~ $domain_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Función para configurar variables de entorno
function setup_env() {
    create_rollback_point "setup_env_start" "Iniciando configuración de variables de entorno"
    
    # Verificar si el archivo .env ya existe
    if [ -f ".env" ]; then
        create_backup ".env" "env_file"
        if ! whiptail --title "Archivo .env existente" \
                     --yesno "El archivo .env ya existe. Se ha creado un backup.\n\n¿Deseas sobrescribirlo?" 10 78; then
            log_message "Operación cancelada por el usuario."
            return
        fi
    fi
    
    # Obtener ID de usuario y grupo
    PUID=$(id -u)
    PGID=$(id -g)
    
    # Mostrar y confirmar ID de usuario y grupo
    if ! whiptail --title "ID de Usuario y Grupo" \
                 --yesno "Se utilizarán los siguientes ID:\n\nID de Usuario (PUID): $PUID\nID de Grupo (PGID): $PGID\n\n¿Es correcto?" 12 78; then
        PUID=$(whiptail --title "ID de Usuario" --inputbox "Introduce el ID de Usuario (PUID):" 8 78 "$PUID" 3>&1 1>&2 2>&3)
        PGID=$(whiptail --title "ID de Grupo" --inputbox "Introduce el ID de Grupo (PGID):" 8 78 "$PGID" 3>&1 1>&2 2>&3)
    fi
    
    # Zona horaria con validación
    while true; do
        TZ=$(whiptail --title "Zona Horaria" --inputbox "Introduce la zona horaria (ej: Europe/Madrid, America/Mexico_City):" 10 78 "Europe/Madrid" 3>&1 1>&2 2>&3)
        if [[ -n "$TZ" ]] && [[ -f "/usr/share/zoneinfo/$TZ" ]]; then
            break
        else
            whiptail --title "Error" --msgbox "Zona horaria inválida. Por favor, introduce una zona horaria válida." 8 78
        fi
    done
    
    # Configuración de dominio con validación
    while true; do
        DOMAIN_NAME=$(whiptail --title "Nombre de Dominio" --inputbox "Introduce el nombre de dominio (ej: midominio.com):" 10 78 "example.com" 3>&1 1>&2 2>&3)
        if [[ -n "$DOMAIN_NAME" ]] && validate_domain "$DOMAIN_NAME"; then
            break
        else
            whiptail --title "Error" --msgbox "Dominio inválido. Por favor, introduce un dominio válido (ej: midominio.com)." 8 78
        fi
    done
    
    # Email de Cloudflare con validación
    while true; do
        CLOUDFLARE_EMAIL=$(whiptail --title "Email de Cloudflare" --inputbox "Introduce el email de Cloudflare:" 10 78 "user@example.com" 3>&1 1>&2 2>&3)
        if [[ -n "$CLOUDFLARE_EMAIL" ]] && validate_email "$CLOUDFLARE_EMAIL"; then
            break
        else
            whiptail --title "Error" --msgbox "Email inválido. Por favor, introduce un email válido." 8 78
        fi
    done
    
    # Token API de Cloudflare con validación
    while true; do
        CLOUDFLARE_API_TOKEN=$(whiptail --title "Token API de Cloudflare" --passwordbox "Introduce el token API de Cloudflare (mínimo 40 caracteres):" 10 78 3>&1 1>&2 2>&3)
        if [[ -n "$CLOUDFLARE_API_TOKEN" ]] && [[ ${#CLOUDFLARE_API_TOKEN} -ge 40 ]]; then
            break
        else
            whiptail --title "Error" --msgbox "Token API inválido. Debe tener al menos 40 caracteres." 8 78
        fi
    done
    
    # Configuración de PostgreSQL
    POSTGRES_DB=$(whiptail --title "Base de Datos PostgreSQL" --inputbox "Introduce el nombre de la base de datos:" 10 78 "n8n" 3>&1 1>&2 2>&3)
    POSTGRES_USER=$(whiptail --title "Usuario PostgreSQL" --inputbox "Introduce el nombre de usuario:" 10 78 "n8n" 3>&1 1>&2 2>&3)
    
    # Opción para generar contraseña automáticamente o introducir manualmente
    if whiptail --title "Contraseña PostgreSQL" \
               --yesno "¿Deseas generar una contraseña segura automáticamente para PostgreSQL?\n\nRecomendado: SÍ (más seguro)" 10 78; then
        POSTGRES_PASSWORD=$(generate_secure_password 32)
        whiptail --title "Contraseña Generada" --msgbox "Se ha generado una contraseña segura para PostgreSQL:\n\n$POSTGRES_PASSWORD\n\nPor favor, anótala en un lugar seguro. Esta información también se guardará en el archivo .env." 12 78
    else
        while true; do
            POSTGRES_PASSWORD=$(whiptail --title "Contraseña PostgreSQL" --passwordbox "Introduce una contraseña segura (mínimo 12 caracteres):" 10 78 3>&1 1>&2 2>&3)
            if [[ -n "$POSTGRES_PASSWORD" ]] && [[ ${#POSTGRES_PASSWORD} -ge 12 ]]; then
                break
            else
                whiptail --title "Error" --msgbox "La contraseña debe tener al menos 12 caracteres." 8 78
            fi
        done
    fi
    
    # Configuración de Pi-hole
    if whiptail --title "Contraseña Pi-hole" \
               --yesno "¿Deseas generar una contraseña segura automáticamente para Pi-hole?\n\nRecomendado: SÍ (más seguro)" 10 78; then
        PIHOLE_PASSWORD=$(generate_secure_password 24)
        whiptail --title "Contraseña Generada" --msgbox "Se ha generado una contraseña segura para Pi-hole:\n\n$PIHOLE_PASSWORD\n\nPor favor, anótala en un lugar seguro." 12 78
    else
        while true; do
            PIHOLE_PASSWORD=$(whiptail --title "Contraseña Pi-hole" --passwordbox "Introduce una contraseña segura (mínimo 8 caracteres):" 10 78 3>&1 1>&2 2>&3)
            if [[ -n "$PIHOLE_PASSWORD" ]] && [[ ${#PIHOLE_PASSWORD} -ge 8 ]]; then
                break
            else
                whiptail --title "Error" --msgbox "La contraseña debe tener al menos 8 caracteres." 8 78
            fi
        done
    fi
    
    # Configuración de Traefik
    TRAEFIK_USER=$(whiptail --title "Usuario Traefik" --inputbox "Introduce el nombre de usuario para Traefik:" 10 78 "admin" 3>&1 1>&2 2>&3)
    
    if whiptail --title "Contraseña Traefik" \
               --yesno "¿Deseas generar una contraseña segura automáticamente para Traefik?\n\nRecomendado: SÍ (más seguro)" 10 78; then
        TRAEFIK_PASSWORD=$(generate_secure_password 24)
        whiptail --title "Contraseña Generada" --msgbox "Se ha generado una contraseña segura para Traefik:\n\n$TRAEFIK_PASSWORD\n\nPor favor, anótala en un lugar seguro." 12 78
    else
        while true; do
            TRAEFIK_PASSWORD=$(whiptail --title "Contraseña Traefik" --passwordbox "Introduce una contraseña segura (mínimo 8 caracteres):" 10 78 3>&1 1>&2 2>&3)
            if [[ -n "$TRAEFIK_PASSWORD" ]] && [[ ${#TRAEFIK_PASSWORD} -ge 8 ]]; then
                break
            else
                whiptail --title "Error" --msgbox "La contraseña debe tener al menos 8 caracteres." 8 78
            fi
        done
    fi
    
    # Generar hash para Traefik
    if command -v htpasswd &> /dev/null; then
        HASHED_PASSWORD=$(htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
    else
        log_warning "htpasswd no está instalado. Instalándolo..."
        if command -v apt-get &> /dev/null; then
            exec_cmd "sudo apt-get install -y apache2-utils" "Instalando apache2-utils para htpasswd"
            HASHED_PASSWORD=$(htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
        else
            log_warning "No se pudo instalar htpasswd. Usando hash básico."
            HASHED_PASSWORD="$TRAEFIK_USER:$TRAEFIK_PASSWORD"
        fi
    fi
    
    # Configuración de red para Raspberry Pi con validación
    while true; do
        RPI_IP=$(whiptail --title "IP de Raspberry Pi" --inputbox "Introduce la dirección IP estática para la Raspberry Pi (formato: 192.168.1.2):" 10 78 "192.168.1.2" 3>&1 1>&2 2>&3)
        if [[ $RPI_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Validar que cada octeto esté en el rango válido
            valid_ip=true
            IFS='.' read -ra ADDR <<< "$RPI_IP"
            for i in "${ADDR[@]}"; do
                if [[ $i -lt 0 || $i -gt 255 ]]; then
                    valid_ip=false
                    break
                fi
            done
            if [[ "$valid_ip" == "true" ]]; then
                break
            fi
        fi
        whiptail --title "Error" --msgbox "Dirección IP inválida. Por favor, introduce una IP válida (ej: 192.168.1.2)." 8 78
    done
    
    # Crear archivo .env
    cat > .env << EOF
# Configuración de usuario y grupo
PUID=$PUID
PGID=$PGID

# Zona horaria
TZ=$TZ

# Configuración de dominio y Cloudflare
DOMAIN_NAME=$DOMAIN_NAME
CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Configuración de PostgreSQL
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Configuración de Pi-hole
PIHOLE_PASSWORD=$PIHOLE_PASSWORD

# Configuración de Traefik
TRAEFIK_USER=$TRAEFIK_USER
TRAEFIK_PASSWORD=$TRAEFIK_PASSWORD
HASHED_PASSWORD=$HASHED_PASSWORD

# Configuración de red para Raspberry Pi
RPI_IP=$RPI_IP
EOF
    
    whiptail --title "Configuración Completada" \
             --msgbox "El archivo .env ha sido creado correctamente." 8 78
}

# Función para configurar la red
function setup_network() {
    create_rollback_point "setup_network_start" "Iniciando configuración de red"
    
    # Verificar si el archivo .env existe
    if [ ! -f ".env" ]; then
        whiptail --title "Error" \
                 --msgbox "El archivo .env no existe. Por favor, ejecuta primero la opción 'Configurar variables de entorno'." 10 78
        return
    fi
    
    # Cargar variables de entorno desde el archivo .env
    source .env
    
    # Verificar que RPI_IP está definido
    if [ -z "$RPI_IP" ]; then
        log_error "La variable RPI_IP no está definida en el archivo .env"
        return
    fi
    
    # Crear backups de archivos críticos de red
    create_backup "/etc/hostname" "hostname"
    create_backup "/etc/hosts" "hosts"
    create_backup "/etc/resolv.conf" "resolv_conf"
    create_backup "/etc/network/interfaces" "network_interfaces"
    
    # Verificar permisos de superusuario
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Esta función requiere privilegios de superusuario. Ejecuta con sudo."
        return
    fi
    
    # Obtener configuración de red actual
    CURRENT_HOSTNAME=$(hostname)
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
    CURRENT_DNS=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)
    
    log_message "Configuración actual: IP=$CURRENT_IP, Gateway=$CURRENT_GATEWAY, DNS=$CURRENT_DNS"
    
    # Solicitar y validar hostname
    while true; do
        NEW_HOSTNAME=$(whiptail --title "Configuración de Red" \
                               --inputbox "Introduce el nuevo hostname (solo letras, números y guiones):" 10 78 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)
        if [[ "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]] && [[ ${#NEW_HOSTNAME} -le 63 ]]; then
            break
        fi
        whiptail --title "Error" --msgbox "Hostname inválido. Debe contener solo letras, números y guiones, máximo 63 caracteres." 8 78
    done
    
    # Solicitar y validar IP estática
    while true; do
        IP_ADDRESS=$(whiptail --title "Dirección IP" --inputbox "Introduce la dirección IP estática:" 8 78 "$RPI_IP" 3>&1 1>&2 2>&3)
        if [[ $IP_ADDRESS =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            valid_ip=true
            IFS='.' read -ra ADDR <<< "$IP_ADDRESS"
            for i in "${ADDR[@]}"; do
                if [[ $i -lt 0 || $i -gt 255 ]]; then
                    valid_ip=false
                    break
                fi
            done
            if [[ "$valid_ip" == "true" ]]; then
                break
            fi
        fi
        whiptail --title "Error" --msgbox "Dirección IP inválida. Introduce una IP válida (ej: 192.168.1.2)." 8 78
    done
    
    # Solicitar y validar gateway
    while true; do
        GATEWAY=$(whiptail --title "Configuración de Red" \
                          --inputbox "Introduce la puerta de enlace (gateway):" 10 78 "$CURRENT_GATEWAY" 3>&1 1>&2 2>&3)
        if [[ $GATEWAY =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            valid_gateway=true
            IFS='.' read -ra ADDR <<< "$GATEWAY"
            for i in "${ADDR[@]}"; do
                if [[ $i -lt 0 || $i -gt 255 ]]; then
                    valid_gateway=false
                    break
                fi
            done
            if [[ "$valid_gateway" == "true" ]]; then
                break
            fi
        fi
        whiptail --title "Error" --msgbox "Dirección de gateway inválida. Introduce una IP válida." 8 78
    done
    
    # Solicitar y validar DNS
    DNS_SERVERS=$(whiptail --title "Servidores DNS" --inputbox "Introduce los servidores DNS (separados por espacios):" 8 78 "1.1.1.1 1.0.0.1" 3>&1 1>&2 2>&3)
    
    # Actualizar .env con la nueva IP
    sed -i "s/RPI_IP=.*/RPI_IP=$IP_ADDRESS/g" .env
    
    # Configurar hostname
    echo "$NEW_HOSTNAME" > /etc/hostname
    hostname "$NEW_HOSTNAME"
    
    # Actualizar /etc/hosts
    sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    
    # Detectar interfaz de red principal
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE="eth0"  # Fallback por defecto
        log_warning "No se pudo detectar la interfaz de red principal, usando eth0 por defecto"
    fi
    log_message "Configurando interfaz de red: $INTERFACE"
    
    # Crear backup de la configuración actual de la interfaz
    if [[ -f "/etc/network/interfaces.d/$INTERFACE" ]]; then
        create_backup "/etc/network/interfaces.d/$INTERFACE" "interface_$INTERFACE"
    fi
    
    # Configurar interfaz de red
    cat > /etc/network/interfaces.d/$INTERFACE << EOF
auto $INTERFACE
iface $INTERFACE inet static
    address $IP_ADDRESS/24
    gateway $GATEWAY
EOF
    
    # Configurar resolv.conf con validación de DNS
    cat > /etc/resolv.conf << EOF
# Generated by Surviving Chernarus setup_network
EOF
    
    # Validar y agregar servidores DNS
    for DNS in $DNS_SERVERS; do
        if [[ $DNS =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            valid_dns=true
            IFS='.' read -ra ADDR <<< "$DNS"
            for i in "${ADDR[@]}"; do
                if [[ $i -lt 0 || $i -gt 255 ]]; then
                    valid_dns=false
                    break
                fi
            done
            if [[ "$valid_dns" == "true" ]]; then
                echo "nameserver $DNS" >> /etc/resolv.conf
                log_debug "DNS agregado: $DNS"
            else
                log_warning "DNS inválido ignorado: $DNS"
            fi
        else
            log_warning "DNS inválido ignorado: $DNS"
        fi
    done
    
    # Verificar que al menos un DNS fue configurado
    if ! grep -q "nameserver" /etc/resolv.conf; then
        log_warning "No se configuró ningún DNS válido, agregando DNS por defecto"
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
        echo "nameserver 1.0.0.1" >> /etc/resolv.conf
    fi
    
    # Preguntar si se desea reiniciar
    if whiptail --title "Reiniciar Sistema" \
               --yesno "La configuración de red ha sido actualizada. Es necesario reiniciar el sistema para aplicar los cambios.\n\n¿Deseas reiniciar ahora?" 12 78; then
        log_message "Reiniciando el sistema..."
        reboot
    else
        whiptail --title "Configuración Completada" \
                 --msgbox "La configuración de red ha sido actualizada. Por favor, reinicia el sistema manualmente para aplicar los cambios." 10 78
    fi
}

# Función para desplegar servicios
function deploy_services() {
    create_rollback_point "deploy_services_start" "Iniciando despliegue de servicios"
    
    # Verificar si el archivo .env existe
    if [ ! -f ".env" ]; then
        whiptail --title "Error" \
                 --msgbox "El archivo .env no existe. Por favor, ejecuta primero la opción 'Configurar variables de entorno'." 10 78
        return
    fi
    
    # Cargar variables de entorno desde el archivo .env
    source .env
    
    # Verificar permisos de superusuario
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Esta función requiere privilegios de superusuario. Ejecuta con sudo."
        return
    fi
    
    # Validar requisitos del sistema antes de continuar
    if ! validate_system_requirements; then
        log_error "Los requisitos del sistema no se cumplen. Abortando despliegue."
        return
    fi
    
    # Verificar variables requeridas
    required_vars=("PUID" "PGID" "TZ" "DOMAIN_NAME" "CLOUDFLARE_EMAIL" "CLOUDFLARE_API_TOKEN" \
                  "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD" "PIHOLE_PASSWORD" \
                  "TRAEFIK_USER" "TRAEFIK_PASSWORD")
    
    missing_vars=0
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_warning "La variable $var no está definida en el archivo .env"
            missing_vars=$((missing_vars+1))
        fi
    done
    
    if [ $missing_vars -gt 0 ]; then
        if ! whiptail --title "Variables faltantes" \
                     --yesno "Faltan $missing_vars variables en el archivo .env. ¿Deseas continuar de todos modos?" 10 78; then
            log_message "Operación cancelada por el usuario."
            return
        fi
    fi
    
    # Nota: La función exec_cmd ya está definida globalmente
    
    # Mostrar resumen de la instalación
    if ! whiptail --title "Resumen de la instalación" \
                 --yesno "Se realizarán las siguientes acciones:\n\n1. Actualización del sistema\n2. Instalación y configuración de UFW\n3. Configuración de UFW para Docker\n4. Instalación de Docker y Docker Compose\n5. Configuración de permisos de Docker\n6. Creación de estructura de directorios\n7. Configuración de Traefik\n8. Creación de docker-compose.yml\n9. Inicio de los servicios\n\n¿Deseas continuar?" 20 78; then
        log_message "Operación cancelada por el usuario."
        return
    fi
    
    # Crear una barra de progreso
    {
        # 1. Actualización del sistema
        echo "10"
        log_message "1. Actualizando el sistema..."
        exec_cmd "sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"
        
        # 2. Instalación y configuración de UFW
        echo "20"
        log_message "2. Instalando y configurando UFW..."
        
        # Crear backups de configuración UFW
        create_backup "/etc/ufw" "ufw_config"
        create_backup "/etc/default/ufw" "ufw_default"
        
        if ! exec_cmd "sudo apt install ufw -y" "Instalando UFW"; then
            log_error "Error crítico: No se pudo instalar UFW"
            return 1
        fi
        
        exec_cmd "sudo ufw --force reset" "Reseteando configuración UFW"
        exec_cmd "sudo ufw default deny incoming" "Configurando política por defecto (deny incoming)"
        exec_cmd "sudo ufw default allow outgoing" "Configurando política por defecto (allow outgoing)"
        exec_cmd "sudo ufw allow ssh" "Permitiendo SSH"
        exec_cmd "sudo ufw allow http" "Permitiendo HTTP"
        exec_cmd "sudo ufw allow https" "Permitiendo HTTPS"
        exec_cmd "sudo ufw allow 53" "Permitiendo DNS"
        exec_cmd "sudo ufw allow 8080/tcp" "Permitiendo Traefik Dashboard"
        exec_cmd "sudo ufw allow 9091/tcp" "Permitiendo rTorrent"
        
        # 3. Configuración de UFW para Docker
        echo "30"
        log_message "3. Configurando UFW para Docker..."
        
        # Crear archivo temporal con la configuración de UFW para Docker
        cat > ufw_docker_config.tmp << 'EOF'
# BEGIN UFW AND DOCKER
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
EOF
        
        # Mover el archivo temporal a /tmp
        exec_cmd "mv ufw_docker_config.tmp /tmp/ufw_docker_config"
        
        # Insertar la configuración en after.rules
        exec_cmd "sudo sed -i '/^*filter/i\n# BEGIN UFW AND DOCKER\n*filter\n:DOCKER-USER - [0:0]\n-A DOCKER-USER -j RETURN -s 10.0.0.0\/8\n-A DOCKER-USER -j RETURN -s 172.16.0.0\/12\n-A DOCKER-USER -j RETURN -s 192.168.0.0\/16\n\n-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN\n\n-A DOCKER-USER -j ufw-user-forward\n\n-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0\/16\n-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0\/8\n-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0\/12\n-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0\/16\n-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0\/8\n-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0\/12\n\n-A DOCKER-USER -j RETURN\nCOMMIT\n# END UFW AND DOCKER\n' /etc/ufw/after.rules"
        
        # Modificar DEFAULT_FORWARD_POLICY
        exec_cmd "sudo sed -i 's/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g' /etc/default/ufw"
        
        # Activar UFW
        exec_cmd "sudo ufw --force enable"
        
        # Eliminar archivo temporal
        rm -f ufw_docker_config.tmp
        
        # 4. Instalación de Docker y Docker Compose
        echo "40"
        log_message "4. Instalando Docker y Docker Compose..."
        
        # Verificar si Docker ya está instalado
        if command -v docker &> /dev/null; then
            log_message "Docker ya está instalado, verificando versión..."
            docker --version
        else
            # Instalar dependencias
            if ! exec_cmd "sudo apt install ca-certificates curl gnupg lsb-release -y" "Instalando dependencias para Docker"; then
                log_error "Error crítico: No se pudieron instalar las dependencias de Docker"
                return 1
            fi
            
            # Detectar distribución y arquitectura
            DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
            ARCH=$(dpkg --print-architecture)
            log_message "Detectado: Distribución=$DISTRO, Arquitectura=$ARCH"
            
            # Verificar arquitectura soportada
            if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" && "$ARCH" != "armhf" ]]; then
                log_warning "Arquitectura $ARCH puede no estar completamente soportada"
            fi
            
            # Añadir la clave GPG oficial de Docker
            exec_cmd "sudo install -m 0755 -d /etc/apt/keyrings" "Creando directorio para claves GPG"
            
            # Usar la URL correcta según la distribución
            if [[ "$DISTRO" == "ubuntu" ]]; then
                GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
                REPO_URL="https://download.docker.com/linux/ubuntu"
            else
                GPG_URL="https://download.docker.com/linux/debian/gpg"
                REPO_URL="https://download.docker.com/linux/debian"
            fi
            
            if ! exec_cmd "curl -fsSL $GPG_URL | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg" "Descargando clave GPG de Docker"; then
                log_error "Error crítico: No se pudo descargar la clave GPG de Docker"
                return 1
            fi
            
            exec_cmd "sudo chmod a+r /etc/apt/keyrings/docker.gpg" "Configurando permisos de clave GPG"
            
            # Configurar el repositorio apt de Docker
            CODENAME=$(lsb_release -cs)
            REPO_LINE="deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] $REPO_URL $CODENAME stable"
            
            if ! exec_cmd "echo '$REPO_LINE' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" "Configurando repositorio de Docker"; then
                log_error "Error crítico: No se pudo configurar el repositorio de Docker"
                return 1
            fi
            
            # Actualizar e instalar Docker
            if ! exec_cmd "sudo apt update" "Actualizando lista de paquetes"; then
                log_error "Error crítico: No se pudo actualizar la lista de paquetes"
                return 1
            fi
            
            if ! exec_cmd "sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y" "Instalando Docker"; then
                log_error "Error crítico: No se pudo instalar Docker"
                return 1
            fi
        fi
        
        # 5. Post-instalación de Docker
        echo "50"
        log_message "5. Configurando permisos de Docker..."
        
        # Configurar usuario para Docker
        if ! groups $USER | grep -q docker; then
            exec_cmd "sudo usermod -aG docker $USER" "Agregando usuario al grupo docker"
            log_warning "Nota: Necesitarás cerrar sesión y volver a iniciar para que los cambios de grupo surtan efecto"
        else
            log_message "El usuario ya pertenece al grupo docker"
        fi
        
        # Habilitar y iniciar Docker
        exec_cmd "sudo systemctl enable docker" "Habilitando Docker al inicio"
        exec_cmd "sudo systemctl start docker" "Iniciando servicio Docker"
        
        # Verificar que Docker esté funcionando
        if ! exec_cmd "sudo systemctl is-active docker" "Verificando estado de Docker"; then
            log_error "Error crítico: Docker no está funcionando correctamente"
            return 1
        fi
        
        # Verificar la instalación de Docker
        log_message "Verificando la instalación de Docker..."
        exec_cmd "docker --version" "Verificando versión de Docker"
        exec_cmd "docker compose version" "Verificando versión de Docker Compose"
        
        # Probar Docker con una imagen simple (evitar hello-world en ARM)
        if [[ "$(uname -m)" == "armv7l" || "$(uname -m)" == "aarch64" ]]; then
            log_message "Probando Docker con imagen compatible con ARM..."
            exec_cmd "docker run --rm alpine:latest echo 'Docker funciona correctamente en ARM'" "Probando Docker en ARM"
        else
            exec_cmd "docker run --rm hello-world" "Probando Docker con hello-world"
        fi
        
        # 6. Crear estructura de directorios para el proyecto
        echo "60"
        log_message "6. Creando estructura de directorios para el proyecto..."
        exec_cmd "sudo mkdir -p /opt/surviving-chernarus/{traefik_data,postgres_data,pihole_data/{pihole,dnsmasq.d},n8n_data,rtorrent_data/{config,downloads,session},heimdall_data,squid_data/{cache}}"
        exec_cmd "sudo chown -R \$USER:\$USER /opt/surviving-chernarus"
        
        # 7. Crear archivo .env en el directorio del proyecto
        echo "70"
        log_message "7. Creando archivo .env en el directorio del proyecto..."
        
        # Crear archivo .env con las variables de entorno
        cat > /opt/surviving-chernarus/.env << EOF
PUID=${PUID}
PGID=${PGID}
TZ=${TZ}
DOMAIN_NAME=${DOMAIN_NAME}
CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
PIHOLE_PASSWORD=${PIHOLE_PASSWORD}
HASHED_PASSWORD=${HASHED_PASSWORD}
EOF
        
        # 8. Crear archivo de configuración de Traefik
        echo "80"
        log_message "8. Configurando Traefik..."
        
        # Crear archivo traefik.yml
        cat > /opt/surviving-chernarus/traefik_data/traefik.yml << 'EOF'
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

certificatesResolvers:
  cloudflare:
    acme:
      email: "${CLOUDFLARE_EMAIL}"
      storage: acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
EOF
        
        # Crear archivo acme.json vacío
        exec_cmd "touch /opt/surviving-chernarus/traefik_data/acme.json"
        exec_cmd "chmod 600 /opt/surviving-chernarus/traefik_data/acme.json"
        
        # 9. Crear archivo docker-compose.yml
        echo "90"
        log_message "9. Creando archivo docker-compose.yml..."
        
        # Crear archivo docker-compose.yml
        cat > /opt/surviving-chernarus/docker-compose.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - cher-net
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik_data/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik_data/acme.json:/acme.json
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-secure.entrypoints=websecure"
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik.${DOMAIN_NAME}`)"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.service=api@internal"
      - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${HASHED_PASSWORD}"

  postgres:
    image: postgres:14-alpine
    container_name: postgres
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - ./postgres_data:/var/lib/postgresql/data

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - TZ=${TZ}
      - WEBPASSWORD=${PIHOLE_PASSWORD}
      - SERVERIP=192.168.1.2  # Ajustar a la IP de la Raspberry Pi
    volumes:
      - ./pihole_data/pihole:/etc/pihole
      - ./pihole_data/dnsmasq.d:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole-secure.entrypoints=websecure"
      - "traefik.http.routers.pihole-secure.rule=Host(`pihole.${DOMAIN_NAME}`)"
      - "traefik.http.routers.pihole-secure.tls=true"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_HOST=${DOMAIN_NAME}
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://n8n.${DOMAIN_NAME}/
      - TZ=${TZ}
    volumes:
      - ./n8n_data:/home/node/.n8n
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n-secure.entrypoints=websecure"
      - "traefik.http.routers.n8n-secure.rule=Host(`n8n.${DOMAIN_NAME}`)"
      - "traefik.http.routers.n8n-secure.tls=true"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

  rtorrent:
    image: linuxserver/rutorrent:latest
    container_name: rtorrent
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ./rtorrent_data/config:/config
      - ./rtorrent_data/downloads:/downloads
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.rtorrent-secure.entrypoints=websecure"
      - "traefik.http.routers.rtorrent-secure.rule=Host(`rtorrent.${DOMAIN_NAME}`)"
      - "traefik.http.routers.rtorrent-secure.tls=true"
      - "traefik.http.services.rtorrent.loadbalancer.server.port=80"

  heimdall:
    image: linuxserver/heimdall:latest
    container_name: heimdall
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ./heimdall_data:/config
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.heimdall-secure.entrypoints=websecure"
      - "traefik.http.routers.heimdall-secure.rule=Host(`${DOMAIN_NAME}`)"
      - "traefik.http.routers.heimdall-secure.tls=true"
      - "traefik.http.services.heimdall.loadbalancer.server.port=80"

networks:
  cher-net:
    driver: bridge
EOF
        
        # 10. Iniciar los servicios
        echo "100"
        log_message "10. Iniciando los servicios..."
        exec_cmd "cd /opt/surviving-chernarus && docker compose up -d"
        
        # 11. Verificar que los servicios están funcionando
        log_message "11. Verificando que los servicios están funcionando..."
        exec_cmd "docker ps"
        
    } | whiptail --title "Progreso de la instalación" --gauge "Iniciando la instalación..." 10 78 0
    
    # Mostrar mensaje de éxito
    whiptail --title "Despliegue Completado" \
             --msgbox "¡Despliegue completado con éxito!\n\nPuedes acceder a los servicios a través de las siguientes URLs:\n\n- Panel de control: https://${DOMAIN_NAME}\n- Traefik Dashboard: https://traefik.${DOMAIN_NAME}\n- Pi-hole: http://pihole.${DOMAIN_NAME}/admin\n- n8n: https://n8n.${DOMAIN_NAME}\n- rTorrent: https://rtorrent.${DOMAIN_NAME}" 20 78
    
    log_message "¡Despliegue completado con éxito!"
    log_message "Puedes acceder a los servicios a través de las siguientes URLs:"
    log_message "- Panel de control: https://${DOMAIN_NAME}"
    log_message "- Traefik Dashboard: https://traefik.${DOMAIN_NAME}"
    log_message "- Pi-hole: http://pihole.${DOMAIN_NAME}/admin"
    log_message "- n8n: https://n8n.${DOMAIN_NAME}"
    log_message "- rTorrent: https://rtorrent.${DOMAIN_NAME}"
    
    # Crear punto de rollback final
    create_rollback_point "deploy_services_completed" "Despliegue de servicios completado exitosamente"
}

# Función para realizar rollback del sistema
function rollback_system() {
    if [[ ! -f "$ROLLBACK_FILE" ]]; then
        whiptail --title "Error" --msgbox "No se encontró archivo de rollback. No hay puntos de restauración disponibles." 10 78
        return
    fi
    
    # Mostrar puntos de rollback disponibles
    local rollback_points=()
    while IFS= read -r line; do
        if [[ $line =~ \"timestamp\":\"([^\"]+)\".*\"action\":\"([^\"]+)\".*\"description\":\"([^\"]+)\" ]]; then
            rollback_points+=("${BASH_REMATCH[1]}" "${BASH_REMATCH[2]} - ${BASH_REMATCH[3]}")
        fi
    done < "$ROLLBACK_FILE"
    
    if [[ ${#rollback_points[@]} -eq 0 ]]; then
        whiptail --title "Error" --msgbox "No hay puntos de rollback disponibles." 10 78
        return
    fi
    
    # Seleccionar punto de rollback
    local selected_point
    selected_point=$(whiptail --title "Seleccionar Punto de Rollback" \
                             --menu "Selecciona un punto de restauración:" 20 78 10 \
                             "${rollback_points[@]}" 3>&1 1>&2 2>&3)
    
    if [[ -z "$selected_point" ]]; then
        return
    fi
    
    # Confirmar rollback
    if ! whiptail --title "Confirmar Rollback" \
                 --yesno "¿Estás seguro de que quieres restaurar el sistema al punto: $selected_point?\n\nEsta acción puede ser irreversible." 12 78; then
        return
    fi
    
    log_message "Iniciando rollback al punto: $selected_point"
    
    # Restaurar archivos desde backups
    if [[ -d "$BACKUP_DIR" ]]; then
        log_message "Restaurando archivos desde backups..."
        
        # Restaurar configuración de red
        for file in hostname hosts resolv_conf network_interfaces; do
            if [[ -f "$BACKUP_DIR/${file}.backup" ]]; then
                case $file in
                    "hostname")
                        exec_cmd "sudo cp '$BACKUP_DIR/${file}.backup' /etc/hostname" "Restaurando /etc/hostname"
                        ;;
                    "hosts")
                        exec_cmd "sudo cp '$BACKUP_DIR/${file}.backup' /etc/hosts" "Restaurando /etc/hosts"
                        ;;
                    "resolv_conf")
                        exec_cmd "sudo cp '$BACKUP_DIR/${file}.backup' /etc/resolv.conf" "Restaurando /etc/resolv.conf"
                        ;;
                    "network_interfaces")
                        exec_cmd "sudo cp '$BACKUP_DIR/${file}.backup' /etc/network/interfaces" "Restaurando /etc/network/interfaces"
                        ;;
                esac
            fi
        done
        
        # Restaurar configuración UFW
        if [[ -d "$BACKUP_DIR/ufw_config.backup" ]]; then
            exec_cmd "sudo cp -r '$BACKUP_DIR/ufw_config.backup'/* /etc/ufw/" "Restaurando configuración UFW"
        fi
        
        if [[ -f "$BACKUP_DIR/ufw_default.backup" ]]; then
            exec_cmd "sudo cp '$BACKUP_DIR/ufw_default.backup' /etc/default/ufw" "Restaurando configuración por defecto de UFW"
        fi
    fi
    
    # Detener servicios Docker si están ejecutándose
    if command -v docker &> /dev/null && docker ps -q &> /dev/null; then
        log_message "Deteniendo servicios Docker..."
        exec_cmd "cd /opt/surviving-chernarus && docker compose down" "Deteniendo servicios"
    fi
    
    log_message "Rollback completado. Es recomendable reiniciar el sistema."
    
    if whiptail --title "Rollback Completado" \
                --yesno "Rollback completado.\n\n¿Deseas reiniciar el sistema ahora para aplicar todos los cambios?" 10 78; then
        log_message "Reiniciando sistema..."
        sudo reboot
    fi
}

# Función para mostrar información de recuperación ante desastres
function show_disaster_recovery() {
    local recovery_info="PLAN DE RECUPERACIÓN ANTE DESASTRES\n\n"
    recovery_info+="1. BACKUPS AUTOMÁTICOS:\n"
    recovery_info+="   - Ubicación: $BACKUP_DIR\n"
    recovery_info+="   - Archivos respaldados: configuración de red, UFW, .env\n\n"
    
    recovery_info+="2. PUNTOS DE ROLLBACK:\n"
    recovery_info+="   - Archivo: $ROLLBACK_FILE\n"
    recovery_info+="   - Uso: ./deploy.sh rollback\n\n"
    
    recovery_info+="3. RECUPERACIÓN MANUAL:\n"
    recovery_info+="   a) Detener servicios: cd /opt/surviving-chernarus && docker compose down\n"
    recovery_info+="   b) Restaurar backups desde $BACKUP_DIR\n"
    recovery_info+="   c) Reiniciar servicios de red: sudo systemctl restart networking\n"
    recovery_info+="   d) Reiniciar Docker: sudo systemctl restart docker\n\n"
    
    recovery_info+="4. LOGS DEL SISTEMA:\n"
    recovery_info+="   - Archivo principal: $LOG_FILE\n"
    recovery_info+="   - Logs de Docker: docker logs <container_name>\n"
    recovery_info+="   - Logs del sistema: journalctl -u docker\n\n"
    
    recovery_info+="5. CONTACTOS DE EMERGENCIA:\n"
    recovery_info+="   - Documentación: https://github.com/tu-repo/surviving-chernarus\n"
    recovery_info+="   - Issues: https://github.com/tu-repo/surviving-chernarus/issues\n\n"
    
    recovery_info+="6. VERIFICACIÓN POST-RECUPERACIÓN:\n"
    recovery_info+="   - Verificar conectividad: ping 8.8.8.8\n"
    recovery_info+="   - Verificar Docker: docker ps\n"
    recovery_info+="   - Verificar servicios: curl -k https://$DOMAIN_NAME\n"
    
    whiptail --title "Plan de Recuperación ante Desastres" \
             --msgbox "$recovery_info" 25 90
}

# Función para configurar variables de entorno en modo silencioso
function setup_env_silent() {
    log_message "Configurando variables de entorno en modo silencioso..."
    
    # Usar valores por defecto o del archivo de configuración
    PUID=${PUID:-$(id -u)}
    PGID=${PGID:-$(id -g)}
    TZ=${TZ:-"Europe/Madrid"}
    DOMAIN_NAME=${DOMAIN_NAME:-"example.com"}
    CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL:-"user@example.com"}
    CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-"your_cloudflare_api_token_here"}
    POSTGRES_DB=${POSTGRES_DB:-"n8n"}
    POSTGRES_USER=${POSTGRES_USER:-"n8n"}
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(generate_secure_password 32)}
    PIHOLE_PASSWORD=${PIHOLE_PASSWORD:-$(generate_secure_password 24)}
    TRAEFIK_USER=${TRAEFIK_USER:-"admin"}
    TRAEFIK_PASSWORD=${TRAEFIK_PASSWORD:-$(generate_secure_password 24)}
    RPI_IP=${RPI_IP:-"192.168.1.2"}
    
    # Generar hash para Traefik
    if command -v htpasswd &> /dev/null; then
        HASHED_PASSWORD=$(htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
    else
        log_warning "htpasswd no está instalado. Instalándolo..."
        if command -v apt-get &> /dev/null; then
            exec_cmd "sudo apt-get install -y apache2-utils" "Instalando apache2-utils para htpasswd"
            HASHED_PASSWORD=$(htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
        else
            log_warning "No se pudo instalar htpasswd. Usando hash básico."
            HASHED_PASSWORD="$TRAEFIK_USER:$TRAEFIK_PASSWORD"
        fi
    fi
    
    # Crear archivo .env
    cat > .env << EOF
# Configuración de usuario y grupo
PUID=$PUID
PGID=$PGID

# Zona horaria
TZ=$TZ

# Configuración de dominio y Cloudflare
DOMAIN_NAME=$DOMAIN_NAME
CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Configuración de PostgreSQL
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Configuración de Pi-hole
PIHOLE_PASSWORD=$PIHOLE_PASSWORD

# Configuración de Traefik
TRAEFIK_USER=$TRAEFIK_USER
TRAEFIK_PASSWORD=$TRAEFIK_PASSWORD
HASHED_PASSWORD=$HASHED_PASSWORD

# Configuración de red para Raspberry Pi
RPI_IP=$RPI_IP
EOF
    
    log_message "Archivo .env creado correctamente en modo silencioso."
    log_message "Contraseñas generadas automáticamente:"
    log_message "  - PostgreSQL: $POSTGRES_PASSWORD"
    log_message "  - Pi-hole: $PIHOLE_PASSWORD"
    log_message "  - Traefik: $TRAEFIK_PASSWORD"
}

# Función para configurar la red en modo silencioso
function setup_network_silent() {
    log_message "Configurando red en modo silencioso..."
    
    # Verificar permisos de superusuario
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Esta función requiere privilegios de superusuario. Ejecuta con sudo."
        return 1
    fi
    
    # Verificar si el archivo .env existe
    if [ ! -f ".env" ]; then
        log_error "El archivo .env no existe. Ejecutando setup_env_silent primero..."
        setup_env_silent
    fi
    
    # Cargar variables de entorno desde el archivo .env
    source .env
    
    # Verificar que RPI_IP está definido
    if [ -z "$RPI_IP" ]; then
        log_error "La variable RPI_IP no está definida en el archivo .env"
        return 1
    fi
    
    create_rollback_point "setup_network_silent_start" "Iniciando configuración de red silenciosa"
    
    # Crear backups de archivos críticos de red
    create_backup "/etc/hostname" "hostname"
    create_backup "/etc/hosts" "hosts"
    create_backup "/etc/resolv.conf" "resolv_conf"
    create_backup "/etc/network/interfaces" "network_interfaces"
    
    # Configuración automática usando valores por defecto
    NEW_HOSTNAME="surviving-chernarus"
    IP_ADDRESS="$RPI_IP"
    GATEWAY="${RPI_IP%.*}.1"  # Asumir gateway en .1
    DNS_SERVERS="1.1.1.1 1.0.0.1"
    
    log_message "Configuración automática: IP=$IP_ADDRESS, Gateway=$GATEWAY, Hostname=$NEW_HOSTNAME"
    
    # Actualizar .env con la nueva IP
    sed -i "s/RPI_IP=.*/RPI_IP=$IP_ADDRESS/g" .env
    
    # Configurar hostname
    echo "$NEW_HOSTNAME" > /etc/hostname
    hostname "$NEW_HOSTNAME"
    
    # Actualizar /etc/hosts
    sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    
    # Detectar interfaz de red principal
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE="eth0"  # Fallback por defecto
        log_warning "No se pudo detectar la interfaz de red principal, usando eth0 por defecto"
    fi
    log_message "Configurando interfaz de red: $INTERFACE"
    
    # Crear backup de la configuración actual de la interfaz
    if [[ -f "/etc/network/interfaces.d/$INTERFACE" ]]; then
        create_backup "/etc/network/interfaces.d/$INTERFACE" "interface_$INTERFACE"
    fi
    
    # Configurar interfaz de red
    cat > /etc/network/interfaces.d/$INTERFACE << EOF
auto $INTERFACE
iface $INTERFACE inet static
    address $IP_ADDRESS/24
    gateway $GATEWAY
EOF
    
    # Configurar resolv.conf
    cat > /etc/resolv.conf << EOF
# Generated by Surviving Chernarus setup_network_silent
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
    
    log_message "Configuración de red completada en modo silencioso."
    log_warning "Es necesario reiniciar el sistema para aplicar los cambios de red."
}

# Función para desplegar servicios en modo silencioso
function deploy_services_silent() {
    log_message "Desplegando servicios en modo silencioso..."
    
    # Verificar permisos de superusuario
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Esta función requiere privilegios de superusuario. Ejecuta con sudo."
        return 1
    fi
    
    # Verificar si el archivo .env existe
    if [ ! -f ".env" ]; then
        log_error "El archivo .env no existe. Ejecutando setup_env_silent primero..."
        setup_env_silent
    fi
    
    # Cargar variables de entorno desde el archivo .env
    source .env
    
    create_rollback_point "deploy_services_silent_start" "Iniciando despliegue de servicios silencioso"
    
    # Validar requisitos del sistema antes de continuar
    if ! validate_system_requirements; then
        log_error "Los requisitos del sistema no se cumplen. Abortando despliegue."
        return 1
    fi
    
    log_message "Iniciando instalación automática de servicios..."
    
    # 1. Actualización del sistema
    log_message "1. Actualizando el sistema..."
    exec_cmd "sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"
    
    # 2. Instalación y configuración de UFW
    log_message "2. Instalando y configurando UFW..."
    
    # Crear backups de configuración UFW
    create_backup "/etc/ufw" "ufw_config"
    create_backup "/etc/default/ufw" "ufw_default"
    
    if ! exec_cmd "sudo apt install ufw -y" "Instalando UFW"; then
        log_error "Error crítico: No se pudo instalar UFW"
        return 1
    fi
    
    exec_cmd "sudo ufw --force reset" "Reseteando configuración UFW"
    exec_cmd "sudo ufw default deny incoming" "Configurando política por defecto (deny incoming)"
    exec_cmd "sudo ufw default allow outgoing" "Configurando política por defecto (allow outgoing)"
    exec_cmd "sudo ufw allow ssh" "Permitiendo SSH"
    exec_cmd "sudo ufw allow http" "Permitiendo HTTP"
    exec_cmd "sudo ufw allow https" "Permitiendo HTTPS"
    exec_cmd "sudo ufw allow 53" "Permitiendo DNS"
    exec_cmd "sudo ufw allow 8080/tcp" "Permitiendo Traefik Dashboard"
    exec_cmd "sudo ufw allow 9091/tcp" "Permitiendo rTorrent"
    
    # 3. Configuración de UFW para Docker
    log_message "3. Configurando UFW para Docker..."
    
    # Modificar DEFAULT_FORWARD_POLICY
    exec_cmd "sudo sed -i 's/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g' /etc/default/ufw"
    
    # Activar UFW
    exec_cmd "sudo ufw --force enable"
    
    # 4. Instalación de Docker y Docker Compose
    log_message "4. Instalando Docker y Docker Compose..."
    
    # Verificar si Docker ya está instalado
    if command -v docker &> /dev/null; then
        log_message "Docker ya está instalado, verificando versión..."
        docker --version
    else
        # Instalar dependencias
        if ! exec_cmd "sudo apt install ca-certificates curl gnupg lsb-release -y" "Instalando dependencias para Docker"; then
            log_error "Error crítico: No se pudieron instalar las dependencias de Docker"
            return 1
        fi
        
        # Detectar distribución y arquitectura
        DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        ARCH=$(dpkg --print-architecture)
        log_message "Detectado: Distribución=$DISTRO, Arquitectura=$ARCH"
        
        # Añadir la clave GPG oficial de Docker
        exec_cmd "sudo install -m 0755 -d /etc/apt/keyrings" "Creando directorio para claves GPG"
        
        # Usar la URL correcta según la distribución
        if [[ "$DISTRO" == "ubuntu" ]]; then
            GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
            REPO_URL="https://download.docker.com/linux/ubuntu"
        else
            # Asumir Debian para Raspberry Pi OS
            GPG_URL="https://download.docker.com/linux/debian/gpg"
            REPO_URL="https://download.docker.com/linux/debian"
        fi
        
        exec_cmd "curl -fsSL $GPG_URL | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg" "Descargando clave GPG de Docker"
        exec_cmd "sudo chmod a+r /etc/apt/keyrings/docker.gpg" "Configurando permisos de clave GPG"
        
        # Añadir el repositorio de Docker
        echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] $REPO_URL $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Actualizar la lista de paquetes e instalar Docker
        exec_cmd "sudo apt update" "Actualizando lista de paquetes"
        exec_cmd "sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y" "Instalando Docker"
    fi
    
    # 5. Configuración de permisos de Docker
    log_message "5. Configurando permisos de Docker..."
    exec_cmd "sudo usermod -aG docker $USER" "Añadiendo usuario al grupo docker"
    exec_cmd "sudo systemctl enable docker" "Habilitando Docker al inicio"
    exec_cmd "sudo systemctl start docker" "Iniciando servicio Docker"
    
    log_message "Instalación completada en modo silencioso."
    log_message "IMPORTANTE: Es necesario cerrar sesión y volver a iniciar para que los cambios de grupo surtan efecto."
    log_message "Después de reiniciar la sesión, ejecuta 'docker ps' para verificar que Docker funciona correctamente."
}

# Función para mostrar la documentación
function show_documentation() {
    # Menú de documentación
    DOC_OPTION=$(whiptail --title "Surviving Chernarus - Documentación" \
                         --menu "Selecciona una opción:" 15 78 4 \
                         "1" "Información general" \
                         "2" "Guía de instalación" \
                         "3" "Solución de problemas" \
                         "4" "Volver al menú principal" 3>&1 1>&2 2>&3)
    
    # Salir si se presiona Cancelar
    if [ $? -ne 0 ]; then
        return
    fi
    
    case $DOC_OPTION in
        1)
            # Información general
            whiptail --title "Información General" \
                     --msgbox "Surviving Chernarus es un ecosistema de servicios auto-alojados diseñado para Raspberry Pi.\n\nServicios incluidos:\n- Traefik: Proxy inverso y balanceador de carga\n- PostgreSQL: Base de datos relacional\n- Pi-hole: Bloqueador de anuncios a nivel de red\n- n8n: Plataforma de automatización de flujos de trabajo\n- rTorrent: Cliente de BitTorrent\n- Heimdall: Panel de control para servicios\n\nRequisitos:\n- Raspberry Pi (recomendado Pi 4 o superior)\n- Raspberry Pi OS (64-bit recomendado)\n- Conexión a Internet\n- Dominio registrado en Cloudflare" 20 78
            show_documentation
            ;;
        2)
            # Guía de instalación
            whiptail --title "Guía de Instalación" \
                     --msgbox "Pasos para la instalación:\n\n1. Configurar variables de entorno (.env)\n   - Ejecuta la opción 1 del menú principal\n   - Configura todas las variables necesarias\n\n2. Configurar red (requiere sudo)\n   - Ejecuta la opción 2 del menú principal\n   - Configura la red para tu Raspberry Pi\n   - Reinicia el sistema cuando se te solicite\n\n3. Desplegar servicios\n   - Ejecuta la opción 3 del menú principal\n   - Sigue las instrucciones en pantalla\n   - Espera a que se complete la instalación\n\n4. Acceder a los servicios\n   - Utiliza las URLs proporcionadas al final de la instalación" 20 78
            show_documentation
            ;;
        3)
            # Solución de problemas
            whiptail --title "Solución de Problemas" \
                     --msgbox "Problemas comunes y soluciones:\n\n1. Error al configurar UFW para Docker\n   - Verifica que estás ejecutando el script con privilegios de superusuario\n   - Asegúrate de que UFW está instalado\n\n2. Error al instalar Docker\n   - Verifica tu conexión a Internet\n   - Asegúrate de que tu sistema está actualizado\n\n3. Los servicios no son accesibles\n   - Verifica que los contenedores están en ejecución con 'docker ps'\n   - Comprueba la configuración de Cloudflare\n   - Verifica que los puertos 80 y 443 están abiertos\n\n4. Problemas con Pi-hole\n   - Asegúrate de que no hay conflictos de puertos\n   - Verifica que el contenedor tiene los permisos necesarios\n\n5. RECUPERACIÓN DEL SISTEMA:\n   - Usa './deploy.sh rollback' para restaurar configuraciones\n   - Consulta './deploy.sh recovery' para el plan de desastres\n   - Los backups se guardan en: $BACKUP_DIR\n   - Los logs están en: $LOG_FILE\n\nPara más ayuda, consulta la documentación completa en:\nhttps://github.com/tu-usuario/surviving-chernarus" 25 78
            show_documentation
            ;;
        4)
            # Volver al menú principal
            return
            ;;
    esac
}

# Verificar si el script se está ejecutando como root para la opción de configuración de red
if [ "$1" = "network" ] && [ "$(id -u)" -ne 0 ]; then
    log_error "Para configurar la red, este script debe ejecutarse con privilegios de superusuario (sudo)."
    exit 1
fi

# Si se proporciona un argumento, ejecutar la función correspondiente
if [ -n "$1" ]; then
    case $1 in
        env)
            setup_env
            exit 0
            ;;
        network)
            setup_network
            exit 0
            ;;
        deploy)
            deploy_services
            exit 0
            ;;
        doc)
            show_documentation
            exit 0
            ;;
        rollback)
            if [ "$(id -u)" -ne 0 ]; then
                log_error "El rollback del sistema requiere privilegios de superusuario (sudo)."
                exit 1
            fi
            rollback_system
            exit 0
            ;;
        recovery)
            show_disaster_recovery
            exit 0
            ;;
        --help|-h)
            echo "Uso: $0 [OPCIÓN]"
            echo ""
            echo "OPCIONES:"
            echo "  env        Configurar variables de entorno"
            echo "  network    Configurar red (requiere sudo)"
            echo "  deploy     Desplegar servicios"
            echo "  doc        Mostrar documentación"
            echo "  rollback   Realizar rollback del sistema (requiere sudo)"
            echo "  recovery   Mostrar plan de recuperación ante desastres"
            echo "  --help, -h Mostrar esta ayuda"
            echo ""
            echo "Si no se proporciona ninguna opción, se mostrará el menú interactivo."
            exit 0
            ;;
        *)
            log_error "Argumento no válido: $1"
            echo "Uso: $0 [env|network|deploy|doc|rollback|recovery|--help]"
            echo "Ejecuta '$0 --help' para más información."
            exit 1
            ;;
    esac
fi

# Fin del script
log_info "Script completado exitosamente"
exit 0