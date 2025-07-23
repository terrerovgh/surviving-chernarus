# Guía de Despliegue: Ecosistema "Surviving Chernarus" en Raspberry Pi

Esta guía proporciona instrucciones paso a paso para desplegar el ecosistema "Surviving Chernarus" en una Raspberry Pi 5 utilizando el script automatizado `deploy.sh`.

## Requisitos Previos

1. Una Raspberry Pi 5 con Raspberry Pi OS Lite (64-bit) instalado
2. Acceso SSH a la Raspberry Pi configurado con el alias `rpi` en tu archivo `~/.ssh/config`
3. Conexión a Internet en la Raspberry Pi
4. Un dominio configurado en Cloudflare (para los certificados SSL/TLS)

## Configuración del Archivo .env

Antes de ejecutar el script de despliegue, debes configurar el archivo `.env` con tus propios valores. Este archivo contiene todas las variables de entorno necesarias para el despliegue.

1. Edita el archivo `.env` en este directorio:

```bash
nano .env
```

2. Modifica los siguientes valores según tu configuración:

   - `PUID` y `PGID`: IDs de usuario y grupo en la Raspberry Pi (obtén estos valores ejecutando `id -u` y `id -g` en la Pi)
   - `TZ`: Tu zona horaria (ej. Europe/Madrid)
   - `DOMAIN_NAME`: Tu dominio configurado en Cloudflare
   - `CLOUDFLARE_EMAIL`: Tu dirección de correo electrónico de Cloudflare
   - `CLOUDFLARE_API_TOKEN`: Tu token de API de Cloudflare con permisos de edición de DNS
   - `POSTGRES_PASSWORD`: Una contraseña segura para la base de datos PostgreSQL
   - `PIHOLE_PASSWORD`: Una contraseña segura para la interfaz web de Pi-hole
   - `TRAEFIK_USER`: Usuario para el dashboard de Traefik
   - `TRAEFIK_PASSWORD`: Contraseña para el dashboard de Traefik
   - `HASHED_PASSWORD`: Contraseña hasheada para el dashboard de Traefik (generada automáticamente con htpasswd)
   - `RPI_IP`: La dirección IP de tu Raspberry Pi en la red local

## Ejecución del Script de Despliegue

Una vez configurado el archivo `.env`, puedes ejecutar el script de despliegue:

```bash
chmod +x deploy.sh
./deploy.sh
```

El script realizará las siguientes acciones:

1. Verificar que todas las variables requeridas están definidas en el archivo `.env`
2. Conectarse a la Raspberry Pi mediante SSH
3. Actualizar el sistema operativo
4. Instalar y configurar UFW (firewall)
5. Configurar UFW para trabajar correctamente con Docker
6. Instalar Docker y Docker Compose
7. Configurar permisos de Docker
8. Crear la estructura de directorios para el proyecto
9. Transferir el archivo `.env` a la Raspberry Pi
10. Crear los archivos de configuración necesarios
11. Crear y transferir el archivo `docker-compose.yml`
12. Iniciar los servicios con Docker Compose
13. Verificar que todos los servicios están funcionando correctamente

## Acceso a los Servicios

Una vez completado el despliegue, podrás acceder a los siguientes servicios:

- **Panel de control (Heimdall)**: `https://tu-dominio.com`
- **Traefik Dashboard**: `https://traefik.tu-dominio.com`
- **Pi-hole**: `https://pihole.tu-dominio.com`
- **n8n**: `https://n8n.tu-dominio.com`
- **rTorrent**: `https://rtorrent.tu-dominio.com`

## Resolución de Problemas

Si encuentras algún problema durante el despliegue, puedes verificar los logs de Docker en la Raspberry Pi:

```bash
ssh rpi "cd /opt/surviving-chernarus && docker compose logs"
```

Para ver los logs de un servicio específico:

```bash
ssh rpi "cd /opt/surviving-chernarus && docker compose logs [nombre-del-servicio]"
```

Donde `[nombre-del-servicio]` puede ser: traefik, postgres, pihole, n8n, rtorrent, o heimdall.

## Mantenimiento

### Actualización de Servicios

Para actualizar todos los servicios a las últimas versiones disponibles:

```bash
ssh rpi "cd /opt/surviving-chernarus && docker compose pull && docker compose up -d"
```

### Copia de Seguridad

Para realizar una copia de seguridad de los datos persistentes:

```bash
ssh rpi "sudo tar -czf /home/$(whoami)/chernarus-backup-$(date +%Y%m%d).tar.gz -C /opt surviving-chernarus"
scp rpi:/home/$(ssh rpi whoami)/chernarus-backup-*.tar.gz .
```

### Restauración

Para restaurar desde una copia de seguridad:

```bash
scp chernarus-backup-YYYYMMDD.tar.gz rpi:/home/$(ssh rpi whoami)/
ssh rpi "sudo tar -xzf /home/$(whoami)/chernarus-backup-YYYYMMDD.tar.gz -C /opt"
ssh rpi "cd /opt/surviving-chernarus && docker compose up -d"
```

## Seguridad

Este despliegue incluye varias capas de seguridad:

1. Firewall UFW configurado para trabajar correctamente con Docker
2. Acceso HTTPS con certificados SSL/TLS gestionados por Traefik y Cloudflare
3. Autenticación básica para el dashboard de Traefik
4. Contraseñas seguras para todos los servicios

Se recomienda cambiar regularmente las contraseñas y mantener todos los servicios actualizados.