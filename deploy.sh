#!/bin/bash

# Script unificado para el proyecto "Surviving Chernarus"
# Este script combina todas las funcionalidades de setup_env.sh, setup_network.sh y deploy.sh
# con una interfaz mejorada usando whiptail

# Colores para mensajes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Función para mostrar mensajes de progreso
function log_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Verificar si whiptail está instalado
if ! command -v whiptail &> /dev/null; then
    log_error "whiptail no está instalado. Instalándolo..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y whiptail
    elif command -v yum &> /dev/null; then
        sudo yum install -y newt
    else
        log_error "No se pudo instalar whiptail. Por favor, instálalo manualmente."
        exit 1
    fi
fi

# Mensaje de bienvenida
whiptail --title "Surviving Chernarus - Instalador Unificado" \
         --msgbox "Bienvenido al instalador unificado de Surviving Chernarus.\n\nEste asistente te guiará a través de todo el proceso de configuración y despliegue del proyecto." 12 78

# Menú principal
while true; do
    OPCION=$(whiptail --title "Surviving Chernarus - Menú Principal" \
                     --menu "Selecciona una opción:" 15 78 5 \
                     "1" "Configurar variables de entorno (.env)" \
                     "2" "Configurar red (requiere sudo)" \
                     "3" "Desplegar servicios" \
                     "4" "Ver documentación" \
                     "5" "Salir" 3>&1 1>&2 2>&3)
    
    # Salir si se presiona Cancelar
    if [ $? -ne 0 ]; then
        log_message "Operación cancelada por el usuario."
        exit 0
    fi
    
    case $OPCION in
        1)
            # Configurar variables de entorno
            setup_env
            ;;
        2)
            # Configurar red
            if [ "$(id -u)" -ne 0 ]; then
                whiptail --title "Error" \
                         --msgbox "Este script debe ejecutarse con privilegios de superusuario (sudo)." 8 78
            else
                setup_network
            fi
            ;;
        3)
            # Desplegar servicios
            deploy_services
            ;;
        4)
            # Ver documentación
            show_documentation
            ;;
        5)
            # Salir
            log_message "Saliendo del instalador."
            exit 0
            ;;
    esac
done

# Función para configurar variables de entorno
function setup_env() {
    # Verificar si el archivo .env ya existe
    if [ -f ".env" ]; then
        if ! whiptail --title "Archivo .env existente" \
                     --yesno "El archivo .env ya existe. ¿Deseas sobrescribirlo?" 8 78; then
            log_message "Operación cancelada por el usuario."
            return
        fi
    fi
    
    # Obtener ID de usuario y grupo
    PUID=$(id -u)
    PGID=$(id -g)
    
    # Mostrar y confirmar ID de usuario y grupo
    if ! whiptail --title "ID de Usuario y Grupo" \
                 --yesno "Se utilizarán los siguientes ID:\n\nID de Usuario (PUID): $PUID\nID de Grupo (PGID): $PGID\n\n¿Es correcto?" 12 78; then
        PUID=$(whiptail --title "ID de Usuario" --inputbox "Introduce el ID de Usuario (PUID):" 8 78 "$PUID" 3>&1 1>&2 2>&3)
        PGID=$(whiptail --title "ID de Grupo" --inputbox "Introduce el ID de Grupo (PGID):" 8 78 "$PGID" 3>&1 1>&2 2>&3)
    fi
    
    # Zona horaria
    TZ=$(whiptail --title "Zona Horaria" --inputbox "Introduce la zona horaria:" 8 78 "Europe/Madrid" 3>&1 1>&2 2>&3)
    
    # Configuración de dominio y Cloudflare
    DOMAIN_NAME=$(whiptail --title "Nombre de Dominio" --inputbox "Introduce el nombre de dominio:" 8 78 "example.com" 3>&1 1>&2 2>&3)
    CLOUDFLARE_EMAIL=$(whiptail --title "Email de Cloudflare" --inputbox "Introduce el email de Cloudflare:" 8 78 "user@example.com" 3>&1 1>&2 2>&3)
    CLOUDFLARE_API_TOKEN=$(whiptail --title "Token API de Cloudflare" --passwordbox "Introduce el token API de Cloudflare:" 8 78 3>&1 1>&2 2>&3)
    
    # Configuración de PostgreSQL
    POSTGRES_DB=$(whiptail --title "Base de Datos PostgreSQL" --inputbox "Introduce el nombre de la base de datos:" 8 78 "n8n" 3>&1 1>&2 2>&3)
    POSTGRES_USER=$(whiptail --title "Usuario PostgreSQL" --inputbox "Introduce el nombre de usuario:" 8 78 "n8n" 3>&1 1>&2 2>&3)
    POSTGRES_PASSWORD=$(whiptail --title "Contraseña PostgreSQL" --passwordbox "Introduce la contraseña:" 8 78 3>&1 1>&2 2>&3)
    
    # Si la contraseña está vacía, generar una aleatoria
    if [ -z "$POSTGRES_PASSWORD" ]; then
        POSTGRES_PASSWORD=$(openssl rand -base64 12)
        whiptail --title "Contraseña Generada" --msgbox "Se ha generado una contraseña aleatoria para PostgreSQL: $POSTGRES_PASSWORD\n\nPor favor, anótala en un lugar seguro." 10 78
    fi
    
    # Configuración de Pi-hole
    PIHOLE_PASSWORD=$(whiptail --title "Contraseña Pi-hole" --passwordbox "Introduce la contraseña para Pi-hole:" 8 78 3>&1 1>&2 2>&3)
    
    # Si la contraseña está vacía, generar una aleatoria
    if [ -z "$PIHOLE_PASSWORD" ]; then
        PIHOLE_PASSWORD=$(openssl rand -base64 8)
        whiptail --title "Contraseña Generada" --msgbox "Se ha generado una contraseña aleatoria para Pi-hole: $PIHOLE_PASSWORD\n\nPor favor, anótala en un lugar seguro." 10 78
    fi
    
    # Configuración de Traefik
    TRAEFIK_USER=$(whiptail --title "Usuario Traefik" --inputbox "Introduce el nombre de usuario para Traefik:" 8 78 "admin" 3>&1 1>&2 2>&3)
    TRAEFIK_PASSWORD=$(whiptail --title "Contraseña Traefik" --passwordbox "Introduce la contraseña para Traefik:" 8 78 3>&1 1>&2 2>&3)
    
    # Si la contraseña está vacía, generar una aleatoria
    if [ -z "$TRAEFIK_PASSWORD" ]; then
        TRAEFIK_PASSWORD=$(openssl rand -base64 10)
        whiptail --title "Contraseña Generada" --msgbox "Se ha generado una contraseña aleatoria para Traefik: $TRAEFIK_PASSWORD\n\nPor favor, anótala en un lugar seguro." 10 78
    fi
    
    # Generar hash para Traefik
    if command -v htpasswd &> /dev/null; then
        HASHED_PASSWORD=$(htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
    else
        log_warning "htpasswd no está instalado. No se pudo generar el hash para Traefik."
        HASHED_PASSWORD="$TRAEFIK_USER:$TRAEFIK_PASSWORD"
    fi
    
    # Configuración de red para Raspberry Pi
    RPI_IP=$(whiptail --title "IP de Raspberry Pi" --inputbox "Introduce la dirección IP estática para la Raspberry Pi:" 8 78 "192.168.1.2" 3>&1 1>&2 2>&3)
    
    # Crear archivo .env
    cat > .env << EOF
# Configuración de usuario y grupo
PUID=$PUID
PGID=$PGID

# Zona horaria
TZ=$TZ

# Configuración de dominio y Cloudflare
DOMAIN_NAME=$DOMAIN_NAME
CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Configuración de PostgreSQL
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Configuración de Pi-hole
PIHOLE_PASSWORD=$PIHOLE_PASSWORD

# Configuración de Traefik
TRAEFIK_USER=$TRAEFIK_USER
TRAEFIK_PASSWORD=$TRAEFIK_PASSWORD
HASHED_PASSWORD=$HASHED_PASSWORD

# Configuración de red para Raspberry Pi
RPI_IP=$RPI_IP
EOF
    
    whiptail --title "Configuración Completada" \
             --msgbox "El archivo .env ha sido creado correctamente." 8 78
}

# Función para configurar la red
function setup_network() {
    # Verificar si el archivo .env existe
    if [ ! -f ".env" ]; then
        whiptail --title "Error" \
                 --msgbox "El archivo .env no existe. Por favor, ejecuta primero la opción 'Configurar variables de entorno'." 10 78
        return
    fi
    
    # Cargar variables de entorno desde el archivo .env
    source .env
    
    # Verificar que RPI_IP está definido
    if [ -z "$RPI_IP" ]; then
        log_error "La variable RPI_IP no está definida en el archivo .env"
        return
    fi
    
    # Obtener configuración de red actual
    CURRENT_HOSTNAME=$(hostname)
    
    # Solicitar configuración de red
    NEW_HOSTNAME=$(whiptail --title "Nombre de Host" --inputbox "Introduce el nombre de host para la Raspberry Pi:" 8 78 "surviving-chernarus" 3>&1 1>&2 2>&3)
    IP_ADDRESS=$(whiptail --title "Dirección IP" --inputbox "Introduce la dirección IP estática:" 8 78 "$RPI_IP" 3>&1 1>&2 2>&3)
    GATEWAY=$(whiptail --title "Puerta de Enlace" --inputbox "Introduce la dirección de la puerta de enlace:" 8 78 "192.168.1.1" 3>&1 1>&2 2>&3)
    DNS_SERVERS=$(whiptail --title "Servidores DNS" --inputbox "Introduce los servidores DNS (separados por espacios):" 8 78 "1.1.1.1 1.0.0.1" 3>&1 1>&2 2>&3)
    
    # Actualizar .env con la nueva IP
    sed -i "s/RPI_IP=.*/RPI_IP=$IP_ADDRESS/g" .env
    
    # Configurar hostname
    echo "$NEW_HOSTNAME" > /etc/hostname
    hostname "$NEW_HOSTNAME"
    
    # Actualizar /etc/hosts
    sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    
    # Configurar interfaz de red eth0
    cat > /etc/network/interfaces.d/eth0 << EOF
auto eth0
iface eth0 inet static
    address $IP_ADDRESS/24
    gateway $GATEWAY
EOF
    
    # Configurar resolv.conf
    cat > /etc/resolv.conf << EOF
# Generated by Surviving Chernarus setup_network
EOF
    
    for DNS in $DNS_SERVERS; do
        echo "nameserver $DNS" >> /etc/resolv.conf
    done
    
    # Preguntar si se desea reiniciar
    if whiptail --title "Reiniciar Sistema" \
               --yesno "La configuración de red ha sido actualizada. Es necesario reiniciar el sistema para aplicar los cambios.\n\n¿Deseas reiniciar ahora?" 12 78; then
        log_message "Reiniciando el sistema..."
        reboot
    else
        whiptail --title "Configuración Completada" \
                 --msgbox "La configuración de red ha sido actualizada. Por favor, reinicia el sistema manualmente para aplicar los cambios." 10 78
    fi
}

# Función para desplegar servicios
function deploy_services() {
    # Verificar si el archivo .env existe
    if [ ! -f ".env" ]; then
        whiptail --title "Error" \
                 --msgbox "El archivo .env no existe. Por favor, ejecuta primero la opción 'Configurar variables de entorno'." 10 78
        return
    fi
    
    # Cargar variables de entorno desde el archivo .env
    source .env
    
    # Verificar variables requeridas
    required_vars=("PUID" "PGID" "TZ" "DOMAIN_NAME" "CLOUDFLARE_EMAIL" "CLOUDFLARE_API_TOKEN" \
                  "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD" "PIHOLE_PASSWORD" \
                  "TRAEFIK_USER" "TRAEFIK_PASSWORD")
    
    missing_vars=0
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_warning "La variable $var no está definida en el archivo .env"
            missing_vars=$((missing_vars+1))
        fi
    done
    
    if [ $missing_vars -gt 0 ]; then
        if ! whiptail --title "Variables faltantes" \
                     --yesno "Faltan $missing_vars variables en el archivo .env. ¿Deseas continuar de todos modos?" 10 78; then
            log_message "Operación cancelada por el usuario."
            return
        fi
    fi
    
    # Función para ejecutar comandos
    exec_cmd() {
        eval "$1"
        if [ $? -ne 0 ]; then
            if ! whiptail --title "Error de comando" \
                         --yesno "Error al ejecutar: $1\n\n¿Deseas continuar de todos modos?" 10 78; then
                log_error "Operación cancelada por el usuario."
                return 1
            fi
        fi
        return 0
    }
    
    # Mostrar resumen de la instalación
    if ! whiptail --title "Resumen de la instalación" \
                 --yesno "Se realizarán las siguientes acciones:\n\n1. Actualización del sistema\n2. Instalación y configuración de UFW\n3. Configuración de UFW para Docker\n4. Instalación de Docker y Docker Compose\n5. Configuración de permisos de Docker\n6. Creación de estructura de directorios\n7. Configuración de Traefik\n8. Creación de docker-compose.yml\n9. Inicio de los servicios\n\n¿Deseas continuar?" 20 78; then
        log_message "Operación cancelada por el usuario."
        return
    fi
    
    # Crear una barra de progreso
    {
        # 1. Actualización del sistema
        echo "10"
        log_message "1. Actualizando el sistema..."
        exec_cmd "sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"
        
        # 2. Instalación y configuración de UFW
        echo "20"
        log_message "2. Instalando y configurando UFW..."
        exec_cmd "sudo apt install ufw -y"
        exec_cmd "sudo ufw default deny incoming"
        exec_cmd "sudo ufw default allow outgoing"
        exec_cmd "sudo ufw allow ssh"
        exec_cmd "sudo ufw allow http"
        exec_cmd "sudo ufw allow https"
        
        # 3. Configuración de UFW para Docker
        echo "30"
        log_message "3. Configurando UFW para Docker..."
        
        # Crear archivo temporal con la configuración de UFW para Docker
        cat > ufw_docker_config.tmp << 'EOF'
# BEGIN UFW AND DOCKER
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
EOF
        
        # Mover el archivo temporal a /tmp
        exec_cmd "mv ufw_docker_config.tmp /tmp/ufw_docker_config"
        
        # Insertar la configuración en after.rules
        exec_cmd "sudo sed -i '/^*filter/i\n# BEGIN UFW AND DOCKER\n*filter\n:DOCKER-USER - [0:0]\n-A DOCKER-USER -j RETURN -s 10.0.0.0\/8\n-A DOCKER-USER -j RETURN -s 172.16.0.0\/12\n-A DOCKER-USER -j RETURN -s 192.168.0.0\/16\n\n-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN\n\n-A DOCKER-USER -j ufw-user-forward\n\n-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0\/16\n-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0\/8\n-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0\/12\n-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0\/16\n-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0\/8\n-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0\/12\n\n-A DOCKER-USER -j RETURN\nCOMMIT\n# END UFW AND DOCKER\n' /etc/ufw/after.rules"
        
        # Modificar DEFAULT_FORWARD_POLICY
        exec_cmd "sudo sed -i 's/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g' /etc/default/ufw"
        
        # Activar UFW
        exec_cmd "sudo ufw --force enable"
        
        # Eliminar archivo temporal
        rm -f ufw_docker_config.tmp
        
        # 4. Instalación de Docker y Docker Compose
        echo "40"
        log_message "4. Instalando Docker y Docker Compose..."
        
        # Instalar dependencias
        exec_cmd "sudo apt install ca-certificates curl gnupg -y"
        
        # Añadir la clave GPG oficial de Docker
        exec_cmd "sudo install -m 0755 -d /etc/apt/keyrings"
        exec_cmd "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
        exec_cmd "sudo chmod a+r /etc/apt/keyrings/docker.gpg"
        
        # Configurar el repositorio apt de Docker
        exec_cmd "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \$(. /etc/os-release && echo \"\$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
        
        # Instalar Docker
        exec_cmd "sudo apt update"
        exec_cmd "sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y"
        
        # 5. Post-instalación de Docker
        echo "50"
        log_message "5. Configurando permisos de Docker..."
        exec_cmd "sudo usermod -aG docker \$USER"
        exec_cmd "newgrp docker"
        exec_cmd "sudo systemctl enable docker"
        exec_cmd "sudo systemctl start docker"
        
        # Verificar la instalación de Docker
        log_message "Verificando la instalación de Docker..."
        exec_cmd "docker --version"
        exec_cmd "docker compose version"
        exec_cmd "docker run hello-world"
        
        # 6. Crear estructura de directorios para el proyecto
        echo "60"
        log_message "6. Creando estructura de directorios para el proyecto..."
        exec_cmd "sudo mkdir -p /opt/surviving-chernarus/{traefik_data,postgres_data,pihole_data/{pihole,dnsmasq.d},n8n_data,rtorrent_data/{config,downloads,session},heimdall_data,squid_data/{cache}}"
        exec_cmd "sudo chown -R \$USER:\$USER /opt/surviving-chernarus"
        
        # 7. Crear archivo .env en el directorio del proyecto
        echo "70"
        log_message "7. Creando archivo .env en el directorio del proyecto..."
        
        # Crear archivo .env con las variables de entorno
        cat > /opt/surviving-chernarus/.env << EOF
PUID=${PUID}
PGID=${PGID}
TZ=${TZ}
DOMAIN_NAME=${DOMAIN_NAME}
CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
PIHOLE_PASSWORD=${PIHOLE_PASSWORD}
HASHED_PASSWORD=${HASHED_PASSWORD}
EOF
        
        # 8. Crear archivo de configuración de Traefik
        echo "80"
        log_message "8. Configurando Traefik..."
        
        # Crear archivo traefik.yml
        cat > /opt/surviving-chernarus/traefik_data/traefik.yml << 'EOF'
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

certificatesResolvers:
  cloudflare:
    acme:
      email: "${CLOUDFLARE_EMAIL}"
      storage: acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
EOF
        
        # Crear archivo acme.json vacío
        exec_cmd "touch /opt/surviving-chernarus/traefik_data/acme.json"
        exec_cmd "chmod 600 /opt/surviving-chernarus/traefik_data/acme.json"
        
        # 9. Crear archivo docker-compose.yml
        echo "90"
        log_message "9. Creando archivo docker-compose.yml..."
        
        # Crear archivo docker-compose.yml
        cat > /opt/surviving-chernarus/docker-compose.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - cher-net
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik_data/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik_data/acme.json:/acme.json
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-secure.entrypoints=websecure"
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik.${DOMAIN_NAME}`)"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.service=api@internal"
      - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${HASHED_PASSWORD}"

  postgres:
    image: postgres:14-alpine
    container_name: postgres
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - ./postgres_data:/var/lib/postgresql/data

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - TZ=${TZ}
      - WEBPASSWORD=${PIHOLE_PASSWORD}
      - SERVERIP=192.168.1.2  # Ajustar a la IP de la Raspberry Pi
    volumes:
      - ./pihole_data/pihole:/etc/pihole
      - ./pihole_data/dnsmasq.d:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole-secure.entrypoints=websecure"
      - "traefik.http.routers.pihole-secure.rule=Host(`pihole.${DOMAIN_NAME}`)"
      - "traefik.http.routers.pihole-secure.tls=true"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_HOST=${DOMAIN_NAME}
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://n8n.${DOMAIN_NAME}/
      - TZ=${TZ}
    volumes:
      - ./n8n_data:/home/node/.n8n
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n-secure.entrypoints=websecure"
      - "traefik.http.routers.n8n-secure.rule=Host(`n8n.${DOMAIN_NAME}`)"
      - "traefik.http.routers.n8n-secure.tls=true"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

  rtorrent:
    image: linuxserver/rutorrent:latest
    container_name: rtorrent
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ./rtorrent_data/config:/config
      - ./rtorrent_data/downloads:/downloads
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.rtorrent-secure.entrypoints=websecure"
      - "traefik.http.routers.rtorrent-secure.rule=Host(`rtorrent.${DOMAIN_NAME}`)"
      - "traefik.http.routers.rtorrent-secure.tls=true"
      - "traefik.http.services.rtorrent.loadbalancer.server.port=80"

  heimdall:
    image: linuxserver/heimdall:latest
    container_name: heimdall
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ./heimdall_data:/config
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.heimdall-secure.entrypoints=websecure"
      - "traefik.http.routers.heimdall-secure.rule=Host(`${DOMAIN_NAME}`)"
      - "traefik.http.routers.heimdall-secure.tls=true"
      - "traefik.http.services.heimdall.loadbalancer.server.port=80"

networks:
  cher-net:
    driver: bridge
EOF
        
        # 10. Iniciar los servicios
        echo "100"
        log_message "10. Iniciando los servicios..."
        exec_cmd "cd /opt/surviving-chernarus && docker compose up -d"
        
        # 11. Verificar que los servicios están funcionando
        log_message "11. Verificando que los servicios están funcionando..."
        exec_cmd "docker ps"
        
    } | whiptail --title "Progreso de la instalación" --gauge "Iniciando la instalación..." 10 78 0
    
    # Mostrar mensaje de éxito
    whiptail --title "Despliegue Completado" \
             --msgbox "¡Despliegue completado con éxito!\n\nPuedes acceder a los servicios a través de las siguientes URLs:\n\n- Panel de control: https://${DOMAIN_NAME}\n- Traefik Dashboard: https://traefik.${DOMAIN_NAME}\n- Pi-hole: http://pihole.${DOMAIN_NAME}/admin\n- n8n: https://n8n.${DOMAIN_NAME}\n- rTorrent: https://rtorrent.${DOMAIN_NAME}" 20 78
    
    log_message "¡Despliegue completado con éxito!"
    log_message "Puedes acceder a los servicios a través de las siguientes URLs:"
    log_message "- Panel de control: https://${DOMAIN_NAME}"
    log_message "- Traefik Dashboard: https://traefik.${DOMAIN_NAME}"
    log_message "- Pi-hole: http://pihole.${DOMAIN_NAME}/admin"
    log_message "- n8n: https://n8n.${DOMAIN_NAME}"
    log_message "- rTorrent: https://rtorrent.${DOMAIN_NAME}"
}

# Función para mostrar la documentación
function show_documentation() {
    # Menú de documentación
    DOC_OPTION=$(whiptail --title "Surviving Chernarus - Documentación" \
                         --menu "Selecciona una opción:" 15 78 4 \
                         "1" "Información general" \
                         "2" "Guía de instalación" \
                         "3" "Solución de problemas" \
                         "4" "Volver al menú principal" 3>&1 1>&2 2>&3)
    
    # Salir si se presiona Cancelar
    if [ $? -ne 0 ]; then
        return
    fi
    
    case $DOC_OPTION in
        1)
            # Información general
            whiptail --title "Información General" \
                     --msgbox "Surviving Chernarus es un ecosistema de servicios auto-alojados diseñado para Raspberry Pi.\n\nServicios incluidos:\n- Traefik: Proxy inverso y balanceador de carga\n- PostgreSQL: Base de datos relacional\n- Pi-hole: Bloqueador de anuncios a nivel de red\n- n8n: Plataforma de automatización de flujos de trabajo\n- rTorrent: Cliente de BitTorrent\n- Heimdall: Panel de control para servicios\n\nRequisitos:\n- Raspberry Pi (recomendado Pi 4 o superior)\n- Raspberry Pi OS (64-bit recomendado)\n- Conexión a Internet\n- Dominio registrado en Cloudflare" 20 78
            show_documentation
            ;;
        2)
            # Guía de instalación
            whiptail --title "Guía de Instalación" \
                     --msgbox "Pasos para la instalación:\n\n1. Configurar variables de entorno (.env)\n   - Ejecuta la opción 1 del menú principal\n   - Configura todas las variables necesarias\n\n2. Configurar red (requiere sudo)\n   - Ejecuta la opción 2 del menú principal\n   - Configura la red para tu Raspberry Pi\n   - Reinicia el sistema cuando se te solicite\n\n3. Desplegar servicios\n   - Ejecuta la opción 3 del menú principal\n   - Sigue las instrucciones en pantalla\n   - Espera a que se complete la instalación\n\n4. Acceder a los servicios\n   - Utiliza las URLs proporcionadas al final de la instalación" 20 78
            show_documentation
            ;;
        3)
            # Solución de problemas
            whiptail --title "Solución de Problemas" \
                     --msgbox "Problemas comunes y soluciones:\n\n1. Error al configurar UFW para Docker\n   - Verifica que estás ejecutando el script con privilegios de superusuario\n   - Asegúrate de que UFW está instalado\n\n2. Error al instalar Docker\n   - Verifica tu conexión a Internet\n   - Asegúrate de que tu sistema está actualizado\n\n3. Los servicios no son accesibles\n   - Verifica que los contenedores están en ejecución con 'docker ps'\n   - Comprueba la configuración de Cloudflare\n   - Verifica que los puertos 80 y 443 están abiertos\n\n4. Problemas con Pi-hole\n   - Asegúrate de que no hay conflictos de puertos\n   - Verifica que el contenedor tiene los permisos necesarios\n\nPara más ayuda, consulta la documentación completa en:\nhttps://github.com/tu-usuario/surviving-chernarus" 20 78
            show_documentation
            ;;
        4)
            # Volver al menú principal
            return
            ;;
    esac
}

# Verificar si el script se está ejecutando como root para la opción de configuración de red
if [ "$1" = "network" ] && [ "$(id -u)" -ne 0 ]; then
    log_error "Para configurar la red, este script debe ejecutarse con privilegios de superusuario (sudo)."
    exit 1
fi

# Si se proporciona un argumento, ejecutar la función correspondiente
if [ -n "$1" ]; then
    case $1 in
        env)
            setup_env
            exit 0
            ;;
        network)
            setup_network
            exit 0
            ;;
        deploy)
            deploy_services
            exit 0
            ;;
        doc)
            show_documentation
            exit 0
            ;;
        *)
            log_error "Argumento no válido: $1"
            echo "Uso: $0 [env|network|deploy|doc]"
            exit 1
            ;;
    esac
fi