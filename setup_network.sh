#!/bin/bash

# Script para configurar la red en la Raspberry Pi OS
# Este script debe ejecutarse después de setup_env.sh y antes de deploy.sh

# Colores para mensajes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=== Configuración de red para Raspberry Pi OS ===${NC}\n"

# Verificar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Este script debe ejecutarse como root. Usa 'sudo $0'${NC}"
    exit 1
fi

# Verificar si el archivo .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}El archivo .env no existe. Ejecuta primero ./setup_env.sh${NC}"
    exit 1
fi

# Cargar variables del archivo .env
source .env

# Verificar que las variables necesarias estén definidas
if [ -z "$RPI_IP" ] || [ -z "$RPI_GATEWAY" ] || [ -z "$RPI_DNS1" ] || [ -z "$RPI_DNS2" ] || [ -z "$HOST_NAME" ]; then
    echo -e "${RED}Faltan variables de configuración de red en el archivo .env${NC}"
    exit 1
fi

echo -e "${BLUE}Configurando la red con los siguientes parámetros:${NC}"
echo -e "IP: $RPI_IP"
echo -e "Gateway: $RPI_GATEWAY"
echo -e "DNS: $RPI_DNS1, $RPI_DNS2"
echo -e "Hostname: $HOST_NAME"

# Configurar el hostname
echo -e "\n${BLUE}Configurando hostname...${NC}"
echo "$HOST_NAME" > /etc/hostname
hostname "$HOST_NAME"

# Actualizar /etc/hosts
echo -e "\n${BLUE}Actualizando /etc/hosts...${NC}"
cat > /etc/hosts << EOF
127.0.0.1       localhost
127.0.1.1       $HOST_NAME

# The following lines are desirable for IPv6 capable hosts
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

# Extraer la dirección IP sin la máscara de red
IP_ADDRESS=$(echo $RPI_IP | cut -d'/' -f1)

# Configurar la interfaz de red eth0
echo -e "\n${BLUE}Configurando interfaz de red eth0...${NC}"
cat > /etc/network/interfaces.d/eth0 << EOF
auto eth0
iface eth0 inet static
    address $RPI_IP
    gateway $RPI_GATEWAY
    dns-nameservers $RPI_DNS1 $RPI_DNS2
EOF

# Configurar resolv.conf
echo -e "\n${BLUE}Configurando resolv.conf...${NC}"
cat > /etc/resolv.conf << EOF
nameserver $RPI_DNS1
nameserver $RPI_DNS2
EOF

echo -e "\n${GREEN}¡Configuración de red completada!${NC}"
echo -e "${YELLOW}NOTA:${NC} Es necesario reiniciar el sistema para aplicar los cambios de red."
echo -e "Ejecuta 'sudo reboot' cuando estés listo para reiniciar.\n"