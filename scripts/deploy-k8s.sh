#!/bin/bash

# =============================================================================
# Script de despliegue para Surviving Chernarus en Kubernetes
# Autor: AI Assistant para terrerov
# Fecha: $(date)
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
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

# Verificar conectividad al cluster
if ! kubectl cluster-info &> /dev/null; then
    error "No se puede conectar al cluster de Kubernetes"
    exit 1
fi

log "🚀 Iniciando despliegue de Surviving Chernarus en Kubernetes..."

# 1. Aplicar namespaces
log "📁 Creando namespaces..."
kubectl apply -f kubernetes/core/namespace.yaml

# 2. Aplicar ConfigMaps y Secrets
log "⚙️ Aplicando configuración y secretos..."
kubectl apply -f kubernetes/core/configmap.yaml

# 3. Desplegar servicios core
log "🗄️ Desplegando PostgreSQL..."
kubectl apply -f kubernetes/apps/surviving-chernarus/postgresql.yaml

# Esperar a que PostgreSQL esté listo
log "⏳ Esperando a que PostgreSQL esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/postgresql-deployment -n surviving-chernarus

# 4. Desplegar n8n
log "🤖 Desplegando n8n Automation Engine..."
kubectl apply -f kubernetes/apps/surviving-chernarus/n8n.yaml

# 5. Desplegar Traefik
log "🌐 Desplegando Traefik Reverse Proxy..."
kubectl apply -f kubernetes/apps/surviving-chernarus/traefik.yaml

# 6. Desplegar Hugo Dashboard
log "🏢 Desplegando Hugo Dashboard..."
kubectl apply -f kubernetes/apps/surviving-chernarus/hugo-dashboard.yaml

# 7. Aplicar Ingress
log "🚪 Configurando Ingress..."
kubectl apply -f kubernetes/apps/surviving-chernarus/ingress.yaml

# Esperar a que todos los deployments estén listos
log "⏳ Esperando a que todos los servicios estén listos..."

# Lista de deployments a verificar
DEPLOYMENTS=(
    "surviving-chernarus/postgresql-deployment"
    "surviving-chernarus/n8n-deployment"
    "chernarus-system/traefik-deployment"
    "surviving-chernarus/hugo-dashboard-deployment"
)

for deployment in "${DEPLOYMENTS[@]}"; do
    namespace=$(echo $deployment | cut -d'/' -f1)
    deploy_name=$(echo $deployment | cut -d'/' -f2)
    log "⏳ Esperando deployment $deploy_name en namespace $namespace..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deploy_name -n $namespace
done

# Mostrar estado del cluster
log "📊 Estado del cluster después del despliegue:"
echo ""
kubectl get pods -n surviving-chernarus
echo ""
kubectl get pods -n chernarus-system
echo ""
kubectl get services -n surviving-chernarus
echo ""
kubectl get ingress -n surviving-chernarus

# Obtener IPs de los servicios
log "🌐 Información de conectividad:"
TRAEFIK_IP=$(kubectl get service traefik-service -n chernarus-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
if [[ "$TRAEFIK_IP" == "Pending" ]]; then
    TRAEFIK_IP=$(kubectl get service traefik-service -n chernarus-system -o jsonpath='{.spec.clusterIP}')
fi

echo ""
success "✅ Despliegue completado exitosamente!"
echo ""
echo "🔗 URLs de acceso:"
echo "   🏢 HQ Dashboard: https://terrerov.com / https://hq.terrerov.com"
echo "   🤖 n8n Automation: https://n8n.terrerov.com"
echo "   🌐 Traefik Dashboard: https://traefik.terrerov.com"
echo ""
echo "📡 IP del Load Balancer: $TRAEFIK_IP"
echo ""
warning "⚠️ Recuerda actualizar los registros DNS para apuntar a la IP del cluster"
echo ""
log "🎯 Surviving Chernarus está ahora corriendo en Kubernetes!"
