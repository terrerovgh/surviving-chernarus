# Guía Completa: CI/CD para Desplegar un Sitio Hugo en Raspberry Pi con GitHub Actions y Runner Auto-Alojado

## 1. Introducción

*   **Objetivo de la guía:** Configurar un sistema de Integración Continua y Despliegue Continuo (CI/CD) para el repositorio `terrerovgh/surviving-chernarus` (un proyecto Hugo). El objetivo es lograr el despliegue automático del sitio web en una Raspberry Pi 5 (ejecutando Arch Linux) cada vez que se realice un `push` a la rama `main`.
*   **Componentes clave:**
    *   **GitHub Actions:** Para orquestar el proceso de build y deploy.
    *   **Runner Auto-Alojado (Self-Hosted Runner):** Instalado en la Raspberry Pi para ejecutar los trabajos de despliegue en el entorno local.
    *   **GitHub CLI (`gh`):** Para la autenticación y gestión de tareas relacionadas con GitHub en la Raspberry Pi.
    *   **Nginx:** Como servidor web en la Raspberry Pi para servir el sitio Hugo.
*   **Flujo general:**
    1.  Un desarrollador realiza un `push` de cambios a la rama `main` del repositorio.
    2.  GitHub Actions detecta el `push` y dispara el workflow definido.
    3.  Un primer job (`build`) se ejecuta en un runner alojado por GitHub para compilar el sitio Hugo. El resultado (la carpeta `public/`) se sube como un artefacto.
    4.  Un segundo job (`deploy`) se ejecuta en el runner auto-alojado en la Raspberry Pi.
    5.  El runner auto-alojado descarga el artefacto (sitio compilado).
    6.  Un script (`deploy.sh`) en la Raspberry Pi se encarga de mover los archivos del sitio al directorio raíz de Nginx, ajustar permisos y reiniciar Nginx.
    7.  El sitio web `surviving-chernarus` se actualiza y sirve la nueva versión.

## 2. Prerrequisitos Generales

Antes de comenzar, asegúrate de contar con lo siguiente:

*   **Cuenta de GitHub:** Necesaria para alojar el repositorio y utilizar GitHub Actions.
*   **Repositorio `terrerovgh/surviving-chernarus`:** Este repositorio debe contener un proyecto Hugo funcional.
*   **Raspberry Pi 5:** Con Arch Linux instalado, configurado con una conexión a internet estable y acceso SSH (recomendado).
*   **Conocimientos básicos:** Es útil tener familiaridad con la línea de comandos de Linux, Git (control de versiones), y el funcionamiento básico de Hugo.

## 3. Configuración del Workflow de GitHub Actions

El corazón de nuestro sistema CI/CD es el archivo de workflow de GitHub Actions. Este archivo YAML define los eventos que disparan el workflow y los jobs que se ejecutarán.

*   **Explicación del archivo `.github/workflows/main.yml`:**
    Este archivo define el pipeline de CI/CD. Se activará con cada `push` a la rama `main`.
*   **Propósito de los dos jobs (`build` y `deploy`):**
    *   **`build`:** Este job se ejecuta en un entorno virtual proporcionado por GitHub (`ubuntu-latest`). Su responsabilidad es:
        1.  Obtener el código del repositorio.
        2.  Configurar el entorno de Hugo.
        3.  Construir el sitio Hugo (generando la carpeta `public`).
        4.  Empaquetar la carpeta `public` como un artefacto y subirlo para que esté disponible para el siguiente job.
    *   **`deploy`:** Este job depende del éxito del job `build` y se ejecuta en nuestro runner auto-alojado (etiquetado como `self-hosted`) en la Raspberry Pi. Su responsabilidad es:
        1.  Descargar el artefacto (la carpeta `public`) generado por el job `build`.
        2.  Ejecutar el script `deploy.sh` para transferir los archivos del sitio al directorio de Nginx y reiniciar el servidor web.

*   **Contenido de `.github/workflows/main.yml`:**

```yaml
# Workflow name
name: CI/CD Hugo Site to Raspberry Pi

# Triggers: This workflow runs on pushes to the main branch
on:
  push:
    branches:
      - main

jobs:
  # Build job: Builds the Hugo site using a GitHub-hosted runner
  build:
    runs-on: ubuntu-latest
    steps:
      # Step 1: Checkout the repository code
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          submodules: true  # Checkout submodules if any (e.g., themes)

      # Step 2: Setup Hugo
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.110.0' # Specify Hugo version
          extended: true          # Use Hugo extended version

      # Step 3: Build the Hugo site
      - name: Build Hugo site
        run: hugo --minify # Build the site and minify output

      # Step 4: Upload the build artifact (the 'public' directory)
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: hugo-site-public # Name of the artifact
          path: public          # Path to the directory to upload

  # Deploy job: Deploys the built site to the self-hosted Raspberry Pi runner
  deploy:
    runs-on: self-hosted # This job runs on the self-hosted runner (Raspberry Pi)
    needs: build         # This job depends on the successful completion of the 'build' job
    steps:
      # Step 1: Download the build artifact
      - name: Download artifact
        uses: actions/download-artifact@v3
        with:
          name: hugo-site-public # Name of the artifact to download
          path: ./downloaded-site # Destination path for the downloaded artifact

      # Step 2: Deploy to Nginx (or other web server)
      # This step assumes you have a 'deploy.sh' script in your repository root
      # and that your self-hosted runner has permissions to execute it and
      # place files in the web server's root directory.
      - name: Deploy to Nginx
        run: |
          echo "Starting deployment..."
          if [ -f ./deploy.sh ]; then
            chmod +x ./deploy.sh
            sh ./deploy.sh ./downloaded-site
            echo "Deployment script executed."
          else
            echo "ERROR: deploy.sh not found!"
            exit 1
          fi
        # Example of what deploy.sh might contain:
        # #!/bin/bash
        # # Check if source directory is provided
        # if [ -z "$1" ]; then
        #   echo "Usage: $0 <source_directory>"
        #   exit 1
        # fi
        # SOURCE_DIR="$1"
        # TARGET_DIR="/var/www/html" # Adjust to your Nginx web root
        # echo "Cleaning target directory: $TARGET_DIR"
        # sudo rm -rf "$TARGET_DIR"/*
        # echo "Copying new site files from $SOURCE_DIR to $TARGET_DIR"
        # sudo cp -r "$SOURCE_DIR"/* "$TARGET_DIR"/
        # echo "Deployment finished."
```

*   **Instrucciones sobre dónde colocar este archivo en el repositorio:**
    Crea un directorio llamado `.github` en la raíz de tu repositorio `terrerovgh/surviving-chernarus`. Dentro de `.github`, crea otro directorio llamado `workflows`. Guarda el contenido YAML anterior en un archivo llamado `main.yml` dentro de este directorio. La ruta completa será: `.github/workflows/main.yml`.

## 4. Configuración del Runner Auto-Alojado en Raspberry Pi (Arch Linux)

Esta sección es crucial ya que el runner auto-alojado es el puente entre GitHub Actions y tu Raspberry Pi.

*   **Guía Detallada:** La configuración completa del runner auto-alojado, incluyendo la instalación del software, creación de un usuario dedicado, y configuración como servicio `systemd`, se encuentra en el siguiente documento:
    *   **[12-Configuracion-Runner-Autoalojado.md](12-Configuracion-Runner-Autoalojado.md)**
*   **Resumen:** Esta guía cubre:
    *   Prerrequisitos de software en la Raspberry Pi (git, gh, nginx, etc.).
    *   Creación de un usuario `github-runner` dedicado por seguridad.
    *   Descarga, configuración y registro del software del runner de GitHub Actions en tu repositorio.
    *   Configuración del runner para que se ejecute como un servicio `systemd`, asegurando que se inicie automáticamente y se mantenga en ejecución.

## 5. Script de Despliegue en la Raspberry Pi (`deploy.sh`)

Este script es ejecutado por el runner auto-alojado en la Raspberry Pi. Su función es tomar los archivos del sitio Hugo compilado (descargados como artefacto) y desplegarlos en el servidor web Nginx.

*   **Explicación del propósito del script `deploy.sh`:**
    El script automatiza las siguientes tareas en la Raspberry Pi:
    1.  Recibe la ruta del artefacto descargado (que contiene el sitio Hugo compilado).
    2.  Crea el directorio raíz web de Nginx si no existe.
    3.  Utiliza `rsync` para sincronizar eficientemente el contenido del artefacto con el directorio raíz web, eliminando archivos antiguos del destino que no estén en la fuente.
    4.  Establece los permisos de archivo y propietario correctos (usuario `http`, grupo `http` para Nginx en Arch Linux) para los archivos del sitio.
    5.  Reinicia el servicio Nginx para que los cambios surtan efecto.
*   **Contenido de `deploy.sh`:**

```bash
#!/bin/bash

# --- Error Handling ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Cause a pipeline to return the exit status of the last command in the pipe that failed.
set -o pipefail

# --- Script Configuration ---
# NGINX_WEB_ROOT: The directory where Nginx serves files for this site.
# This path is standard for user-deployed sites on Arch Linux (under /srv/http/).
# IMPORTANT:
# 1. This directory will be created by the script if it doesn't exist.
# 2. The 'github-runner' user (or the user executing this script) needs sudo privileges
#    to create this directory, run rsync with delete, chown, chmod, and restart nginx.
NGINX_WEB_ROOT="/srv/http/surviving-chernarus"

# --- Input Parameter Validation ---
# Check if the path to the downloaded artifact is provided as the first argument.
if [ -z "$1" ]; then
  echo "Error: No artifact path provided."
  echo "Usage: $0 <path_to_artifact>"
  exit 1
fi

# Store the artifact path from the first argument.
ARTIFACT_PATH="$1"
echo "Artifact path: $ARTIFACT_PATH"

# --- Deployment Steps ---
echo "Starting deployment to Nginx web root: $NGINX_WEB_ROOT ..."

# 1. Create Nginx web root directory if it doesn't exist.
#    The -p flag ensures that parent directories are also created if needed,
#    and it doesn't error if the directory already exists.
echo "Ensuring Nginx web root directory exists: $NGINX_WEB_ROOT"
sudo mkdir -p "$NGINX_WEB_ROOT"

# 2. Clear existing content from Nginx web root and copy new site files.
#    Using rsync with --delete is an efficient way to synchronize the content.
#    The source path "$ARTIFACT_PATH/" (with a trailing slash) means "copy the contents
#    of ARTIFACT_PATH".
#    The destination path "$NGINX_WEB_ROOT/" ensures files are placed directly into it.
#    --delete will remove any files in $NGINX_WEB_ROOT that are not in $ARTIFACT_PATH.
echo "Clearing old content and copying new site files from $ARTIFACT_PATH to $NGINX_WEB_ROOT ..."
sudo rsync -a --delete "$ARTIFACT_PATH/" "$NGINX_WEB_ROOT/"

# 3. Set appropriate permissions for the web files.
#    This is crucial for security and for Nginx to be able to read the files.
#    On Arch Linux, Nginx typically runs as the 'http' user and group.
echo "Setting permissions for $NGINX_WEB_ROOT ..."
# Set ownership to http:http
sudo chown -R http:http "$NGINX_WEB_ROOT"
# Set directory permissions to 755 (rwxr-xr-x)
sudo find "$NGINX_WEB_ROOT" -type d -exec chmod 755 {} \;
# Set file permissions to 644 (rw-r--r--)
sudo find "$NGINX_WEB_ROOT" -type f -exec chmod 644 {} \;

# 4. Restart Nginx to apply changes.
#    This ensures that Nginx serves the new files.
echo "Restarting Nginx service ..."
sudo systemctl restart nginx

echo "-------------------------------------"
echo "Deployment completed successfully!"
echo "Site deployed to: $NGINX_WEB_ROOT"
echo "-------------------------------------"

exit 0
```

*   **Instrucciones sobre dónde colocar este script en el repositorio y cómo hacerlo ejecutable:**
    1.  Guarda el contenido del script en un archivo llamado `deploy.sh` en la **raíz de tu repositorio** `terrerovgh/surviving-chernarus`.
    2.  Hazlo ejecutable:
        ```bash
        git add deploy.sh
        git update-index --chmod=+x deploy.sh
        git commit -m "Add deploy script and make it executable"
        git push
        ```
        Alternativamente, puedes ejecutar `chmod +x deploy.sh` en tu entorno local antes de hacer `git add` y `git commit`. `git update-index --chmod=+x` es útil si el archivo ya está trackeado.

*   **Importante: Configuración de `sudo` para el runner:**
    El usuario `github-runner` (bajo el cual se ejecuta el servicio del runner en la Raspberry Pi) necesita permisos para ejecutar los comandos con `sudo` que se encuentran dentro de `deploy.sh` (específicamente `mkdir`, `rsync`, `chown`, `find`, y `systemctl`).
    La forma recomendada de configurar esto es editando el archivo `sudoers` en la Raspberry Pi.

    **Usa `sudo visudo` para editar el archivo `sudoers`. Nunca edites `sudoers` directamente con un editor de texto normal.**

    *   **Opción 1: Permitir `NOPASSWD` para comandos específicos (Más Seguro):**
        Esta es la opción preferida porque limita los comandos que `github-runner` puede ejecutar sin contraseña.
        Añade las siguientes líneas al final del archivo `sudoers` (usando `sudo visudo`):
        ```
        # Allow github-runner to execute specific deployment commands without a password
        Cmnd_Alias DEPLOY_COMMANDS = /usr/bin/mkdir, /usr/bin/rsync, /usr/bin/chown, /usr/bin/find, /usr/bin/systemctl restart nginx
        github-runner ALL=(ALL) NOPASSWD: DEPLOY_COMMANDS
        ```
        *Nota: Para `chown` y `find`, podrías ser aún más específico con los argumentos si fuera necesario, pero esto proporciona un buen balance entre seguridad y funcionalidad.*

    *   **Opción 2: Permitir `NOPASSWD` para el script completo (Menos Seguro):**
        Si eliges esta opción, asegúrate de que el script `deploy.sh` no sea modificable por usuarios no autorizados. La ruta al script puede ser un poco dinámica debido a cómo GitHub Actions clona el repositorio en el directorio de trabajo del runner (e.g., `/home/github-runner/actions-runner/_work/surviving-chernarus/surviving-chernarus/deploy.sh`). Debido a esta ruta dinámica, la Opción 1 (comandos específicos) es generalmente más robusta y segura.
        Si aun así deseas usar esta opción, y asumiendo que el script se encuentra en una ruta predecible que el runner utiliza, podrías añadir:
        `github-runner ALL=(ALL) NOPASSWD: /ruta/absoluta/al/deploy.sh`
        **Advertencia:** Esta opción es menos segura porque si el script `deploy.sh` es comprometido y modificado para incluir comandos maliciosos, estos se ejecutarán con `sudo` sin contraseña.

## 6. Uso y Autenticación de GitHub CLI (`gh`) en la Raspberry Pi

La herramienta `gh` es esencial para que el runner auto-alojado se autentique con GitHub y para diversas tareas de administración y diagnóstico.

*   **Guía Detallada:** Las instrucciones completas para instalar y autenticar `gh` para el usuario `github-runner` en tu Raspberry Pi se encuentran aquí:
    *   **[13-GitHub-CLI-Autenticacion.md](13-GitHub-CLI-Autenticacion.md)**
*   **Resumen:** Este documento explica:
    *   Cómo instalar `gh` en Arch Linux.
    *   El proceso paso a paso para autenticar `gh` usando un Personal Access Token (PAT), asegurando que el usuario `github-runner` pueda interactuar con tu repositorio.
    *   Cómo `gh` almacena de forma segura el token.

## 7. Gestión de Secretos (Personal Access Tokens - PAT)

El manejo adecuado de los Personal Access Tokens (PATs) es vital para la seguridad de tu configuración.

*   **Guía Detallada:** Aprende sobre la gestión de PATs tanto en GitHub Actions como en la configuración local de `gh` en la Raspberry Pi:
    *   **[14-Gestion-Secretos.md](14-Gestion-Secretos.md)**
*   **Resumen:** Este documento cubre:
    *   Cómo configurar secretos a nivel de repositorio en GitHub Actions (aunque no se usan directamente para la autenticación del runner en este flujo específico).
    *   Cómo el PAT para `gh` se maneja de forma segura en la Raspberry Pi.
    *   Buenas prácticas cruciales para la creación, uso y gestión de PATs (principio de menor privilegio, expiración, no incrustar tokens en código, etc.).

## 8. Configuración de Nginx

Nginx es el servidor web que mostrará tu sitio Hugo al mundo. Aquí se asume que ya tienes Nginx instalado (cubierto en los prerrequisitos de la guía del runner).

*   **Directorio Raíz Web:** El script `deploy.sh` está configurado para desplegar los archivos del sitio en `/srv/http/surviving-chernarus`.
*   **Archivo de Configuración del Sitio (Virtual Host):**
    Crea un archivo de configuración para tu sitio en Nginx. Por ejemplo, `/etc/nginx/sites-available/surviving-chernarus.conf`:
    ```bash
    sudo nano /etc/nginx/sites-available/surviving-chernarus.conf
    ```
    Pega la siguiente configuración, **ajustando `server_name`** a la dirección IP de tu Raspberry Pi o a tu nombre de dominio si tienes uno configurado:

    ```nginx
    server {
        listen 80;
        # Cambia 'tu_dominio_o_ip_de_rpi' por la IP de tu Raspberry Pi
        # o tu nombre de dominio si lo tienes.
        server_name tu_dominio_o_ip_de_rpi;

        # Directorio raíz donde se encuentran los archivos de tu sitio Hugo
        root /srv/http/surviving-chernarus;
        index index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }

        # Opcional: Configuraciones de logs
        access_log /var/log/nginx/surviving-chernarus.access.log;
        error_log /var/log/nginx/surviving-chernarus.error.log;

        # Opcional: Para mejorar la entrega de assets estáticos
        location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1M; # Cache de 1 mes para assets estáticos
            add_header Cache-Control "public";
        }
    }
    ```

*   **Habilitar el Sitio y Probar Configuración:**
    1.  Crea un enlace simbólico desde `sites-available` a `sites-enabled` para activar la configuración:
        ```bash
        sudo ln -s /etc/nginx/sites-available/surviving-chernarus.conf /etc/nginx/sites-enabled/surviving-chernarus.conf
        ```
        (Si el archivo ya existe en `sites-enabled` porque es la configuración por defecto, este paso podría no ser necesario o podrías estar editando el archivo por defecto directamente).
    2.  Prueba la configuración de Nginx para asegurarte de que no hay errores de sintaxis:
        ```bash
        sudo nginx -t
        ```
        Si muestra "syntax is ok" y "test is successful", todo está bien.
    3.  Recarga o reinicia Nginx para aplicar los cambios (el script `deploy.sh` ya incluye un reinicio, pero si haces cambios manuales en la configuración de Nginx, necesitarás recargarlo):
        ```bash
        sudo systemctl reload nginx
        ```
        o
        ```bash
        sudo systemctl restart nginx
        ```

## 9. Puesta en Marcha y Pruebas

Con todos los componentes configurados, es hora de poner en marcha el sistema y probarlo.

*   **Resumen de los pasos para activar todo:**
    1.  Asegúrate de que el archivo de workflow `.github/workflows/main.yml` y el script `deploy.sh` están en tu repositorio (`terrerovgh/surviving-chernarus`) y que los cambios han sido subidos a GitHub (`git push`).
    2.  Verifica que el runner auto-alojado está configurado, en línea y escuchando trabajos en tu Raspberry Pi (revisa el estado del servicio `systemd` y la sección "Runners" en la configuración de tu repositorio en GitHub).
    3.  Confirma que `gh` está autenticado para el usuario `github-runner` en la Raspberry Pi.
    4.  Revisa que Nginx esté configurado con el virtual host para servir el sitio desde `/srv/http/surviving-chernarus` y que el servicio Nginx esté corriendo.
    5.  Asegúrate de que los permisos de `sudo` para el usuario `github-runner` (para ejecutar los comandos en `deploy.sh`) estén correctamente configurados en el archivo `sudoers` de la Raspberry Pi.

*   **Cómo probar:**
    1.  Realiza un cambio en tu sitio Hugo (e.g., modifica un archivo de contenido, crea un nuevo post).
    2.  Haz `commit` de los cambios y luego `push` a la rama `main` de tu repositorio en GitHub.
        ```bash
        git add .
        git commit -m "Prueba de despliegue CI/CD"
        git push origin main
        ```
    3.  Observa el workflow en la pestaña "Actions" de tu repositorio en GitHub. Deberías ver el workflow dispararse.
    4.  Sigue el progreso del job `build`. Una vez completado, sigue el progreso del job `deploy`.
    5.  Si todo va bien, el job `deploy` debería finalizar con éxito.
    6.  Abre un navegador web y accede a la dirección de tu Raspberry Pi (la que configuraste en `server_name` en Nginx). Deberías ver tu sitio Hugo actualizado.

*   **Troubleshooting básico (Solución de problemas):**
    *   **Logs de GitHub Actions:** Revisa la salida de cada paso en los jobs `build` y `deploy` directamente en la interfaz de GitHub Actions. Aquí encontrarás errores de compilación de Hugo, problemas de descarga/subida de artefactos, o errores del script `deploy.sh`.
    *   **Logs del Runner en la Raspberry Pi:** Los logs del servicio del runner pueden proporcionar información si el runner no se conecta o no recoge trabajos. Usa `journalctl -u NOMBRE_DEL_SERVICIO_DEL_RUNNER -f` (reemplaza con el nombre real de tu servicio de runner). También puedes encontrar logs más detallados dentro del directorio de instalación del runner en la carpeta `_diag`.
    *   **Logs de Nginx en la Raspberry Pi:**
        *   `access_log` (`/var/log/nginx/surviving-chernarus.access.log` o el general `/var/log/nginx/access.log`): Muestra las peticiones HTTP recibidas por Nginx.
        *   `error_log` (`/var/log/nginx/surviving-chernarus.error.log` o el general `/var/log/nginx/error.log`): Registra errores de Nginx, como problemas de permisos de archivo, errores de configuración, etc.
    *   **Verificar permisos de `sudo`:** Si el `deploy.sh` falla en la Raspberry Pi, asegúrate de que los permisos en `sudoers` son correctos y que el usuario `github-runner` puede ejecutar los comandos necesarios.

## 10. Conclusión

¡Felicidades! Si has seguido esta guía, ahora tienes un sistema de CI/CD completamente funcional que compila tu sitio Hugo y lo despliega automáticamente en tu Raspberry Pi cada vez que haces un push a tu rama `main`. Esta configuración te ahorra el trabajo manual de compilación y despliegue, permitiéndote enfocarte en crear contenido para tu sitio.

*   **Posibles mejoras futuras:**
    *   **Notificaciones:** Configurar notificaciones (e.g., por email o Slack) sobre el estado de los workflows (éxito o fallo).
    *   **Manejo de Fallos Avanzado:** Implementar estrategias de rollback o alertas más detalladas si un despliegue falla.
    *   **Pruebas Automatizadas:** Añadir un paso de pruebas (e.g., `hugo server -D` y luego `curl` para verificar que el sitio se construye correctamente, o pruebas de enlaces rotos) en el job `build`.
    *   **Seguridad Avanzada:** Implementar HTTPS usando Let's Encrypt para tu sitio Nginx.
    *   **Optimización de la Build:** Para sitios muy grandes, explorar estrategias de caché de Hugo o de dependencias para acelerar el job `build`.

Esta guía proporciona una base sólida. ¡Siéntete libre de adaptarla y expandirla según tus necesidades!
```
