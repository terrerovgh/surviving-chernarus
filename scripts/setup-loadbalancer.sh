#!/bin/bash

# ============================================================================
# CHERNARUS LOAD BALANCER SETUP SCRIPT
# ============================================================================
# Este script configura un load balancer en Kubernetes para acceso HTTPS
# a todos los servicios de Chernarus usando nombres de dominio
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Configuración
KUBERNETES_DIR="/home/terrerov/surviving-chernarus/kubernetes"
DOMAIN="terrerov.com"

print_header "CONFIGURANDO LOAD BALANCER PARA CHERNARUS"

echo "Este script configurará:"
echo "  🌐 Load Balancer con IPs externas"
echo "  🔒 Certificados SSL automáticos"
echo "  📡 Ingress para todos los servicios"
echo "  🛡️ Middlewares de seguridad"
echo ""

# Verificar acceso a kubectl
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "No se puede acceder al cluster de Kubernetes"
    print_info "Asegúrate de que kubectl esté configurado correctamente"
    exit 1
fi

print_success "Cluster de Kubernetes accesible"

# Verificar namespaces
print_info "Verificando namespaces..."
kubectl create namespace chernarus-system --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
kubectl create namespace surviving-chernarus --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
print_success "Namespaces verificados"

# Aplicar configuración de load balancer
print_info "Aplicando configuración de load balancer..."
if kubectl apply -f "$KUBERNETES_DIR/core/traefik-loadbalancer.yaml"; then
    print_success "Load balancer configurado"
else
    print_error "Error al configurar load balancer"
    exit 1
fi

# Aplicar configuración SSL
print_info "Aplicando configuración SSL..."
if kubectl apply -f "$KUBERNETES_DIR/core/ssl-config.yaml"; then
    print_success "Configuración SSL aplicada"
else
    print_warning "Error al aplicar configuración SSL (puede requerir cert-manager)"
fi

# Aplicar Ingress HTTPS
print_info "Aplicando configuración de Ingress HTTPS..."
if kubectl apply -f "$KUBERNETES_DIR/core/https-ingress.yaml"; then
    print_success "Ingress HTTPS configurado"
else
    print_error "Error al configurar Ingress HTTPS"
    exit 1
fi

# Esperar a que los servicios estén listos
print_info "Esperando a que el load balancer esté disponible..."
sleep 10

# Verificar estado
print_header "VERIFICANDO CONFIGURACIÓN"

echo "Estado de servicios LoadBalancer:"
kubectl get svc -n chernarus-system traefik-loadbalancer -o wide 2>/dev/null || print_warning "Load balancer no encontrado"

echo ""
echo "Estado de Ingress:"
kubectl get ingress -A 2>/dev/null || print_warning "No se encontraron Ingress"

echo ""
echo "Endpoints externos disponibles:"
EXTERNAL_IPS=$(kubectl get svc -n chernarus-system traefik-loadbalancer -o jsonpath='{.spec.externalIPs[*]}' 2>/dev/null || echo "")
if [ -n "$EXTERNAL_IPS" ]; then
    for IP in $EXTERNAL_IPS; do
        echo "  https://$DOMAIN (via $IP)"
        echo "  https://n8n.$DOMAIN (via $IP)"
        echo "  https://traefik.$DOMAIN (via $IP)"
        echo "  https://grafana.$DOMAIN (via $IP)"
        echo "  https://pihole.$DOMAIN (via $IP)"
    done
else
    print_warning "IPs externas no asignadas aún"
fi

print_header "CONFIGURACIÓN DE DNS REQUERIDA"

echo "Para acceder a los servicios externamente, configura estos registros DNS:"
echo ""
echo "Tipo A records en tu proveedor DNS:"
echo "  terrerov.com      → 192.168.0.2 (o IP pública)"
echo "  *.terrerov.com    → 192.168.0.2 (wildcard)"
echo ""
echo "O para testing local, agrega a /etc/hosts:"
echo "  192.168.0.2  terrerov.com"
echo "  192.168.0.2  n8n.terrerov.com"
echo "  192.168.0.2  traefik.terrerov.com"
echo "  192.168.0.2  grafana.terrerov.com"
echo "  192.168.0.2  pihole.terrerov.com"

print_header "SERVICIOS DISPONIBLES"

echo "Una vez configurado DNS, los servicios estarán disponibles en:"
echo ""
echo "  🏠 Dashboard Principal:  https://terrerov.com"
echo "  🤖 n8n Automation:      https://n8n.terrerov.com"
echo "  🌐 Traefik Dashboard:   https://traefik.terrerov.com"
echo "  📊 Grafana Monitoring:  https://grafana.terrerov.com"
echo "  🛡️ Pi-hole Admin:       https://pihole.terrerov.com"
echo ""

print_success "¡Configuración de load balancer completada!"
print_info "Los certificados SSL se generarán automáticamente al acceder a los dominios"

# Comandos útiles
print_header "COMANDOS ÚTILES"

echo "Verificar estado del load balancer:"
echo "  kubectl get svc -n chernarus-system traefik-loadbalancer"
echo ""
echo "Ver logs de Traefik:"
echo "  kubectl logs -n chernarus-system -l app=traefik -f"
echo ""
echo "Verificar certificados:"
echo "  kubectl get certificates -A"
echo ""
echo "Probar conectividad:"
echo "  curl -I https://traefik.terrerov.com"
