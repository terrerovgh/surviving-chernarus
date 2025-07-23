# Guía de Referencia

## Referencia Completa del Ecosistema Surviving Chernarus

Esta guía de referencia proporciona información detallada sobre todos los componentes, configuraciones y parámetros del ecosistema Surviving Chernarus. Utiliza esta guía como un recurso completo para entender y personalizar tu instalación.

## Estructura del Proyecto

### Directorios Principales

```
/opt/surviving-chernarus/
├── docker-compose.yml      # Configuración principal de Docker Compose
├── .env                    # Variables de entorno
├── deploy.sh               # Script de despliegue unificado
├── traefik/                # Configuración y datos de Traefik
│   ├── config/             # Archivos de configuración
│   │   ├── traefik.yml     # Configuración principal
│   │   └── dynamic_conf.yml # Configuración dinámica
│   ├── data/               # Datos persistentes
│   └── logs/               # Archivos de registro
├── pihole/                 # Configuración y datos de Pi-hole
│   ├── etc-pihole/         # Configuración principal
│   └── etc-dnsmasq.d/      # Configuración de DNS
├── n8n/                    # Configuración y datos de n8n
│   └── data/               # Datos persistentes
├── postgres/               # Datos de PostgreSQL
│   └── data/               # Datos persistentes
├── rtorrent/               # Configuración y datos de rTorrent
│   ├── config/             # Archivos de configuración
│   └── downloads/          # Directorio de descargas
└── dashboard/              # Panel de control
    └── html/               # Archivos HTML, CSS y JavaScript
```

## Variables de Entorno

El archivo `.env` contiene todas las variables de entorno utilizadas por los servicios. A continuación se detallan todas las variables disponibles:

| Variable | Descripción | Valor Predeterminado | Obligatorio |
|----------|-------------|----------------------|-------------|
| `SC_PROJECT_PATH` | Ruta de instalación del proyecto | `/opt/surviving-chernarus` | Sí |
| `SC_USER` | Usuario del sistema para permisos | `$(whoami)` | Sí |
| `SC_PUID` | ID de usuario para contenedores | `$(id -u $SC_USER)` | Sí |
| `SC_PGID` | ID de grupo para contenedores | `$(id -g $SC_USER)` | Sí |
| `SC_TZ` | Zona horaria | `America/New_York` | Sí |
| `SC_DOMAIN_NAME` | Nombre de dominio principal | - | Sí |
| `SC_CLOUDFLARE_EMAIL` | Email de Cloudflare | - | Sí |
| `SC_CLOUDFLARE_API_TOKEN` | Token de API de Cloudflare | - | Sí |
| `SC_POSTGRES_DB` | Nombre de la base de datos | `n8n_db` | Sí |
| `SC_POSTGRES_USER` | Usuario de PostgreSQL | `n8n_user` | Sí |
| `SC_POSTGRES_PASSWORD` | Contraseña de PostgreSQL | - | Sí |
| `SC_PIHOLE_PASSWORD` | Contraseña de Pi-hole | - | Sí |
| `SC_HOTSPOT_INTERFACE` | Interfaz para el punto de acceso | `wlan1` | No |
| `SC_INTERNET_INTERFACE` | Interfaz para conexión a Internet | `eth0` | No |
| `SC_HOTSPOT_SSID` | SSID del punto de acceso | `SurvivingChernarus` | No |
| `SC_HOTSPOT_PASSWORD` | Contraseña del punto de acceso | - | No |
| `SC_N8N_BASIC_AUTH_USER` | Usuario para autenticación de n8n | `admin` | No |
| `SC_N8N_BASIC_AUTH_PASSWORD` | Contraseña para autenticación de n8n | - | No |
| `SC_RTORRENT_AUTH_USER` | Usuario para autenticación de rTorrent | `admin` | No |
| `SC_RTORRENT_AUTH_PASSWORD` | Contraseña para autenticación de rTorrent | - | No |

## Servicios

### Traefik

Traefik es un proxy inverso moderno y enrutador HTTP que gestiona el tráfico hacia todos los servicios.

#### Configuración Principal

Archivo: `/opt/surviving-chernarus/traefik/config/traefik.yml`

```yaml
api:
  dashboard: true
  insecure: false

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
  file:
    filename: /etc/traefik/dynamic_conf.yml

certificatesResolvers:
  cloudflare:
    acme:
      email: ${SC_CLOUDFLARE_EMAIL}
      storage: /etc/traefik/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"

log:
  level: INFO
```

#### Configuración Dinámica

Archivo: `/opt/surviving-chernarus/traefik/config/dynamic_conf.yml`

```yaml
http:
  middlewares:
    secureHeaders:
      headers:
        sslRedirect: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
    basicAuth:
      basicAuth:
        users:
          - "admin:$apr1$ruca84Hq$mbjdMZBAG.KWn7vfN/SNK/"

  routers:
    dashboard:
      rule: "Host(`traefik.${SC_DOMAIN_NAME}`)"
      service: api@internal
      entryPoints:
        - websecure
      middlewares:
        - secureHeaders
        - basicAuth
      tls:
        certResolver: cloudflare
```

### Pi-hole

Pi-hole es un bloqueador de anuncios y rastreadores a nivel de red que funciona como servidor DNS.

#### Configuración Principal

La configuración principal de Pi-hole se gestiona a través de su interfaz web en `https://pihole.tu-dominio.com/admin/`.

#### Configuración Personalizada de DNS

Archivo: `/opt/surviving-chernarus/pihole/etc-dnsmasq.d/02-custom.conf`

```
# Ejemplo de configuración personalizada
server=/local/192.168.4.1
address=/example.com/192.168.4.1
```

### n8n

n8n es una plataforma de automatización de flujos de trabajo que permite conectar diferentes servicios y APIs.

#### Variables de Entorno

| Variable | Descripción | Valor Predeterminado |
|----------|-------------|----------------------|
| `N8N_BASIC_AUTH_ACTIVE` | Activar autenticación básica | `true` |
| `N8N_BASIC_AUTH_USER` | Usuario para autenticación | `${SC_N8N_BASIC_AUTH_USER}` |
| `N8N_BASIC_AUTH_PASSWORD` | Contraseña para autenticación | `${SC_N8N_BASIC_AUTH_PASSWORD}` |
| `N8N_HOST` | Host para acceso externo | `n8n.${SC_DOMAIN_NAME}` |
| `N8N_PROTOCOL` | Protocolo para acceso externo | `https` |
| `N8N_PORT` | Puerto para acceso externo | `443` |
| `N8N_ENCRYPTION_KEY` | Clave de cifrado | Generada automáticamente |
| `WEBHOOK_URL` | URL para webhooks | `https://n8n.${SC_DOMAIN_NAME}/` |
| `DB_TYPE` | Tipo de base de datos | `postgresdb` |
| `DB_POSTGRESDB_HOST` | Host de PostgreSQL | `postgres` |
| `DB_POSTGRESDB_PORT` | Puerto de PostgreSQL | `5432` |
| `DB_POSTGRESDB_DATABASE` | Nombre de la base de datos | `${SC_POSTGRES_DB}` |
| `DB_POSTGRESDB_USER` | Usuario de PostgreSQL | `${SC_POSTGRES_USER}` |
| `DB_POSTGRESDB_PASSWORD` | Contraseña de PostgreSQL | `${SC_POSTGRES_PASSWORD}` |

### PostgreSQL

PostgreSQL es un sistema de gestión de bases de datos relacional utilizado por n8n y otros servicios.

#### Variables de Entorno

| Variable | Descripción | Valor Predeterminado |
|----------|-------------|----------------------|
| `POSTGRES_DB` | Nombre de la base de datos | `${SC_POSTGRES_DB}` |
| `POSTGRES_USER` | Usuario de PostgreSQL | `${SC_POSTGRES_USER}` |
| `POSTGRES_PASSWORD` | Contraseña de PostgreSQL | `${SC_POSTGRES_PASSWORD}` |

### rTorrent

rTorrent con la interfaz Flood proporciona capacidades de descarga de torrents.

#### Configuración Principal

Archivo: `/opt/surviving-chernarus/rtorrent/config/.rtorrent.rc`

```
# Configuración básica de rTorrent
directory.default.set = /downloads/incomplete
session.directory.set = /config/rtorrent/session
protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

# Configuración de red
network.port_range.set = 50000-50000
network.port_random.set = no
dht.mode.set = auto
protocol.pex.set = yes
trackers.use_udp.set = yes

# Configuración de rendimiento
pieces.memory.max.set = 1024M
network.max_open_files.set = 1024
network.http.max_open.set = 512
network.xmlrpc.size_limit.set = 4M

# Configuración de velocidad
throttle.global_down.max_rate.set = 0
throttle.global_up.max_rate.set = 0

# Configuración de archivos
system.file.allocate.set = 1
pieces.hash.on_completion.set = yes

# Configuración de la interfaz XMLRPC para Flood
network.scgi.open_local = /tmp/rpc.sock
execute.nothrow = chmod,"g+w,o=",/tmp/rpc.sock

# Al completar una descarga, moverla a la carpeta de completados
method.insert = d.data_path, simple, "if=(d.is_multi_file), (cat,(d.directory),/), (cat,(d.directory),/,(d.name))"
method.insert = d.move_to_complete, simple, "d.directory.set=/downloads/complete; execute=mkdir,-p,$d.directory=; execute=mv,-u,$d.data_path=,$d.directory="
method.set_key = event.download.finished,move_complete,"d.move_to_complete="
```

#### Variables de Entorno para Flood

| Variable | Descripción | Valor Predeterminado |
|----------|-------------|----------------------|
| `FLOOD_OPTION_rundir` | Directorio de ejecución | `/config` |
| `FLOOD_OPTION_host` | Host para la interfaz web | `0.0.0.0` |
| `FLOOD_OPTION_port` | Puerto para la interfaz web | `3000` |
| `FLOOD_OPTION_maxHistoryStates` | Estados máximos de historial | `30` |
| `FLOOD_OPTION_secret` | Secreto para sesiones | Generado automáticamente |
| `FLOOD_OPTION_auth` | Tipo de autenticación | `none` |
| `FLOOD_OPTION_rtsocket` | Socket de rTorrent | `/tmp/rpc.sock` |

## Punto de Acceso Wi-Fi

### Configuración de hostapd

Archivo: `/etc/hostapd/hostapd.conf`

```
interface=${SC_HOTSPOT_INTERFACE}
driver=nl80211
ssid=${SC_HOTSPOT_SSID}
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=${SC_HOTSPOT_PASSWORD}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

### Configuración de dnsmasq

Archivo: `/etc/dnsmasq.conf`

```
interface=${SC_HOTSPOT_INTERFACE}
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
domain=local
address=/gw.local/192.168.4.1
```

## Script de Despliegue

El script `deploy.sh` es el componente central que gestiona la instalación y configuración de todo el ecosistema Surviving Chernarus.

### Opciones de Línea de Comandos

| Opción | Descripción |
|--------|-------------|
| `--help` | Muestra la ayuda |
| `--verbose` | Muestra información detallada durante la ejecución |
| `--config-env` | Configura solo las variables de entorno |
| `--config-network` | Configura solo la red |
| `--deploy` | Despliega solo los servicios |
| `--update` | Actualiza los servicios existentes |
| `--restart` | Reinicia los servicios |
| `--stop` | Detiene los servicios |
| `--status` | Muestra el estado de los servicios |
| `--backup` | Realiza un respaldo del sistema |
| `--restore <archivo>` | Restaura un respaldo |

### Funciones Principales

#### Configuración de Variables de Entorno

```bash
configure_env() {
  echo "Configurando variables de entorno..."
  
  # Crear directorio del proyecto si no existe
  mkdir -p "$SC_PROJECT_PATH"
  
  # Crear archivo .env si no existe
  if [ ! -f "$SC_PROJECT_PATH/.env" ]; then
    cat > "$SC_PROJECT_PATH/.env" << EOL
SC_PROJECT_PATH=$SC_PROJECT_PATH
SC_USER=$SC_USER
SC_PUID=$SC_PUID
SC_PGID=$SC_PGID
SC_TZ=$SC_TZ
SC_DOMAIN_NAME=$SC_DOMAIN_NAME
SC_CLOUDFLARE_EMAIL=$SC_CLOUDFLARE_EMAIL
SC_CLOUDFLARE_API_TOKEN=$SC_CLOUDFLARE_API_TOKEN
SC_POSTGRES_DB=$SC_POSTGRES_DB
SC_POSTGRES_USER=$SC_POSTGRES_USER
SC_POSTGRES_PASSWORD=$SC_POSTGRES_PASSWORD
SC_PIHOLE_PASSWORD=$SC_PIHOLE_PASSWORD
SC_HOTSPOT_INTERFACE=$SC_HOTSPOT_INTERFACE
SC_INTERNET_INTERFACE=$SC_INTERNET_INTERFACE
SC_HOTSPOT_SSID=$SC_HOTSPOT_SSID
SC_HOTSPOT_PASSWORD=$SC_HOTSPOT_PASSWORD
SC_N8N_BASIC_AUTH_USER=$SC_N8N_BASIC_AUTH_USER
SC_N8N_BASIC_AUTH_PASSWORD=$SC_N8N_BASIC_AUTH_PASSWORD
SC_RTORRENT_AUTH_USER=$SC_RTORRENT_AUTH_USER
SC_RTORRENT_AUTH_PASSWORD=$SC_RTORRENT_AUTH_PASSWORD
EOL
  else
    echo "El archivo .env ya existe. Omitiendo la creación."
  fi
}
```

#### Configuración de Red

```bash
configure_network() {
  echo "Configurando red..."
  
  # Verificar si se debe configurar el punto de acceso Wi-Fi
  if [ -n "$SC_HOTSPOT_INTERFACE" ] && [ -n "$SC_HOTSPOT_SSID" ] && [ -n "$SC_HOTSPOT_PASSWORD" ]; then
    echo "Configurando punto de acceso Wi-Fi..."
    
    # Instalar paquetes necesarios
    apt update
    apt install -y hostapd dnsmasq
    
    # Detener servicios para configurarlos
    systemctl stop hostapd
    systemctl stop dnsmasq
    
    # Configurar IP estática para la interfaz del punto de acceso
    cat > /etc/network/interfaces.d/hotspot << EOL
allow-hotplug $SC_HOTSPOT_INTERFACE
iface $SC_HOTSPOT_INTERFACE inet static
  address 192.168.4.1
  netmask 255.255.255.0
  network 192.168.4.0
  broadcast 192.168.4.255
EOL
    
    # Configurar hostapd
    cat > /etc/hostapd/hostapd.conf << EOL
interface=$SC_HOTSPOT_INTERFACE
driver=nl80211
ssid=$SC_HOTSPOT_SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$SC_HOTSPOT_PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL
    
    # Configurar dnsmasq
    cat > /etc/dnsmasq.conf << EOL
interface=$SC_HOTSPOT_INTERFACE
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
domain=local
address=/gw.local/192.168.4.1
EOL
    
    # Habilitar IP forwarding
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ip-forward.conf
    sysctl -p /etc/sysctl.d/99-ip-forward.conf
    
    # Configurar NAT
    iptables -t nat -A POSTROUTING -o $SC_INTERNET_INTERFACE -j MASQUERADE
    iptables -A FORWARD -i $SC_HOTSPOT_INTERFACE -o $SC_INTERNET_INTERFACE -j ACCEPT
    iptables -A FORWARD -i $SC_INTERNET_INTERFACE -o $SC_HOTSPOT_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    # Guardar reglas de iptables
    apt install -y iptables-persistent
    netfilter-persistent save
    
    # Habilitar y iniciar servicios
    systemctl unmask hostapd
    systemctl enable hostapd
    systemctl enable dnsmasq
    systemctl start hostapd
    systemctl start dnsmasq
    
    echo "Punto de acceso Wi-Fi configurado correctamente."
  else
    echo "No se configuró el punto de acceso Wi-Fi. Faltan parámetros necesarios."
  fi
}
```

#### Despliegue de Servicios

```bash
deploy_services() {
  echo "Desplegando servicios..."
  
  # Crear estructura de directorios
  mkdir -p "$SC_PROJECT_PATH/traefik/config"
  mkdir -p "$SC_PROJECT_PATH/traefik/data"
  mkdir -p "$SC_PROJECT_PATH/traefik/logs"
  mkdir -p "$SC_PROJECT_PATH/pihole/etc-pihole"
  mkdir -p "$SC_PROJECT_PATH/pihole/etc-dnsmasq.d"
  mkdir -p "$SC_PROJECT_PATH/n8n/data"
  mkdir -p "$SC_PROJECT_PATH/postgres/data"
  mkdir -p "$SC_PROJECT_PATH/rtorrent/config"
  mkdir -p "$SC_PROJECT_PATH/rtorrent/downloads/incomplete"
  mkdir -p "$SC_PROJECT_PATH/rtorrent/downloads/complete"
  mkdir -p "$SC_PROJECT_PATH/dashboard/html"
  
  # Configurar permisos
  chown -R "$SC_PUID:$SC_PGID" "$SC_PROJECT_PATH"
  
  # Crear configuración de Traefik
  cat > "$SC_PROJECT_PATH/traefik/config/traefik.yml" << EOL
api:
  dashboard: true
  insecure: false

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
  file:
    filename: /etc/traefik/dynamic_conf.yml

certificatesResolvers:
  cloudflare:
    acme:
      email: \${SC_CLOUDFLARE_EMAIL}
      storage: /etc/traefik/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"

log:
  level: INFO
EOL
  
  # Crear configuración dinámica de Traefik
  cat > "$SC_PROJECT_PATH/traefik/config/dynamic_conf.yml" << EOL
http:
  middlewares:
    secureHeaders:
      headers:
        sslRedirect: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
    basicAuth:
      basicAuth:
        users:
          - "admin:$apr1$ruca84Hq$mbjdMZBAG.KWn7vfN/SNK/"

  routers:
    dashboard:
      rule: "Host(\`traefik.\${SC_DOMAIN_NAME}\`)"
      service: api@internal
      entryPoints:
        - websecure
      middlewares:
        - secureHeaders
        - basicAuth
      tls:
        certResolver: cloudflare
EOL
  
  # Crear docker-compose.yml
  cat > "$SC_PROJECT_PATH/docker-compose.yml" << EOL
version: '3'

services:
  traefik:
    image: traefik:v2.9
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/config/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/config/dynamic_conf.yml:/etc/traefik/dynamic_conf.yml:ro
      - ./traefik/data:/etc/traefik
      - ./traefik/logs:/logs
    environment:
      - CF_API_EMAIL=\${SC_CLOUDFLARE_EMAIL}
      - CF_API_KEY=\${SC_CLOUDFLARE_API_TOKEN}
    networks:
      - traefik_network

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    environment:
      - TZ=\${SC_TZ}
      - WEBPASSWORD=\${SC_PIHOLE_PASSWORD}
      - SERVERIP=127.0.0.1
      - DNS1=1.1.1.1
      - DNS2=1.0.0.1
    volumes:
      - ./pihole/etc-pihole:/etc/pihole
      - ./pihole/etc-dnsmasq.d:/etc/dnsmasq.d
    networks:
      - traefik_network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole.rule=Host(\`pihole.\${SC_DOMAIN_NAME}\`)"
      - "traefik.http.routers.pihole.entrypoints=websecure"
      - "traefik.http.routers.pihole.tls=true"
      - "traefik.http.routers.pihole.tls.certresolver=cloudflare"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"

  postgres:
    image: postgres:13
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=\${SC_POSTGRES_DB}
      - POSTGRES_USER=\${SC_POSTGRES_USER}
      - POSTGRES_PASSWORD=\${SC_POSTGRES_PASSWORD}
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
    networks:
      - traefik_network

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=\${SC_N8N_BASIC_AUTH_USER:-admin}
      - N8N_BASIC_AUTH_PASSWORD=\${SC_N8N_BASIC_AUTH_PASSWORD:-\${SC_POSTGRES_PASSWORD}}
      - N8N_HOST=n8n.\${SC_DOMAIN_NAME}
      - N8N_PROTOCOL=https
      - N8N_PORT=443
      - N8N_ENCRYPTION_KEY=\${SC_N8N_ENCRYPTION_KEY:-a_random_n8n_encryption_key}
      - WEBHOOK_URL=https://n8n.\${SC_DOMAIN_NAME}/
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=\${SC_POSTGRES_DB}
      - DB_POSTGRESDB_USER=\${SC_POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=\${SC_POSTGRES_PASSWORD}
    volumes:
      - ./n8n/data:/home/node/.n8n
    networks:
      - traefik_network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(\`n8n.\${SC_DOMAIN_NAME}\`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls=true"
      - "traefik.http.routers.n8n.tls.certresolver=cloudflare"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"
    depends_on:
      - postgres

  rtorrent:
    image: jesec/rtorrent-flood:latest
    container_name: rtorrent
    restart: unless-stopped
    environment:
      - PUID=\${SC_PUID}
      - PGID=\${SC_PGID}
      - TZ=\${SC_TZ}
      - FLOOD_OPTION_rundir=/config
      - FLOOD_OPTION_host=0.0.0.0
      - FLOOD_OPTION_port=3000
      - FLOOD_OPTION_maxHistoryStates=30
      - FLOOD_OPTION_secret=\${SC_RTORRENT_SECRET:-a_random_flood_secret}
      - FLOOD_OPTION_auth=none
      - FLOOD_OPTION_rtsocket=/tmp/rpc.sock
    volumes:
      - ./rtorrent/config:/config
      - ./rtorrent/downloads:/downloads
    networks:
      - traefik_network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.rtorrent.rule=Host(\`rtorrent.\${SC_DOMAIN_NAME}\`)"
      - "traefik.http.routers.rtorrent.entrypoints=websecure"
      - "traefik.http.routers.rtorrent.tls=true"
      - "traefik.http.routers.rtorrent.tls.certresolver=cloudflare"
      - "traefik.http.services.rtorrent.loadbalancer.server.port=3000"

  dashboard:
    image: nginx:alpine
    container_name: dashboard
    restart: unless-stopped
    volumes:
      - ./dashboard/html:/usr/share/nginx/html
    networks:
      - traefik_network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(\`\${SC_DOMAIN_NAME}\`)"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.tls=true"
      - "traefik.http.routers.dashboard.tls.certresolver=cloudflare"
      - "traefik.http.services.dashboard.loadbalancer.server.port=80"

networks:
  traefik_network:
    driver: bridge
EOL
  
  # Crear página de inicio del panel de control
  cat > "$SC_PROJECT_PATH/dashboard/html/index.html" << EOL
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Surviving Chernarus - Panel de Control</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #f5f5f5;
      color: #333;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }
    header {
      background-color: #2c3e50;
      color: white;
      padding: 20px 0;
      text-align: center;
    }
    h1 {
      margin: 0;
      font-size: 2.5em;
    }
    .subtitle {
      font-style: italic;
      margin-top: 10px;
    }
    .services {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 20px;
      margin-top: 30px;
    }
    .service-card {
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      overflow: hidden;
      transition: transform 0.3s ease;
    }
    .service-card:hover {
      transform: translateY(-5px);
    }
    .service-header {
      background-color: #3498db;
      color: white;
      padding: 15px;
      font-size: 1.2em;
      font-weight: bold;
    }
    .service-body {
      padding: 15px;
    }
    .service-description {
      margin-bottom: 15px;
      color: #555;
    }
    .service-link {
      display: inline-block;
      background-color: #2c3e50;
      color: white;
      text-decoration: none;
      padding: 10px 15px;
      border-radius: 4px;
      transition: background-color 0.3s ease;
    }
    .service-link:hover {
      background-color: #1a252f;
    }
    .status {
      margin-top: 30px;
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      padding: 20px;
    }
    .status h2 {
      margin-top: 0;
      color: #2c3e50;
    }
    .status-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 15px;
    }
    .status-item {
      display: flex;
      align-items: center;
    }
    .status-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      margin-right: 10px;
    }
    .online {
      background-color: #2ecc71;
    }
    .offline {
      background-color: #e74c3c;
    }
    footer {
      margin-top: 40px;
      text-align: center;
      color: #7f8c8d;
      font-size: 0.9em;
    }
    @media (max-width: 768px) {
      .services {
        grid-template-columns: 1fr;
      }
      .status-grid {
        grid-template-columns: 1fr 1fr;
      }
    }
  </style>
</head>
<body>
  <header>
    <div class="container">
      <h1>Surviving Chernarus</h1>
      <div class="subtitle">Ecosistema de Servicios Autónomo</div>
    </div>
  </header>
  
  <div class="container">
    <div class="services">
      <div class="service-card">
        <div class="service-header">Traefik Dashboard</div>
        <div class="service-body">
          <div class="service-description">Panel de administración del proxy inverso Traefik.</div>
          <a href="https://traefik.${SC_DOMAIN_NAME}" class="service-link" target="_blank">Acceder</a>
        </div>
      </div>
      
      <div class="service-card">
        <div class="service-header">Pi-hole Admin</div>
        <div class="service-body">
          <div class="service-description">Administración del bloqueador de anuncios y rastreadores a nivel de red.</div>
          <a href="https://pihole.${SC_DOMAIN_NAME}/admin" class="service-link" target="_blank">Acceder</a>
        </div>
      </div>
      
      <div class="service-card">
        <div class="service-header">n8n Automation</div>
        <div class="service-body">
          <div class="service-description">Plataforma de automatización de flujos de trabajo.</div>
          <a href="https://n8n.${SC_DOMAIN_NAME}" class="service-link" target="_blank">Acceder</a>
        </div>
      </div>
      
      <div class="service-card">
        <div class="service-header">rTorrent/Flood</div>
        <div class="service-body">
          <div class="service-description">Cliente de torrents con interfaz web moderna.</div>
          <a href="https://rtorrent.${SC_DOMAIN_NAME}" class="service-link" target="_blank">Acceder</a>
        </div>
      </div>
    </div>
    
    <div class="status">
      <h2>Estado de los Servicios</h2>
      <div class="status-grid">
        <div class="status-item">
          <div class="status-indicator online" id="traefik-status"></div>
          <span>Traefik</span>
        </div>
        <div class="status-item">
          <div class="status-indicator online" id="pihole-status"></div>
          <span>Pi-hole</span>
        </div>
        <div class="status-item">
          <div class="status-indicator online" id="n8n-status"></div>
          <span>n8n</span>
        </div>
        <div class="status-item">
          <div class="status-indicator online" id="rtorrent-status"></div>
          <span>rTorrent</span>
        </div>
        <div class="status-item">
          <div class="status-indicator online" id="postgres-status"></div>
          <span>PostgreSQL</span>
        </div>
      </div>
    </div>
  </div>
  
  <footer>
    <div class="container">
      <p>Surviving Chernarus - Ecosistema de Servicios Autónomo</p>
    </div>
  </footer>
  
  <script>
    // Función para verificar el estado de los servicios
    function checkServiceStatus() {
      // En una implementación real, aquí se realizarían peticiones AJAX
      // para verificar el estado de cada servicio
      // Por ahora, simplemente simulamos el estado
      
      // Ejemplo de cómo actualizar el estado de un servicio
      // document.getElementById('traefik-status').className = 'status-indicator offline';
    }
    
    // Verificar el estado al cargar la página
    window.addEventListener('load', checkServiceStatus);
    
    // Verificar el estado cada 60 segundos
    setInterval(checkServiceStatus, 60000);
  </script>
</body>
</html>
EOL
  
  # Instalar Docker si no está instalado
  if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker "$SC_USER"
  fi
  
  # Instalar Docker Compose si no está instalado
  if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    apt install -y docker-compose-plugin
  fi
  
  # Iniciar servicios
  cd "$SC_PROJECT_PATH"
  docker compose up -d
  
  echo "Servicios desplegados correctamente."
}
```

## Comandos Útiles

### Gestión de Servicios

```bash
# Verificar estado de los servicios
docker compose -f /opt/surviving-chernarus/docker-compose.yml ps

# Ver registros de un servicio específico
docker compose -f /opt/surviving-chernarus/docker-compose.yml logs nombre_del_servicio

# Reiniciar un servicio específico
docker compose -f /opt/surviving-chernarus/docker-compose.yml restart nombre_del_servicio

# Detener todos los servicios
docker compose -f /opt/surviving-chernarus/docker-compose.yml down

# Iniciar todos los servicios
docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d
```

### Respaldo y Restauración

```bash
# Respaldar datos
rsync -avz --exclude="*.log" /opt/surviving-chernarus/ /mnt/backup/surviving-chernarus/

# Respaldar base de datos
docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres pg_dump -U $SC_POSTGRES_USER $SC_POSTGRES_DB > /mnt/backup/surviving-chernarus/database_backup_$(date +%Y%m%d).sql

# Restaurar datos
rsync -avz /mnt/backup/surviving-chernarus/ /opt/surviving-chernarus/

# Restaurar base de datos
cat /mnt/backup/surviving-chernarus/database_backup_YYYYMMDD.sql | docker compose -f /opt/surviving-chernarus/docker-compose.yml exec -T postgres psql -U $SC_POSTGRES_USER -d $SC_POSTGRES_DB
```

### Monitorización del Sistema

```bash
# Verificar uso de CPU y memoria
top

# Verificar uso de disco
df -h

# Verificar temperatura de la CPU
vcgencmd measure_temp

# Verificar puertos abiertos
netstat -tulpn
```

## Recursos Adicionales

### Documentación Oficial de los Servicios

- [Documentación de Docker](https://docs.docker.com/)
- [Documentación de Traefik](https://doc.traefik.io/traefik/)
- [Documentación de Pi-hole](https://docs.pi-hole.net/)
- [Documentación de n8n](https://docs.n8n.io/)
- [Documentación de rTorrent](https://github.com/rakshasa/rtorrent/wiki)
- [Documentación de Flood](https://github.com/jesec/flood)

### Comunidad y Soporte

- [Repositorio del Proyecto](https://github.com/tuusuario/surviving-chernarus)
- [Foro de la Comunidad](https://foro.tudominio.com)
- [Canal de Discord](https://discord.gg/tucanal)

## Glosario

| Término | Descripción |
|---------|-------------|
| **Traefik** | Proxy inverso moderno y enrutador HTTP que gestiona el tráfico hacia todos los servicios. |
| **Pi-hole** | Bloqueador de anuncios y rastreadores a nivel de red que funciona como servidor DNS. |
| **n8n** | Plataforma de automatización de flujos de trabajo que permite conectar diferentes servicios y APIs. |
| **PostgreSQL** | Sistema de gestión de bases de datos relacional utilizado por n8n y otros servicios. |
| **rTorrent** | Cliente de torrents con interfaz web moderna (Flood). |
| **Docker** | Plataforma de contenedores que permite ejecutar aplicaciones en entornos aislados. |
| **Docker Compose** | Herramienta para definir y ejecutar aplicaciones Docker multi-contenedor. |
| **Cloudflare** | Servicio de CDN y DNS que proporciona protección y certificados SSL. |
| **Let's Encrypt** | Autoridad de certificación que proporciona certificados SSL/TLS gratuitos. |
| **Punto de Acceso Wi-Fi** | Configuración que permite a la Raspberry Pi funcionar como un punto de acceso inalámbrico. |