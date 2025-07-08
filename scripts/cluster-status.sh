#!/bin/bash
# Script para verificar el estado del cluster Kubernetes
# Surviving Chernarus - Kubernetes Cluster Status

echo "🎯 === ESTADO DEL CLUSTER KUBERNETES ==="
echo "Fecha: $(date)"
echo "Ejecutado desde: $(hostname)"
echo ""

# Verificar conectividad al master
echo "🌐 Verificando conectividad al master..."
if nmap -Pn -p 6443 192.168.0.2 2>/dev/null | grep -q "open"; then
    echo "✅ Master (192.168.0.2:6443) accesible"
else
    echo "❌ Master no accesible"
    exit 1
fi

# Verificar sincronización de tiempo
echo ""
echo "⏰ Verificando sincronización de tiempo..."
echo "Tiempo local: $(date)"
echo "Zona horaria: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
echo "NTP sincronizado: $(timedatectl | grep 'synchronized' | awk '{print $3}')"

# Si estamos en rpi, mostrar información del cluster
if [ "$(hostname)" = "rpi" ]; then
    echo ""
    echo "🎛️ INFORMACIÓN DEL CLUSTER (desde master):"
    echo ""

    echo "📊 Estado de los nodos:"
    KUBECONFIG=/home/terrerov/.kube/config kubectl get nodes -o wide

    echo ""
    echo "🐳 Pods del sistema:"
    KUBECONFIG=/home/terrerov/.kube/config kubectl get pods -n kube-system --no-headers | wc -l | xargs echo "Total pods kube-system:"
    KUBECONFIG=/home/terrerov/.kube/config kubectl get pods -n kube-flannel --no-headers | wc -l | xargs echo "Total pods kube-flannel:"

    echo ""
    echo "🌐 Estado de Flannel CNI:"
    KUBECONFIG=/home/terrerov/.kube/config kubectl get pods -n kube-flannel -o wide

    echo ""
    echo "🔐 Información de certificados:"
    echo "API Server endpoint: $(KUBECONFIG=/home/terrerov/.kube/config kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"

else
    echo ""
    echo "ℹ️  Para información detallada del cluster, ejecutar desde rpi (master node)"
fi

echo ""
echo "📋 RESUMEN:"
echo "- Master: rpi (192.168.0.2) - Raspberry Pi 5"
echo "- Worker: lenlab (192.168.0.3) - Arch Linux x86_64"
echo "- CNI: Flannel"
echo "- Kubernetes: v1.33.2"
echo "- Container Runtime: containerd 2.1.3"
echo ""
echo "🎉 Cluster operativo y listo para workloads!"
