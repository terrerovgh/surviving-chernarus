#!/bin/bash
# Script de configuración para nodo rpi
set -e

# 1. Configuración de red con NetworkManager
sudo nmcli con mod "$(nmcli -g NAME con show --active | head -n1)" ipv4.addresses 192.168.0.2/25
sudo nmcli con mod "$(nmcli -g NAME con show --active | head -n1)" ipv4.gateway 192.168.0.1
sudo nmcli con mod "$(nmcli -g NAME con show --active | head -n1)" ipv4.dns "1.1.1.1,192.168.0.2,192.168.0.3"
sudo nmcli con mod "$(nmcli -g NAME con show --active | head -n1)" ipv4.method manual
sudo nmcli con down "$(nmcli -g NAME con show --active | head -n1)" && sudo nmcli con up "$(nmcli -g NAME con show --active | head -n1)"

# 2. Crear usuario terrerov
if ! id terrerov &>/dev/null; then
  sudo useradd -m -s /bin/bash terrerov
  echo 'terrerov:3L.sdla' | sudo chpasswd
  sudo usermod -aG sudo terrerov
fi

# 3. Generar llave SSH para terrerov
sudo -u terrerov bash -c '[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa'

# 4. Configurar hostname
sudo hostnamectl set-hostname rpi

echo "\nScript completado en rpi. Ejecuta el script en lenlab y luego intercambia las llaves SSH."
