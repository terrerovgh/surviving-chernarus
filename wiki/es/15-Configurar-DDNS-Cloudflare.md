# Configurar DDNS Dinámico con Cloudflare

## 1. Introducción/Propósito

El script `cloudflare_ddns.py` está diseñado para mantener actualizado un registro DNS 'A' en Cloudflare con la dirección IP pública dinámica de tu Raspberry Pi (o cualquier máquina donde se ejecute). Esto es útil si tu proveedor de internet te asigna direcciones IP que cambian con el tiempo, permitiéndote tener un nombre de dominio fijo (ej. `rpi.terrerov.com`) que siempre apunte a tu red local.

El script:
1. Obtiene la dirección IP pública actual de la máquina.
2. Comprueba el registro DNS 'A' configurado en Cloudflare.
3. Si la IP pública ha cambiado, actualiza el registro DNS en Cloudflare con la nueva IP.

## 2. Dependencias/Prerrequisitos

Antes de configurar y ejecutar el script, asegúrate de tener lo siguiente:

*   **Python 3:** Instalado en el sistema donde se ejecutará el script (generalmente tu Raspberry Pi).
    ```bash
    sudo apt update
    sudo apt install python3
    ```
*   **Librería `requests` de Python:** Necesaria para realizar peticiones HTTP a los servicios de IP y a la API de Cloudflare.
    ```bash
    pip3 install requests
    ```
    O, si prefieres usar `apt` para la versión del sistema (puede ser más antigua):
    ```bash
    sudo apt install python3-requests
    ```
*   **Cuenta de Cloudflare y Dominio:** Debes tener una cuenta activa en [Cloudflare](https://www.cloudflare.com/) y un dominio (ej. `terrerov.com`) añadido y gestionado a través de sus servicios.
*   **Registro DNS 'A' (Recomendado):** Es ideal que el registro DNS 'A' que deseas actualizar (ej. `rpi.terrerov.com`) ya esté creado en tu panel de Cloudflare. Si el script no lo encuentra, mostrará una advertencia y no intentará crearlo automáticamente (requiere creación manual la primera vez).

## 3. Obtención del Token de API de Cloudflare

Para que el script pueda interactuar con tu cuenta de Cloudflare de forma segura, necesitas generar un Token de API con permisos específicos.

1.  **Inicia sesión en Cloudflare:** Ve a [dash.cloudflare.com](https://dash.cloudflare.com).
2.  **Ve a "My Profile":** Haz clic en el icono de perfil en la esquina superior derecha.
3.  **Selecciona "API Tokens":** En el menú lateral izquierdo de tu perfil.
4.  **Haz clic en "Create Token".**
5.  **Usa una plantilla (recomendado) o crea uno personalizado:**
    *   La opción más sencilla es buscar la plantilla "Edit zone DNS". Si no la encuentras, puedes crear uno personalizado.
    *   Para un **token personalizado**, asígnale un nombre descriptivo (ej. "DDNS_Token_RPi").
6.  **Configura los Permisos:**
    *   **Permissions:**
        *   Selecciona `Zone`
        *   Selecciona `DNS`
        *   Selecciona `Edit`
    *   **Zone Resources:**
        *   Selecciona `Include`
        *   Selecciona `Specific zone`
        *   Elige el dominio que quieres gestionar (ej. `terrerov.com`).
    *   Puedes dejar "Client IP Address Filtering" y "TTL" con sus valores predeterminados o ajustarlos si tienes necesidades específicas de seguridad.
7.  **Haz clic en "Continue to summary".**
8.  **Revisa los permisos y haz clic en "Create Token".**
9.  **¡COPIA EL TOKEN INMEDIATAMENTE!** Cloudflare te mostrará el token generado. Cópialo y guárdalo en un lugar seguro. **No podrás verlo de nuevo.** Este token es el que usarás para la variable de entorno `CLOUDFLARE_API_TOKEN`.

## 4. Configuración del Script (Variables de Entorno)

El script `cloudflare_ddns.py` se configura mediante las siguientes tres variables de entorno:

*   `CLOUDFLARE_API_TOKEN`: Pega aquí el token de API que generaste en el paso anterior.
*   `CLOUDFLARE_ZONE_NAME`: Es el nombre de tu dominio gestionado en Cloudflare. Por ejemplo, si tu dominio es `terrerov.com`, ese es el valor.
*   `CLOUDFLARE_RECORD_NAME`: Es el nombre completo del registro 'A' que quieres actualizar. Por ejemplo, si quieres que `rpi.terrerov.com` apunte a tu IP, este sería el valor. Si quieres actualizar el registro raíz (ej. `terrerov.com` directamente), usarías `terrerov.com`.

Estas variables se gestionarán de forma centralizada en el proyecto a través de un archivo `.env` ubicado en `/opt/surviving-chernarus/.env`. El script de ejecución periódica (cron job) se encargará de cargar estas variables desde dicho archivo.

## 5. Ejecución Manual del Script

Para probar el script manualmente, primero asegúrate de que las variables de entorno estén definidas en tu sesión actual o carga el archivo `.env`.

**Opción 1: Exportar variables temporalmente**
```bash
export CLOUDFLARE_API_TOKEN="tu_api_token_aqui"
export CLOUDFLARE_ZONE_NAME="terrerov.com"
export CLOUDFLARE_RECORD_NAME="rpi.terrerov.com"
python3 /opt/surviving-chernarus/scripts/cloudflare_ddns.py
```

**Opción 2: Cargar desde .env y ejecutar (recomendado para pruebas si .env ya está configurado)**
```bash
# Suponiendo que estás en el directorio /opt/surviving-chernarus/
source .env
python3 scripts/cloudflare_ddns.py
```

El script imprimirá información sobre su progreso, incluyendo la IP pública detectada, la IP actual en Cloudflare y si se necesita o no una actualización.

## 6. Ejecución Periódica (Cron Job)

Para que el script se ejecute automáticamente y mantenga tu DNS actualizado, puedes configurar un cron job.

1.  Abre la tabla de cron para el usuario `root` (o el usuario que deba ejecutar el script, asegurándote de que tenga acceso a Python, al script y al archivo `.env`):
    ```bash
    sudo crontab -e
    ```
2.  Añade la siguiente línea al final del archivo para ejecutar el script cada 15 minutos:

    ```cron
    */15 * * * * bash -c 'source /opt/surviving-chernarus/.env && /usr/bin/python3 /opt/surviving-chernarus/scripts/cloudflare_ddns.py' >> /var/log/cloudflare_ddns.log 2>&1
    ```

    **Desglose del comando cron:**
    *   `*/15 * * * *`: Define la frecuencia (cada 15 minutos).
    *   `bash -c '...'`: Ejecuta el comando dentro de las comillas simples usando bash. Esto es útil para encadenar comandos como `source` y la ejecución del script.
    *   `source /opt/surviving-chernarus/.env`: Carga las variables de entorno desde el archivo `.env` antes de ejecutar el script. **Asegúrate de que la ruta al archivo `.env` sea correcta.**
    *   `/usr/bin/python3 /opt/surviving-chernarus/scripts/cloudflare_ddns.py`: Ruta completa al intérprete de Python 3 y al script. **Verifica estas rutas en tu sistema.**
    *   `>> /var/log/cloudflare_ddns.log 2>&1`: Redirige tanto la salida estándar (stdout) como la salida de error (stderr) al archivo de log `/var/log/cloudflare_ddns.log`. Esto es crucial para el seguimiento y la depuración.

3.  Guarda y cierra el archivo. El cron job se activará automáticamente.

## 7. Logging (Registro)

Como se mencionó anteriormente, el script `cloudflare_ddns.py` imprime mensajes informativos y de error a la salida estándar (stdout) y a la salida de error estándar (stderr).

Cuando se ejecuta mediante el cron job configurado en el ejemplo anterior:
*   Toda la salida se redirige al archivo `/var/log/cloudflare_ddns.log`.
*   Puedes revisar este archivo para verificar que el script se está ejecutando correctamente, ver las IPs detectadas y cualquier error que pueda haber ocurrido.
    ```bash
    tail -f /var/log/cloudflare_ddns.log
    ```

Es recomendable revisar este log periódicamente, especialmente después de la configuración inicial, para asegurar el correcto funcionamiento del sistema DDNS.
