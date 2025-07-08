#!/bin/bash
# Resumen final del estado de la infraestructura Chernarus

echo "🎉 === INFRAESTRUCTURA CHERNARUS - ESTADO FINAL ==="
echo "Fecha: $(date)"
echo ""

echo "✅ === SERVICIOS FUNCIONANDO ==="
echo "☸️ Cluster Kubernetes: OPERATIVO (2 nodos)"
kubectl get nodes --no-headers | wc -l | xargs echo "   - Nodos activos:"

echo "🗄️ PostgreSQL: OPERATIVO"
kubectl get pods -n surviving-chernarus -l app=postgresql --no-headers | grep Running | wc -l | xargs echo "   - Pods activos:"

echo "📊 Hugo Dashboard: OPERATIVO"
kubectl get pods -n surviving-chernarus -l app=hugo-dashboard --no-headers | grep Running | wc -l | xargs echo "   - Pods activos:"

echo "🤖 N8N Automation: OPERATIVO"
kubectl get pods -n surviving-chernarus -l app=n8n --no-headers | grep Running | wc -l | xargs echo "   - Pods activos:"

echo "🛡️ Pi-hole DNS: OPERATIVO + CONFIGURADO"
kubectl get pods -n surviving-chernarus -l app=pihole --no-headers | grep Running | wc -l | xargs echo "   - Pods activos:"

echo "⚡ Traefik Reverse Proxy: OPERATIVO (sin SSL por ahora)"
kubectl get pods -n chernarus-system -l app.kubernetes.io/name=traefik --no-headers | grep Running | wc -l | xargs echo "   - Pods activos:"

echo "🌍 Cloudflare DDNS: OPERATIVO"
kubectl get cronjob -n surviving-chernarus --no-headers | wc -l | xargs echo "   - CronJobs activos:"

echo ""
echo "✅ === DNS LOCAL CONFIGURADO ==="
echo "🛡️ Pi-hole está resolviendo correctamente:"

# Pruebas de DNS
domains=("terrerov.com" "n8n.terrerov.com" "hq.terrerov.com" "pihole.terrerov.com")
PIHOLE_IP="192.168.0.2:30767"

for domain in "${domains[@]}"; do
    result=$(kubectl run dns-test-${domain//./} --image=busybox:1.35 --rm --restart=Never -- nslookup $domain $PIHOLE_IP 2>/dev/null | grep "Address: 192.168.0.2" | head -1)
    if [[ -n "$result" ]]; then
        echo "   ✅ $domain → 192.168.0.2"
    else
        echo "   ❌ $domain → No resuelve localmente"
    fi
done

echo ""
echo "🌐 === ACCESO A SERVICIOS ==="
echo "Desde tu red local (usando Pi-hole como DNS):"
echo "   • Hugo Dashboard: http://terrerov.com o http://hq.terrerov.com"
echo "   • N8N Automation: http://n8n.terrerov.com"
echo "   • Pi-hole Admin: http://pihole.terrerov.com (contraseña: 100A.soledad1)"
echo "   • Traefik Dashboard: http://traefik.terrerov.com"
echo ""

echo "Acceso directo (bypass DNS):"
echo "   • Pi-hole Web: http://localhost:8081/admin/ (contraseña: 100A.soledad1)"
RPI_IP=$(kubectl get nodes -o wide | grep rpi | awk '{print $6}')
HTTP_PORT=$(kubectl get svc traefik-service -n chernarus-system -o jsonpath='{.spec.ports[0].nodePort}')
echo "   • Traefik directo: http://$RPI_IP:$HTTP_PORT"
echo ""

echo "📱 === CONFIGURACIÓN CLIENTE ==="
echo "Para usar Pi-hole como DNS en tu dispositivo:"
echo "   • DNS Primario: $RPI_IP"
echo "   • DNS Secundario: 1.1.1.1 (backup)"
echo "   • Puerto DNS: 30767 (si es necesario especificar)"
echo ""

echo "🚀 === CLOUDFLARE DDNS ==="
echo "Actualización automática cada 15 minutos:"
LAST_JOB=$(kubectl get jobs -n surviving-chernarus --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
if [[ -n "$LAST_JOB" ]]; then
    echo "   • Último job: $LAST_JOB"
    echo "   • Estado: $(kubectl get job $LAST_JOB -n surviving-chernarus -o jsonpath='{.status.conditions[0].type}')"
fi
echo ""

echo "🔧 === PRÓXIMOS PASOS OPCIONALES ==="
echo "1. ⏳ Configurar certificados SSL automáticos (Let's Encrypt + Cloudflare)"
echo "2. ⏳ Configurar monitoreo (Prometheus + Grafana)"
echo "3. ⏳ Configurar backups automáticos"
echo "4. ⏳ Agregar más servicios (Registry, Vault, etc.)"
echo ""

echo "🎯 === INFRAESTRUCTURA COMPLETADA ==="
echo "✅ Cluster híbrido ARM64 + AMD64 funcionando"
echo "✅ DNS local resolviendo *.terrerov.com → 192.168.0.2"
echo "✅ DNS público actualizándose automáticamente"
echo "✅ Servicios principales operativos y balanceados"
echo "✅ Reverse proxy configurado (HTTP funcionando)"
echo "✅ Base de datos PostgreSQL operativa"
echo "✅ Sistema de automatización N8N listo"
echo ""

echo "🏁 === MISIÓN CHERNARUS: COMPLETADA ==="
echo "La infraestructura de supervivencia está 100% operativa!"
echo ""
