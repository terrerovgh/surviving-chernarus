#!/bin/bash

# =============================================================================
# Script para obtener kubeconfig del cluster Kubernetes desde el master
# Autor: AI Assistant para terrerov
# Fecha: $(date)
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

MASTER_IP="192.168.0.2"
MASTER_USER="pi"

# Opciones de SSH
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no"

# Función para probar SSH
test_ssh() {
    if ssh $SSH_OPTS "$MASTER_USER@$MASTER_IP" "echo 'SSH OK'" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

log "🔑 Obteniendo kubeconfig del master Kubernetes (rpi)..."

# Verificar conectividad al master (SSH y Kubernetes API)
log "🔍 Verificando conectividad SSH y Kubernetes API..."
if ! nc -z "$MASTER_IP" 22 2>/dev/null; then
    error "No se puede conectar al puerto SSH (22) en $MASTER_IP"
    exit 1
fi

if ! nc -z "$MASTER_IP" 6443 2>/dev/null; then
    error "No se puede conectar al puerto Kubernetes API (6443) en $MASTER_IP"
    exit 1
fi

success "✅ Conectividad SSH y Kubernetes API verificada"

log "📡 Conectando a $MASTER_USER@$MASTER_IP..."

# Obtener kubeconfig del master
if ssh -o ConnectTimeout=10 "$MASTER_USER@$MASTER_IP" "test -f /etc/rancher/k3s/k3s.yaml"; then
    log "📄 Copiando kubeconfig desde el master..."

    # Crear backup del kubeconfig actual si existe
    if [[ -f ~/.kube/config ]]; then
        cp ~/.kube/config ~/.kube/config.backup.$(date +%s)
        warning "Backup del kubeconfig anterior creado"
    fi

    # Copiar kubeconfig desde el master
    scp "$MASTER_USER@$MASTER_IP:/etc/rancher/k3s/k3s.yaml" ~/.kube/config

    # Reemplazar la IP localhost con la IP real del master
    sed -i "s/127.0.0.1/$MASTER_IP/g" ~/.kube/config

    # Establecer permisos correctos
    chmod 600 ~/.kube/config

    success "✅ Kubeconfig obtenido exitosamente"

    # Probar la conexión
    log "🧪 Probando conexión al cluster..."
    if kubectl cluster-info; then
        success "🎯 Conexión al cluster establecida correctamente"

        # Mostrar información del cluster
        echo ""
        log "📊 Información del cluster:"
        kubectl get nodes -o wide

        echo ""
        log "📦 Namespaces disponibles:"
        kubectl get namespaces

    else
        error "No se pudo conectar al cluster"
        exit 1
    fi

else
    error "No se encontró el archivo kubeconfig en el master"
    exit 1
fi
