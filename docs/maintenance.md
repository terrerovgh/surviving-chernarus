# Mantenimiento y Actualizaciones

## Mantenimiento Regular

Para mantener tu ecosistema Surviving Chernarus funcionando de manera óptima, es importante realizar tareas de mantenimiento regulares. Esta guía te mostrará cómo mantener tu sistema actualizado, seguro y en buen estado.

### Actualizaciones del Sistema Operativo

Es importante mantener el sistema operativo de la Raspberry Pi actualizado para recibir parches de seguridad y mejoras de rendimiento.

#### Actualización Regular

Para actualizar el sistema operativo:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean
```

Se recomienda realizar estas actualizaciones al menos una vez al mes.

#### Reinicio Después de Actualizaciones Importantes

Después de actualizaciones importantes del kernel o componentes críticos, reinicia la Raspberry Pi:

```bash
sudo reboot
```

### Actualizaciones de Contenedores Docker

Los servicios de Surviving Chernarus se ejecutan en contenedores Docker que también deben actualizarse regularmente.

#### Actualización de Imágenes

Para actualizar todas las imágenes Docker a sus versiones más recientes:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml pull
docker compose -f /opt/surviving-chernarus/docker-compose.yml down
docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d
```

Este proceso descargará las nuevas versiones de las imágenes, detendrá los contenedores actuales y los reiniciará con las nuevas imágenes.

#### Verificación de Actualizaciones

Para verificar qué imágenes tienen actualizaciones disponibles:

```bash
docker images | grep -v REPOSITORY
```

Luego puedes buscar manualmente las versiones más recientes de cada imagen en Docker Hub o en los repositorios oficiales.

### Respaldos

Realizar respaldos regulares es crucial para proteger tus datos contra pérdidas accidentales o fallos de hardware.

#### Respaldo de Datos de Servicios

Para respaldar los datos de todos los servicios:

```bash
sudo mkdir -p /mnt/backup/surviving-chernarus
sudo rsync -avz --exclude="*.log" /opt/surviving-chernarus/ /mnt/backup/surviving-chernarus/
```

#### Respaldo de la Base de Datos

Para respaldar específicamente la base de datos PostgreSQL:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres pg_dump -U $SC_POSTGRES_USER $SC_POSTGRES_DB > /mnt/backup/surviving-chernarus/database_backup_$(date +%Y%m%d).sql
```

#### Automatización de Respaldos

Puedes automatizar los respaldos utilizando cron o creando un flujo de trabajo en n8n. Para configurar un respaldo semanal con cron:

```bash
sudo crontab -e
```

Añade la siguiente línea para realizar un respaldo todos los domingos a las 2 AM:

```
0 2 * * 0 /bin/bash -c 'mkdir -p /mnt/backup/surviving-chernarus && rsync -avz --exclude="*.log" /opt/surviving-chernarus/ /mnt/backup/surviving-chernarus/ && docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres pg_dump -U $SC_POSTGRES_USER $SC_POSTGRES_DB > /mnt/backup/surviving-chernarus/database_backup_$(date +%Y%m%d).sql'
```

### Limpieza de Disco

Con el tiempo, los archivos temporales, registros y descargas pueden acumular espacio en disco.

#### Limpieza de Imágenes Docker No Utilizadas

Para eliminar imágenes Docker antiguas que ya no se utilizan:

```bash
docker system prune -a --volumes
```

**Precaución**: Este comando eliminará todas las imágenes no utilizadas, contenedores detenidos y volúmenes no utilizados. Asegúrate de tener respaldos antes de ejecutarlo.

#### Limpieza de Registros

Para limpiar archivos de registro antiguos:

```bash
sudo find /opt/surviving-chernarus -name "*.log" -type f -mtime +30 -delete
```

Este comando eliminará archivos de registro con más de 30 días de antigüedad.

#### Limpieza de Descargas Completadas

Si utilizas rTorrent para descargas, considera limpiar periódicamente las descargas completadas que ya no necesitas:

```bash
find /opt/surviving-chernarus/rtorrent/downloads -type f -mtime +90 -name "*.completed" | xargs rm -f
```

Este comando eliminará archivos marcados como completados con más de 90 días de antigüedad.

## Actualizaciones del Script Principal

El script `deploy.sh` puede recibir actualizaciones con nuevas características o correcciones de errores.

### Verificación de Actualizaciones

Para verificar si hay actualizaciones disponibles para el script principal:

```bash
curl -s https://raw.githubusercontent.com/tuusuario/surviving-chernarus/main/deploy.sh | diff -u /opt/surviving-chernarus/deploy.sh -
```

Este comando mostrará las diferencias entre tu versión actual y la versión más reciente disponible en el repositorio.

### Actualización del Script

Para actualizar el script principal:

```bash
curl -fsSL https://raw.githubusercontent.com/tuusuario/surviving-chernarus/main/deploy.sh -o /tmp/deploy.sh
sudo mv /tmp/deploy.sh /opt/surviving-chernarus/deploy.sh
sudo chmod +x /opt/surviving-chernarus/deploy.sh
```

## Monitorización del Sistema

Monitorizar regularmente el rendimiento y la salud del sistema te ayudará a identificar problemas potenciales antes de que afecten a los servicios.

### Monitorización de Recursos

Para verificar el uso de CPU y memoria:

```bash
top
```

O para una vista más detallada:

```bash
htop
```

Si htop no está instalado, puedes instalarlo con:

```bash
sudo apt install htop
```

### Monitorización de Espacio en Disco

Para verificar el espacio en disco disponible:

```bash
df -h
```

Para identificar directorios que ocupan mucho espacio:

```bash
du -h --max-depth=1 /opt/surviving-chernarus | sort -hr
```

### Monitorización de Temperatura

La Raspberry Pi puede sobrecalentarse en ciertas condiciones. Para verificar la temperatura de la CPU:

```bash
vcgencmd measure_temp
```

O para una monitorización continua:

```bash
watch -n 1 vcgencmd measure_temp
```

## Solución de Problemas Comunes

### Servicios que No Inician

Si un servicio no inicia correctamente después de una actualización:

1. Verifica los registros del servicio:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs nombre_del_servicio
   ```

2. Comprueba si hay conflictos de puertos:
   ```bash
   sudo netstat -tulpn | grep <puerto>
   ```

3. Verifica los permisos de los archivos de configuración:
   ```bash
   sudo chown -R $SC_USER:$SC_USER /opt/surviving-chernarus
   ```

### Problemas de Red

Si experimentas problemas de conectividad:

1. Verifica la configuración de red:
   ```bash
   ip addr show
   ```

2. Comprueba la conectividad DNS:
   ```bash
   nslookup google.com
   ```

3. Reinicia los servicios de red:
   ```bash
   sudo systemctl restart NetworkManager
   ```

### Recuperación de Respaldos

Si necesitas restaurar desde un respaldo:

1. Detén todos los servicios:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml down
   ```

2. Restaura los archivos desde el respaldo:
   ```bash
   sudo rsync -avz /mnt/backup/surviving-chernarus/ /opt/surviving-chernarus/
   ```

3. Restaura la base de datos:
   ```bash
   cat /mnt/backup/surviving-chernarus/database_backup_YYYYMMDD.sql | docker compose -f /opt/surviving-chernarus/docker-compose.yml exec -T postgres psql -U $SC_POSTGRES_USER -d $SC_POSTGRES_DB
   ```

4. Reinicia todos los servicios:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d
   ```

## Mantenimiento de Seguridad

### Actualizaciones de Seguridad

Para asegurarte de recibir solo actualizaciones de seguridad críticas:

```bash
sudo apt update
sudo apt upgrade -y
```

### Verificación de Puertos Abiertos

Para verificar qué puertos están abiertos en tu sistema:

```bash
sudo netstat -tulpn
```

### Revisión de Registros de Autenticación

Para revisar intentos de inicio de sesión fallidos:

```bash
sudo grep "Failed password" /var/log/auth.log
```

## Próximos Pasos

Ahora que conoces cómo mantener y actualizar tu ecosistema Surviving Chernarus, puedes consultar la guía de [Solución de Problemas](troubleshooting.md) para resolver problemas específicos que puedas encontrar durante el uso del sistema.