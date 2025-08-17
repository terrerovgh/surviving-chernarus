# Plan de Implementación: Fase 5 - El Plan de Contingencia

**Nombre Clave de la Fase:** `El Plan de Contingencia (The Contingency Plan)`
**Operador IA:** `Stalker`
**Objetivo:** Establecer un sistema de backups robusto, automatizado y seguro. Este sistema comprimirá los datos y configuraciones críticas del proyecto, los encriptará y los sincronizará con un almacenamiento en la nube (Google Drive) para garantizar la recuperación ante desastres.

---

### Prerrequisitos

-   Haber completado exitosamente la **Fase 4: Activación del Perímetro Defensivo**.
-   Tener una cuenta de Google Drive con suficiente espacio de almacenamiento.

---

### Paso 1: Instalación y Configuración de `rclone`

**Justificación:** `rclone` es una herramienta de línea de comandos extremadamente potente para sincronizar archivos y directorios con una multitud de servicios de almacenamiento en la nube. La usaremos por su capacidad de encriptación del lado del cliente, asegurando que nuestros backups estén ilegibles para cualquiera, excepto para nosotros.

**Acciones:**
1.  **Instalar `rclone` en el Host:**
    -   Instalar el paquete desde los repositorios oficiales: `sudo pacman -S rclone`.
2.  **Configuración de `rclone` (Paso Manual del Usuario):**
    -   La configuración de `rclone` con Google Drive requiere un proceso de autenticación (OAuth) que debe realizarse en un navegador.
    -   **Acción para el usuario:** Ejecutar `rclone config` en la terminal.
    -   **Instrucciones para el usuario:**
        -   Crear un nuevo remote (`n`).
        -   Darle un nombre, por ejemplo, `gdrive_encrypted`.
        -   Seleccionar el tipo de almacenamiento `crypt`.
        -   Configurar la encriptación de nombres de archivo y directorios.
        -   Crear una contraseña segura (y un "salt") para la encriptación.
        -   A continuación, `rclone` pedirá configurar el remote "upstream" (el Google Drive real).
        -   Crear un nuevo remote para Google Drive, por ejemplo, `gdrive_raw`.
        -   Seguir los pasos de autenticación en el navegador.
    -   **Resultado:** Se generará un archivo `rclone.conf` en `~/.config/rclone/rclone.conf` con los tokens necesarios.

---

### Paso 2: Creación del Script de Backup

**Justificación:** Un script centralizará toda la lógica del backup: detener servicios para asegurar la consistencia de los datos, crear el archivo comprimido, ejecutar la sincronización encriptada y limpiar archivos antiguos.

**Acciones:**
1.  **Crear el archivo `backup.sh`:**
    -   Crear el script en una ubicación del proyecto, por ejemplo, `/home/terrerov/surviving-chernarus/scripts/backup.sh`.
2.  **Lógica del Script:**
    -   **Definir variables:** Directorios de volúmenes a respaldar (`traefik`, `elektrozavodsk_db`, `n8n`, `pihole`), directorio temporal de backup, nombre del remote de `rclone`.
    -   **Parada segura de servicios:** Detener el contenedor de la base de datos para evitar corrupción: `docker stop Elektrozavodsk_Databank`.
    -   **Creación del archivo:** Usar `tar` para crear un archivo `.tar.gz` comprimido de los directorios de volúmenes. El nombre del archivo debe incluir la fecha y hora.
    -   **Reinicio de servicios:** Iniciar nuevamente el contenedor de la base de datos: `docker start Elektrozavodsk_Databank`.
    -   **Sincronización encriptada:** Usar `rclone copy` para subir el archivo comprimido al remote encriptado de Google Drive.
    -   **Limpieza:** Eliminar el archivo `.tar.gz` local y usar `rclone delete` o `rclone cleanup` para eliminar backups antiguos en la nube, manteniendo solo los últimos 7, por ejemplo.

---

### Paso 3: Orquestación con `n8n`

**Justificación:** `n8n` (*NWAF_Command_Center*) es el cerebro de nuestras automatizaciones. Lo usaremos para ejecutar el script de backup de forma programada (diariamente) y para que nos notifique sobre el resultado.

**Acciones:**
1.  **Crear un Workflow en `n8n`:**
    -   **Acción para el usuario:** Importar un workflow desde un archivo JSON que se proporcionará.
2.  **Diseño del Workflow (a ser exportado en JSON):**
    -   **Nodo Trigger:** Un nodo "Cron" configurado para ejecutarse todos los días a una hora de baja actividad (ej. 3:00 AM).
    -   **Nodo Principal:** Un nodo "Execute Command" que ejecute el script: `bash /home/terrerov/surviving-chernarus/scripts/backup.sh`.
    -   **Manejo de Errores:** Configurar el nodo para que la salida de error (stderr) cause que la ejecución falle.
    -   **Notificaciones (Opcional pero recomendado):** Conectar nodos de notificación (ej. Telegram, Email) a las salidas de éxito y error del nodo de ejecución para recibir alertas sobre el estado de los backups.

---

**Conclusión de la Fase 5:**
Con el plan de contingencia activo, el proyecto alcanza un nuevo nivel de resiliencia. Los datos críticos estarán protegidos contra fallos de hardware, corrupción de datos o errores humanos, asegurando que el "búnker digital" pueda ser reconstruido rápidamente en cualquier momento.

---

### Actualización del Tablero Kanban

*   **Mover a `In Progress`:**
    *   `Seguridad: Configurar backups automáticos y encriptados en la nube.`
*   **Crear y mover a `To Do` (desglose):**
    *   `Fase 5: Instalar y configurar rclone.`
    *   `Fase 5: Crear script de backup.`
    *   `Fase 5: Crear y configurar workflow de n8n.`