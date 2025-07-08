#!/bin/bash

# Script para configurar DNS local y Cloudflare para Surviving Chernarus
# Este script configura Pi-hole como DNS local y actualiza Cloudflare para DNS público

set -e

echo "🏗️ CONFIGURANDO DNS PARA SURVIVING CHERNARUS"
echo "============================================="

# Variables de configuración
CLUSTER_IPS=("192.168.0.2" "192.168.0.3")
SUBDOMINIOS=("terrerov.com" "www" "hq" "n8n" "traefik" "pihole" "api" "admin" "dashboard" "monitoring")

echo "📡 IPs del cluster: ${CLUSTER_IPS[*]}"
echo "🔗 Subdominios a configurar: ${SUBDOMINIOS[*]}"

# 1. Verificar estado del cluster
echo ""
echo "1️⃣ Verificando estado del cluster..."
kubectl get nodes -o wide
kubectl get pods -n surviving-chernarus

# 2. Actualizar configuración de Pi-hole con datos correctos
echo ""
echo "2️⃣ Configurando Pi-hole para DNS local..."

# Obtener IP del servicio de Traefik (LoadBalancer) o usar NodePort
TRAEFIK_IP=$(kubectl get svc traefik-service -n chernarus-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "192.168.0.2")

# Actualizar ConfigMap con IP correcta
kubectl patch configmap pihole-custom-dns -n surviving-chernarus --type='merge' -p='{
  "data": {
    "custom.list": "# DNS personalizado para dominios de Chernarus\n192.168.0.2 terrerov.com\n192.168.0.2 www.terrerov.com\n192.168.0.2 hq.terrerov.com\n192.168.0.2 n8n.terrerov.com\n192.168.0.2 traefik.terrerov.com\n192.168.0.2 pihole.terrerov.com\n192.168.0.2 api.terrerov.com\n192.168.0.2 admin.terrerov.com\n192.168.0.2 dashboard.terrerov.com\n192.168.0.2 monitoring.terrerov.com"
  }
}'

# 3. Reiniciar Pi-hole
echo ""
echo "3️⃣ Reiniciando Pi-hole..."
kubectl rollout restart deployment/pihole-deployment -n surviving-chernarus
kubectl rollout status deployment/pihole-deployment -n surviving-chernarus

# 4. Probar resolución DNS local
echo ""
echo "4️⃣ Probando resolución DNS local..."
PIHOLE_NODEPORT=$(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.ports[?(@.name=="dns-tcp")].nodePort}')
echo "Puerto NodePort de Pi-hole: $PIHOLE_NODEPORT"

sleep 5
echo "Probando resolución de terrerov.com..."
kubectl run dns-test-local --image=busybox:1.35 --rm -it --restart=Never -- nslookup terrerov.com 192.168.0.2:$PIHOLE_NODEPORT

# 5. Ejecutar actualización de Cloudflare
echo ""
echo "5️⃣ Actualizando registros DNS en Cloudflare..."
kubectl create job --from=cronjob/cloudflare-ddns-updater cloudflare-manual-update -n surviving-chernarus
sleep 10
kubectl logs -l job-name=cloudflare-manual-update -n surviving-chernarus

# 6. Mostrar resumen
echo ""
echo "🎉 CONFIGURACIÓN DNS COMPLETADA"
echo "==============================="
echo "DNS Local (Pi-hole):"
echo "  - Servicio: pihole-service.surviving-chernarus.svc.cluster.local"
echo "  - IP Cluster: $(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.clusterIP}')"
echo "  - NodePort: 192.168.0.2:$PIHOLE_NODEPORT (TCP/UDP)"
echo ""
echo "DNS Público (Cloudflare):"
echo "  - Zona: terrerov.com"
echo "  - Subdominios actualizados con IP pública dinámica"
echo "  - Actualización automática cada 15 minutos"
echo ""
echo "Para usar Pi-hole como DNS:"
echo "  - En la red local: usar 192.168.0.2:$PIHOLE_NODEPORT como DNS"
echo "  - Los dominios *.terrerov.com resolverán a 192.168.0.2 (cluster)"
echo ""
echo "Para acceso externo:"
echo "  - Los subdominios resolverán a la IP pública (via Cloudflare)"
echo "  - SSL automático habilitado via Let's Encrypt + Cloudflare"
