# Instalación de Arch Linux en Raspberry Pi 5

Este apartado te guiará a través del proceso de instalación de Arch Linux ARM en tu Raspberry Pi 5, desde la descarga de la imagen hasta la configuración inicial y actualización del sistema.

## Descargar la Imagen de Arch Linux ARM
El primer paso es obtener la imagen más reciente de Arch Linux ARM para la Raspberry Pi 5.

1.  Visita la página oficial del proyecto Arch Linux ARM para las imágenes de Raspberry Pi:
    *   [https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-5](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-5)
    *   Busca la sección "Installation" o "Downloads".
2.  Descarga la última versión disponible de la imagen para la Raspberry Pi 5. Generalmente, el enlace de descarga estará etiquetado como "Latest Release" o similar.
3.  El archivo descargado será un fichero comprimido, típicamente con extensión `.tar.gz`. Deberás descomprimir este archivo para obtener el fichero de imagen (`.img`) que flashearás en la tarjeta microSD.
    *   En Linux o macOS, puedes usar el comando: `tar -xzf ArchLinuxARM-rpi-5-latest.tar.gz` (sustituye el nombre del archivo si es diferente).
    *   En Windows, puedes usar herramientas como 7-Zip.

## Flashear la Imagen en la Tarjeta microSD
Una vez que tengas el archivo `.img` de Arch Linux, utilizarás Raspberry Pi Imager para escribirlo en tu tarjeta microSD.

1.  Abre Raspberry Pi Imager en tu computadora.
2.  Haz clic en "CHOOSE DEVICE" y selecciona "Raspberry Pi 5".
3.  Haz clic en "CHOOSE OS". En el menú desplegable, selecciona "Use custom".
4.  Navega y selecciona el archivo de imagen `.img` de Arch Linux que descomprimiste en el paso anterior.
5.  Haz clic en "CHOOSE STORAGE" y selecciona tu tarjeta microSD.
    *   **¡ADVERTENCIA!** Este proceso borrará todos los datos existentes en la tarjeta microSD. Asegúrate de haber seleccionado la tarjeta correcta y de haber respaldado cualquier dato importante.
6.  Haz clic en "NEXT". Se te podría preguntar si deseas aplicar personalizaciones del SO. Por ahora, puedes seleccionar "No" o "No, use basic settings", ya que configuraremos el sistema manualmente.
7.  Revisa las selecciones y haz clic en "WRITE" (o "YES" para confirmar) para comenzar el proceso de escritura.
8.  Espera pacientemente a que Raspberry Pi Imager termine de escribir y verificar la imagen en la tarjeta. Esto puede tardar varios minutos.

## Primer Arranque y Configuración Inicial
Con la imagen de Arch Linux ya en la microSD, es momento de arrancar tu Raspberry Pi 5.

1.  Inserta la tarjeta microSD en la Raspberry Pi 5.
2.  Conecta los periféricos:
    *   Teclado USB
    *   Ratón USB (opcional, pero útil para entornos gráficos futuros)
    *   Monitor (mediante el cable micro-HDMI)
    *   Cable Ethernet (recomendado para la primera configuración y actualización)
3.  Conecta la fuente de alimentación USB-C para encender la Raspberry Pi 5.
4.  La Raspberry Pi 5 arrancará Arch Linux ARM. Por defecto, los credenciales de acceso son:
    *   Usuario: `alarm`
    *   Contraseña: `alarm`
    *   Usuario root: `root`
    *   Contraseña root: `root`
5.  **Cambio de Contraseñas (¡MUY IMPORTANTE!):** Lo primero que debes hacer por seguridad es cambiar las contraseñas por defecto. Abre una terminal o accede a la consola y ejecuta:
    *   `passwd alarm` (sigue las instrucciones para cambiar la contraseña del usuario `alarm`)
    *   `su -` (para cambiar al usuario root, introduce la contraseña `root`)
    *   `passwd root` (sigue las instrucciones para cambiar la contraseña del usuario `root`)
    *   Escribe `exit` para volver al usuario `alarm` si es necesario.
6.  **Configuración Básica del Sistema:**
    *   **Hostname:** Asigna un nombre de host a tu Raspberry Pi. Reemplaza `nombre-deseado` con el nombre que prefieras (e.g., `rpi5-arch`).
        ```bash
        sudo hostnamectl set-hostname nombre-deseado
        ```
    *   **Zona Horaria:** Configura tu zona horaria.
        *   Para listar las zonas horarias disponibles: `timedatectl list-timezones`
        *   Para establecer la zona horaria (ejemplo para España):
            ```bash
            sudo timedatectl set-timezone Europe/Madrid
            ```
    *   **Locale (Idioma y Codificación):** Configura el idioma y la codificación de caracteres del sistema.
        *   Edita el archivo `/etc/locale.gen`. Puedes usar `nano` (si no está, instálalo con `sudo pacman -S nano`):
            ```bash
            sudo nano /etc/locale.gen
            ```
            Busca la línea correspondiente a tu locale (e.g., `es_ES.UTF-8 UTF-8`) y descoméntala (elimina el `#` al inicio). Guarda el archivo y cierra `nano` (Ctrl+X, luego Y, luego Enter).
        *   Genera los locales:
            ```bash
            sudo locale-gen
            ```
        *   Crea o edita el archivo `/etc/locale.conf` para establecer el locale por defecto:
            ```bash
            sudo nano /etc/locale.conf
            ```
            Añade la siguiente línea (o modifica la existente):
            ```
            LANG=es_ES.UTF-8
            ```
            Guarda y cierra el archivo.
            Es posible que necesites reiniciar para que todos los cambios de locale surtan efecto completamente, o al menos cerrar sesión y volver a iniciarla.

## Actualizar el Sistema
Una vez configurado lo básico, es fundamental actualizar tu sistema para tener los últimos paquetes y parches de seguridad.

1.  Sincroniza la base de datos de paquetes de `pacman` (el gestor de paquetes de Arch Linux) y actualiza todos los paquetes instalados:
    ```bash
    sudo pacman -Syu
    ```
2.  Confirma la actualización presionando `Y` cuando se te solicite.
3.  Este comando (`sudo pacman -Syu`) es el que usarás regularmente para mantener tu sistema Arch Linux actualizado. Se recomienda ejecutarlo periódicamente.

¡Felicidades! Ahora tienes una instalación base de Arch Linux funcionando en tu Raspberry Pi 5, lista para las siguientes etapas del proyecto Escrowed Kathy.
