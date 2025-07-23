# Surviving Chernarus

## Descripción

Surviving Chernarus es un ecosistema de servicios auto-hospedados diseñado para ser desplegado en una Raspberry Pi utilizando Raspberry Pi OS. El proyecto utiliza Docker y Docker Compose para crear un entorno completo con varios servicios útiles para la gestión de medios, automatización y monitoreo.

## Servicios Incluidos

- **Traefik**: Proxy inverso y balanceador de carga que gestiona el acceso a todos los servicios.
- **PostgreSQL**: Base de datos relacional para almacenar datos de aplicaciones.
- **Pi-hole**: Bloqueador de anuncios a nivel de red.
- **n8n**: Plataforma de automatización de flujos de trabajo.
- **rTorrent**: Cliente de BitTorrent para descargas.
- **Heimdall**: Panel de control para acceder a todos los servicios.

## Requisitos

- Raspberry Pi (recomendado modelo 4 con al menos 4GB de RAM)
- Raspberry Pi OS instalado
- Conexión a Internet
- Dominio configurado con Cloudflare (opcional, pero recomendado para acceso remoto)

## Scripts Disponibles

1. **setup_env.sh**: Configura las variables de entorno necesarias para el despliegue.
2. **setup_network.sh**: Configura la red en la Raspberry Pi con los valores proporcionados.
3. **deploy.sh**: Despliega todos los servicios en la Raspberry Pi.
4. **verify_deployment.sh**: Verifica que todos los servicios estén funcionando correctamente.

## Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/surviving-chernarus.git
cd surviving-chernarus
```

### 2. Configurar Variables de Entorno

```bash
./setup_env.sh
```

Este script te pedirá información como:
- PUID y PGID para los contenedores
- Zona horaria
- Nombre de dominio
- Credenciales de Cloudflare (opcional)
- Credenciales de PostgreSQL
- Contraseña para Pi-hole
- Usuario y contraseña para Traefik Dashboard

### 3. Configurar la Red

```bash
sudo ./setup_network.sh
```

Este script configurará:
- El nombre de host
- El archivo /etc/hosts
- La configuración de red para eth0
- Los servidores DNS

**Nota**: Después de ejecutar este script, es necesario reiniciar la Raspberry Pi.

### 4. Desplegar los Servicios

```bash
./deploy.sh
```

Este script realizará las siguientes acciones:
1. Actualizar el sistema
2. Configurar UFW (firewall)
3. Instalar Docker y Docker Compose
4. Crear la estructura de directorios
5. Configurar Traefik
6. Desplegar todos los servicios con Docker Compose

### 5. Verificar el Despliegue

```bash
./verify_deployment.sh
```

Este script verificará que todos los servicios estén funcionando correctamente.

## Acceso a los Servicios

Una vez desplegado, puedes acceder a los servicios a través de las siguientes URLs:

- Panel de control: `https://tu-dominio.com`
- Traefik Dashboard: `https://traefik.tu-dominio.com`
- Pi-hole: `https://pihole.tu-dominio.com`
- n8n: `https://n8n.tu-dominio.com`
- rTorrent: `https://rtorrent.tu-dominio.com`

## Mantenimiento

### Actualizar los Servicios

```bash
cd /opt/surviving-chernarus
docker compose pull
docker compose up -d
```

### Actualizar el Sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### Realizar Copias de Seguridad

Es recomendable realizar copias de seguridad regulares del directorio `/opt/surviving-chernarus`.

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

## Seguridad

- Cambia regularmente las contraseñas de los servicios
- Mantén el sistema actualizado
- Utiliza HTTPS para todas las conexiones
- Configura correctamente el firewall (UFW)

## Licencia

Este proyecto está licenciado bajo la licencia MIT.