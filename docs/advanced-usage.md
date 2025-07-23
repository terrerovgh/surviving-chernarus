# Casos de Uso Avanzados

## Expandiendo las Capacidades de Surviving Chernarus

Una vez que tengas tu ecosistema Surviving Chernarus funcionando correctamente, puedes explorar casos de uso más avanzados para aprovechar al máximo sus capacidades. Esta guía te mostrará cómo implementar escenarios de uso avanzados y expandir la funcionalidad del sistema.

## Automatización con n8n

### Monitorización del Sistema

Puedes crear flujos de trabajo en n8n para monitorizar el estado de tu sistema y recibir notificaciones cuando algo no funcione correctamente.

#### Flujo de Trabajo de Monitorización de Servicios

1. Accede a n8n en `https://n8n.tu-dominio.com`
2. Crea un nuevo flujo de trabajo
3. Añade un nodo "Cron" para ejecutar el flujo de trabajo periódicamente (por ejemplo, cada 15 minutos)
4. Añade un nodo "HTTP Request" para verificar el estado de cada servicio
5. Añade un nodo "IF" para comprobar si la respuesta es correcta
6. Añade nodos de notificación (como "Telegram", "Email" o "Webhook") para enviar alertas cuando un servicio no responda

**Ejemplo de configuración del nodo HTTP Request:**
- URL: `https://pihole.tu-dominio.com/admin/`
- Método: GET
- Autenticación: None

**Ejemplo de configuración del nodo IF:**
- Condición: `{{$node["HTTP Request"].json["statusCode"]}} !== 200`

### Respaldo Automático

Configura un flujo de trabajo para realizar respaldos automáticos de tus datos importantes.

#### Flujo de Trabajo de Respaldo

1. Crea un nuevo flujo de trabajo en n8n
2. Añade un nodo "Cron" para ejecutar el flujo de trabajo semanalmente
3. Añade un nodo "Execute Command" para ejecutar un script de respaldo
4. Añade un nodo "FTP" o "S3" para subir el respaldo a un almacenamiento externo
5. Añade un nodo de notificación para informar sobre el resultado del respaldo

**Ejemplo de script de respaldo:**
```bash
#!/bin/bash
BACKUP_DIR="/opt/surviving-chernarus/backups"
BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d).tar.gz"

mkdir -p $BACKUP_DIR

# Respaldar archivos de configuración
tar -czf $BACKUP_FILE /opt/surviving-chernarus/traefik/config /opt/surviving-chernarus/n8n/data /opt/surviving-chernarus/pihole/etc-pihole

# Respaldar base de datos
docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres pg_dump -U $SC_POSTGRES_USER $SC_POSTGRES_DB > $BACKUP_DIR/database_backup_$(date +%Y%m%d).sql
tar -rf $BACKUP_FILE $BACKUP_DIR/database_backup_$(date +%Y%m%d).sql

echo "Backup completed: $BACKUP_FILE"
```

### Integración con Servicios Externos

Utiliza n8n para integrar tu ecosistema Surviving Chernarus con servicios externos como Telegram, IFTTT, o servicios de almacenamiento en la nube.

#### Flujo de Trabajo de Notificaciones de Telegram

1. Crea un bot de Telegram usando BotFather
2. Configura las credenciales de Telegram en n8n
3. Crea un flujo de trabajo que utilice eventos del sistema como disparadores
4. Añade un nodo "Telegram" para enviar mensajes a tu chat o grupo

**Ejemplo de mensaje de Telegram:**
```
🚨 Alerta del Sistema

Servicio: {{$node["HTTP Request"].json["service"]}}
Estado: {{$node["HTTP Request"].json["status"]}}
Hora: {{$now}}
```

## Expansión del Ecosistema

### Añadir Nuevos Servicios

Puedes expandir tu ecosistema Surviving Chernarus añadiendo nuevos servicios según tus necesidades.

#### Añadir Jellyfin (Servidor de Medios)

1. Edita el archivo `docker-compose.yml`:
   ```bash
   sudo nano /opt/surviving-chernarus/docker-compose.yml
   ```

2. Añade la configuración del servicio Jellyfin:
   ```yaml
   jellyfin:
     image: jellyfin/jellyfin:latest
     container_name: jellyfin
     user: ${SC_PUID}:${SC_PGID}
     volumes:
       - /opt/surviving-chernarus/jellyfin/config:/config
       - /opt/surviving-chernarus/jellyfin/cache:/cache
       - /opt/surviving-chernarus/rtorrent/downloads:/media
     restart: unless-stopped
     networks:
       - traefik_network
     labels:
       - "traefik.enable=true"
       - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.${SC_DOMAIN_NAME}`)"
       - "traefik.http.routers.jellyfin.entrypoints=websecure"
       - "traefik.http.routers.jellyfin.tls=true"
       - "traefik.http.routers.jellyfin.tls.certresolver=cloudflare"
       - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
   ```

3. Crea los directorios necesarios:
   ```bash
   sudo mkdir -p /opt/surviving-chernarus/jellyfin/config
   sudo mkdir -p /opt/surviving-chernarus/jellyfin/cache
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/jellyfin
   ```

4. Actualiza la configuración de Traefik:
   ```bash
   sudo nano /opt/surviving-chernarus/traefik/config/dynamic_conf.yml
   ```
   Añade la configuración para Jellyfin.

5. Inicia el nuevo servicio:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d jellyfin
   ```

#### Añadir Navidrome (Servidor de Música)

1. Edita el archivo `docker-compose.yml`:
   ```bash
   sudo nano /opt/surviving-chernarus/docker-compose.yml
   ```

2. Añade la configuración del servicio Navidrome:
   ```yaml
   navidrome:
     image: deluan/navidrome:latest
     container_name: navidrome
     user: ${SC_PUID}:${SC_PGID}
     volumes:
       - /opt/surviving-chernarus/navidrome/data:/data
       - /opt/surviving-chernarus/navidrome/music:/music
     environment:
       - ND_SCANSCHEDULE=1h
       - ND_LOGLEVEL=info
     restart: unless-stopped
     networks:
       - traefik_network
     labels:
       - "traefik.enable=true"
       - "traefik.http.routers.navidrome.rule=Host(`music.${SC_DOMAIN_NAME}`)"
       - "traefik.http.routers.navidrome.entrypoints=websecure"
       - "traefik.http.routers.navidrome.tls=true"
       - "traefik.http.routers.navidrome.tls.certresolver=cloudflare"
       - "traefik.http.services.navidrome.loadbalancer.server.port=4533"
   ```

3. Crea los directorios necesarios:
   ```bash
   sudo mkdir -p /opt/surviving-chernarus/navidrome/data
   sudo mkdir -p /opt/surviving-chernarus/navidrome/music
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/navidrome
   ```

4. Inicia el nuevo servicio:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d navidrome
   ```

### Integración con Home Assistant

Si utilizas Home Assistant para la automatización del hogar, puedes integrarlo con tu ecosistema Surviving Chernarus.

1. Añade Home Assistant a tu `docker-compose.yml`:
   ```yaml
   homeassistant:
     image: ghcr.io/home-assistant/home-assistant:stable
     container_name: homeassistant
     volumes:
       - /opt/surviving-chernarus/homeassistant:/config
       - /etc/localtime:/etc/localtime:ro
     restart: unless-stopped
     privileged: true
     networks:
       - traefik_network
     labels:
       - "traefik.enable=true"
       - "traefik.http.routers.homeassistant.rule=Host(`ha.${SC_DOMAIN_NAME}`)"
       - "traefik.http.routers.homeassistant.entrypoints=websecure"
       - "traefik.http.routers.homeassistant.tls=true"
       - "traefik.http.routers.homeassistant.tls.certresolver=cloudflare"
       - "traefik.http.services.homeassistant.loadbalancer.server.port=8123"
   ```

2. Crea el directorio de configuración:
   ```bash
   sudo mkdir -p /opt/surviving-chernarus/homeassistant
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/homeassistant
   ```

3. Inicia Home Assistant:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d homeassistant
   ```

4. Configura la integración con n8n utilizando webhooks.

## Optimización del Sistema

### Mejora del Rendimiento

Para mejorar el rendimiento de tu ecosistema Surviving Chernarus, puedes realizar varias optimizaciones.

#### Optimización de la Memoria Swap

1. Crea un archivo swap si no tienes suficiente RAM:
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

2. Haz el swap permanente:
   ```bash
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

#### Ajuste de Parámetros del Sistema

1. Optimiza los parámetros del sistema para mejorar el rendimiento:
   ```bash
   sudo nano /etc/sysctl.conf
   ```

2. Añade o modifica las siguientes líneas:
   ```
   vm.swappiness=10
   vm.vfs_cache_pressure=50
   ```

3. Aplica los cambios:
   ```bash
   sudo sysctl -p
   ```

### Optimización de Docker

1. Configura el daemon de Docker para un mejor rendimiento:
   ```bash
   sudo nano /etc/docker/daemon.json
   ```

2. Añade o modifica el archivo con la siguiente configuración:
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     },
     "storage-driver": "overlay2"
   }
   ```

3. Reinicia Docker:
   ```bash
   sudo systemctl restart docker
   ```

## Seguridad Avanzada

### Configuración de Fail2ban

Instala y configura Fail2ban para proteger tu sistema contra intentos de acceso no autorizados.

1. Instala Fail2ban:
   ```bash
   sudo apt install -y fail2ban
   ```

2. Crea una configuración personalizada:
   ```bash
   sudo nano /etc/fail2ban/jail.local
   ```

3. Añade la siguiente configuración:
   ```
   [DEFAULT]
   bantime = 1h
   findtime = 10m
   maxretry = 5

   [sshd]
   enabled = true
   port = ssh
   filter = sshd
   logpath = /var/log/auth.log
   maxretry = 3

   [traefik-auth]
   enabled = true
   filter = traefik-auth
   logpath = /opt/surviving-chernarus/traefik/logs/access.log
   maxretry = 5
   ```

4. Crea un filtro personalizado para Traefik:
   ```bash
   sudo nano /etc/fail2ban/filter.d/traefik-auth.conf
   ```

5. Añade la siguiente configuración:
   ```
   [Definition]
   failregex = ^.*"[A-Z]+ .* HTTP/[0-9]\.[0-9]" 401.*$
   ignoreregex =
   ```

6. Reinicia Fail2ban:
   ```bash
   sudo systemctl restart fail2ban
   ```

### Configuración de Firewall UFW

Configura el firewall UFW para limitar el acceso a tu sistema.

1. Instala UFW si no está instalado:
   ```bash
   sudo apt install -y ufw
   ```

2. Configura las reglas básicas:
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow ssh
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

3. Si utilizas el punto de acceso Wi-Fi, permite el tráfico en la interfaz correspondiente:
   ```bash
   sudo ufw allow in on $SC_HOTSPOT_INTERFACE
   ```

4. Habilita el firewall:
   ```bash
   sudo ufw enable
   ```

## Escenarios de Uso Específicos

### Modo Viajero

Configura tu ecosistema Surviving Chernarus para un uso óptimo mientras viajas.

#### Configuración de VPN para Acceso Remoto

1. Añade WireGuard a tu `docker-compose.yml`:
   ```yaml
   wireguard:
     image: linuxserver/wireguard:latest
     container_name: wireguard
     cap_add:
       - NET_ADMIN
       - SYS_MODULE
     environment:
       - PUID=${SC_PUID}
       - PGID=${SC_PGID}
       - TZ=${SC_TZ}
       - SERVERURL=${SC_DOMAIN_NAME}
       - SERVERPORT=51820
       - PEERS=3
       - PEERDNS=auto
       - INTERNAL_SUBNET=10.13.13.0
     volumes:
       - /opt/surviving-chernarus/wireguard:/config
       - /lib/modules:/lib/modules
     ports:
       - 51820:51820/udp
     sysctls:
       - net.ipv4.conf.all.src_valid_mark=1
     restart: unless-stopped
     networks:
       - traefik_network
   ```

2. Crea el directorio de configuración:
   ```bash
   sudo mkdir -p /opt/surviving-chernarus/wireguard
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/wireguard
   ```

3. Inicia WireGuard:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d wireguard
   ```

4. Configura tu router para reenviar el puerto 51820/UDP a tu Raspberry Pi.

5. Utiliza los archivos de configuración generados en `/opt/surviving-chernarus/wireguard/config/peer1` para configurar clientes WireGuard en tus dispositivos.

### Modo Desconectado

Configura tu ecosistema para funcionar sin conexión a Internet.

#### Configuración de DNS Local

1. Edita la configuración de Pi-hole para resolver nombres de dominio localmente:
   ```bash
   sudo nano /opt/surviving-chernarus/pihole/etc-dnsmasq.d/02-custom.conf
   ```

2. Añade entradas para tus servicios locales:
   ```
   address=/tu-dominio.com/192.168.4.1
   address=/traefik.tu-dominio.com/192.168.4.1
   address=/pihole.tu-dominio.com/192.168.4.1
   address=/n8n.tu-dominio.com/192.168.4.1
   address=/rtorrent.tu-dominio.com/192.168.4.1
   ```

3. Reinicia Pi-hole:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart pihole
   ```

#### Configuración de Certificados Autofirmados

Para entornos sin conexión, puedes utilizar certificados autofirmados en lugar de Let's Encrypt.

1. Genera un certificado autofirmado:
   ```bash
   mkdir -p /opt/surviving-chernarus/traefik/certs
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/surviving-chernarus/traefik/certs/key.pem -out /opt/surviving-chernarus/traefik/certs/cert.pem -subj "/CN=*.tu-dominio.com"
   ```

2. Edita la configuración de Traefik para utilizar el certificado autofirmado:
   ```bash
   sudo nano /opt/surviving-chernarus/traefik/config/traefik.yml
   ```

3. Modifica la sección de certificados:
   ```yaml
   tls:
     certificates:
       - certFile: /certs/cert.pem
         keyFile: /certs/key.pem
   ```

4. Reinicia Traefik:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart traefik
   ```

## Contribución al Proyecto

### Desarrollo Local

Si deseas contribuir al desarrollo del proyecto Surviving Chernarus, puedes configurar un entorno de desarrollo local.

1. Clona el repositorio:
   ```bash
   git clone https://github.com/tuusuario/surviving-chernarus.git
   cd surviving-chernarus
   ```

2. Realiza tus modificaciones y pruébalas en tu entorno local.

3. Envía un pull request con tus cambios al repositorio principal.

### Informes de Errores y Sugerencias

Si encuentras errores o tienes sugerencias para mejorar el proyecto:

1. Abre un issue en el [repositorio de GitHub](https://github.com/tuusuario/surviving-chernarus/issues).
2. Describe detalladamente el problema o la sugerencia.
3. Incluye capturas de pantalla o registros si es relevante.

## Próximos Pasos

Ahora que has explorado los casos de uso avanzados de Surviving Chernarus, puedes consultar la [Guía de Referencia](reference.md) para obtener información detallada sobre todos los componentes y configuraciones del sistema.