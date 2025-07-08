#!/bin/bash

# backup-chernarus.sh - Script de respaldo completo para la infraestructura Chernarus
# Uso: ./scripts/backup-chernarus.sh [--full] [--config-only] [--data-only]

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
DATE=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="chernarus_backup_$DATE"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Opciones
FULL_BACKUP=true
CONFIG_ONLY=false
DATA_ONLY=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_BACKUP=true
            CONFIG_ONLY=false
            DATA_ONLY=false
            shift
            ;;
        --config-only)
            CONFIG_ONLY=true
            FULL_BACKUP=false
            DATA_ONLY=false
            shift
            ;;
        --data-only)
            DATA_ONLY=true
            FULL_BACKUP=false
            CONFIG_ONLY=false
            shift
            ;;
        *)
            echo "Uso: $0 [--full] [--config-only] [--data-only]"
            exit 1
            ;;
    esac
done

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
    echo -e "${BLUE}💾 CHERNARUS BACKUP SYSTEM${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Función para crear backup de base de datos
backup_database() {
    log "🗄️ Creando backup de PostgreSQL..."

    # Crear directorio para backup de DB
    mkdir -p "$BACKUP_PATH/database"

    # Backup de todas las bases de datos
    if docker ps | grep -q postgres_db; then
        log "📊 Respaldando base de datos PostgreSQL..."

        # Backup de todas las databases
        docker exec postgres_db pg_dumpall -U postgres > "$BACKUP_PATH/database/all_databases.sql"

        # Backup individual de la DB de N8N
        docker exec postgres_db pg_dump -U postgres n8n > "$BACKUP_PATH/database/n8n_db.sql"

        # Información de la base de datos
        docker exec postgres_db psql -U postgres -c "\l" > "$BACKUP_PATH/database/database_list.txt"

        log "✅ Backup de base de datos completado"
    else
        warn "⚠️ Contenedor PostgreSQL no encontrado o no está ejecutándose"
    fi
}

# Función para crear backup de configuraciones
backup_configurations() {
    log "⚙️ Creando backup de configuraciones..."

    # Crear directorio para configuraciones
    mkdir -p "$BACKUP_PATH/config"

    # Docker Compose y variables de entorno
    log "📋 Respaldando docker-compose.yml y .env"
    cp "$PROJECT_DIR/docker-compose.yml" "$BACKUP_PATH/config/"
    cp "$PROJECT_DIR/.env" "$BACKUP_PATH/config/" 2>/dev/null || warn "Archivo .env no encontrado"

    # Configuraciones de servicios
    log "🔧 Respaldando configuraciones de servicios"
    cp -r "$PROJECT_DIR/services" "$BACKUP_PATH/config/"

    # Scripts
    log "📜 Respaldando scripts"
    cp -r "$PROJECT_DIR/scripts" "$BACKUP_PATH/config/"

    # Kubernetes configs (si existen)
    if [ -d "$PROJECT_DIR/kubernetes" ]; then
        log "☸️ Respaldando configuraciones de Kubernetes"
        cp -r "$PROJECT_DIR/kubernetes" "$BACKUP_PATH/config/"
    fi

    # Documentación
    if [ -d "$PROJECT_DIR/docs" ]; then
        log "📚 Respaldando documentación"
        cp -r "$PROJECT_DIR/docs" "$BACKUP_PATH/config/"
    fi

    # Archivos de configuración del proyecto
    log "📄 Respaldando archivos del proyecto"
    for file in README.md DEVELOPMENT.md MISSION_LOG.md requirements.txt deploy.sh; do
        if [ -f "$PROJECT_DIR/$file" ]; then
            cp "$PROJECT_DIR/$file" "$BACKUP_PATH/config/"
        fi
    done

    log "✅ Backup de configuraciones completado"
}

# Función para crear backup de datos
backup_data() {
    log "💾 Creando backup de datos..."

    # Crear directorio para datos
    mkdir -p "$BACKUP_PATH/data"

    # Datos de proyectos web
    if [ -d "$BASE_DIR/data/projects" ]; then
        log "🌐 Respaldando proyectos web"
        cp -r "$BASE_DIR/data/projects" "$BACKUP_PATH/data/"
    fi

    # Datos de N8N
    if [ -d "$BASE_DIR/data/n8n" ]; then
        log "⚙️ Respaldando datos de N8N"
        cp -r "$BASE_DIR/data/n8n" "$BACKUP_PATH/data/"
    fi

    # Certificados SSL
    if [ -d "$BASE_DIR/data/letsencrypt" ]; then
        log "🔐 Respaldando certificados SSL"
        cp -r "$BASE_DIR/data/letsencrypt" "$BACKUP_PATH/data/"
    fi

    # Logs (últimos 7 días)
    if [ -d "$BASE_DIR/logs" ]; then
        log "📋 Respaldando logs recientes"
        mkdir -p "$BACKUP_PATH/data/logs"
        find "$BASE_DIR/logs" -name "*.log" -mtime -7 -exec cp {} "$BACKUP_PATH/data/logs/" \;
    fi

    # Datos de Traefik
    if [ -d "$BASE_DIR/data/traefik" ]; then
        log "🔀 Respaldando configuración de Traefik"
        cp -r "$BASE_DIR/data/traefik" "$BACKUP_PATH/data/"
    fi

    log "✅ Backup de datos completado"
}

# Función para crear backup de estado de Docker
backup_docker_state() {
    log "🐳 Creando backup del estado de Docker..."

    # Crear directorio para estado de Docker
    mkdir -p "$BACKUP_PATH/docker"

    # Lista de contenedores
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$BACKUP_PATH/docker/containers.txt"

    # Lista de imágenes
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" > "$BACKUP_PATH/docker/images.txt"

    # Lista de redes
    docker network ls > "$BACKUP_PATH/docker/networks.txt"

    # Lista de volúmenes
    docker volume ls > "$BACKUP_PATH/docker/volumes.txt"

    # Estado de docker-compose
    cd "$PROJECT_DIR"
    docker-compose config > "$BACKUP_PATH/docker/compose-config.yml" 2>/dev/null || warn "No se pudo obtener configuración de docker-compose"

    log "✅ Backup del estado de Docker completado"
}

# Función para crear manifiesto del backup
create_manifest() {
    log "📋 Creando manifiesto del backup..."

    cat > "$BACKUP_PATH/MANIFEST.txt" << EOF
CHERNARUS INFRASTRUCTURE BACKUP
===============================

Información del Backup:
- Fecha: $(date)
- Nombre: $BACKUP_NAME
- Tipo: $([ "$FULL_BACKUP" = true ] && echo "COMPLETO" || ([ "$CONFIG_ONLY" = true ] && echo "SOLO CONFIGURACIONES" || echo "SOLO DATOS"))
- Servidor: $(hostname)
- Usuario: $(whoami)

Contenido del Backup:
$(if [ "$FULL_BACKUP" = true ] || [ "$CONFIG_ONLY" = true ]; then
    echo "✅ Configuraciones (docker-compose.yml, .env, services/, scripts/)"
fi)
$(if [ "$FULL_BACKUP" = true ] || [ "$DATA_ONLY" = true ]; then
    echo "✅ Datos (proyectos web, N8N, certificados SSL, logs)"
fi)
$(if [ "$FULL_BACKUP" = true ]; then
    echo "✅ Base de datos PostgreSQL"
    echo "✅ Estado de Docker"
fi)

Estructura del Backup:
$(tree "$BACKUP_PATH" 2>/dev/null || find "$BACKUP_PATH" -type f | head -20)

Tamaño del Backup:
$(du -sh "$BACKUP_PATH")

Verificación:
- MD5: $(find "$BACKUP_PATH" -type f -exec md5sum {} \; | md5sum | cut -d' ' -f1)
- Archivos: $(find "$BACKUP_PATH" -type f | wc -l)
- Directorios: $(find "$BACKUP_PATH" -type d | wc -l)

Para restaurar este backup:
1. Ejecutar: ./scripts/restore-chernarus.sh $BACKUP_NAME
2. O extraer manualmente en la ubicación correspondiente

EOF

    log "✅ Manifiesto creado"
}

# Función para comprimir backup
compress_backup() {
    log "🗜️ Comprimiendo backup..."

    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

    # Verificar compresión
    if [ -f "${BACKUP_NAME}.tar.gz" ]; then
        log "✅ Backup comprimido: ${BACKUP_NAME}.tar.gz"
        log "📦 Tamaño: $(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)"

        # Calcular MD5 del archivo comprimido
        local md5_hash=$(md5sum "${BACKUP_NAME}.tar.gz" | cut -d' ' -f1)
        echo "$md5_hash  ${BACKUP_NAME}.tar.gz" > "${BACKUP_NAME}.tar.gz.md5"
        log "🔐 MD5: $md5_hash"

        # Limpiar directorio sin comprimir
        rm -rf "$BACKUP_NAME"
        log "🧹 Directorio temporal limpiado"
    else
        error "❌ Error al comprimir el backup"
        exit 1
    fi
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log "🧹 Limpiando backups antiguos (manteniendo últimos 5)..."

    cd "$BACKUP_DIR"

    # Contar backups existentes
    local backup_count=$(ls -1 chernarus_backup_*.tar.gz 2>/dev/null | wc -l)

    if [ "$backup_count" -gt 5 ]; then
        # Eliminar backups más antiguos
        ls -1t chernarus_backup_*.tar.gz | tail -n +6 | xargs rm -f
        ls -1t chernarus_backup_*.tar.gz.md5 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
        log "✅ Backups antiguos eliminados"
    else
        log "ℹ️ No es necesario limpiar (hay $backup_count backups)"
    fi

    # Mostrar backups disponibles
    log "📂 Backups disponibles:"
    ls -lh chernarus_backup_*.tar.gz 2>/dev/null || log "No hay backups existentes"
}

# Función principal
main() {
    title

    log "🚀 Iniciando backup de Chernarus..."
    log "📍 Tipo de backup: $([ "$FULL_BACKUP" = true ] && echo "COMPLETO" || ([ "$CONFIG_ONLY" = true ] && echo "SOLO CONFIGURACIONES" || echo "SOLO DATOS"))"

    # Crear directorio de backup
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_PATH"

    # Ejecutar backups según tipo
    if [ "$FULL_BACKUP" = true ]; then
        backup_configurations
        backup_data
        backup_database
        backup_docker_state
    elif [ "$CONFIG_ONLY" = true ]; then
        backup_configurations
        backup_docker_state
    elif [ "$DATA_ONLY" = true ]; then
        backup_data
        backup_database
    fi

    # Crear manifiesto
    create_manifest

    # Comprimir backup
    compress_backup

    # Limpiar backups antiguos
    cleanup_old_backups

    log "🎉 Backup completado exitosamente!"
    log "📦 Archivo: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    log "📋 Para restaurar: ./scripts/restore-chernarus.sh $BACKUP_NAME"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    error "❌ No se encuentra docker-compose.yml en $PROJECT_DIR"
    error "   Ejecuta este script desde el directorio del proyecto"
    exit 1
fi

# Ejecutar función principal
main
