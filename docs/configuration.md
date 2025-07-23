# Configuración de Servicios

## Configuración General

Una vez que hayas completado la [instalación básica](installation.md), puedes personalizar cada uno de los servicios según tus necesidades específicas. Esta guía te mostrará cómo configurar cada componente del ecosistema Surviving Chernarus.

## Estructura de Directorios

Todos los servicios se instalan en la ruta especificada por la variable `SC_PROJECT_PATH` (por defecto `/opt/surviving-chernarus`). La estructura de directorios es la siguiente:

```
/opt/surviving-chernarus/
├── docker-compose.yml
├── .env
├── traefik/
│   ├── config/
│   │   ├── traefik.yml
│   │   └── dynamic_conf.yml
│   └── data/
├── pihole/
│   ├── etc-pihole/
│   └── etc-dnsmasq.d/
├── n8n/
│   └── data/
├── postgres/
│   └── data/
├── rtorrent/
│   ├── config/
│   └── downloads/
└── dashboard/
    └── html/
```

## Traefik (Proxy Inverso)

Traefik gestiona el enrutamiento de tráfico y los certificados SSL para todos los servicios.

### Configuración Básica

El archivo principal de configuración se encuentra en `traefik/config/traefik.yml`. Para modificarlo:

```bash
sudo nano /opt/surviving-chernarus/traefik/config/traefik.yml
```

Aspectos importantes a considerar:

- **Entrypoints**: Define los puertos en los que Traefik escucha (por defecto 80 y 443)
- **Certificados**: Configuración de Let's Encrypt con el proveedor Cloudflare
- **Middlewares**: Configuraciones de seguridad como cabeceras HTTP y redirecciones

### Configuración Dinámica

La configuración dinámica se encuentra en `traefik/config/dynamic_conf.yml` y contiene las reglas de enrutamiento para cada servicio:

```bash
sudo nano /opt/surviving-chernarus/traefik/config/dynamic_conf.yml
```

Para añadir un nuevo servicio, agrega una nueva sección en este archivo siguiendo el patrón existente.

### Reinicio de Traefik

Después de realizar cambios en la configuración, reinicia Traefik:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml restart traefik
```

## Pi-hole (Filtrado DNS)

Pi-hole proporciona bloqueo de anuncios y rastreadores a nivel de red.

### Acceso al Panel de Administración

Accede al panel de administración a través de `https://pihole.tu-dominio.com` utilizando la contraseña que configuraste en `SC_PIHOLE_PASSWORD`.

### Listas de Bloqueo Personalizadas

Para añadir listas de bloqueo adicionales:

1. Accede al panel de administración de Pi-hole
2. Ve a "Group Management" > "Adlists"
3. Añade las URLs de las listas de bloqueo que desees utilizar
4. Haz clic en "Add" para guardar
5. Ve a "Tools" > "Update Gravity" para actualizar las listas

Algunas listas recomendadas:

- [StevenBlack Hosts](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts)
- [OISD](https://dbl.oisd.nl/)
- [Firebog Tick List](https://v.firebog.net/hosts/lists.php?type=tick)

### Configuración de DNS Personalizado

Para configurar servidores DNS personalizados:

1. Accede al panel de administración de Pi-hole
2. Ve a "Settings" > "DNS"
3. Selecciona los servidores DNS que desees utilizar (recomendados: Quad9, Cloudflare, o NextDNS)
4. Guarda los cambios

## n8n (Automatización)

n8n es una plataforma de automatización de flujos de trabajo que te permite conectar diferentes servicios y APIs.

### Acceso al Panel de n8n

Accede al panel de n8n a través de `https://n8n.tu-dominio.com`.

### Configuración de Credenciales

Para configurar credenciales para servicios externos:

1. Accede al panel de n8n
2. Haz clic en "Settings" > "Credentials"
3. Haz clic en "New" y selecciona el tipo de credencial que deseas añadir
4. Completa los detalles requeridos y guarda

### Creación de Flujos de Trabajo

Para crear un nuevo flujo de trabajo:

1. Accede al panel de n8n
2. Haz clic en "Workflows" > "New"
3. Arrastra y suelta nodos para construir tu flujo de trabajo
4. Configura cada nodo según tus necesidades
5. Haz clic en "Save" para guardar el flujo de trabajo

### Ejemplos de Flujos de Trabajo

Algunos ejemplos de flujos de trabajo útiles para Surviving Chernarus:

- Monitorización del estado de los servicios y notificaciones
- Sincronización de datos entre servicios locales
- Automatización de descargas con rTorrent
- Respaldos automáticos de bases de datos

## PostgreSQL (Base de Datos)

PostgreSQL es la base de datos utilizada por n8n y otros servicios.

### Acceso a la Base de Datos

Para acceder a la base de datos desde la línea de comandos:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres psql -U $SC_POSTGRES_USER -d $SC_POSTGRES_DB
```

### Respaldo de la Base de Datos

Para crear un respaldo de la base de datos:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml exec postgres pg_dump -U $SC_POSTGRES_USER $SC_POSTGRES_DB > backup_$(date +%Y%m%d).sql
```

### Restauración de la Base de Datos

Para restaurar un respaldo de la base de datos:

```bash
cat backup_YYYYMMDD.sql | docker compose -f /opt/surviving-chernarus/docker-compose.yml exec -T postgres psql -U $SC_POSTGRES_USER -d $SC_POSTGRES_DB
```

## rTorrent (Gestor de Descargas)

rTorrent con la interfaz Flood proporciona capacidades de descarga de torrents.

### Acceso a la Interfaz de Usuario

Accede a la interfaz de usuario a través de `https://rtorrent.tu-dominio.com`.

### Configuración de Directorios de Descarga

Por defecto, las descargas se almacenan en `/opt/surviving-chernarus/rtorrent/downloads`. Puedes modificar esta ubicación editando el archivo `docker-compose.yml`:

```bash
sudo nano /opt/surviving-chernarus/docker-compose.yml
```

Busca la sección del servicio `rtorrent` y modifica los volúmenes según tus necesidades.

### Configuración Avanzada

Para una configuración más avanzada, puedes editar el archivo de configuración de rTorrent:

```bash
sudo nano /opt/surviving-chernarus/rtorrent/config/.rtorrent.rc
```

## Punto de Acceso Wi-Fi

Si configuraste el punto de acceso Wi-Fi durante la instalación, puedes personalizar su configuración.

### Modificación de la Configuración del Punto de Acceso

Para modificar la configuración del punto de acceso:

```bash
sudo nano /etc/hostapd/hostapd.conf
```

Aquí puedes cambiar parámetros como el canal Wi-Fi, el modo de seguridad, etc.

### Reinicio del Servicio

Después de realizar cambios, reinicia el servicio:

```bash
sudo systemctl restart hostapd
```

## Panel de Control

El panel de control proporciona acceso centralizado a todos los servicios.

### Personalización del Panel

Para personalizar el panel de control, puedes editar los archivos HTML, CSS y JavaScript en el directorio `/opt/surviving-chernarus/dashboard/html/`:

```bash
sudo nano /opt/surviving-chernarus/dashboard/html/index.html
```

### Añadir Nuevos Servicios al Panel

Para añadir un nuevo servicio al panel de control, edita el archivo `index.html` y añade un nuevo elemento en la sección de servicios siguiendo el patrón existente.

## Variables de Entorno

Todas las variables de configuración se almacenan en el archivo `.env` en el directorio raíz del proyecto:

```bash
sudo nano /opt/surviving-chernarus/docker-compose.yml
```

Después de modificar las variables de entorno, reinicia todos los servicios:

```bash
docker compose -f /opt/surviving-chernarus/docker-compose.yml down
docker compose -f /opt/surviving-chernarus/docker-compose.yml up -d
```

## Próximos Pasos

Una vez que hayas configurado todos los servicios según tus necesidades, consulta la guía de [Uso Diario](daily-usage.md) para aprender a utilizar tu ecosistema Surviving Chernarus de manera efectiva.