#!/bin/bash

# Script de despliegue para el proyecto "Surviving Chernarus" en Raspberry Pi
# Este script configura todos los servicios necesarios en la Raspberry Pi
# según el plan descrito en README.md

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

# Verificar si el archivo .env existe
if [ ! -f ".env" ]; then
    log_error "El archivo .env no existe. Por favor, crea este archivo con las variables de entorno necesarias."
fi

# Cargar variables de entorno desde el archivo .env
log_message "Cargando variables de entorno desde .env"
source .env

# Verificar variables requeridas
required_vars=("PUID" "PGID" "TZ" "DOMAIN_NAME" "CLOUDFLARE_EMAIL" "CLOUDFLARE_API_TOKEN" \
              "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD" "PIHOLE_PASSWORD" \
              "TRAEFIK_USER" "TRAEFIK_PASSWORD")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "La variable $var no está definida en el archivo .env"
    fi
done

log_message "Todas las variables requeridas están definidas"

# Función para ejecutar comandos
exec_cmd() {
    eval "$1"
    if [ $? -ne 0 ]; then
        log_error "Error al ejecutar: $1"
    fi
}

# 1. Actualización del sistema
log_message "1. Actualizando el sistema..."
exec_cmd "sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"

# 2. Instalación y configuración de UFW
log_message "2. Instalando y configurando UFW..."
exec_cmd "sudo apt install ufw -y"
exec_cmd "sudo ufw default deny incoming"
exec_cmd "sudo ufw default allow outgoing"
exec_cmd "sudo ufw allow ssh"
exec_cmd "sudo ufw allow http"
exec_cmd "sudo ufw allow https"

# 3. Configuración de UFW para Docker
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
rm ufw_docker_config.tmp

# 4. Instalación de Docker y Docker Compose
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
log_message "6. Creando estructura de directorios para el proyecto..."
exec_cmd "sudo mkdir -p /opt/surviving-chernarus/{traefik_data,postgres_data,pihole_data/{pihole,dnsmasq.d},n8n_data,rtorrent_data/{config,downloads,session},heimdall_data,squid_data/{cache}}"
exec_cmd "sudo chown -R \$USER:\$USER /opt/surviving-chernarus"

# 7. Crear archivo .env en el directorio del proyecto
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
EOF

# 8. Crear archivo de configuración de Traefik
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

# Crear archivo traefik_dynamic.yml
cat > /opt/surviving-chernarus/traefik_data/traefik_dynamic.yml << 'EOF'

# 9. Crear archivo docker-compose.yml
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
log_message "10. Iniciando los servicios..."
exec_cmd "cd /opt/surviving-chernarus && docker compose up -d"

# 11. Verificar que los servicios están funcionando
log_message "11. Verificando que los servicios están funcionando..."
exec_cmd "docker ps"

log_message "¡Despliegue completado con éxito!"
log_message "Puedes acceder a los servicios a través de las siguientes URLs:"
log_message "- Panel de control: https://${DOMAIN_NAME}"
log_message "- Traefik Dashboard: https://traefik.${DOMAIN_NAME}"
log_message "- Pi-hole: http://pihole.${DOMAIN_NAME}/admin"
log_message "- n8n: https://n8n.${DOMAIN_NAME}"
log_message "- rTorrent: https://rtorrent.${DOMAIN_NAME}"