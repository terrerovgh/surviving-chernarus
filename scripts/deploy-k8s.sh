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

# Función para verificar si un comando existe
check_command() {
    command -v "$1" &> /dev/null
}

# Función para verificar conectividad de red
check_network() {
    local host=$1
    local port=$2
    if check_command nc; then
        nc -z "$host" "$port" 2>/dev/null
    else
        # Fallback usando telnet o timeout
        timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null
    fi
}

# Función para obtener el hostname actual
get_hostname() {
    if check_command hostname; then
        hostname
    elif [[ -f /etc/hostname ]]; then
        cat /etc/hostname
    else
        uname -n
    fi
}

# Verificar que estamos en el directorio correcto
if [[ ! -f "kubernetes/core/namespace.yaml" ]]; then
    error "Este script debe ejecutarse desde el directorio raíz del proyecto"
    exit 1
fi

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    error "kubectl no está instalado o no está en el PATH"
    echo "💡 Instala kubectl con: sudo pacman -S kubectl (Arch Linux)"
    exit 1
fi

# Configurar KUBECONFIG si estamos en el master
CURRENT_HOSTNAME=$(get_hostname)
if [[ "$CURRENT_HOSTNAME" == "rpi" ]]; then
    export KUBECONFIG="$HOME/.kube/config"
    log "🔧 Configurando KUBECONFIG para el nodo master (rpi)"
elif [[ -f "$HOME/.kube/config" ]]; then
    export KUBECONFIG="$HOME/.kube/config"
    log "🔧 Usando kubeconfig local"
fi

# Verificar herramientas de red
if ! command -v nc &> /dev/null; then
    warning "⚠️ netcat (nc) no está disponible, algunas verificaciones serán limitadas"
    warning "💡 Instala con: sudo pacman -S openbsd-netcat"
fi

# Verificar conectividad al cluster
log "🔍 Verificando estado del cluster de Kubernetes..."

# Usar una variable para almacenar el resultado
CLUSTER_ACCESSIBLE=false
if kubectl cluster-info &> /dev/null; then
    CLUSTER_ACCESSIBLE=true
    success "✅ Conectado al cluster de Kubernetes exitosamente"
else
    CLUSTER_ACCESSIBLE=false
fi

if [[ "$CLUSTER_ACCESSIBLE" == "false" ]]; then
    error "No se puede conectar al cluster de Kubernetes"
    echo ""
    warning "Diagnóstico de problemas:"

    # Verificar si estamos en el master
    if [[ "$CURRENT_HOSTNAME" == "rpi" ]]; then
        echo "🔧 Estás en el nodo master (rpi). Verificando configuración local..."

        # Verificar si existe kubeconfig
        if [[ ! -f "$HOME/.kube/config" ]]; then
            error "Archivo kubeconfig no encontrado en $HOME/.kube/config"
            echo "💡 Ejecuta: sudo ./scripts/k8s-setup-master.sh para configurar el cluster"
        else
            echo "✅ Archivo kubeconfig encontrado"

            # Verificar si los servicios están corriendo
            if ! systemctl is-active --quiet kubelet; then
                error "El servicio kubelet no está corriendo"
                echo "💡 Ejecuta: sudo systemctl start kubelet"
            else
                echo "✅ Servicio kubelet está corriendo"
            fi

            if ! systemctl is-active --quiet containerd; then
                error "El servicio containerd no está corriendo"
                echo "💡 Ejecuta: sudo systemctl start containerd"
            else
                echo "✅ Servicio containerd está corriendo"
            fi

            # Verificar puerto de API server
            if ! check_network localhost 6443; then
                error "API Server no está respondiendo en el puerto 6443"
                echo "💡 El cluster puede necesitar ser inicializado o reiniciado"
            else
                echo "✅ API Server está respondiendo en el puerto 6443"
            fi
        fi
    else
        echo "🔧 No estás en el nodo master. Verificando conectividad..."

        # Verificar conectividad al master
        if ! check_network 192.168.0.2 6443; then
            error "No se puede conectar al master (192.168.0.2:6443)"
            echo "💡 Verifica que el master esté corriendo y accesible"
        else
            echo "✅ Master es accesible en 192.168.0.2:6443"
        fi

        # Verificar kubeconfig
        if [[ ! -f "$HOME/.kube/config" ]]; then
            error "Archivo kubeconfig no encontrado"
            echo "💡 Ejecuta: ./scripts/get-kubeconfig.sh para obtener la configuración"
        else
            echo "✅ Archivo kubeconfig encontrado"
        fi
    fi

    echo ""
    echo "📋 Pasos sugeridos para resolver el problema:"
    echo "1. 🏗️ Si el cluster no está configurado: ./scripts/k8s-setup-master.sh (en rpi)"
    echo "2. 🔑 Si necesitas kubeconfig: ./scripts/get-kubeconfig.sh (desde cualquier nodo)"
    echo "3. 📊 Verificar estado: ./scripts/cluster-status.sh"
    echo "4. 🔄 Reiniciar servicios: sudo systemctl restart kubelet containerd (en rpi)"
    echo ""
    exit 1
fi

log "🚀 Iniciando despliegue de Surviving Chernarus en Kubernetes..."

# Verificar que el cluster esté listo
log "⚕️ Verificando que el cluster esté listo para el despliegue..."

# Verificar nodos
READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready ")
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)

if [[ $READY_NODES -eq 0 ]]; then
    error "No hay nodos listos en el cluster"
    kubectl get nodes
    exit 1
fi

success "✅ Cluster listo: $READY_NODES/$TOTAL_NODES nodos disponibles"

# Verificar que el CNI esté funcionando
if ! kubectl get pods -n kube-flannel &> /dev/null; then
    warning "⚠️ Flannel CNI no encontrado, verificando conectividad de red..."
    if ! kubectl get pods -n kube-system | grep -q "coredns.*Running"; then
        error "Sistema DNS del cluster no está funcionando correctamente"
        exit 1
    fi
fi

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
echo ""
echo "📋 Comandos útiles para administración:"
echo "   📊 Ver estado del cluster: kubectl get all -A"
echo "   📝 Ver logs de un pod: kubectl logs <pod-name> -n <namespace>"
echo "   🔄 Reiniciar deployment: kubectl rollout restart deployment/<name> -n <namespace>"
echo "   🗑️ Eliminar todo: kubectl delete -f kubernetes/apps/surviving-chernarus/"
echo ""
echo "🔧 Para solucionar problemas:"
echo "   📊 Estado del cluster: ./scripts/cluster-status.sh"
echo "   💾 Backup del cluster: ./scripts/backup-chernarus.sh"
echo "   🏥 Health check: ./scripts/health-check.sh"
