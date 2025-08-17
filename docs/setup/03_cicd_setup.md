# Guía de Configuración: Fase 5 - CI/CD y Despliegue Automatizado

**Nombre Clave:** `El Plan de Contingencia (The Contingency Plan)`
**Operador IA:** `Stalker`

Este documento detalla la arquitectura y el proceso de configuración del sistema de despliegue automatizado para "Surviving Chernarus".

## 1. Arquitectura y Flujo de Trabajo

El sistema se basa en un modelo de **Infraestructura como Código (IaC)** donde toda la configuración reside en un repositorio Git. Los despliegues son gestionados por **GitHub Actions** y ejecutados por un **runner auto-alojado** en la propia Raspberry Pi.

### Flujo de Despliegue:

1.  **Disparador (Trigger):** El flujo se inicia al crear y subir un **tag de Git** al repositorio que coincida con el patrón `v*` (ej. `v1.0.0`, `v1.2.3`).
2.  **Job 1: Validación (`lint`):**
    *   Se ejecuta en un runner temporal en la nube de GitHub.
    *   Verifica que la sintaxis del archivo `docker-compose.yml` es correcta.
    *   Este paso previene que errores de configuración básicos lleguen a la Raspberry Pi.
3.  **Job 2: Despliegue (`deploy`):**
    *   Solo se ejecuta si el job `lint` ha sido exitoso.
    *   Se ejecuta en el **runner auto-alojado** en la Raspberry Pi.
    *   Descarga el código fuente correspondiente al tag.
    *   Ejecuta `docker compose up -d` para aplicar los cambios.
4.  **Job 3: Notificación (`notify`):**
    *   Se ejecuta al finalizar el despliegue.
    *   Envía un mensaje a Telegram indicando el resultado (éxito o fallo) del proceso.

---

## 2. Guía de Configuración Inicial

Esta sección detalla los pasos necesarios para configurar el sistema de CI/CD desde cero.

### Paso 2.1: Configuración de Secretos en GitHub

El workflow necesita credenciales para operar. Ve a la configuración de tu repositorio en `Settings > Secrets and variables > Actions` y añade los siguientes secretos:

*   **`TELEGRAM_TOKEN`**:
    *   **Cómo obtenerlo:** Habla con `@BotFather` en Telegram, crea un nuevo bot y copia el token que te proporciona.
*   **`TELEGRAM_TO`**:
    *   **Cómo obtenerlo:** Habla con `@userinfobot` en Telegram y copia tu `Chat ID`.

### Paso 2.2: Instalación del Runner Auto-Alojado

El runner es el software que conecta tu Raspberry Pi con GitHub Actions.

1.  **Crear Directorio:**
    ```bash
    mkdir ~/actions-runner
    ```
2.  **Descargar y Descomprimir:**
    *   Ve a la página de runners de tu repositorio (`Settings > Actions > Runners > New self-hosted runner`).
    *   Selecciona `Linux` y `ARM64`.
    *   Copia y ejecuta los comandos de descarga y descompresión proporcionados por GitHub.
3.  **Configurar el Runner:**
    *   Obtén un token de registro desde la misma página de GitHub.
    *   Ejecuta el script de configuración:
        ```bash
        ./config.sh --url https://github.com/terrerovgh/surviving-chernarus --token TU_TOKEN_DE_REGISTRO
        ```
4.  **Instalar como Servicio `systemd`:**
    *   Esto hace que el runner se inicie automáticamente con el sistema.
        ```bash
        sudo ./svc.sh install
        sudo systemctl start actions.runner.terrerovgh-surviving-chernarus.*.service
        ```

### Paso 2.3: Configuración del DNS Dinámico (DDNS)

Este sistema asegura que el dominio `rpi.terrerov.com` siempre apunte a la IP pública correcta.

1.  **Instalar Dependencias:**
    ```bash
    sudo pacman -S --noconfirm jq cronie
    sudo systemctl enable --now cronie.service
    ```
2.  **Configurar Variables de Entorno:**
    *   Asegúrate de que tu archivo `~/.env` contiene las siguientes variables con los valores correctos:
        *   `DOMAIN`: Tu dominio (ej. `terrerov.com`).
        *   `CF_API_TOKEN`: Tu token de API de Cloudflare.
        *   `CF_EMAIL`: Tu email de Cloudflare.
        *   `CF_ZONE_ID`: El Zone ID de tu dominio en Cloudflare.
3.  **Crear el Script:** El script `scripts/ddns_update.sh` ya está en el repositorio.
4.  **Programar el Cron Job:**
    *   El siguiente comando añade una tarea que ejecuta el script cada 15 minutos:
        ```bash
        (crontab -l 2>/dev/null; echo "*/15 * * * * /home/terrerov/surviving-chernarus/scripts/ddns_update.sh") | crontab -
        ```

---

## 3. Uso en el Día a Día

Una vez configurado, el proceso de despliegue es muy simple.

1.  **Realiza tus cambios:** Modifica el código, `docker-compose.yml` o la documentación.
2.  **Haz commit y push a `main`:**
    ```bash
    git add .
    git commit -m "Un mensaje descriptivo de tus cambios"
    git push origin main
    ```
3.  **Crea y sube un tag de versión:**
    *   Decide qué tipo de cambio es (major, minor, patch) siguiendo el versionado semántico.
    *   Crea el tag y súbelo. Esto activará el despliegue.
        ```bash
        # Ejemplo para un cambio menor
        git tag v1.1.0
        git push origin v1.1.0
        ```
4.  **Verifica:** Revisa la pestaña "Actions" en GitHub y espera la notificación en Telegram.