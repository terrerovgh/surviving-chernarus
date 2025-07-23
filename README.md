# Surviving Chernarus

## Descripción

Este proyecto proporciona un conjunto de herramientas para configurar y desplegar varios servicios en una Raspberry Pi, incluyendo Traefik, PostgreSQL, Pi-hole, n8n, rtorrent y heimdall.

## Requisitos

- Raspberry Pi (recomendado Pi 4 o superior)
- Raspberry Pi OS (64-bit recomendado)
- Conexión a Internet
- Dominio registrado en Cloudflare

## Instalación

### Instalación Manual

1. Clona el repositorio o descarga el script `deploy.sh`
2. Dale permisos de ejecución al script:

```bash
chmod +x deploy.sh
```

3. Ejecuta el script:

```bash
./deploy.sh
```

### 🚀 Instalación Automática con GitHub Actions

Este proyecto incluye CI/CD automático que despliega cambios directamente a tu Raspberry Pi:

#### Configuración Rápida:

```bash
# Configurar GitHub Actions automáticamente
./.github/setup-github-actions.sh
```

#### Configuración Manual:

1. **Generar claves SSH**:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions@surviving-chernarus"
   ssh-copy-id terrerov@rpi.terrerov.com
   ```

2. **Configurar GitHub Secrets**:
   - Ve a Settings → Secrets and variables → Actions
   - Agrega `SSH_PRIVATE_KEY` con tu clave privada

3. **Deployment Automático**:
   - Push a `main` → Deployment automático
   - Pull Request → Tests automáticos
   - Manual → Ejecutar desde GitHub Actions

📖 **Documentación completa**: [CI/CD Guide](docs/ci-cd.md)

## Uso del Script

El script proporciona un menú interactivo con las siguientes opciones:

### 1. Configurar variables de entorno (.env)

Esta opción te guiará a través de la configuración de todas las variables necesarias para el proyecto:

- ID de usuario y grupo
- Zona horaria
- Configuración de dominio y Cloudflare
- Configuración de PostgreSQL
- Configuración de Pi-hole
- Configuración de Traefik
- Configuración de red para Raspberry Pi

Todas estas variables se guardarán en el archivo `.env` para su uso posterior.

### 2. Configurar red (requiere sudo)

Esta opción debe ejecutarse con privilegios de superusuario. Te guiará a través de la configuración de red para tu Raspberry Pi:

- Configuración de dirección IP estática
- Configuración de puerta de enlace
- Configuración de servidores DNS
- Configuración de nombre de host

Al finalizar, te preguntará si deseas reiniciar el sistema para aplicar los cambios.

### 3. Desplegar servicios

Esta opción desplegará todos los servicios necesarios para el proyecto Surviving Chernarus:

1. Actualización del sistema
2. Instalación y configuración de UFW
3. Configuración de UFW para Docker
4. Instalación de Docker y Docker Compose
5. Configuración de permisos de Docker
6. Creación de estructura de directorios
7. Configuración de Traefik
8. Creación de docker-compose.yml
9. Inicio de los servicios

El script mostrará una barra de progreso durante la instalación y te informará cuando el proceso haya finalizado.

### 4. Ver documentación

Esta opción proporciona acceso a la documentación del proyecto:

- Información general
- Guía de instalación
- Solución de problemas

### 5. Salir

Sale del script.

## Uso desde la línea de comandos

También puedes ejecutar el script con argumentos para acceder directamente a una función específica:

```bash
# Configurar variables de entorno
./deploy.sh env

# Configurar red (requiere sudo)
sudo ./deploy.sh network

# Desplegar servicios
./deploy.sh deploy

# Ver documentación
./deploy.sh doc
```

## Servicios desplegados

El script despliega los siguientes servicios:

- **Traefik**: Proxy inverso y balanceador de carga
- **PostgreSQL**: Sistema de gestión de bases de datos relacional
- **Pi-hole**: Bloqueador de anuncios y rastreadores a nivel de red
- **n8n**: Plataforma de automatización de flujos de trabajo
- **rtorrent**: Cliente BitTorrent
- **heimdall**: Panel de control para acceder a todos los servicios

## Acceso a los servicios

Una vez desplegados, puedes acceder a los servicios a través de las siguientes URLs:

- **Traefik Dashboard**: https://traefik.tudominio.com
- **Pi-hole**: https://pihole.tudominio.com
- **n8n**: https://n8n.tudominio.com
- **rtorrent**: https://rtorrent.tudominio.com
- **heimdall**: https://heimdall.tudominio.com o https://tudominio.com

## Solución de Problemas

Si encuentras algún problema durante la ejecución del script:

1. Verifica que estás ejecutando el script con los permisos adecuados
2. Asegúrate de que tu Raspberry Pi tiene conexión a Internet
3. Verifica que el archivo `.env` existe y contiene todas las variables necesarias
4. Consulta la sección de documentación del script para soluciones a problemas comunes

### Problemas comunes

#### El script no puede instalar paquetes

Asegúrate de que tu Raspberry Pi tiene conexión a Internet y que los repositorios están actualizados:

```bash
sudo apt update
```

#### Los servicios no son accesibles a través de las URLs

1. Verifica que Traefik está funcionando correctamente:

```bash
docker ps | grep traefik
```

2. Comprueba que los registros DNS de Cloudflare apuntan a la IP de tu Raspberry Pi
3. Verifica que los puertos 80 y 443 están abiertos en tu router y redirigidos a tu Raspberry Pi

#### Error al iniciar los servicios con Docker Compose

Verifica los logs de Docker Compose:

```bash
cd /opt/surviving-chernarus
docker compose logs
```

## Actualización de servicios

Para actualizar los servicios después de la instalación inicial:

```bash
cd /opt/surviving-chernarus
docker compose pull
docker compose up -d
```

## Backup y restauración

### Backup

Para realizar una copia de seguridad de los datos:

```bash
cd /opt/surviving-chernarus
docker compose down
tar -czvf backup.tar.gz data
docker compose up -d
```

## 🔄 CI/CD con GitHub Actions

### Workflows Disponibles

#### 1. Deploy Workflow
- **Trigger**: Push a `main`, PR mergeado, o ejecución manual
- **Función**: Despliega automáticamente a la Raspberry Pi
- **Incluye**: Backup, deployment, tests, reportes

#### 2. Test Workflow
- **Trigger**: Pull Requests
- **Función**: Valida código antes del merge
- **Incluye**: Sintaxis, estructura, seguridad, compatibilidad

### Estado de los Workflows

![Deploy Status](https://github.com/terrerovgh/surviving-chernarus/workflows/Deploy%20to%20Raspberry%20Pi/badge.svg)
![Test Status](https://github.com/terrerovgh/surviving-chernarus/workflows/Test%20and%20Validate/badge.svg)

### Configuración Rápida

```bash
# Configurar GitHub Actions
./.github/setup-github-actions.sh

# Seguir las instrucciones del script para:
# 1. Generar claves SSH
# 2. Configurar Raspberry Pi
# 3. Configurar GitHub Secrets
```

### Monitoreo

- **Logs**: Disponibles en GitHub Actions tab
- **Reportes**: Generados automáticamente después de cada deployment
- **Notificaciones**: Estado de deployment en tiempo real

### Rollback

```bash
# Rollback automático desde la Raspberry Pi
ssh terrerov@rpi.terrerov.com
cd /opt/surviving-chernarus
sudo ./deploy.sh rollback
```

📖 **Documentación completa de CI/CD**: [docs/ci-cd.md](docs/ci-cd.md)

### Restauración

Para restaurar una copia de seguridad:

```bash
cd /opt/surviving-chernarus
docker compose down
rm -rf data
tar -xzvf backup.tar.gz
docker compose up -d
```

## Seguridad

El script configura UFW para permitir solo el tráfico necesario. Por defecto, solo se permiten los puertos 22 (SSH), 80 (HTTP) y 443 (HTTPS).

Se recomienda:

1. Cambiar el puerto SSH por defecto
2. Configurar la autenticación por clave SSH en lugar de contraseña
3. Mantener el sistema y los contenedores actualizados
4. Revisar regularmente los logs en busca de actividad sospechosa

## Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o un pull request para sugerir cambios o mejoras.

## Licencia

Este proyecto está licenciado bajo la licencia MIT. Consulta el archivo LICENSE para más detalles.