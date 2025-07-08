#!/bin/bash

# =============================================================================
# Script para configurar acceso de GitHub Actions al cluster Kubernetes
# Autor: AI Assistant para terrerov
# Fecha: $(date)
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log "🔧 Configurando acceso de GitHub Actions al cluster Kubernetes..."

# 1. Crear ServiceAccount para GitHub Actions
log "👤 Creando ServiceAccount para GitHub Actions..."

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-actions-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: github-actions
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  name: github-actions-secret
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: github-actions
type: kubernetes.io/service-account-token
EOF

# 2. Esperar a que se genere el token
log "⏳ Esperando a que se genere el token..."
sleep 5

# 3. Obtener información del cluster
CLUSTER_NAME=$(kubectl config current-context)
CLUSTER_SERVER=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# 4. Obtener el token del ServiceAccount
TOKEN=$(kubectl get secret github-actions-secret -n kube-system -o jsonpath='{.data.token}' | base64 -d)

# 5. Crear kubeconfig para GitHub Actions
log "📄 Generando kubeconfig para GitHub Actions..."

KUBECONFIG_CONTENT=$(cat <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: github-actions
  name: github-actions@${CLUSTER_NAME}
current-context: github-actions@${CLUSTER_NAME}
users:
- name: github-actions
  user:
    token: ${TOKEN}
EOF
)

# 6. Codificar en base64 para GitHub Secrets
KUBECONFIG_BASE64=$(echo "$KUBECONFIG_CONTENT" | base64 -w 0)

# 7. Crear archivo temporal con el kubeconfig
TEMP_DIR=$(mktemp -d)
KUBECONFIG_FILE="${TEMP_DIR}/kubeconfig-github-actions.yaml"
echo "$KUBECONFIG_CONTENT" > "$KUBECONFIG_FILE"

# 8. Mostrar instrucciones
echo ""
success "✅ Configuración completada exitosamente!"
echo ""
log "📋 Instrucciones para configurar GitHub Secrets:"
echo ""
echo "1. Ve a tu repositorio en GitHub"
echo "2. Navega a Settings → Secrets and Variables → Actions"
echo "3. Agrega los siguientes secretos:"
echo ""
echo "   🔑 KUBECONFIG:"
echo "   $KUBECONFIG_BASE64"
echo ""
echo "   🔑 POSTGRES_PASSWORD (ejemplo):"
echo "   c2VjdXJlX3Bhc3N3b3Jk"  # secure_password en base64
echo ""
echo "   🔑 N8N_DB_PASSWORD (ejemplo):"
echo "   bjhuX3NlY3VyZV9wYXNzd29yZA=="  # n8n_secure_password en base64
echo ""
echo "   🔑 N8N_ENCRYPTION_KEY (ejemplo):"
echo "   Y2hlcm5hcnVzX2VuY3J5cHRpb25fa2V5X3NlY3VyZQ=="  # chernarus_encryption_key_secure en base64
echo ""
echo "   🔑 CLOUDFLARE_EMAIL:"
echo "   Y29udGFjdG9AdGVycmVyb3YuY29t"  # contacto@terrerov.com en base64
echo ""
echo "   🔑 CF_DNS_API_TOKEN:"
echo "   dHVfY2xvdWRmbGFyZV90b2tlbl9hcXVp"  # tu_cloudflare_token_aqui en base64
echo ""
echo "   🔑 TELEGRAM_BOT_TOKEN (opcional):"
echo "   dHVfdGVsZWdyYW1fYm90X3Rva2VuX2FxdWk="  # tu_telegram_bot_token_aqui en base64
echo ""
echo "   🔑 OPENAI_API_KEY (opcional):"
echo "   dHVfb3BlbmFpX2FwaV9rZXlfYXF1aQ=="  # tu_openai_api_key_aqui en base64
echo ""
warning "⚠️ Importante: Reemplaza los valores de ejemplo con tus credenciales reales"
echo ""
log "💾 El kubeconfig también se ha guardado en: $KUBECONFIG_FILE"
echo ""
log "🧪 Para probar la configuración manualmente:"
echo "   kubectl --kubeconfig=$KUBECONFIG_FILE get nodes"
echo ""
log "🔐 Recuerda eliminar el archivo temporal cuando termines:"
echo "   rm -rf $TEMP_DIR"
echo ""
success "🎯 GitHub Actions está ahora configurado para desplegar en tu cluster!"
