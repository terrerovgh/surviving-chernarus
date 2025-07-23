# Guía de Instalación

## Requisitos Previos

### Hardware

- Raspberry Pi 5 (recomendado) o Raspberry Pi 4 con al menos 4GB de RAM
- Tarjeta microSD de alta calidad (clase A2 o superior) o SSD externo conectado por USB 3.0
- Adaptador de corriente oficial para Raspberry Pi
- Opcional: Adaptador Wi-Fi USB adicional para configuración de punto de acceso dual

### Software y Servicios

- Raspberry Pi Imager (para preparar la tarjeta SD/SSD)
- Cuenta de Cloudflare con un dominio configurado
- Token de API de Cloudflare con permisos para editar registros DNS

## Preparación del Sistema Operativo

### 1. Configuración Inicial con Raspberry Pi Imager

1. Descarga e instala [Raspberry Pi Imager](https://www.raspberrypi.com/software/) en tu computadora
2. Inserta la tarjeta microSD o conecta el SSD a tu computadora
3. Abre Raspberry Pi Imager y selecciona:
   - **Sistema Operativo**: Raspberry Pi OS Lite (64-bit)
   - **Almacenamiento**: Tu tarjeta SD o SSD

4. Haz clic en el icono de engranaje (⚙️) para acceder a las opciones avanzadas y configura:
   - **Hostname**: Un nombre único (ej. chernarus-pi)
   - **Habilitar SSH**: Selecciona "Usar contraseña para autenticación"
   - **Usuario y contraseña**: Crea un usuario personalizado (no uses el predeterminado "pi")
   - **Configurar Wi-Fi**: Ingresa los datos de tu red Wi-Fi
   - **Zona horaria y teclado**: Configura según tu ubicación

5. Haz clic en "Guardar" y luego en "Escribir" para crear la imagen del sistema operativo

### 2. Primer Arranque y Acceso

1. Inserta la tarjeta SD en la Raspberry Pi o conecta el SSD
2. Conecta la alimentación a la Raspberry Pi
3. Espera unos minutos para que el sistema arranque completamente
4. Accede a la Raspberry Pi mediante SSH desde tu computadora:
   ```bash
   ssh tuusuario@chernarus-pi.local
   ```
   o usando la dirección IP si el nombre de host no funciona

## Instalación del Script Unificado

### 1. Descarga del Script de Despliegue

1. Una vez conectado a la Raspberry Pi mediante SSH, actualiza el sistema:
   ```bash
   sudo apt update && sudo apt full-upgrade -y
   ```

2. Descarga el script de despliegue:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/tuusuario/surviving-chernarus/main/deploy.sh -o deploy.sh
   ```

3. Haz el script ejecutable:
   ```bash
   chmod +x deploy.sh
   ```

### 2. Configuración del Script

Antes de ejecutar el script, debes configurar las variables de entorno según tus necesidades. Abre el script con un editor de texto:

```bash
nanodeploy.sh
```

Busca la sección de variables al principio del archivo y modifica los valores según tus necesidades:

```bash
export SC_PROJECT_PATH="/opt/surviving-chernarus"
export SC_USER=$(whoami)
export SC_PUID=$(id -u $SC_USER)
export SC_PGID=$(id -g $SC_USER)
export SC_TZ="America/New_York" # Cambia a tu zona horaria
export SC_DOMAIN_NAME="tu-dominio.com" # Cambia a tu dominio real
export SC_CLOUDFLARE_EMAIL="tu-email@ejemplo.com" # Cambia a tu email de Cloudflare
export SC_CLOUDFLARE_API_TOKEN="tu_token_de_api_de_cloudflare" # Cambia a tu token de API
export SC_POSTGRES_DB="n8n_db"
export SC_POSTGRES_USER="n8n_user"
export SC_POSTGRES_PASSWORD="GeneraUnaContraseñaSeguraAquí1!"
export SC_PIHOLE_PASSWORD="GeneraOtraContraseñaSeguraAquí2!"
export SC_HOTSPOT_INTERFACE="wlan1" # Interfaz para el hotspot
export SC_INTERNET_INTERFACE="eth0" # Interfaz para la conexión a Internet
export SC_HOTSPOT_SSID="SurvivingChernarus"
export SC_HOTSPOT_PASSWORD="UnaContraseñaSeguraParaElHotspot!"
```

Guarda los cambios y sal del editor (en nano: Ctrl+O, Enter, Ctrl+X).

### 3. Ejecución del Script

Ejecuta el script de despliegue:

```bash
./deploy.sh
```

El script realizará las siguientes acciones:

1. Actualización del sistema y configuración del firewall
2. Instalación de Docker y Docker Compose
3. Creación de la estructura del proyecto y archivos de configuración
4. Configuración del punto de acceso Wi-Fi (si se especificó)
5. Despliegue de todos los servicios con Docker Compose

El proceso puede tardar entre 15 y 30 minutos dependiendo de la velocidad de tu conexión a Internet y el rendimiento de la Raspberry Pi.

## Verificación de la Instalación

Una vez completado el script, verifica que todos los servicios estén funcionando correctamente:

1. Comprueba el estado de los contenedores Docker:
   ```bash
   docker compose -f /opt/surviving-chernarus/docker-compose.yml ps
   ```

2. Verifica que puedes acceder a los servicios a través de sus respectivas URLs:
   - Panel de Control: `https://tu-dominio.com`
   - Traefik Dashboard: `https://traefik.tu-dominio.com`
   - Pi-hole Admin: `https://pihole.tu-dominio.com`
   - n8n Automation: `https://n8n.tu-dominio.com`
   - rTorrent/Flood UI: `https://rtorrent.tu-dominio.com`

3. Si configuraste el punto de acceso Wi-Fi, verifica que puedes conectarte a la red "SurvivingChernarus" (o el SSID que hayas configurado) desde otro dispositivo.

## Solución de Problemas

Si encuentras problemas durante la instalación, consulta la sección de [Solución de Problemas](troubleshooting.md) para obtener ayuda.

## Próximos Pasos

Una vez que hayas completado la instalación básica, puedes continuar con la [Configuración](configuration.md) para personalizar tu ecosistema Surviving Chernarus según tus necesidades específicas.