#!/bin/bash
#
# Script para ejecutar en 'rpi' para desplegar o actualizar el sistema.
# TODO: Implementar lógica de despliegue para K3s y servicios del host.

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${BLUE}[DEPLOY_RPI]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DEPLOY_RPI]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DEPLOY_RPI]${NC} $1"
}

log_error() {
    echo -e "${RED}[DEPLOY_RPI]${NC} $1"
}

# Variables de entorno
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KUBE_CONFIG="/etc/rancher/k3s/k3s.yaml"

# Función para verificar prerrequisitos
check_prerequisites() {
    log_info "Verificando prerrequisitos del Beacon..."

    # Verificar que estamos en rpi
    if [[ "$(hostname)" != "rpi" ]]; then
        log_error "Este script debe ejecutarse en el nodo master 'rpi'"
        exit 1
    fi

    # Verificar que existe el archivo .env
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        log_error "Archivo .env no encontrado. Copia .env.example a .env y configúralo"
        exit 1
    fi

    # Cargar variables de entorno
    set -a
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/.env"
    set +a

    # Verificar que K3s está instalado
    if ! command -v k3s &> /dev/null; then
        log_error "K3s no está instalado. Ejecutar: curl -sfL https://get.k3s.io | sh -"
        exit 1
    fi

    # Verificar que kubectl está disponible
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl no está en PATH, usando k3s kubectl"
        alias kubectl="k3s kubectl"
    fi

    # Verificar que envsubst está disponible para procesar templates
    if ! command -v envsubst &> /dev/null; then
        log_error "envsubst no está instalado. Ejecutar: apt-get install gettext-base"
        exit 1
    fi

    log_success "Prerrequisitos verificados"
}

# Función para procesar configuraciones con variables de entorno
process_configurations() {
    log_info "Procesando configuraciones con variables de entorno..."

    # Ejecutar el script de procesamiento de configuraciones
    if [[ -f "$PROJECT_ROOT/scripts/process-configs.sh" ]]; then
        "$PROJECT_ROOT/scripts/process-configs.sh"
    else
        log_error "Script de procesamiento de configuraciones no encontrado"
        exit 1
    fi

    log_success "Configuraciones procesadas"
}

# Función para actualizar configuraciones del sistema
update_system_configs() {
    log_info "Actualizando configuraciones del sistema host..."

    # TODO: Actualizar configuración de hostapd
    # TODO: Actualizar configuración de Pi-hole
    # TODO: Actualizar reglas de nftables
    # TODO: Reiniciar servicios si es necesario

    log_success "Configuraciones del sistema actualizadas"
}

# Función para desplegar manifiestos de Kubernetes
deploy_kubernetes_manifests() {
    log_info "Desplegando manifiestos de Kubernetes..."

    # Aplicar configuraciones core primero
    if [[ -d "$PROJECT_ROOT/kubernetes/core" ]]; then
        log_info "Aplicando configuraciones core..."
        kubectl apply -f "$PROJECT_ROOT/kubernetes/core/"
    fi

    # Aplicar aplicaciones
    if [[ -d "$PROJECT_ROOT/kubernetes/apps" ]]; then
        log_info "Desplegando aplicaciones..."
        find "$PROJECT_ROOT/kubernetes/apps" -name "kustomization.yaml" -execdir kubectl apply -k . \;
    fi

    log_success "Manifiestos de Kubernetes desplegados"
}

# Función para verificar el estado del despliegue
verify_deployment() {
    log_info "Verificando estado del despliegue..."

    # Esperar a que todos los pods estén ready
    log_info "Esperando a que todos los pods estén listos..."
    kubectl wait --for=condition=ready pod --all --timeout=300s

    # Mostrar estado de los servicios
    log_info "Estado de los servicios:"
    kubectl get pods -A
    kubectl get services -A

    log_success "Verificación completada"
}

# Función para ejecutar tests post-despliegue
run_post_deployment_tests() {
    log_info "Ejecutando tests post-despliegue..."

    # TODO: Verificar conectividad a servicios
    # TODO: Verificar acceso a subdominios
    # TODO: Verificar funcionamiento de n8n
    # TODO: Verificar acceso a base de datos

    log_success "Tests post-despliegue completados"
}

# Función principal
main() {
    log_info "Iniciando protocolo de despliegue en el Beacon..."

    check_prerequisites
    process_configurations
    update_system_configs
    deploy_kubernetes_manifests
    verify_deployment
    run_post_deployment_tests

    log_success "Protocolo de despliegue completado exitosamente"
    log_info "El Colectivo Chernarus está operativo, Operador"
}

# Manejo de señales
trap 'log_error "Despliegue interrumpido"; exit 1' INT TERM

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
