#!/bin/bash

# restore-chernarus.sh - Script de restauración para la infraestructura Chernarus
# Uso: ./scripts/restore-chernarus.sh <backup_name> [--dry-run] [--force]

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
BACKUP_DIR="$BASE_DIR/backups"
DRY_RUN=false
FORCE=false

# Verificar argumentos
if [ $# -lt 1 ]; then
    echo "Uso: $0 <backup_name> [--dry-run] [--force]"
    echo ""
    echo "Backups disponibles:"
    ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | xargs -n1 basename | sed 's/.tar.gz$//' || echo "No hay backups disponibles"
    exit 1
fi

BACKUP_NAME="$1"
shift

# Procesar argumentos adicionales
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo "Opción desconocida: $1"
            exit 1
            ;;
    esac
done

BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
TEMP_RESTORE_DIR="/tmp/restore_$BACKUP_NAME"

# Función para logging con colores
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

title() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}♻️ CHERNARUS RESTORE SYSTEM${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Función para ejecutar comando (respeta dry-run)
execute() {
    local cmd="$1"
    local description="$2"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY-RUN]${NC} $description"
        echo -e "${CYAN}[COMMAND]${NC} $cmd"
    else
        log "$description"
        eval "$cmd"
    fi
}

# Función para verificar backup
verify_backup() {
    log "🔍 Verificando backup..."

    if [ ! -f "$BACKUP_FILE" ]; then
        error "❌ Archivo de backup no encontrado: $BACKUP_FILE"
        exit 1
    fi

    # Verificar MD5 si existe
    if [ -f "${BACKUP_FILE}.md5" ]; then
        log "🔐 Verificando integridad MD5..."
        if md5sum -c "${BACKUP_FILE}.md5" >/dev/null 2>&1; then
            log "✅ Verificación MD5 exitosa"
        else
            error "❌ Verificación MD5 falló"
            if [ "$FORCE" = false ]; then
                exit 1
            else
                warn "⚠️ Continuando con --force (ignoring MD5 mismatch)"
            fi
        fi
    else
        warn "⚠️ No se encontró archivo MD5 para verificación"
    fi

    log "📦 Tamaño del backup: $(du -sh "$BACKUP_FILE" | cut -f1)"
}

# Función para extraer backup
extract_backup() {
    log "📂 Extrayendo backup..."

    # Limpiar directorio temporal si existe
    if [ -d "$TEMP_RESTORE_DIR" ]; then
        execute "rm -rf '$TEMP_RESTORE_DIR'" "Limpiando directorio temporal anterior"
    fi

    # Crear directorio temporal
    execute "mkdir -p '$TEMP_RESTORE_DIR'" "Creando directorio temporal"

    # Extraer backup
    execute "cd '$TEMP_RESTORE_DIR' && tar -xzf '$BACKUP_FILE'" "Extrayendo archivo de backup"

    # Verificar estructura del backup
    if [ ! -d "$TEMP_RESTORE_DIR/$BACKUP_NAME" ]; then
        error "❌ Estructura de backup inválida"
        exit 1
    fi

    BACKUP_CONTENT_DIR="$TEMP_RESTORE_DIR/$BACKUP_NAME"

    # Mostrar contenido del backup
    log "📋 Contenido del backup:"
    if [ "$DRY_RUN" = false ]; then
        ls -la "$BACKUP_CONTENT_DIR"
    fi

    # Mostrar manifiesto si existe
    if [ -f "$BACKUP_CONTENT_DIR/MANIFEST.txt" ]; then
        log "📄 Información del backup:"
        if [ "$DRY_RUN" = false ]; then
            head -20 "$BACKUP_CONTENT_DIR/MANIFEST.txt"
        fi
    fi
}

# Función para parar servicios
stop_services() {
    log "🛑 Deteniendo servicios..."

    execute "cd '$PROJECT_DIR' && docker-compose down" "Deteniendo todos los servicios Docker"
}

# Función para restaurar configuraciones
restore_configurations() {
    if [ -d "$BACKUP_CONTENT_DIR/config" ]; then
        log "⚙️ Restaurando configuraciones..."

        # Backup de configuraciones actuales
        if [ "$DRY_RUN" = false ] && [ "$FORCE" = false ]; then
            local current_backup_dir="$PROJECT_DIR/backup_before_restore_$(date +%Y%m%d_%H%M%S)"
            execute "mkdir -p '$current_backup_dir'" "Creando backup de configuraciones actuales"
            execute "cp '$PROJECT_DIR/docker-compose.yml' '$current_backup_dir/' 2>/dev/null || true" "Respaldando docker-compose.yml actual"
            execute "cp '$PROJECT_DIR/.env' '$current_backup_dir/' 2>/dev/null || true" "Respaldando .env actual"
        fi

        # Restaurar archivos de configuración
        execute "cp '$BACKUP_CONTENT_DIR/config/docker-compose.yml' '$PROJECT_DIR/'" "Restaurando docker-compose.yml"
        execute "cp '$BACKUP_CONTENT_DIR/config/.env' '$PROJECT_DIR/' 2>/dev/null || true" "Restaurando .env"

        # Restaurar servicios
        if [ -d "$BACKUP_CONTENT_DIR/config/services" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/config/services' '$PROJECT_DIR/'" "Restaurando configuraciones de servicios"
        fi

        # Restaurar scripts
        if [ -d "$BACKUP_CONTENT_DIR/config/scripts" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/config/scripts' '$PROJECT_DIR/'" "Restaurando scripts"
            execute "chmod +x '$PROJECT_DIR/scripts'/*.sh" "Haciendo scripts ejecutables"
        fi

        # Restaurar documentación
        if [ -d "$BACKUP_CONTENT_DIR/config/docs" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/config/docs' '$PROJECT_DIR/'" "Restaurando documentación"
        fi

        # Restaurar archivos del proyecto
        for file in README.md DEVELOPMENT.md MISSION_LOG.md requirements.txt deploy.sh; do
            if [ -f "$BACKUP_CONTENT_DIR/config/$file" ]; then
                execute "cp '$BACKUP_CONTENT_DIR/config/$file' '$PROJECT_DIR/'" "Restaurando $file"
            fi
        done

        log "✅ Configuraciones restauradas"
    else
        warn "⚠️ No se encontraron configuraciones en el backup"
    fi
}

# Función para restaurar datos
restore_data() {
    if [ -d "$BACKUP_CONTENT_DIR/data" ]; then
        log "💾 Restaurando datos..."

        # Crear directorios de datos si no existen
        execute "mkdir -p '$BASE_DIR/data'" "Creando directorio de datos"

        # Restaurar proyectos web
        if [ -d "$BACKUP_CONTENT_DIR/data/projects" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/data/projects' '$BASE_DIR/data/'" "Restaurando proyectos web"
        fi

        # Restaurar datos de N8N
        if [ -d "$BACKUP_CONTENT_DIR/data/n8n" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/data/n8n' '$BASE_DIR/data/'" "Restaurando datos de N8N"
        fi

        # Restaurar certificados SSL
        if [ -d "$BACKUP_CONTENT_DIR/data/letsencrypt" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/data/letsencrypt' '$BASE_DIR/data/'" "Restaurando certificados SSL"
        fi

        # Restaurar datos de Traefik
        if [ -d "$BACKUP_CONTENT_DIR/data/traefik" ]; then
            execute "cp -r '$BACKUP_CONTENT_DIR/data/traefik' '$BASE_DIR/data/'" "Restaurando configuración de Traefik"
        fi

        # Restaurar logs
        if [ -d "$BACKUP_CONTENT_DIR/data/logs" ]; then
            execute "mkdir -p '$BASE_DIR/logs'" "Creando directorio de logs"
            execute "cp -r '$BACKUP_CONTENT_DIR/data/logs'/* '$BASE_DIR/logs/' 2>/dev/null || true" "Restaurando logs"
        fi

        log "✅ Datos restaurados"
    else
        warn "⚠️ No se encontraron datos en el backup"
    fi
}

# Función para restaurar base de datos
restore_database() {
    if [ -d "$BACKUP_CONTENT_DIR/database" ]; then
        log "🗄️ Restaurando base de datos..."

        # Primero necesitamos que PostgreSQL esté ejecutándose
        execute "cd '$PROJECT_DIR' && docker-compose up -d postgres_db" "Iniciando PostgreSQL"

        if [ "$DRY_RUN" = false ]; then
            # Esperar a que PostgreSQL esté listo
            log "⏳ Esperando a que PostgreSQL esté listo..."
            sleep 10

            # Verificar si PostgreSQL está ejecutándose
            if docker ps | grep -q postgres_db; then
                # Restaurar base de datos completa
                if [ -f "$BACKUP_CONTENT_DIR/database/all_databases.sql" ]; then
                    execute "docker exec -i postgres_db psql -U postgres < '$BACKUP_CONTENT_DIR/database/all_databases.sql'" "Restaurando todas las bases de datos"
                fi

                # Restaurar específicamente N8N si el archivo existe
                if [ -f "$BACKUP_CONTENT_DIR/database/n8n_db.sql" ]; then
                    execute "docker exec postgres_db createdb -U postgres n8n 2>/dev/null || true" "Creando base de datos N8N"
                    execute "docker exec -i postgres_db psql -U postgres -d n8n < '$BACKUP_CONTENT_DIR/database/n8n_db.sql'" "Restaurando base de datos N8N"
                fi

                log "✅ Base de datos restaurada"
            else
                error "❌ PostgreSQL no está ejecutándose"
            fi
        fi
    else
        warn "⚠️ No se encontraron datos de base de datos en el backup"
    fi
}

# Función para iniciar servicios
start_services() {
    log "🚀 Iniciando servicios..."

    execute "cd '$PROJECT_DIR' && docker-compose up -d" "Iniciando todos los servicios"

    if [ "$DRY_RUN" = false ]; then
        log "⏳ Esperando a que los servicios estén listos..."
        sleep 15

        # Verificar estado de servicios
        log "📊 Estado de servicios:"
        docker-compose -f "$PROJECT_DIR/docker-compose.yml" ps
    fi
}

# Función para limpieza
cleanup() {
    log "🧹 Limpiando archivos temporales..."

    execute "rm -rf '$TEMP_RESTORE_DIR'" "Eliminando directorio temporal"
}

# Función para verificar restauración
verify_restore() {
    if [ "$DRY_RUN" = false ]; then
        log "🔍 Verificando restauración..."

        # Verificar servicios principales
        local services=("traefik_proxy" "postgres_db" "n8n_engine" "hq_dashboard")
        for service in "${services[@]}"; do
            if docker ps | grep -q "$service"; then
                log "✅ $service está ejecutándose"
            else
                warn "⚠️ $service no está ejecutándose"
            fi
        done

        # Verificar acceso a servicios web (opcional)
        log "🌐 Para verificar los servicios web, ejecuta:"
        echo "   ./scripts/monitor-services.sh"
    fi
}

# Función de confirmación
confirm_restore() {
    if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
        echo ""
        warn "⚠️ ADVERTENCIA: Esta operación sobreescribirá la configuración actual"
        echo -e "${YELLOW}¿Estás seguro de que quieres restaurar el backup '$BACKUP_NAME'? (yes/no):${NC}"
        read -r response

        if [ "$response" != "yes" ]; then
            log "❌ Restauración cancelada por el usuario"
            exit 0
        fi
    fi
}

# Función principal
main() {
    title

    log "♻️ Iniciando restauración de Chernarus..."
    log "📦 Backup: $BACKUP_NAME"
    log "🔧 Modo: $([ "$DRY_RUN" = true ] && echo "DRY-RUN" || echo "RESTAURACIÓN REAL")"

    # Verificar backup
    verify_backup

    # Extraer backup
    extract_backup

    # Confirmar restauración
    confirm_restore

    # Detener servicios
    stop_services

    # Restaurar componentes
    restore_configurations
    restore_data
    restore_database

    # Iniciar servicios
    start_services

    # Verificar restauración
    verify_restore

    # Limpiar
    cleanup

    if [ "$DRY_RUN" = true ]; then
        log "🔍 DRY-RUN completado. No se realizaron cambios."
        log "💡 Para ejecutar la restauración real: $0 $BACKUP_NAME"
    else
        log "🎉 Restauración completada exitosamente!"
        log "🔍 Verifica los servicios con: ./scripts/monitor-services.sh"
    fi
}

# Verificar que estamos en el directorio correcto
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    error "❌ No se encuentra docker-compose.yml en $PROJECT_DIR"
    error "   Ejecuta este script desde el directorio del proyecto"
    exit 1
fi

# Ejecutar función principal
main
