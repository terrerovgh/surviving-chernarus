#!/bin/bash

echo "🧪 PROBANDO CONFIGURACIÓN DNS LOCAL Y CLOUDFLARE"
echo "================================================"
echo ""

# Obtener IPs del cluster
PIHOLE_NODE_PORT=$(kubectl get svc -n surviving-chernarus pihole-service -o jsonpath='{.spec.ports[?(@.name=="dns-udp")].nodePort}')
TRAEFIK_HTTP_PORT=$(kubectl get svc -n chernarus-system traefik-service -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')
TRAEFIK_HTTPS_PORT=$(kubectl get svc -n chernarus-system traefik-service -o jsonpath='{.spec.ports[?(@.name=="websecure")].nodePort}')

echo "📊 INFORMACIÓN DEL CLUSTER:"
echo "- Pi-hole DNS Puerto: $PIHOLE_NODE_PORT"
echo "- Traefik HTTP Puerto: $TRAEFIK_HTTP_PORT"
echo "- Traefik HTTPS Puerto: $TRAEFIK_HTTPS_PORT"
echo ""

echo "🌐 ACCESO A SERVICIOS EN LA RED LOCAL:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 DNS Server (Pi-hole):"
echo "   - Puerto DNS: rpi.terrerov.com:$PIHOLE_NODE_PORT (UDP/TCP)"
echo "   - Puerto DNS: lenlab.terrerov.com:$PIHOLE_NODE_PORT (UDP/TCP)"
echo "   - Web Admin:  http://rpi.terrerov.com:$(kubectl get svc -n surviving-chernarus pihole-service -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')"
echo ""
echo "🌐 Servicios Web:"
echo "   - Hugo Dashboard: http://rpi.terrerov.com:$TRAEFIK_HTTP_PORT"
echo "   - N8N:           http://rpi.terrerov.com:$TRAEFIK_HTTP_PORT (Host: n8n.terrerov.com)"
echo "   - Traefik:       http://rpi.terrerov.com:8080"
echo ""

echo "🔧 CONFIGURAR DNS EN TU ROUTER/DISPOSITIVOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DNS Primario:   rpi.terrerov.com (192.168.0.2)"
echo "DNS Secundario: lenlab.terrerov.com (192.168.0.3)"
echo "Puerto DNS:     $PIHOLE_NODE_PORT (si tu router lo soporta, sino usar 53 por defecto)"
echo ""

echo "🌍 DOMINIOS CONFIGURADOS PARA RESOLUCIÓN LOCAL:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ terrerov.com      -> rpi.terrerov.com"
echo "✅ www.terrerov.com  -> rpi.terrerov.com"
echo "✅ hq.terrerov.com   -> rpi.terrerov.com"
echo "✅ n8n.terrerov.com  -> rpi.terrerov.com"
echo "✅ traefik.terrerov.com -> rpi.terrerov.com"
echo "✅ pihole.terrerov.com  -> rpi.terrerov.com"
echo "✅ *.terrerov.com    -> rpi.terrerov.com (wildcard)"
echo ""

echo "☁️ CLOUDFLARE DYNAMIC DNS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Para activar actualización automática:"
echo "   1. Configurar credenciales Cloudflare:"
echo "      export CLOUDFLARE_EMAIL='contacto@terrerov.com'"
echo "      export CLOUDFLARE_API_TOKEN='tu_token_aqui'"
echo ""
echo "   2. Ejecutar script manual:"
echo "      ./scripts/update-cloudflare-dns.sh"
echo ""
echo "   3. O desplegar CronJob automático:"
echo "      kubectl apply -f kubernetes/apps/surviving-chernarus/cloudflare-ddns.yaml"
echo ""

echo "🎯 PRÓXIMOS PASOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Configurar DNS en tu router para usar rpi.terrerov.com como DNS primario"
echo "2. Configurar credenciales reales de Cloudflare"
echo "3. Aplicar Ingress rules para SSL automático"
echo "4. Probar acceso a https://terrerov.com desde cualquier dispositivo"

echo ""
echo "🔍 ESTADO ACTUAL DEL CLUSTER:"
kubectl get pods -n surviving-chernarus -o wide
