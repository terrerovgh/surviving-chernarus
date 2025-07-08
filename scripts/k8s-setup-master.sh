#!/bin/bash
# Script para configurar rpi (Raspberry Pi 5) como master de Kubernetes en Arch Linux ARM
set -e

# 1. Detectar arquitectura
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
  echo "Este script está diseñado para Raspberry Pi (aarch64). Arquitectura detectada: $ARCH"
  exit 1
fi

# 2. Instalar iptables-nft (responder automáticamente sí a todas las preguntas)
yes | sudo pacman -S iptables-nft

# 3. Instalar containerd, kubeadm, kubelet, kubectl (sin actualizar todo el sistema)
sudo pacman -S --noconfirm containerd kubeadm kubelet kubectl

# 4. Habilitar e iniciar containerd
sudo systemctl enable --now containerd

# 5. Habilitar e iniciar kubelet
sudo systemctl enable --now kubelet

# 6. Desactivar swap temporalmente y habilitar cgroups memory
sudo swapoff -a

# Habilitar cgroup memory en Raspberry Pi
if ! grep -q "cgroup_memory=1" /boot/cmdline.txt; then
  sudo sed -i 's/$/ cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt
  echo "Se han habilitado los cgroups. REINICIA el sistema y ejecuta el script nuevamente."
  exit 0
fi

# 7. Resetear kubeadm y limpiar antes de inicializar cluster
sudo kubeadm reset -f || true
sudo systemctl stop kubelet containerd || true
sudo pkill -f kube || true
sudo systemctl start containerd
sudo systemctl start kubelet

# 8. Inicializar cluster con IP específico
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.0.2 --ignore-preflight-errors=Port-6443,Port-10259,Port-10257,Port-10250

# 9. Configurar kubectl para terrerov
sudo -u terrerov mkdir -p /home/terrerov/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/terrerov/.kube/config
sudo chown terrerov:terrerov /home/terrerov/.kube/config

# Corregir endpoint del servidor para evitar problemas de certificados
sudo -u terrerov sed -i 's|server: https://127.0.0.1:6443|server: https://192.168.0.2:6443|g' /home/terrerov/.kube/config

# 10. Instalar Flannel CNI
KUBECONFIG=/home/terrerov/.kube/config sudo -u terrerov kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 11. Mostrar join command
sudo kubeadm token create --print-join-command

echo "\nMaster listo en Raspberry Pi 5. Copia el comando de join y ejecútalo en lenlab (worker)."
