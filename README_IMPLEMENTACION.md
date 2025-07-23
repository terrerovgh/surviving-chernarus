# Implementación de Surviving Chernarus

Este documento proporciona instrucciones para implementar el ecosistema "Surviving Chernarus" en una Raspberry Pi 5 utilizando los scripts proporcionados.

## Descripción General

El proyecto "Surviving Chernarus" es un ecosistema de servicios auto-hospedados que se ejecutan en una Raspberry Pi 5 utilizando Docker Compose. Los servicios incluyen:

- **Traefik**: Proxy inverso y balanceador de carga con soporte SSL
- **PostgreSQL**: Base de datos relacional
- **Pi-hole**: Bloqueador de anuncios y DNS a nivel de red
- **n8n**: Plataforma de automatización de flujos de trabajo
- **rTorrent**: Cliente de BitTorrent
- **Heimdall**: Panel de control para acceder a todos los servicios

## Requisitos Previos

1. Una Raspberry Pi 5 con Raspberry Pi OS instalado
2. Conexión SSH configurada a la Raspberry Pi (idealmente mediante el alias `rpi`)
3. Dominio propio y cuenta de Cloudflare (para acceso remoto seguro)
4. Conocimientos básicos de Linux y Docker

## Scripts Disponibles

Se proporcionan cuatro scripts para facilitar la implementación:

1. **setup_env.sh**: Configura el archivo `.env` con tus valores personalizados
2. **setup_network.sh**: Configura la red en la Raspberry Pi OS con los valores del archivo `.env`
3. **deploy.sh**: Despliega el ecosistema completo en la Raspberry Pi
4. **verify_deployment.sh**: Verifica que todos los servicios estén funcionando correctamente

## Pasos para la Implementación

### 1. Configurar Variables de Entorno

Ejecuta el script de configuración para crear el archivo `.env` con tus valores personalizados:

```bash
./setup_env.sh
```

Este script te guiará a través de la configuración de todas las variables necesarias, como:

- IDs de usuario y grupo (PUID, PGID)
- Zona horaria (TZ)
- Nombre de dominio y credenciales de Cloudflare
- Credenciales de PostgreSQL
- Contraseña de Pi-hole
- Configuración de red (IP, gateway, DNS)

### 2. Configurar la Red

Una vez configurado el archivo `.env`, ejecuta el script de configuración de red como root:

```bash
sudo ./setup_network.sh
```

Este script configurará:

- El hostname de la Raspberry Pi
- La configuración de red estática para eth0
- Los servidores DNS

Después de ejecutar este script, será necesario reiniciar la Raspberry Pi para aplicar los cambios de red:

```bash
sudo reboot
```

### 3. Desplegar el Ecosistema

Una vez reiniciada la Raspberry Pi con la nueva configuración de red, ejecuta el script de despliegue:

```bash
./deploy.sh
```

Este script realizará las siguientes acciones en la Raspberry Pi:

1. Actualizar el sistema
2. Configurar el firewall (UFW)
3. Instalar Docker y Docker Compose
4. Crear la estructura de directorios necesaria
5. Configurar Traefik con SSL
6. Crear y configurar el archivo `docker-compose.yml`
7. Iniciar todos los servicios

### 4. Verificar el Despliegue

Después de que el despliegue haya finalizado, puedes verificar que todo esté funcionando correctamente:

```bash
./verify_deployment.sh
```

Este script verificará:

- La instalación de Docker y Docker Compose
- La estructura de directorios y archivos
- El estado de los contenedores
- La conectividad de red entre contenedores
- Los puertos de Traefik

## Acceso a los Servicios

Una vez desplegado, podrás acceder a los servicios a través de las siguientes URLs:

- **Panel de control**: `https://tu-dominio.com`
- **Traefik**: `https://traefik.tu-dominio.com`
- **Pi-hole**: `https://pihole.tu-dominio.com`
- **n8n**: `https://n8n.tu-dominio.com`
- **rTorrent**: `https://rtorrent.tu-dominio.com`

## Solución de Problemas

Si encuentras problemas durante la implementación:

1. Verifica los logs de los contenedores:
   ```bash
   docker logs [nombre-del-contenedor]
   ```

2. Reinicia todos los servicios:
   ```bash
   cd /opt/surviving-chernarus && docker compose restart
   ```

3. Detén todos los servicios:
   ```bash
   cd /opt/surviving-chernarus && docker compose down
   ```

4. Inicia todos los servicios:
   ```bash
   cd /opt/surviving-chernarus && docker compose up -d
   ```

## Mantenimiento

Para mantener el sistema actualizado:

1. Actualiza las imágenes de Docker:
   ```bash
   cd /opt/surviving-chernarus && docker compose pull && docker compose up -d
   ```

2. Actualiza el sistema operativo:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. Realiza copias de seguridad regulares del directorio `/opt/surviving-chernarus`

## Seguridad

Recuerda seguir estas prácticas de seguridad:

1. Mantén tu Raspberry Pi actualizada
2. Utiliza contraseñas fuertes para todos los servicios
3. Limita el acceso SSH solo a las IPs necesarias
4. Revisa regularmente los logs en busca de actividades sospechosas
5. Configura correctamente el firewall UFW

---

¡Disfruta de tu ecosistema "Surviving Chernarus" auto-hospedado!