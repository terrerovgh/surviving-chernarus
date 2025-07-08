#!/bin/bash

echo "🔍 Diagnóstico de Configuración de Traefik - Chernarus"
echo "=================================================="
echo

echo "📊 Estado de Contenedores:"
docker-compose ps reverse_proxy
echo

echo "🔧 Variables de Entorno de Cloudflare:"
echo "CLOUDFLARE_EMAIL: $(docker exec traefik_proxy printenv CLOUDFLARE_EMAIL 2>/dev/null || echo 'No configurado')"
echo "CLOUDFLARE_DNS_API_TOKEN: $(docker exec traefik_proxy printenv CLOUDFLARE_DNS_API_TOKEN 2>/dev/null | head -c 10)..."
echo

echo "🌐 Test de Conectividad a Cloudflare:"
docker exec traefik_proxy nslookup api.cloudflare.com 2>/dev/null && echo "✅ DNS funciona" || echo "❌ Problema con DNS"
echo

echo "📋 Últimos logs de error de Traefik:"
docker exec traefik_proxy tail -5 /var/log/traefik/traefik.log | grep -i error || echo "Sin errores recientes"
echo

echo "🔍 Estado de routers configurados:"
docker exec traefik_proxy curl -s http://localhost:8080/api/http/routers 2>/dev/null | jq -r '.[] | select(.status != "disabled") | "\(.name): \(.status)"' 2>/dev/null || echo "No se puede acceder a la API"
echo

echo "⚙️ Configuración de certificados ACME:"
ls -la /tmp/chernarus/data/traefik/ 2>/dev/null || echo "Directorio ACME no encontrado"

echo
echo "🎯 Para solucionar:"
echo "1. Verificar que CLOUDFLARE_DNS_API_TOKEN sea válido"
echo "2. Comprobar que el dominio terrerov.com esté en Cloudflare"
echo "3. Verificar permisos del token para Zone:Read y DNS:Edit"
