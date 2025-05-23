# Configuración del Runner Auto-Alojado en Raspberry Pi (Arch Linux)

## Introducción
Un runner auto-alojado (self-hosted runner) es una aplicación que instalas y ejecutas en tu propia infraestructura (en este caso, tu Raspberry Pi) para procesar trabajos (jobs) de tus flujos de trabajo de GitHub Actions. Para nuestro flujo de CI/CD, donde queremos desplegar el sitio Hugo compilado en la Raspberry Pi que también sirve como servidor web, un runner auto-alojado es esencial. Permite que GitHub Actions interactúe directamente con el entorno de despliegue.

Este documento te guiará a través de la instalación y configuración de un runner auto-alojado en tu Raspberry Pi 5 con Arch Linux.

## Prerrequisitos en la Raspberry Pi
Antes de configurar el runner, asegúrate de que tu sistema Arch Linux en la Raspberry Pi esté preparado:

1.  **Sistema Actualizado:**
    Es crucial tener el sistema al día. Abre una terminal y ejecuta:
    ```bash
    sudo pacman -Syu
    ```

2.  **Git:**
    Necesario para que el runner clone repositorios.
    ```bash
    sudo pacman -S --noconfirm --needed git
    ```
    (`--noconfirm` evita la pregunta y `--needed` solo instala si no está presente o es una versión más antigua).

3.  **GitHub CLI (`gh`):**
    Útil para interactuar con GitHub desde la línea de comandos, especialmente para la autenticación.
    ```bash
    sudo pacman -S --noconfirm --needed github-cli
    ```

4.  **Herramientas de Descarga y Compresión:**
    `curl` para descargar el software del runner y `tar` para extraerlo.
    ```bash
    sudo pacman -S --noconfirm --needed tar curl
    ```

5.  **`jq` (Opcional pero recomendado):**
    Una herramienta para procesar JSON, útil para extraer información como la URL de descarga del runner.
    ```bash
    sudo pacman -S --noconfirm --needed jq
    ```

6.  **Servidor Web Nginx:**
    Nginx servirá nuestro sitio Hugo.
    ```bash
    sudo pacman -S --noconfirm --needed nginx
    ```
    *   **Habilitar e Iniciar Nginx:**
        Para que Nginx se inicie automáticamente con el sistema y arranque ahora:
        ```bash
        sudo systemctl enable --now nginx
        ```
    *   **Verificar Nginx:**
        Abre un navegador web en una computadora de tu red local y navega a la dirección IP de tu Raspberry Pi (e.g., `http://DIRECCION_IP_RASPBERRY_PI`). Deberías ver la página de bienvenida de Nginx ("Welcome to nginx!").

7.  **Opcional: Hugo:**
    Aunque el flujo de trabajo propuesto (Opción A) construye el sitio en un runner alojado por GitHub, podrías querer instalar Hugo en la Raspberry Pi para pruebas locales o como parte de un script de despliegue más complejo.
    ```bash
    sudo pacman -S --noconfirm --needed hugo
    ```

## Crear un Usuario Dedicado para el Runner (Recomendado)
Por razones de seguridad, es una mala práctica ejecutar el runner de GitHub Actions con el usuario `root` o con tu usuario personal. Crear un usuario dedicado con privilegios limitados es la mejor opción.

1.  **Crear el usuario `github-runner`:**
    ```bash
    sudo useradd -m -s /bin/bash github-runner
    ```
    *   `-m`: Crea el directorio home del usuario (e.g., `/home/github-runner`).
    *   `-s /bin/bash`: Establece bash como el shell por defecto.

2.  **Establecer una contraseña para el nuevo usuario:**
    ```bash
    sudo passwd github-runner
    ```
    Sigue las instrucciones para crear una contraseña segura. Alternativamente, si solo vas a acceder a este usuario mediante `sudo -u github-runner ...` o SSH con claves, una contraseña local podría no ser estrictamente necesaria, pero es una buena práctica tenerla.

3.  **Permisos `sudo` (con precaución):**
    El runner en sí mismo no debería necesitar permisos `sudo` para sus operaciones normales. Sin embargo, tu *script de despliegue* (e.g., `deploy.sh`) que el runner ejecutará sí podría necesitar `sudo` para copiar archivos al directorio raíz de Nginx (e.g., `/var/www/html/`) y para reiniciar el servicio Nginx.

    La mejor práctica es que el script `deploy.sh` maneje los comandos `sudo` internamente. Por ejemplo, el script podría empezar con una verificación de que se ejecuta con `sudo` o llamar a `sudo` para comandos específicos.

    Si necesitas que el usuario `github-runner` pueda ejecutar ciertos comandos específicos sin contraseña, puedes usar `visudo`. Por ejemplo, para permitir reiniciar Nginx y usar `rsync` (solo como ejemplo ilustrativo, **adapta esto cuidadosamente a tus necesidades y script de despliegue**):
    ```bash
    # sudo visudo
    ```
    Y añadir una línea como:
    `github-runner ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/cp, /usr/bin/rm`
    **Advertencia:** `NOPASSWD` debe usarse con extrema precaución y solo para comandos muy específicos y seguros. Es preferible que el script de despliegue sea el que pida `sudo` si es necesario, o que el runner ejecute un script que ya tenga los permisos adecuados (por ejemplo, mediante `sudo` en el propio comando del workflow, aunque esto también tiene implicaciones de seguridad).

    Para el propósito de esta guía, asumiremos que el `deploy.sh` que el runner invoca manejará los permisos `sudo` necesarios internamente.

## Instalar y Configurar el Runner de GitHub Actions
La instalación se realiza como el usuario `github-runner` en su directorio home.

1.  **Navega a GitHub para obtener instrucciones y token:**
    *   En tu navegador, ve a tu repositorio: `https://github.com/terrerovgh/surviving-chernarus`
    *   Haz clic en "Settings" (Configuración).
    *   En el menú de la izquierda, ve a "Actions" y luego a "Runners".
    *   Haz clic en el botón "New self-hosted runner".
    *   Selecciona "Linux" como sistema operativo y "ARM64" como arquitectura.
    *   GitHub te proporcionará una serie de comandos, incluyendo un token de registro. **Este token es sensible y único para tu repositorio.**

2.  **Pasos Generales (ejecutados como `github-runner`):**
    Los siguientes comandos son una guía basada en lo que GitHub proporciona. Asegúrate de usar los comandos exactos y el token de la página de GitHub.

    *   **Crear directorio para el runner y navegar a él:**
        Estos comandos deben ejecutarse como el usuario `github-runner`. Puedes cambiar a este usuario con `su - github-runner` o prefijar los comandos con `sudo -u github-runner sh -c '...'`.
        ```bash
        sudo -u github-runner mkdir -p /home/github-runner/actions-runner
        cd /home/github-runner/actions-runner
        ```
        **Nota:** A partir de aquí, los siguientes comandos de descarga y configuración se deben ejecutar en este directorio (`/home/github-runner/actions-runner`) **y como el usuario `github-runner`**. Para ello, puedes abrir una sesión shell como `github-runner`:
        ```bash
        sudo su - github-runner
        # Ahora estás como el usuario github-runner en su home.
        # Navega al directorio creado si no estás ya allí:
        cd /home/github-runner/actions-runner
        ```

    *   **Descargar el último paquete del runner:**
        (Los siguientes comandos asumen que estás operando como `github-runner` en el directorio `/home/github-runner/actions-runner`)
        ```bash
        # Obtener la última versión del runner
        export RUNNER_VERSION=$(curl -s -L https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
        # Descargar el paquete
        curl -L -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
        ```
        Verifica que la arquitectura sea `arm64` para la Raspberry Pi 5.

    *   **Verificar el hash (opcional pero recomendado):**
        GitHub proporciona un hash SHA256 para el paquete. Puedes verificarlo con:
        ```bash
        echo "<HASH_PROPORCIONADO_POR_GITHUB> actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" | sha256sum -c
        ```
        Debería indicar "OK".

    *   **Extraer el instalador:**
        ```bash
        tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
        ```

    *   **Configurar el runner:**
        Aquí es donde usarás el token que obtuviste de la página de GitHub.
        **¡NO PEGUES TU TOKEN DIRECTAMENTE EN SCRIPTS QUE SUBAS AL REPOSITORIO!**
        ```bash
        ./config.sh --url https://github.com/terrerovgh/surviving-chernarus --token TU_TOKEN_DE_REGISTRO_AQUI
        ```
        Sigue las instrucciones:
        *   **Enter the name of runner group to add this runner to:** Presiona Enter para el default.
        *   **Enter the name of runner to use:** Sugiere un nombre descriptivo, e.g., `rp5-arch-surviving-chernarus`.
        *   **Enter any additional labels (comma separated):** Sugiere `self-hosted,linux,arm64`. El flujo de trabajo (`main.yml`) usará `self-hosted` para seleccionar este runner.
        *   **Enter name of work folder:** Presiona Enter para el default (`_work`).

## Ejecutar el Runner como un Servicio (systemd)
Para que el runner se ejecute de forma continua y se reinicie automáticamente, es mejor configurarlo como un servicio `systemd`. Los siguientes comandos se ejecutan desde el directorio del runner (`/home/github-runner/actions-runner`), pero el comando `svc.sh` necesita `sudo` para instalar el servicio.

1.  **Instalar el servicio:**
    Este comando debe ejecutarse desde el directorio donde extrajiste y configuraste el runner (e.g., `/home/github-runner/actions-runner`). El `github-runner` al final del comando es el nombre del usuario bajo el cual se ejecutará el servicio.
    ```bash
    sudo ./svc.sh install github-runner
    ```

2.  **Iniciar el servicio:**
    El nombre del servicio se genera basado en tu repositorio y nombre de runner. Puedes encontrar el nombre exacto con `systemctl list-units | grep actions.runner`.
    Un ejemplo del nombre podría ser: `actions.runner.terrerovgh.surviving-chernarus.rp5-arch-surviving-chernarus.service`.
    ```bash
    sudo systemctl start NOMBRE_DEL_SERVICIO_DEL_RUNNER
    ```
    Reemplaza `NOMBRE_DEL_SERVICIO_DEL_RUNNER` con el nombre real.

3.  **Habilitar para inicio automático:**
    ```bash
    sudo systemctl enable NOMBRE_DEL_SERVICIO_DEL_RUNNER
    ```

4.  **Verificar el estado del servicio:**
    ```bash
    sudo systemctl status NOMBRE_DEL_SERVICIO_DEL_RUNNER
    ```
    Deberías ver que está "active (running)". También puedes revisar los logs con `journalctl -u NOMBRE_DEL_SERVICIO_DEL_RUNNER -f`.

    Una vez que el servicio esté corriendo, deberías ver tu runner listado como "Idle" en la sección "Settings" > "Actions" > "Runners" de tu repositorio en GitHub.

## Consideraciones de Seguridad y Mantenimiento

*   **Permisos del Runner:** Ejecuta siempre el runner con un usuario de privilegios mínimos (`github-runner` en este caso). Evita darle más permisos `sudo` de los estrictamente necesarios.
*   **Actualizaciones del Runner:** El software del runner se actualiza periódicamente. GitHub Actions generalmente maneja esto indicando cuándo una versión es obsoleta. Puede que necesites descargar la nueva versión y reconfigurar el servicio. Revisa los logs del runner y la interfaz de GitHub para notificaciones.
*   **Seguridad del Token de Registro y PATs:** Aunque el token de registro se usa una sola vez para conectar el runner, el runner tiene acceso a un `GITHUB_TOKEN` con permisos sobre el repositorio durante la ejecución de los workflows. Para la gestión general de Personal Access Tokens (PATs) y otros secretos, consulta las guías `[[14-Gestion-Secretos]]` y el archivo `SECURITY.md` del proyecto. Asegúrate de que el runner solo pueda ejecutar los scripts y comandos necesarios.
*   **Acceso a la Red:** La Raspberry Pi debe tener acceso saliente a `github.com` y a las URLs de descarga de artefactos (generalmente `*.actions.githubusercontent.com`).
*   **Firewall:** Si tienes un firewall configurado en la Raspberry Pi (como `ufw` o `iptables`), asegúrate de que no bloquea las conexiones salientes necesarias para el runner. Para `ufw`, el tráfico saliente suele estar permitido por defecto.

## Autenticación de GitHub CLI (`gh`) en la Raspberry Pi (para el usuario `github-runner`)
Aunque el script de despliegue básico (copiar artefactos) podría no necesitar `gh` directamente, tenerlo autenticado para el usuario `github-runner` es útil para mantenimiento, diagnósticos o futuras necesidades de scripting que interactúen con la API de GitHub.

1.  **Iniciar sesión como `github-runner`:**
    ```bash
    sudo -u github-runner gh auth login
    ```
2.  **Sigue las instrucciones:**
    *   **What account do you want to log into?** Selecciona `GitHub.com`.
    *   **What is your preferred protocol for Git operations?** Selecciona `HTTPS` (o `SSH` si has configurado claves SSH para el usuario `github-runner`).
    *   **Authenticate Git with your GitHub credentials?** Selecciona `Y` (Yes).
    *   **How would you like to authenticate?** Selecciona `Paste an authentication token`.
3.  **Obtener un Personal Access Token (PAT):**
    *   En GitHub, ve a "Settings" (tu perfil, no el del repo) > "Developer settings" > "Personal access tokens" > "Tokens (classic)".
    *   Haz clic en "Generate new token" (o "Generate new token (classic)").
    *   Dale un nombre descriptivo (e.g., `gh-runner-rpi`).
    *   Selecciona la expiración deseada.
    *   Selecciona los scopes. Para la mayoría de usos de `gh` relacionados con el repositorio, el scope `repo` es suficiente.
    *   Haz clic en "Generate token". **Copia el token inmediatamente, no podrás volver a verlo.**
4.  **Pegar el token en la terminal:**
    Pega el PAT copiado en la terminal donde `gh auth login` lo solicita.
5.  `gh` almacenará el token de forma segura en el directorio home del usuario `github-runner`.

Con esto, el usuario `github-runner` está autenticado para usar `gh` en la Raspberry Pi.

¡Felicidades! Ahora tienes un runner auto-alojado configurado en tu Raspberry Pi, listo para ejecutar los trabajos de despliegue de tu flujo de CI/CD.
