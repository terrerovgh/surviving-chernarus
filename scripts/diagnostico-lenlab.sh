#!/bin/bash
# Diagnóstico de red y servicios para lenlab

echo "============================="
echo " Diagnóstico de lenlab "
echo "============================="

# 1. Conectividad básica
echo -e "\n🔗 Probando conectividad básica..."
ping -c 3 rpi.terrerov.com || echo "No hay conectividad con rpi.terrerov.com"
ping -c 3 8.8.8.8 || echo "No hay conectividad con Internet (8.8.8.8)"
GW=$(ip route | grep default | awk '{print $3}')
echo "Gateway: $GW"
ping -c 3 $GW || echo "No hay conectividad con el gateway"

# 2. Resolución DNS solo con CoreDNS
# Forzar uso de CoreDNS (192.168.0.2) como único servidor DNS
export DNS_SERVER=192.168.0.2
echo -e "\n🌐 Probando resolución DNS solo con CoreDNS ($DNS_SERVER)..."
dig @$DNS_SERVER terrerov.com || echo "No se resuelve terrerov.com"
dig @$DNS_SERVER n8n.terrerov.com || echo "No se resuelve n8n.terrerov.com"
dig @$DNS_SERVER google.com || echo "No se resuelve google.com"

# 3. Estado de servicios Kubernetes
echo -e "\n☸️  Estado de servicios Kubernetes..."
kubectl get nodes -o wide 2>/dev/null || echo "Kubernetes no disponible"
kubectl get pods -A 2>/dev/null || echo "No se pudo obtener pods"

# 4. Comprobación de puertos relevantes (solo K8s)
echo -e "\n🔎 Comprobando puertos de servicios Kubernetes..."
echo "n8n (5678):" && nc -zv localhost 5678 || echo "No disponible"
echo "Traefik (30365):" && nc -zv localhost 30365 || echo "No disponible"
echo "Prometheus (9090):" && nc -zv localhost 9090 || echo "No disponible"
echo "Grafana (3000):" && nc -zv localhost 3000 || echo "No disponible"

echo -e "\n✅ Diagnóstico finalizado. Solo servicios Kubernetes y CoreDNS deben estar activos."
