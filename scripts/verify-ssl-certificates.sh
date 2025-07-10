#!/bin/bash
# Script para verificar y configurar certificados SSL de Traefik
# Este script verifica la configuración SSL, dominios y certificados

set -e

echo "🔒 === VERIFICACIÓN DE CERTIFICADOS SSL TRAEFIK ==="
echo "$(date)"
echo ""

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar conectividad
check_connectivity() {
    local host=$1
    local port=${2:-443}
    echo "🔍 Verificando conectividad a $host:$port..."

    if command_exists nc; then
        if nc -z -v -w5 "$host" "$port" 2>/dev/null; then
            echo "✅ $host:$port - CONECTADO"
            return 0
        else
            echo "❌ $host:$port - NO ACCESIBLE"
            return 1
        fi
    else
        echo "⚠️  netcat no disponible, saltando verificación de conectividad"
        return 0
    fi
}

# Función para verificar certificado SSL
check_ssl_cert() {
    local domain=$1
    echo "🔐 Verificando certificado SSL para $domain..."

    if command_exists openssl; then
        if openssl s_client -connect "$domain:443" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null; then
            echo "✅ Certificado SSL válido para $domain"
            return 0
        else
            echo "❌ No se pudo verificar certificado SSL para $domain"
            return 1
        fi
    else
        echo "⚠️  openssl no disponible, saltando verificación SSL"
        return 0
    fi
}

# Verificar si Traefik está corriendo
echo "📊 ESTADO DE TRAEFIK"
echo "═══════════════════════════════════════════════════════════════"

if command_exists docker; then
    if docker ps | grep -q traefik; then
        echo "✅ Traefik container está corriendo"
        TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}')
        echo "   Container ID: $TRAEFIK_CONTAINER"
    else
        echo "❌ Traefik container no está corriendo"
        echo "💡 Ejecutar: docker-compose up -d traefik"
        exit 1
    fi
elif command_exists kubectl; then
    if kubectl get pods -n chernarus-system | grep -q traefik; then
        echo "✅ Traefik pod está corriendo en Kubernetes"
        kubectl get pods -n chernarus-system | grep traefik
    else
        echo "❌ Traefik pod no está corriendo en Kubernetes"
        echo "💡 Verificar: kubectl get pods -n chernarus-system"
    fi
else
    echo "⚠️  Ni Docker ni kubectl disponibles"
fi

echo ""

# Verificar configuración de variables de entorno
echo "⚙️  CONFIGURACIÓN DE VARIABLES DE ENTORNO"
echo "═══════════════════════════════════════════════════════════════"

if [[ -f .env ]]; then
    echo "✅ Archivo .env encontrado"

    # Verificar variables críticas para SSL
    REQUIRED_VARS=(
        "CLOUDFLARE_EMAIL"
        "CLOUDFLARE_API_TOKEN"
        "TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL"
        "YOUR_DOMAIN_NAME"
    )

    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var=" .env; then
            value=$(grep "^$var=" .env | cut -d'=' -f2)
            if [[ -n "$value" && "$value" != "example.com" && "$value" != "your_token_here" ]]; then
                echo "✅ $var configurado"
            else
                echo "⚠️  $var necesita configuración real"
            fi
        else
            echo "❌ $var no encontrado en .env"
        fi
    done
else
    echo "❌ Archivo .env no encontrado"
    echo "💡 Copiar: cp .env.example .env"
fi

echo ""

# Verificar acceso al dashboard de Traefik
echo "🌐 VERIFICACIÓN DE DASHBOARD TRAEFIK"
echo "═══════════════════════════════════════════════════════════════"

TRAEFIK_URLS=(
    "http://rpi.terrerov.com:8080"
    "http://lenlab.terrerov.com:8080"
    "http://traefik.terrerov.com:8080"
)

for url in "${TRAEFIK_URLS[@]}"; do
    echo "🔍 Probando acceso a: $url"

    if command_exists curl; then
        if curl -s --connect-timeout 5 "$url/api/overview" >/dev/null 2>&1; then
            echo "✅ Dashboard accesible en: $url"

            # Obtener información de routers
            routers=$(curl -s "$url/api/http/routers" | jq length 2>/dev/null || echo "unknown")
            services=$(curl -s "$url/api/http/services" | jq length 2>/dev/null || echo "unknown")
            echo "   📊 Routers configurados: $routers"
            echo "   🔧 Servicios activos: $services"
            break
        else
            echo "❌ No accesible: $url"
        fi
    else
        echo "⚠️  curl no disponible para verificar dashboard"
    fi
done

echo ""

# Verificar dominios configurados
echo "🌍 VERIFICACIÓN DE DOMINIOS"
echo "═══════════════════════════════════════════════════════════════"

DOMAINS_TO_CHECK=(
    "terrerov.com"
    "rpi.terrerov.com"
    "lenlab.terrerov.com"
    "n8n.terrerov.com"
    "traefik.terrerov.com"
    "pihole.terrerov.com"
)

for domain in "${DOMAINS_TO_CHECK[@]}"; do
    echo "🔍 Verificando: $domain"

    # Verificar resolución DNS
    if command_exists dig; then
        ip=$(dig +short "$domain" | head -1)
        if [[ -n "$ip" ]]; then
            echo "   📍 DNS: $domain → $ip"
        else
            echo "   ❌ DNS: No resuelve"
        fi
    elif command_exists nslookup; then
        if nslookup "$domain" >/dev/null 2>&1; then
            echo "   ✅ DNS: Resuelve"
        else
            echo "   ❌ DNS: No resuelve"
        fi
    fi

    # Verificar conectividad HTTP
    if command_exists curl; then
        if curl -s --connect-timeout 5 -I "http://$domain" >/dev/null 2>&1; then
            echo "   ✅ HTTP: Accesible"
        else
            echo "   ❌ HTTP: No accesible"
        fi
    fi
done

echo ""

# Verificar archivos de certificados
echo "📁 VERIFICACIÓN DE ARCHIVOS DE CERTIFICADOS"
echo "═══════════════════════════════════════════════════════════════"

CERT_PATHS=(
    "./data/traefik/acme/acme.json"
    "/var/lib/docker/volumes/surviving-chernarus_traefik-ssl/_data/acme.json"
    "./volumes/traefik/acme.json"
)

for cert_path in "${CERT_PATHS[@]}"; do
    if [[ -f "$cert_path" ]]; then
        echo "✅ Archivo de certificados encontrado: $cert_path"

        # Verificar permisos
        perms=$(stat -c "%a" "$cert_path" 2>/dev/null || echo "unknown")
        if [[ "$perms" == "600" ]]; then
            echo "   ✅ Permisos correctos: $perms"
        else
            echo "   ⚠️  Permisos: $perms (recomendado: 600)"
            echo "   💡 Corregir: chmod 600 $cert_path"
        fi

        # Verificar contenido (si es JSON válido)
        if command_exists jq; then
            if jq empty "$cert_path" 2>/dev/null; then
                certs_count=$(jq '.letsencrypt.Certificates | length' "$cert_path" 2>/dev/null || echo "0")
                echo "   📊 Certificados almacenados: $certs_count"
            else
                echo "   ⚠️  Archivo no es JSON válido"
            fi
        fi
        break
    else
        echo "❌ No encontrado: $cert_path"
    fi
done

echo ""

# Generar comando para forzar renovación de certificados
echo "🔄 COMANDOS DE GESTIÓN DE CERTIFICADOS"
echo "═══════════════════════════════════════════════════════════════"

echo "💡 Para forzar renovación de certificados:"
echo "   # Detener Traefik"
echo "   docker-compose stop traefik"
echo ""
echo "   # Eliminar certificados existentes"
echo "   rm -f ./data/traefik/acme/acme.json"
echo ""
echo "   # Reiniciar Traefik"
echo "   docker-compose up -d traefik"
echo ""
echo "   # Verificar logs"
echo "   docker-compose logs -f traefik"

echo ""

# Verificar configuración de Cloudflare
echo "☁️  VERIFICACIÓN DE CONFIGURACIÓN CLOUDFLARE"
echo "═══════════════════════════════════════════════════════════════"

if [[ -f .env ]]; then
    if grep -q "^CLOUDFLARE_EMAIL=" .env && grep -q "^CLOUDFLARE_API_TOKEN=" .env; then
        EMAIL=$(grep "^CLOUDFLARE_EMAIL=" .env | cut -d'=' -f2)
        TOKEN=$(grep "^CLOUDFLARE_API_TOKEN=" .env | cut -d'=' -f2)

        if [[ -n "$EMAIL" && "$EMAIL" != "your_email@example.com" ]]; then
            echo "✅ Email de Cloudflare configurado: $EMAIL"
        else
            echo "⚠️  Email de Cloudflare necesita configuración"
        fi

        if [[ -n "$TOKEN" && "$TOKEN" != "your_token_here" ]]; then
            echo "✅ Token de Cloudflare configurado: ${TOKEN:0:8}..."

            # Verificar token si curl está disponible
            if command_exists curl; then
                echo "🔍 Verificando token de Cloudflare..."
                response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json")

                if command_exists jq; then
                    if echo "$response" | jq -e '.success' >/dev/null 2>&1; then
                        echo "✅ Token de Cloudflare válido"
                    else
                        echo "❌ Token de Cloudflare inválido"
                        echo "   $response"
                    fi
                fi
            fi
        else
            echo "⚠️  Token de Cloudflare necesita configuración"
        fi
    else
        echo "❌ Credenciales de Cloudflare no configuradas"
    fi
fi

echo ""

# Resumen y próximos pasos
echo "📋 RESUMEN Y PRÓXIMOS PASOS"
echo "═══════════════════════════════════════════════════════════════"
echo "1. ✅ Verificar que Traefik esté corriendo"
echo "2. ⚙️  Configurar variables de entorno en .env"
echo "3. ☁️  Configurar credenciales de Cloudflare"
echo "4. 🌍 Verificar que los dominios resuelvan a tus IPs"
echo "5. 🔒 Esperar generación automática de certificados SSL"
echo "6. 🌐 Acceder a servicios vía HTTPS"

echo ""
echo "📊 Para monitorear en tiempo real:"
echo "   docker-compose logs -f traefik | grep -i cert"
echo ""
echo "✅ Verificación completada $(date)"
