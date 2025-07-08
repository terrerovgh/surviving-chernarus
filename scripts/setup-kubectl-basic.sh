#!/bin/bash

# =============================================================================
# Script alternativo para configurar kubectl sin SSH
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
API_PORT="6443"

log "🔧 Configurando kubectl para conectar directamente al cluster..."

# Crear directorio .kube si no existe
mkdir -p ~/.kube

# Crear kubeconfig básico para conectar al cluster
cat > ~/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://${MASTER_IP}:${API_PORT}
    insecure-skip-tls-verify: true
  name: chernarus-cluster
contexts:
- context:
    cluster: chernarus-cluster
    user: admin
  name: chernarus-admin
current-context: chernarus-admin
users:
- name: admin
  user:
    username: admin
    password: admin
EOF

# Establecer permisos correctos
chmod 600 ~/.kube/config

log "📄 Kubeconfig básico creado"

# Verificar conectividad
log "🧪 Probando conectividad al cluster..."

if kubectl version --short 2>/dev/null; then
    success "✅ kubectl configurado exitosamente"

    log "📊 Información del cluster:"
    kubectl cluster-info --insecure-skip-tls-verify 2>/dev/null || true

    echo ""
    log "🔍 Intentando obtener nodos..."
    kubectl get nodes --insecure-skip-tls-verify 2>/dev/null || {
        warning "⚠️ No se pudieron obtener los nodos (puede requerir autenticación)"

        log "💡 Opciones para resolver:"
        echo "1. Configurar certificados desde el master:"
        echo "   scp pi@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
        echo "   sed -i 's/127.0.0.1/${MASTER_IP}/g' ~/.kube/config"
        echo ""
        echo "2. O usar token de admin desde el master:"
        echo "   kubectl --server=https://${MASTER_IP}:${API_PORT} --insecure-skip-tls-verify get nodes"
        echo ""
        echo "3. Para despliegue temporal, usar configuración insegura:"
        echo "   kubectl --insecure-skip-tls-verify apply -f kubernetes/"
    }

else
    error "No se pudo conectar al cluster"
    exit 1
fi

log "🎯 Configuración inicial completada"
log "💡 Para acceso completo, necesitarás los certificados del master o configurar autenticación"
