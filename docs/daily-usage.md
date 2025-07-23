# Uso Diario

## Acceso a los Servicios

Una vez que hayas completado la [instalación](installation.md) y [configuración](configuration.md) de tu ecosistema Surviving Chernarus, puedes comenzar a utilizarlo en tu día a día. Esta guía te mostrará cómo aprovechar al máximo cada uno de los servicios.

### Panel de Control Central

El punto de entrada principal es el panel de control, accesible a través de `https://tu-dominio.com`. Desde aquí puedes acceder a todos los servicios con un solo clic.

## Escenarios de Uso

### Escenario 1: Uso en Casa con Internet Estable

Cuando estás en casa con una conexión a Internet estable, Surviving Chernarus funciona como un centro de servicios autoalojados tradicional:

1. Conecta la Raspberry Pi a tu red doméstica mediante Ethernet o Wi-Fi
2. Todos los servicios son accesibles a través de Internet usando tu dominio personalizado
3. Puedes acceder a los servicios desde cualquier dispositivo, dentro o fuera de tu red local

### Escenario 2: Uso en Movimiento (Modo Nómada)

Cuando estás viajando o en un lugar con conectividad limitada:

1. Conecta la Raspberry Pi a una red Wi-Fi disponible (hotel, café, punto de acceso móvil)
2. La Raspberry Pi creará simultáneamente su propio punto de acceso Wi-Fi llamado "SurvivingChernarus" (o el nombre que hayas configurado)
3. Conecta tus dispositivos personales a esta red Wi-Fi
4. Accede a todos los servicios usando tu dominio personalizado, incluso sin conexión a Internet

### Escenario 3: Modo Completamente Desconectado

En situaciones donde no hay conectividad a Internet disponible:

1. Enciende la Raspberry Pi y espera a que cree su punto de acceso Wi-Fi
2. Conecta tus dispositivos personales a esta red
3. Accede a los servicios localmente usando direcciones IP o nombres de host locales
4. Los servicios funcionarán con funcionalidad limitada (sin actualizaciones externas o sincronización)

## Uso de Servicios Específicos

### Pi-hole (Filtrado DNS)

#### Bloqueo de Anuncios y Rastreadores

Pi-hole funciona automáticamente para todos los dispositivos conectados a la red de Surviving Chernarus, bloqueando anuncios y rastreadores a nivel de DNS.

Para ver estadísticas y gestionar el filtrado:

1. Accede al panel de administración en `https://pihole.tu-dominio.com`
2. Revisa el dashboard para ver estadísticas de bloqueo
3. Utiliza la opción "Disable" temporalmente si algún sitio no funciona correctamente

#### Listas Blancas y Negras

Para añadir dominios a la lista blanca o negra:

1. Accede al panel de administración de Pi-hole
2. Ve a "Whitelist" o "Blacklist" en el menú lateral
3. Añade los dominios que desees permitir o bloquear específicamente

### n8n (Automatización)

#### Ejecución de Flujos de Trabajo

Para ejecutar flujos de trabajo manualmente:

1. Accede a n8n en `https://n8n.tu-dominio.com`
2. Ve a la sección "Workflows"
3. Selecciona el flujo de trabajo que deseas ejecutar
4. Haz clic en el botón "Execute Workflow"

#### Monitorización de Ejecuciones

Para monitorizar las ejecuciones de tus flujos de trabajo:

1. Accede a n8n
2. Ve a "Executions" en el menú lateral
3. Revisa el estado y los registros de las ejecuciones recientes

### rTorrent (Gestor de Descargas)

#### Añadir Nuevas Descargas

Para añadir nuevas descargas:

1. Accede a la interfaz Flood en `https://rtorrent.tu-dominio.com`
2. Haz clic en el botón "+" en la esquina inferior derecha
3. Sube un archivo .torrent o introduce un enlace magnet
4. Configura las opciones de descarga y haz clic en "Add Torrent"

#### Gestión de Descargas

Para gestionar tus descargas activas:

1. Accede a la interfaz Flood
2. Utiliza los filtros para ver descargas activas, completadas, etc.
3. Selecciona una descarga para ver detalles o realizar acciones como pausar, reanudar o eliminar

#### Acceso a los Archivos Descargados

Para acceder a los archivos descargados:

1. Los archivos se almacenan en `/opt/surviving-chernarus/rtorrent/downloads`
2. Puedes configurar un servidor Samba o SFTP para acceder a estos archivos desde otros dispositivos

## Mantenimiento Diario

### Monitorización del Estado

Para verificar que todos los servicios están funcionando correctamente:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml ps
```

Esto mostrará el estado de todos los contenedores Docker.

### Verificación de Espacio en Disco

Para verificar el espacio en disco disponible:

```bash
df -h
```

Si el espacio se está agotando, considera eliminar descargas antiguas o archivos de registro.

### Reinicio de Servicios

Si un servicio no funciona correctamente, puedes reiniciarlo:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml restart nombre_del_servicio
```

Para reiniciar todos los servicios:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml restart
```

## Uso en Diferentes Dispositivos

### Dispositivos Móviles

Todos los servicios están optimizados para funcionar en dispositivos móviles. Simplemente accede a las URLs correspondientes desde el navegador de tu teléfono o tablet.

Para una experiencia mejorada:

1. Añade accesos directos a la pantalla de inicio para cada servicio
2. Utiliza un gestor de contraseñas para almacenar las credenciales de acceso

### Ordenadores

En ordenadores, puedes acceder a todos los servicios a través del navegador web. Además, puedes:

1. Configurar tu ordenador para usar Pi-hole como servidor DNS
2. Montar los directorios de descargas como unidades de red

## Escenarios Avanzados

### Integración con Servicios Externos

Puedes integrar tu ecosistema Surviving Chernarus con servicios externos utilizando n8n:

1. Configura webhooks para recibir datos de servicios externos
2. Utiliza APIs para enviar datos a servicios externos
3. Crea flujos de trabajo que conecten tus servicios locales con servicios en la nube

### Uso como Servidor de Medios

Puedes expandir tu ecosistema para incluir servicios de medios:

1. Añade Jellyfin o Plex para streaming de vídeo
2. Configura Navidrome para streaming de música
3. Utiliza Calibre-Web para gestionar y leer libros electrónicos

## Solución de Problemas Comunes

### Problemas de Conectividad

Si no puedes acceder a los servicios:

1. Verifica que estás conectado a la red correcta
2. Comprueba que la Raspberry Pi está encendida y funcionando
3. Intenta acceder usando la dirección IP local en lugar del dominio

### Problemas con Servicios Específicos

Si un servicio específico no funciona correctamente:

1. Verifica los registros del servicio:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml logs nombre_del_servicio
   ```

2. Reinicia el servicio:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml restart nombre_del_servicio
   ```

## Próximos Pasos

Ahora que conoces cómo utilizar tu ecosistema Surviving Chernarus en el día a día, puedes consultar la guía de [Mantenimiento y Actualizaciones](maintenance.md) para mantener tu sistema actualizado y seguro.