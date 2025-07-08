#!/bin/bash
# Script maestro para configurar el cluster Kubernetes desde lenlab
# Ejecutar como terrerov en lenlab
set -e

RPI_HOST="rpi"
USER="terrerov"

# 1. Instalar y configurar master en rpi
ssh $USER@$RPI_HOST 'bash -s' < /home/terrerov/surviving-chernarus/scripts/k8s-setup-master.sh

# 2. Obtener el comando de join desde rpi
JOIN_CMD=$(ssh $USER@$RPI_HOST "sudo kubeadm token create --print-join-command")
echo "\nComando de join obtenido: $JOIN_CMD"

# 3. Instalar y preparar worker en lenlab
bash /home/terrerov/surviving-chernarus/scripts/k8s-setup-worker.sh

# 4. Unir lenlab al cluster
sudo $JOIN_CMD

echo "\nCluster configurado. Puedes verificar los nodos con: kubectl get nodes"
