#!/bin/bash

# =============================================================================
# Script de despliegue temporal para Surviving Chernarus sin SSH
# Requiere acceso físico al master o configuración manual de kubeconfig
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

log "🚀 Iniciando despliegue temporal de Surviving Chernarus..."

# Verificar que estamos en el directorio correcto
if [[ ! -f "kubernetes/core/namespace.yaml" ]]; then
    error "Este script debe ejecutarse desde el directorio raíz del proyecto"
    exit 1
fi

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    error "kubectl no está instalado o no está en el PATH"
    exit 1
fi

# Mostrar instrucciones para configurar kubeconfig
echo ""
warning "⚠️ CONFIGURACIÓN REQUERIDA:"
echo ""
echo "Para desplegar en Kubernetes, necesitas ejecutar estos comandos en el MASTER (rpi):"
echo ""
echo "1. 📥 Clonar el repositorio en el master:"
echo "   git clone https://github.com/terrerovgh/surviving-chernarus.git"
echo "   cd surviving-chernarus"
echo ""
echo "2. 🚀 Ejecutar el despliegue desde el master:"
echo "   ./scripts/deploy-k8s.sh"
echo ""
echo "3. 🔄 O alternativamente, copiar kubeconfig aquí:"
echo "   scp pi@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
echo "   sed -i 's/127.0.0.1/${MASTER_IP}/g' ~/.kube/config"
echo "   chmod 600 ~/.kube/config"
echo ""

# Verificar si ya tenemos un kubeconfig funcional
if kubectl cluster-info &>/dev/null; then
    success "✅ kubectl ya está configurado correctamente"
    log "🚀 Procediendo con el despliegue..."

    # Ejecutar el script de despliegue principal
    exec ./scripts/deploy-k8s.sh

else
    warning "❌ kubectl no está configurado o no puede conectar al cluster"

    log "💡 Opciones disponibles:"
    echo ""
    echo "A) 📋 Ejecutar comandos manualmente desde el master (rpi):"
    echo "   ssh pi@${MASTER_IP}"
    echo "   sudo kubectl apply -f kubernetes/"
    echo ""
    echo "B) 🔧 Configurar kubeconfig y reintentar:"
    echo "   ./scripts/get-kubeconfig.sh"
    echo "   ./scripts/deploy-temp.sh"
    echo ""
    echo "C) 🌐 Verificar que el cluster esté funcionando:"
    echo "   curl -k https://${MASTER_IP}:6443/version"
    echo ""

    # Mostrar información del cluster si está accesible
    if curl -k -s "https://${MASTER_IP}:6443/version" &>/dev/null; then
        success "✅ Cluster Kubernetes está accesible en https://${MASTER_IP}:6443"

        log "📊 Información del cluster:"
        curl -k -s "https://${MASTER_IP}:6443/version" | python3 -m json.tool 2>/dev/null || {
            curl -k -s "https://${MASTER_IP}:6443/version"
        }
    else
        error "❌ No se puede acceder al API de Kubernetes"
    fi

    echo ""
    log "🎯 Una vez configurado kubectl, puedes ejecutar:"
    echo "   ./scripts/deploy-k8s.sh"

    exit 1
fi
