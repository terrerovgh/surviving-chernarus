#!/bin/bash
# Script para configurar Pi-hole DNS correctamente

set -e

echo "🛡️ Configurando Pi-hole DNS para Chernarus..."

# Verificar que el namespace existe
kubectl get namespace surviving-chernarus >/dev/null 2>&1 || {
    echo "❌ Error: Namespace 'surviving-chernarus' no existe"
    exit 1
}

# Obtener la IP del nodo maestro (donde está Traefik)
RPI_IP=$(kubectl get nodes -o wide | grep rpi | awk '{print $6}')
echo "📍 IP del nodo maestro (rpi): $RPI_IP"

# Crear ConfigMap con configuración de DNS local mejorada
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: pihole-local-dns
  namespace: surviving-chernarus
data:
  local.list: |
    # DNS local para dominios de Chernarus
    # Apunta todos los subdominios a la IP del nodo maestro donde está Traefik
    $RPI_IP terrerov.com
    $RPI_IP www.terrerov.com
    $RPI_IP hq.terrerov.com
    $RPI_IP n8n.terrerov.com
    $RPI_IP traefik.terrerov.com
    $RPI_IP pihole.terrerov.com
    $RPI_IP api.terrerov.com
    $RPI_IP admin.terrerov.com
    $RPI_IP dashboard.terrerov.com
    $RPI_IP monitoring.terrerov.com
    $RPI_IP grafana.terrerov.com
    $RPI_IP prometheus.terrerov.com
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pihole-dnsmasq-local
  namespace: surviving-chernarus
data:
  99-local.conf: |
    # Configuración para dominios locales
    local=/terrerov.com/
    domain=terrerov.com
    expand-hosts
    # No reenviar consultas de dominios locales
    server=/terrerov.com/
    # Cache local
    cache-size=10000
    # Log de consultas
    log-queries
    # Permitir consultas desde cualquier origen
    listen-address=0.0.0.0
    bind-interfaces
    interface=eth0
EOF

echo "✅ ConfigMaps creados"

# Crear deployment de Pi-hole optimizado
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pihole-deployment
  namespace: surviving-chernarus
  labels:
    app: pihole
    component: dns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pihole
  template:
    metadata:
      labels:
        app: pihole
        component: dns
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64  # Ejecutar en Raspberry Pi
      initContainers:
      - name: setup-dns-config
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "Configurando archivos DNS..."
          cp /tmp/local.list /etc/pihole/custom.list
          cp /tmp/dnsmasq-local.conf /etc/dnsmasq.d/99-local.conf
          chmod 644 /etc/pihole/custom.list
          chmod 644 /etc/dnsmasq.d/99-local.conf
          echo "Configuración DNS completada"
        volumeMounts:
        - name: local-dns-source
          mountPath: /tmp/local.list
          subPath: local.list
        - name: dnsmasq-local-source
          mountPath: /tmp/dnsmasq-local.conf
          subPath: 99-local.conf
        - name: pihole-config
          mountPath: /etc/pihole
        - name: pihole-dnsmasq
          mountPath: /etc/dnsmasq.d
      containers:
      - name: pihole
        image: pihole/pihole:latest
        ports:
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 53
          name: dns-udp
          protocol: UDP
        - containerPort: 80
          name: http
          protocol: TCP
        env:
        - name: TZ
          value: "Europe/Madrid"
        - name: WEBPASSWORD
          valueFrom:
            secretKeyRef:
              name: pihole-secret
              key: webpassword
        - name: PIHOLE_DNS_
          value: "1.1.1.1;8.8.8.8"  # DNS upstream para dominios no locales
        - name: DNSMASQ_LISTENING
          value: "all"
        - name: INTERFACE
          value: "eth0"
        - name: QUERY_LOGGING
          value: "true"
        - name: VIRTUAL_HOST
          value: "pihole.terrerov.com"
        - name: PIHOLE_DOMAIN
          value: "terrerov.com"
        - name: TEMPERATUREUNIT
          value: "c"
        - name: WEBUIBOXEDLAYOUT
          value: "boxed"
        - name: REV_SERVER
          value: "true"
        - name: REV_SERVER_DOMAIN
          value: "terrerov.com"
        - name: REV_SERVER_TARGET
          value: "$RPI_IP"
        - name: REV_SERVER_CIDR
          value: "192.168.0.0/24"
        volumeMounts:
        - name: pihole-config
          mountPath: /etc/pihole
        - name: pihole-dnsmasq
          mountPath: /etc/dnsmasq.d
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: pihole-config
        hostPath:
          path: /data/pihole/config
          type: DirectoryOrCreate
      - name: pihole-dnsmasq
        hostPath:
          path: /data/pihole/dnsmasq
          type: DirectoryOrCreate
      - name: local-dns-source
        configMap:
          name: pihole-local-dns
      - name: dnsmasq-local-source
        configMap:
          name: pihole-dnsmasq-local
EOF

echo "✅ Pi-hole deployment actualizado"

# Esperar a que el pod esté listo
echo "⏳ Esperando a que Pi-hole esté listo..."
kubectl wait --for=condition=ready pod -l app=pihole -n surviving-chernarus --timeout=120s

echo "🎉 Pi-hole configurado correctamente!"
echo "📱 Acceso web: http://localhost:8081/admin/"
echo "🔑 Contraseña: 100A.soledad1"
echo "🌐 DNS Server IP (ClusterIP): $(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.clusterIP}')"
echo "🌐 DNS Server IP (NodePort): $RPI_IP:$(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.ports[0].nodePort}')"
EOF
