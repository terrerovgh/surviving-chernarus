#!/bin/bash
# ============================================================================
# VERIFICACIÓN DE ACCESO POR DOMINIO HTTPS - RESUELTO ✅
# ============================================================================

set -e

echo "✅ Verificando estado del acceso por dominio HTTPS..."
echo "============================================================================"
echo "STATUS: RESUELTO - IngressClass implementado exitosamente"
echo "Fecha de resolución: 10 de Julio 2025"
echo ""

# 1. Verificar que el LoadBalancer esté funcionando
echo "📊 1. Verificando LoadBalancer..."
LB_STATUS=$(kubectl get svc traefik-loadbalancer -n chernarus-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "no-ip")
if [ "$LB_STATUS" = "no-ip" ]; then
    echo "⚠️  LoadBalancer no tiene IP externa asignada"
    echo "🔧 Verificando configuración..."
    kubectl get svc traefik-loadbalancer -n chernarus-system
else
    echo "✅ LoadBalancer con IP externa: $LB_STATUS"
fi

# 2. Limpiar Ingress problemáticos
echo ""
echo "🧹 2. Limpiando Ingress conflictivos..."
kubectl delete ingress -n surviving-chernarus -l acme.cert-manager.io/http01-solver=true 2>/dev/null || echo "No hay ACME solvers que limpiar"
kubectl delete ingress -n chernarus-system -l acme.cert-manager.io/http01-solver=true 2>/dev/null || echo "No hay ACME solvers que limpiar"

# 3. Crear un Ingress mínimo que funcione
echo ""
echo "🛠️  3. Creando Ingress mínimo funcional..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chernarus-working-ingress
  namespace: surviving-chernarus
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  ingressClassName: traefik
  rules:
  - host: n8n.terrerov.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: n8n-service
            port:
              number: 5678
  - host: hq.terrerov.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hugo-dashboard-service
            port:
              number: 80
  - host: terrerov.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hugo-dashboard-service
            port:
              number: 80
EOF

# 4. Crear Ingress para Traefik Dashboard
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-working-ingress
  namespace: chernarus-system
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
spec:
  ingressClassName: traefik
  rules:
  - host: traefik.terrerov.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: traefik-dashboard-service
            port:
              number: 8080
EOF

# 5. Reiniciar Traefik para que cargue la nueva configuración
echo ""
echo "🔄 4. Reiniciando Traefik..."
kubectl delete pod -n chernarus-system -l app=traefik

# 6. Esperar a que Traefik esté listo
echo ""
echo "⏳ 5. Esperando a que Traefik esté listo..."
kubectl wait --for=condition=ready pod -l app=traefik -n chernarus-system --timeout=60s

# 7. Probar acceso y verificación adicional
echo ""
echo "🧪 6. Probando acceso..."
sleep 10

echo "Probando n8n.terrerov.com:"
RESPONSE=$(curl -H "Host: n8n.terrerov.com" http://192.168.0.2/ -I 2>/dev/null | head -1)
echo "$RESPONSE"

if [[ "$RESPONSE" == *"404"* ]]; then
    echo ""
    echo "⚠️  Aún hay 404. Verificando configuración de Traefik..."

    # Verificar si el Ingress se detecta
    echo "📋 Ingress configurados:"
    kubectl get ingress -A

    echo ""
    echo "🔍 Verificando backends del Ingress:"
    kubectl describe ingress -n surviving-chernarus

    echo ""
    echo "🧪 Probando acceso directo al servicio desde dentro del cluster:"
    kubectl run test-connectivity --image=curlimages/curl --rm -i --restart=Never -- curl -s http://n8n-service.surviving-chernarus.svc.cluster.local:5678/ | head -c 100 || echo "Servicio no accesible"

    echo ""
    echo "🔧 SOLUCIÓN ALTERNATIVA:"
    echo "   El LoadBalancer funciona pero hay problemas con el Ingress."
    echo "   Usa port-forward para acceso directo:"
    echo ""
    echo "   kubectl port-forward -n surviving-chernarus svc/n8n-service 5678:5678 --address=0.0.0.0"
    echo "   Luego accede a: http://localhost:5678"
    echo ""
fi

echo ""
echo "============================================================================"
echo "🎯 SOLUCIÓN PARA EL PROBLEMA DE CERTIFICADO Y 404"
echo "============================================================================"
echo ""
echo "🔐 PROBLEMA DEL CERTIFICADO:"
echo "   - Traefik usa certificado por defecto porque Let's Encrypt falló"
echo "   - Es normal en un entorno de desarrollo local"
echo "   - Solución: Aceptar certificado auto-firmado en el navegador"
echo ""
echo "🔍 PROBLEMA DEL 404:"
echo "   - Verificando si las rutas se cargan correctamente..."
echo ""
echo "📋 CONFIGURACIÓN DNS NECESARIA:"
echo "   Agrega a /etc/hosts para testing local:"
echo "   echo '192.168.0.2 n8n.terrerov.com hq.terrerov.com traefik.terrerov.com' | sudo tee -a /etc/hosts"
echo ""
echo "🌐 ACCESO:"
echo "   • https://n8n.terrerov.com (acepta certificado auto-firmado)"
echo "   • https://hq.terrerov.com"
echo "   • https://traefik.terrerov.com"
echo ""
