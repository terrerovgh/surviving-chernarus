# Guía de Configuración: Fase 5 - CI/CD y Despliegue Automatizado

**Nombre Clave:** `El Plan de Contingencia (The Contingency Plan)`
**Operador IA:** `Stalker`

## 1. Filosofía y Enfoque

Para la gestión de la configuración y los despliegues del proyecto "Surviving Chernarus", se ha adoptado un enfoque de **Infraestructura como Código (IaC)** gestionado a través de un flujo de **Integración Continua y Despliegue Continuo (CI/CD)**.

El método inicial de usar SSH para el despliegue fue descartado debido a una limitación crítica: la Raspberry Pi a menudo operará en redes que bloquean las conexiones SSH entrantes.

La solución implementada invierte el flujo de control: en lugar de que un sistema externo "empuje" los cambios a la Pi, **la propia Pi "escucha" los cambios desde GitHub y los aplica localmente**. Esto se logra mediante un **runner auto-alojado (self-hosted runner) de GitHub Actions**.

### Ventajas de este Modelo:

*   **Seguridad:** No se necesita abrir ningún puerto SSH en el firewall. El runner establece una conexión saliente segura con GitHub.
*   **Fiabilidad:** Funciona detrás de cualquier firewall o NAT, ya que no depende de una IP pública estática o de la redirección de puertos.
*   **Automatización Completa:** El despliegue es un proceso "manos libres". Un simple `git push` a la rama `main` es suficiente para actualizar la pila de servicios.
*   **Control de Versiones:** Toda la configuración de la infraestructura (`docker-compose.yml`, scripts, etc.) está versionada en Git, proporcionando un historial completo de cambios y la capacidad de revertir a estados anteriores.

## 2. Componentes del Sistema

El flujo de CI/CD se compone de tres elementos principales:

1.  **Repositorio Git:** El código fuente, la documentación y los archivos de configuración residen en el repositorio `terrerovgh/surviving-chernarus` en GitHub.
2.  **Workflow de GitHub Actions (`.github/workflows/deploy.yml`):** Este archivo YAML define los pasos que se deben ejecutar cuando hay un cambio en el repositorio.
3.  **Runner Auto-Alojado:** Un servicio que se ejecuta constantemente en la Raspberry Pi, escucha a GitHub y ejecuta los trabajos que se le asignan.

## 3. Flujo de Trabajo del Despliegue

El despliegue se controla mediante **tags de Git**. Un simple `push` a la rama `main` ya no activa un despliegue; se requiere la creación intencionada de un "release" a través de un tag.

1.  **Creación de un Tag:** El operador crea y sube un tag de Git (ej. `v1.0.1`).
    ```bash
    git tag v1.0.1
    git push origin v1.0.1
    ```
2.  **Activación del Workflow:** Este evento (`push` de un tag que empieza por `v*`) activa el workflow en GitHub Actions.
3.  **Job 1: `lint` (Ejecutado en la nube de GitHub):**
    *   Se inicia una máquina virtual temporal de Ubuntu.
    *   Descarga el código.
    *   Ejecuta `docker-compose config` para verificar que la sintaxis del archivo `docker-compose.yml` es válida.
    *   Si este paso falla, todo el workflow se detiene y se envía una notificación de error.
4.  **Job 2: `deploy` (Ejecutado en la Raspberry Pi):**
    *   Este job solo se inicia si el job `lint` se ha completado con éxito (`needs: lint`).
    *   GitHub envía el trabajo al runner `surviving-chernarus-runner`.
    *   El runner en la Pi ejecuta los siguientes pasos:
        a.  **`actions/checkout@v3`**: Descarga el código correspondiente al tag que activó el workflow.
        b.  **`docker compose up -d`**: Carga las variables del archivo `~/.env` y aplica los cambios definidos en `docker-compose.yml`.
5.  **Notificación:**
    *   Al finalizar el job `deploy`, se envía una notificación a Telegram indicando si el despliegue fue exitoso o si falló.

Este flujo de trabajo de dos etapas asegura que solo se intente desplegar código que ha pasado una verificación de sintaxis básica, reduciendo la probabilidad de errores en producción.


## 4. Gestión del Runner Auto-Alojado

El runner está instalado en `/home/terrerov/actions-runner` y se ejecuta como un servicio `systemd`, lo que garantiza que se inicie automáticamente.

### Comandos Útiles:

*   **Verificar el estado del servicio:**
    ```bash
    sudo systemctl status actions.runner.terrerovgh-surviving-chernarus.surviving-chernarus-runner.service
    ```

*   **Ver los logs del servicio:**
    ```bash
    sudo journalctl -u actions.runner.terrerovgh-surviving-chernarus.surviving-chernarus-runner.service -f
    ```

*   **Iniciar/Detener el servicio manualmente:**
    ```bash
    sudo systemctl start actions.runner.terrerovgh-surviving-chernarus.surviving-chernarus-runner.service
    sudo systemctl stop actions.runner.terrerovgh-surviving-chernarus.surviving-chernarus-runner.service
    ```

## 5. Sistema de DNS Dinámico (DDNS)

Para que el runner (y otros servicios futuros) pueda ser localizado de forma fiable, se ha implementado un sistema de DNS dinámico.

*   Un script (`/home/terrerov/surviving-chernarus/scripts/ddns_update.sh`) se ejecuta cada 15 minutos a través de un `cron job`.
*   El script verifica la IP pública actual de la red y la compara con el registro DNS de tipo `A` para `rpi.terrerov.com` en Cloudflare.
*   Si las IPs difieren, el script actualiza automáticamente el registro en Cloudflare.
*   Esto asegura que `rpi.terrerov.com` siempre apunte a la red correcta, aunque la IP pública cambie.
