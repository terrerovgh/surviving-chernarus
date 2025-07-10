#!/bin/bash
# Resumen completo del estado de la infraestructura Chernarus

echo "🚀 === ESTADO DE LA INFRAESTRUCTURA SURVIVING CHERNARUS ==="
echo "$(date)"
echo ""

echo "☸️ === CLUSTER KUBERNETES ==="
kubectl get nodes -o wide
echo ""

echo "📦 === PODS EN SURVIVING-CHERNARUS ==="
kubectl get pods -n surviving-chernarus -o wide
echo ""

echo "🌐 === SERVICIOS ==="
kubectl get svc -n surviving-chernarus
echo ""

echo "🔀 === INGRESS ==="
kubectl get ingress -n surviving-chernarus
echo ""

echo "⚡ === TRAEFIK (Reverse Proxy) ==="
kubectl get pods -n chernarus-system -l app.kubernetes.io/name=traefik
kubectl get svc -n chernarus-system
echo ""

echo "🛡️ === PI-HOLE DNS ==="
PIHOLE_IP=$(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.clusterIP}')
PIHOLE_NODEPORT=$(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.ports[0].nodePort}')
echo "ClusterIP: $PIHOLE_IP"
echo "NodePort: rpi.terrerov.com:$PIHOLE_NODEPORT"
echo "Web Interface: http://rpi.terrerov.com:8081/admin/ (password: 100A.soledad1)"
echo ""

echo "🤖 === CLOUDFLARE DDNS ==="
kubectl get cronjob -n surviving-chernarus
kubectl get jobs -n surviving-chernarus --sort-by=.metadata.creationTimestamp | tail -3
echo ""

echo "🌍 === PRUEBAS DE CONECTIVIDAD ==="
echo "Probando resolución DNS..."
echo "1. DNS externo (Google):"
kubectl run dns-test-external --image=busybox:1.35 --rm -it --restart=Never -- nslookup google.com 8.8.8.8 2>/dev/null | grep "Address:" | tail -1 || echo "❌ Fallo"

echo ""
echo "2. Pi-hole (dominio externo):"
kubectl run dns-test-pihole-ext --image=busybox:1.35 --rm -it --restart=Never -- nslookup google.com $PIHOLE_IP 2>/dev/null | grep "Address:" | tail -1 || echo "❌ Fallo"

echo ""
echo "3. Pi-hole (dominio local via NodePort):"
kubectl run dns-test-pihole-local --image=busybox:1.35 --rm -it --restart=Never -- nslookup n8n.terrerov.com 192.168.0.2:$PIHOLE_NODEPORT 2>/dev/null | grep "Address:" | tail -1 || echo "❌ Fallo"

echo ""
echo "📊 === RECURSOS ==="
kubectl top nodes 2>/dev/null || echo "Metrics server no disponible"
echo ""

echo "🔧 === CONFIGURACIÓN ACTUAL ==="
echo "Dominio principal: terrerov.com"
echo "Nodos del cluster:"
echo "  - rpi (master): 192.168.0.2 (ARM64)"
echo "  - lenlab (worker): 192.168.0.3 (AMD64)"
echo ""

echo "🌐 === ACCESO A SERVICIOS ==="
echo "• Traefik Dashboard: https://traefik.terrerov.com (via Ingress)"
echo "• Hugo Dashboard: https://terrerov.com, https://hq.terrerov.com"
echo "• N8N Automation: https://n8n.terrerov.com"
echo "• Pi-hole Admin: https://pihole.terrerov.com o http://rpi.terrerov.com:8081/admin/"
echo ""

echo "🔑 === CREDENCIALES ==="
echo "• Pi-hole Admin: 100A.soledad1"
echo "• Cloudflare DNS: Configurado con API Token"
echo ""

echo "📝 === LOGS RECIENTES ==="
echo "Últimos logs de Pi-hole:"
kubectl logs -n surviving-chernarus -l app=pihole --tail=3 2>/dev/null || echo "No hay logs disponibles"
echo ""

echo "🎯 === PRÓXIMOS PASOS ==="
echo "1. ✅ Cluster Kubernetes funcionando (2 nodos)"
echo "2. ✅ Traefik reverse proxy con SSL automático"
echo "3. ✅ Servicios principales desplegados (PostgreSQL, Hugo, N8N)"
echo "4. ✅ Pi-hole DNS server configurado"
echo "5. ✅ Cloudflare DDNS automático cada 15 minutos"
echo "6. 🔄 Verificar resolución DNS local (en progreso)"
echo "7. ⏳ Probar acceso externo via dominios públicos"
echo ""

echo "🚀 === INFRAESTRUCTURA CHERNARUS LISTA ==="
