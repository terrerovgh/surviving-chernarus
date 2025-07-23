# Solución de Problemas

## Problemas Comunes y Soluciones

Esta guía te ayudará a resolver los problemas más comunes que puedes encontrar al utilizar el ecosistema Surviving Chernarus. Sigue los pasos de diagnóstico y solución para cada tipo de problema.

## Problemas de Instalación

### El Script de Instalación Falla

**Síntomas:**
- El script `deploy.sh` se detiene con un error
- Algunos servicios no se inician correctamente después de la instalación

**Soluciones:**

1. **Verificar requisitos previos:**
   ```bash
   # Verificar versión de Raspberry Pi OS
   cat /etc/os-release
   
   # Verificar arquitectura
   uname -m
   ```
   Asegúrate de que estás utilizando Raspberry Pi OS de 64 bits (arm64/aarch64).

2. **Verificar permisos:**
   ```bash
   sudo chmod +x deploy.sh
   ```

3. **Verificar conectividad a Internet:**
   ```bash
   ping -c 4 google.com
   ```

4. **Ejecutar el script con registro detallado:**
   ```bash
   ./deploy.sh --verbose 2>&1 | tee installation_log.txt
   ```
   Revisa el archivo `installation_log.txt` para identificar el error específico.

5. **Limpiar instalación parcial y reintentar:**
   ```bash
   sudo rm -rf /opt/surviving-chernarus
   ./deploy.sh
   ```

### Problemas con Docker

**Síntomas:**
- Error al instalar Docker
- Los contenedores no se inician

**Soluciones:**

1. **Reinstalar Docker:**
   ```bash
   sudo apt remove --purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```
   Cierra la sesión y vuelve a iniciarla para que los cambios de grupo surtan efecto.

2. **Verificar el servicio Docker:**
   ```bash
   sudo systemctl status docker
   ```
   Si no está en ejecución:
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

3. **Verificar espacio en disco:**
   ```bash
   df -h
   ```
   Docker necesita suficiente espacio libre para funcionar correctamente.

## Problemas de Red

### No se Puede Acceder a los Servicios por Dominio

**Síntomas:**
- Los servicios no son accesibles a través de `https://tu-dominio.com`
- Error "No se puede acceder al sitio" en el navegador

**Soluciones:**

1. **Verificar configuración DNS en Cloudflare:**
   - Accede a tu panel de control de Cloudflare
   - Verifica que los registros DNS apuntan a la dirección IP correcta
   - Asegúrate de que el proxy de Cloudflare está activado (icono naranja)

2. **Verificar token de API de Cloudflare:**
   ```bash
   sudo nano /opt/surviving-chernarus/.env
   ```
   Verifica que `SC_CLOUDFLARE_EMAIL` y `SC_CLOUDFLARE_API_TOKEN` son correctos.

3. **Verificar configuración de Traefik:**
   ```bash
   sudo nano /opt/surviving-chernarus/traefik/config/traefik.yml
   ```
   Asegúrate de que la configuración de Cloudflare es correcta.

4. **Reiniciar Traefik:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart traefik
   ```

5. **Verificar registros de Traefik:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs traefik
   ```
   Busca errores relacionados con la obtención de certificados SSL.

### Punto de Acceso Wi-Fi No Funciona

**Síntomas:**
- No aparece la red Wi-Fi "SurvivingChernarus"
- No se puede conectar al punto de acceso

**Soluciones:**

1. **Verificar estado del servicio hostapd:**
   ```bash
   sudo systemctl status hostapd
   ```
   Si no está en ejecución:
   ```bash
   sudo systemctl start hostapd
   sudo systemctl enable hostapd
   ```

2. **Verificar configuración de hostapd:**
   ```bash
   sudo nano /etc/hostapd/hostapd.conf
   ```
   Asegúrate de que la interfaz configurada es correcta.

3. **Verificar que la interfaz Wi-Fi está disponible:**
   ```bash
   ip addr show
   ```
   Busca la interfaz configurada en `SC_HOTSPOT_INTERFACE`.

4. **Reiniciar servicios de red:**
   ```bash
   sudo systemctl restart hostapd
   sudo systemctl restart dnsmasq
   ```

5. **Verificar compatibilidad del adaptador Wi-Fi:**
   No todos los adaptadores Wi-Fi son compatibles con el modo punto de acceso. Verifica que tu adaptador es compatible:
   ```bash
   iw list | grep -A 10 "Supported interface modes"
   ```
   Debería mostrar "AP" en la lista de modos soportados.

## Problemas con Servicios Específicos

### Traefik

**Síntomas:**
- Error 502 Bad Gateway al acceder a los servicios
- Los certificados SSL no se generan correctamente

**Soluciones:**

1. **Verificar configuración de Traefik:**
   ```bash
   sudo nano /opt/surviving-chernarus/traefik/config/traefik.yml
   sudo nano /opt/surviving-chernarus/traefik/config/dynamic_conf.yml
   ```

2. **Verificar registros de Traefik:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs traefik
   ```

3. **Reiniciar Traefik:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart traefik
   ```

4. **Verificar conectividad con Cloudflare:**
   ```bash
   curl -s https://api.cloudflare.com/client/v4/user/tokens/verify -H "Authorization: Bearer $SC_CLOUDFLARE_API_TOKEN" | jq
   ```
   Debería devolver `"success": true`.

### Pi-hole

**Síntomas:**
- La interfaz web de Pi-hole no es accesible
- El bloqueo de anuncios no funciona

**Soluciones:**

1. **Verificar estado del contenedor:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml ps pihole
   ```

2. **Verificar registros de Pi-hole:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs pihole
   ```

3. **Reiniciar Pi-hole:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart pihole
   ```

4. **Restablecer contraseña de Pi-hole:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml exec pihole pihole -a -p nuevacontraseña
   ```

5. **Verificar configuración de DNS:**
   ```bash
   cat /etc/resolv.conf
   ```
   Asegúrate de que apunta a la dirección IP de Pi-hole.

### n8n

**Síntomas:**
- La interfaz web de n8n no es accesible
- Los flujos de trabajo no se ejecutan correctamente

**Soluciones:**

1. **Verificar estado del contenedor:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml ps n8n
   ```

2. **Verificar registros de n8n:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs n8n
   ```

3. **Verificar conexión con la base de datos:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres psql -U $SC_POSTGRES_USER -d $SC_POSTGRES_DB -c "\l"
   ```

4. **Reiniciar n8n:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart n8n
   ```

5. **Verificar variables de entorno:**
   ```bash
   sudo nano /opt/surviving-chernarus/.env
   ```
   Asegúrate de que las variables relacionadas con n8n y PostgreSQL son correctas.

### PostgreSQL

**Síntomas:**
- Errores de conexión a la base de datos
- n8n no puede conectarse a PostgreSQL

**Soluciones:**

1. **Verificar estado del contenedor:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml ps postgres
   ```

2. **Verificar registros de PostgreSQL:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs postgres
   ```

3. **Verificar que la base de datos existe:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres psql -U $SC_POSTGRES_USER -c "\l"
   ```

4. **Reiniciar PostgreSQL:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart postgres
   ```

5. **Verificar permisos de los archivos de datos:**
   ```bash
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/postgres/data
   ```

### rTorrent

**Síntomas:**
- La interfaz web de Flood no es accesible
- Las descargas no funcionan correctamente

**Soluciones:**

1. **Verificar estado del contenedor:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml ps rtorrent
   ```

2. **Verificar registros de rTorrent:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs rtorrent
   ```

3. **Verificar permisos de los directorios de descarga:**
   ```bash
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/rtorrent/downloads
   sudo chown -R $SC_PUID:$SC_PGID /opt/surviving-chernarus/rtorrent/config
   ```

4. **Reiniciar rTorrent:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart rtorrent
   ```

5. **Verificar configuración de rTorrent:**
   ```bash
   sudo nano /opt/surviving-chernarus/rtorrent/config/.rtorrent.rc
   ```

## Problemas de Rendimiento

### Sistema Lento

**Síntomas:**
- La Raspberry Pi responde lentamente
- Los servicios tardan mucho en cargar

**Soluciones:**

1. **Verificar uso de CPU y memoria:**
   ```bash
   top
   ```
   o
   ```bash
   htop
   ```

2. **Verificar temperatura de la CPU:**
   ```bash
   vcgencmd measure_temp
   ```
   Si la temperatura es superior a 80°C, considera mejorar la refrigeración.

3. **Verificar espacio en disco:**
   ```bash
   df -h
   ```
   Si el espacio libre es inferior al 10%, libera espacio eliminando archivos innecesarios.

4. **Verificar procesos que consumen muchos recursos:**
   ```bash
   ps aux --sort=-%cpu | head -10
   ps aux --sort=-%mem | head -10
   ```

5. **Limitar recursos de contenedores:**
   Edita el archivo `docker-compose.yml` para limitar los recursos asignados a cada contenedor:
   ```bash
   sudo nano /opt/surviving-chernarus/docker-compose.yml
   ```
   Añade límites de recursos a los servicios que consumen más recursos.

### Problemas de Almacenamiento

**Síntomas:**
- Errores de "No space left on device"
- Los servicios se detienen inesperadamente

**Soluciones:**

1. **Identificar directorios que ocupan mucho espacio:**
   ```bash
   sudo du -h --max-depth=1 /opt/surviving-chernarus | sort -hr
   ```

2. **Limpiar archivos de registro antiguos:**
   ```bash
   sudo find /opt/surviving-chernarus -name "*.log" -type f -mtime +30 -delete
   ```

3. **Limpiar imágenes Docker no utilizadas:**
   ```bash
   docker system prune -a --volumes
   ```

4. **Limpiar descargas antiguas:**
   ```bash
   find /opt/surviving-chernarus/rtorrent/downloads -type f -mtime +90 | xargs rm -f
   ```

5. **Considerar migrar a un almacenamiento externo:**
   ```bash
   sudo apt install -y rsync
   sudo rsync -avz /opt/surviving-chernarus/ /mnt/external_drive/surviving-chernarus/
   ```
   Luego actualiza las rutas en el archivo `docker-compose.yml`.

## Recuperación de Desastres

### Restauración Completa del Sistema

Si necesitas restaurar completamente el sistema después de un fallo catastrófico:

1. **Reinstala el sistema operativo** siguiendo los pasos en la [Guía de Instalación](installation.md).

2. **Restaura desde el respaldo:**
   ```bash
   sudo mkdir -p /opt/surviving-chernarus
   sudo rsync -avz /mnt/backup/surviving-chernarus/ /opt/surviving-chernarus/
   ```

3. **Restaura la base de datos:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d postgres
   cat /mnt/backup/surviving-chernarus/database_backup_YYYYMMDD.sql | docker compose -f /opt/surviving-chernarus/docker-compose.yml exec -T postgres psql -U $SC_POSTGRES_USER -d $SC_POSTGRES_DB
   ```

4. **Inicia todos los servicios:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d
   ```

### Recuperación de Contraseñas

Si has olvidado las contraseñas de los servicios:

1. **Contraseña de Pi-hole:**
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml exec pihole pihole -a -p nuevacontraseña
   ```

2. **Contraseña de PostgreSQL:**
   ```bash
   sudo nano /opt/surviving-chernarus/.env
   ```
   Actualiza la variable `SC_POSTGRES_PASSWORD` y luego reinicia PostgreSQL:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart postgres
   ```

3. **Contraseña del punto de acceso Wi-Fi:**
   ```bash
   sudo nano /etc/hostapd/hostapd.conf
   ```
   Actualiza el valor de `wpa_passphrase` y reinicia hostapd:
   ```bash
   sudo systemctl restart hostapd
   ```

## Contacto y Soporte

Si has seguido todos los pasos de solución de problemas y sigues experimentando dificultades, puedes buscar ayuda adicional:

1. **Abrir un Issue en GitHub:**
   Visita el [repositorio del proyecto](https://github.com/tuusuario/surviving-chernarus) y abre un nuevo issue describiendo detalladamente tu problema.

2. **Foro de la Comunidad:**
   Participa en el foro de la comunidad para discutir problemas y soluciones con otros usuarios.

3. **Documentación Adicional:**
   Consulta la documentación oficial de los servicios individuales para problemas específicos:
   - [Documentación de Docker](https://docs.docker.com/)
   - [Documentación de Traefik](https://doc.traefik.io/traefik/)
   - [Documentación de Pi-hole](https://docs.pi-hole.net/)
   - [Documentación de n8n](https://docs.n8n.io/)

## Próximos Pasos

Ahora que sabes cómo solucionar problemas comunes en tu ecosistema Surviving Chernarus, puedes consultar la guía de [Casos de Uso Avanzados](advanced-usage.md) para explorar funcionalidades adicionales y escenarios de uso más complejos.