#!/bin/bash
# Script para configurar lenlab como worker de Kubernetes en Arch Linux ARM
set -e

echo "🚀 Configurando lenlab como worker node de Kubernetes..."

# 1. Detectar arquitectura
ARCH=$(uname -m)
echo "Arquitectura detectada: $ARCH"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "x86_64" ]]; then
  echo "Este script está diseñado para Arch Linux ARM (aarch64) o PC (x86_64). Arquitectura detectada: $ARCH"
  exit 1
fi

# 2. Sincronizar tiempo con UTC y habilitar NTP
echo "⏰ Sincronizando tiempo con el master..."
sudo timedatectl set-timezone UTC
sudo timedatectl set-ntp true
sudo systemctl enable --now systemd-timesyncd
sleep 3
echo "✅ Tiempo sincronizado: $(date)"

# 3. Verificar conectividad al master
echo "🌐 Verificando conectividad al master (192.168.0.2:6443)..."
if ! command -v nmap >/dev/null 2>&1; then
  echo "📦 Instalando nmap para verificar conectividad..."
  sudo pacman -S --noconfirm nmap
fi
if nmap -Pn -p 6443 192.168.0.2 | grep -q "open"; then
  echo "✅ Puerto 6443 del master accesible"
else
  echo "❌ Error: No se puede conectar al master en 192.168.0.2:6443"
  exit 1
fi

# 4. Actualizar sistema solo si es necesario (comentado para evitar problemas)
# sudo pacman -Syu --overwrite '/usr/lib/firmware/nvidia/*' --noconfirm

# 5. Instalar containerd, kubeadm, kubelet, kubectl
echo "📦 Instalando componentes de Kubernetes..."
sudo pacman -S --noconfirm containerd kubeadm kubelet

# 6. Habilitar e iniciar containerd
echo "🐳 Configurando containerd..."
sudo systemctl enable --now containerd

# 7. Habilitar kubelet (se iniciará cuando se haga join)
echo "🔧 Configurando kubelet..."
sudo systemctl enable kubelet

# 8. Desactivar swap temporalmente (Arch usualmente no usa swap por defecto)
echo "💾 Desactivando swap..."
sudo swapoff -a

# 9. Limpiar configuraciones previas de Kubernetes
echo "🧹 Limpiando configuraciones previas..."
sudo kubeadm reset -f || true
sudo systemctl stop kubelet || true
sudo pkill -f kube || true

# 10. Mostrar información del sistema
echo ""
echo "📊 Información del sistema preparado:"
echo "Fecha/Hora: $(date)"
echo "Zona horaria: $(timedatectl | grep 'Time zone')"
echo "NTP sincronizado: $(timedatectl | grep 'synchronized')"
echo "Arquitectura: $ARCH"
echo ""
echo "✅ Worker node preparado para join al cluster"
echo ""
echo "🔗 Para unir al cluster, ejecuta el comando proporcionado por el master:"

echo "\nWorker listo. Ejecuta el comando de join que te da el master para unir este nodo al cluster."
