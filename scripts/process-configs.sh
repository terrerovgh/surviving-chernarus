#!/bin/bash
#
# Script para procesar templates de configuración con variables de entorno
# Reemplaza variables ${VARIABLE} en archivos .template con valores reales

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${BLUE}[CONFIG_PROCESSOR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[CONFIG_PROCESSOR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[CONFIG_PROCESSOR]${NC} $1"
}

log_error() {
    echo -e "${RED}[CONFIG_PROCESSOR]${NC} $1"
}

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Función para verificar que existe el archivo .env
check_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "Archivo .env no encontrado en: $ENV_FILE"
        log_info "Copia .env.example a .env y configura las variables necesarias"
        log_info "cp .env.example .env"
        exit 1
    fi

    log_success "Archivo .env encontrado: $ENV_FILE"
}

# Función para cargar variables de entorno
load_env_vars() {
    log_info "Cargando variables de entorno desde $ENV_FILE"

    # Cargar variables de entorno, ignorando comentarios y líneas vacías
    set -a  # Automatically export all variables
    # shellcheck source=/dev/null
    source <(grep -v '^#' "$ENV_FILE" | grep -v '^$' | sed 's/^/export /')
    set +a

    log_success "Variables de entorno cargadas"
}

# Función para procesar un template específico
process_template() {
    local template_file="$1"
    local output_file="${template_file%.template}"

    log_info "Procesando template: $template_file"

    if [[ ! -f "$template_file" ]]; then
        log_error "Template no encontrado: $template_file"
        return 1
    fi

    # Usar envsubst para reemplazar variables de entorno
    if command -v envsubst &> /dev/null; then
        envsubst < "$template_file" > "$output_file"
        log_success "Template procesado: $template_file -> $output_file"
    else
        log_error "envsubst no está instalado. Instalalo con: apt-get install gettext-base"
        return 1
    fi
}

# Función para procesar todos los templates
process_all_templates() {
    log_info "Buscando archivos .template en el proyecto..."

    local template_count=0

    # Buscar todos los archivos .template en el proyecto
    while IFS= read -r -d '' template_file; do
        process_template "$template_file"
        ((template_count++))
    done < <(find "$PROJECT_ROOT" -name "*.template" -print0)

    if [[ $template_count -eq 0 ]]; then
        log_warning "No se encontraron archivos .template para procesar"
    else
        log_success "Se procesaron $template_count archivos template"
    fi
}

# Función para validar configuraciones críticas
validate_configs() {
    log_info "Validando configuraciones críticas..."

    # Variables críticas que deben estar definidas
    local critical_vars=(
        "YOUR_DOMAIN_NAME"
        "POSTGRES_PASSWORD"
        "N8N_ENCRYPTION_KEY"
        "CLOUDFLARE_API_KEY"
    )

    local missing_vars=()

    for var in "${critical_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Variables críticas no definidas:"
        printf '%s\n' "${missing_vars[@]}"
        log_error "Configura estas variables en el archivo .env"
        return 1
    fi

    log_success "Todas las variables críticas están configuradas"
}

# Función para crear directorios necesarios
create_required_directories() {
    log_info "Creando directorios necesarios..."

    local directories=(
        "${DATA_PATH}/postgres"
        "${DATA_PATH}/n8n"
        "${DATA_PATH}/traefik"
        "${DATA_PATH}/squid"
        "${LOG_PATH}/postgres"
        "${LOG_PATH}/n8n"
        "${LOG_PATH}/traefik"
        "${LOG_PATH}/nginx"
        "${LOG_PATH}/squid"
        "${BACKUP_PATH}"
    )

    for dir in "${directories[@]}"; do
        if [[ -n "$dir" ]]; then  # Solo si la variable no está vacía
            sudo mkdir -p "$dir"
            sudo chown -R "$USER:$USER" "$dir"
            log_info "Directorio creado: $dir"
        fi
    done

    log_success "Directorios necesarios creados"
}

# Función para generar secretos automáticamente si no existen
generate_missing_secrets() {
    log_info "Verificando secretos automáticos..."

    local updated_env=false

    # Verificar N8N_ENCRYPTION_KEY
    if [[ "${N8N_ENCRYPTION_KEY:-}" == *"GENERATE"* ]]; then
        local n8n_key
        n8n_key=$(openssl rand -hex 32)
        sed -i.bak "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$n8n_key/" "$ENV_FILE"
        log_success "Generada N8N_ENCRYPTION_KEY automáticamente"
        updated_env=true
    fi

    # Verificar APP_SECRET_KEY
    if [[ "${APP_SECRET_KEY:-}" == *"GENERATE"* ]]; then
        local app_key
        app_key=$(openssl rand -hex 32)
        sed -i.bak "s/APP_SECRET_KEY=.*/APP_SECRET_KEY=$app_key/" "$ENV_FILE"
        log_success "Generada APP_SECRET_KEY automáticamente"
        updated_env=true
    fi

    if [[ "$updated_env" == true ]]; then
        log_warning "Archivo .env actualizado con secretos generados. Recarga las variables:"
        log_info "source .env"
    fi
}

# Función principal
main() {
    log_info "Iniciando procesamiento de configuraciones del Colectivo Chernarus..."

    check_env_file
    load_env_vars
    validate_configs
    generate_missing_secrets
    create_required_directories
    process_all_templates

    log_success "Procesamiento de configuraciones completado"
    log_info "El Colectivo está listo para el despliegue, Operador"
}

# Función de ayuda
show_help() {
    cat << EOF
Script de Procesamiento de Configuraciones - Surviving Chernarus

USO:
    $0 [OPCIÓN]

OPCIONES:
    -h, --help              Mostrar esta ayuda
    -t, --template FILE     Procesar un template específico
    -v, --validate          Solo validar configuraciones
    --generate-secrets      Solo generar secretos faltantes

EJEMPLOS:
    $0                                          # Procesar todos los templates
    $0 -t services/squid/squid.conf.template   # Procesar template específico
    $0 --validate                               # Solo validar variables

EOF
}

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--template)
            if [[ -n "${2:-}" ]]; then
                check_env_file
                load_env_vars
                process_template "$2"
                exit 0
            else
                log_error "Opción --template requiere un archivo"
                exit 1
            fi
            ;;
        -v|--validate)
            check_env_file
            load_env_vars
            validate_configs
            exit 0
            ;;
        --generate-secrets)
            check_env_file
            load_env_vars
            generate_missing_secrets
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Ejecutar función principal si no se pasaron argumentos específicos
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
