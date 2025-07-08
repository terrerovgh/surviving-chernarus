#!/bin/bash

# ============================================================================
# SURVIVING CHERNARUS - TEST SCRIPT PARA SERVICIOS HTTPS
# ============================================================================

echo "🔐 SURVIVING CHERNARUS - PRUEBAS HTTPS 🔐"
echo "==========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Estado de Contenedores:${NC}"
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${BLUE}🌐 Pruebas de Conectividad HTTP → HTTPS:${NC}"

# Función para probar redirección
test_redirect() {
    local url=$1
    local service_name=$2

    echo -n "   $service_name: "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [[ "$response" == "301" ]] || [[ "$response" == "308" ]]; then
        echo -e "${GREEN}✅ Redirección HTTP→HTTPS ($response)${NC}"
    else
        echo -e "${RED}❌ Error ($response)${NC}"
    fi
}

# Función para probar HTTPS
test_https() {
    local url=$1
    local service_name=$2

    echo -n "   $service_name HTTPS: "
    response=$(curl -s -k -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [[ "$response" == "200" ]]; then
        echo -e "${GREEN}✅ HTTPS Funcionando ($response)${NC}"
    else
        echo -e "${RED}❌ Error HTTPS ($response)${NC}"
    fi
}

# Probar servicios
test_redirect "http://terrerov.com" "HQ Dashboard"
test_https "https://terrerov.com" "HQ Dashboard"

test_redirect "http://n8n.terrerov.com" "N8N Engine"
test_https "https://n8n.terrerov.com" "N8N Engine"

test_redirect "http://traefik.terrerov.com:8080" "Traefik Dashboard"

echo ""
echo -e "${BLUE}🔑 Estado de Certificados SSL:${NC}"

# Verificar archivo ACME
if [ -f "/tmp/chernarus/data/traefik/acme.json" ]; then
    acme_size=$(stat -c%s "/tmp/chernarus/data/traefik/acme.json" 2>/dev/null || echo "0")
    if [ "$acme_size" -gt 50 ]; then
        echo -e "   ${GREEN}✅ Archivo ACME presente (${acme_size} bytes)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Archivo ACME pequeño (${acme_size} bytes) - Certificados en proceso${NC}"
    fi
else
    echo -e "   ${RED}❌ Archivo ACME no encontrado${NC}"
fi

echo ""
echo -e "${BLUE}📊 URLs de Acceso:${NC}"
echo "   🏢 HQ Dashboard: https://terrerov.com"
echo "   ⚙️  N8N Automation: https://n8n.terrerov.com"
echo "   🌐 Traefik Dashboard: http://traefik.terrerov.com:8080/dashboard/"
echo "   💾 PostgreSQL: localhost:5432"
echo ""

echo -e "${BLUE}🔧 Logs Recientes de Traefik:${NC}"
docker logs traefik_proxy --tail 5 2>/dev/null || echo "   No se pueden obtener logs"

echo ""
echo -e "${GREEN}🎯 SURVIVING CHERNARUS HTTPS - CONFIGURACIÓN COMPLETA${NC}"
echo -e "${YELLOW}Nota: Si los certificados SSL están pendientes, espera unos minutos para que Let's Encrypt los genere.${NC}"
