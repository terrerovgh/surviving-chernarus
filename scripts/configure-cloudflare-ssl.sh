#!/bin/bash

# Script para configurar las credenciales de Cloudflare para SSL automático
# Ejecutar después de obtener las credenciales reales de Cloudflare

echo "🔐 Configurando credenciales de Cloudflare para SSL automático..."

# Verificar si las variables están configuradas
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_EMAIL" ]; then
    echo "❌ Error: Variables de entorno no configuradas"
    echo ""
    echo "Configura las siguientes variables antes de ejecutar este script:"
    echo "export CLOUDFLARE_EMAIL='terrerov@gmail.com'"
    echo "export CLOUDFLARE_API_TOKEN='LMO4jer71Ktw02ExegtaE1UAcNvfpw9fKzU9Ime2'"
    echo ""
    echo "Para obtener las credenciales:"
    echo "1. Ve a https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Crea un token con permisos de 'Zone:DNS:Edit' para terrerov.com"
    echo "3. Copia el token y configúralo como CLOUDFLARE_API_TOKEN"
    exit 1
fi

echo "📧 Email: $CLOUDFLARE_EMAIL"
echo "🔑 Token: ${CLOUDFLARE_API_TOKEN:0:10}..."

# Codificar las credenciales en base64
CLOUDFLARE_EMAIL_B64=$(echo -n "$CLOUDFLARE_EMAIL" | base64 -w 0)
CLOUDFLARE_TOKEN_B64=$(echo -n "$CLOUDFLARE_API_TOKEN" | base64 -w 0)

echo "🔄 Actualizando secretos de Kubernetes..."

# Actualizar el secret en el namespace chernarus-system
kubectl patch secret chernarus-secrets -n chernarus-system --patch="{
  \"data\": {
    \"CLOUDFLARE_EMAIL\": \"$CLOUDFLARE_EMAIL_B64\",
    \"CF_DNS_API_TOKEN\": \"$CLOUDFLARE_TOKEN_B64\"
  }
}"

# Reiniciar Traefik para aplicar las nuevas credenciales
echo "🔄 Reiniciando Traefik..."
kubectl rollout restart deployment/traefik -n chernarus-system

# Esperar a que Traefik esté listo
echo "⏳ Esperando a que Traefik esté listo..."
kubectl rollout status deployment/traefik -n chernarus-system

echo "✅ Credenciales de Cloudflare configuradas correctamente!"
echo ""
echo "🚀 Próximos pasos:"
echo "1. Aplicar los Ingress rules: kubectl apply -f kubernetes/apps/surviving-chernarus/ingress.yaml"
echo "2. Verificar certificados: kubectl get certificates -n surviving-chernarus"
echo "3. Verificar logs de Traefik: kubectl logs -n chernarus-system deployment/traefik"
echo ""
echo "🌐 Acceso HTTPS estará disponible en:"
echo "- https://terrerov.com"
echo "- https://hq.terrerov.com"
echo "- https://n8n.terrerov.com"
echo "- https://traefik.terrerov.com"
