# Plan de Implementación: Fase 6 - Despertando a Stalker

**Nombre Clave de la Fase:** `Despertando a Stalker (Stalker's Awakening)`
**Operador IA:** `Stalker`
**Objetivo:** Implementar el primer flujo de trabajo inteligente utilizando `n8n` y la API de Gemini. El objetivo es crear un "briefing diario" automatizado que recopile noticias y el clima, utilice la IA para generar un resumen personalizado y lo entregue a través de Telegram.

---

### Prerrequisitos

-   Haber completado exitosamente la **Fase 5: Integración de CI/CD**.
-   Tener una clave de API de Gemini válida y configurada en el archivo `~/.env`.
-   Tener las credenciales de un bot de Telegram listas para ser usadas en `n8n`.

---

### Paso 1: Configuración del Entorno de `n8n`

**Justificación:** Para que `n8n` pueda comunicarse con la API de Gemini, necesita acceso a la clave de API. La forma más segura y flexible de hacerlo es pasar la clave como una variable de entorno al contenedor de `n8n`.

**Acciones:**
1.  **Actualizar el archivo `.env` del proyecto:**
    -   Copiar la variable `GEMINI_API_KEY` desde `~/.env` al archivo `/home/terrerov/surviving-chernarus/.env`.
2.  **Modificar el `docker-compose.yml`:**
    -   En la definición del servicio `n8n`, añadir la variable de entorno `GEMINI_API_KEY` para que el contenedor la reciba del archivo `.env`.

---

### Paso 2: Creación del Flujo de Trabajo "Briefing Diario"

**Justificación:** En lugar de crear el flujo manualmente en la interfaz, lo definiremos como un archivo JSON. Esto se alinea con el principio de Infraestructura como Código, permitiendo que el workflow esté versionado en Git.

**Acciones:**
1.  **Diseñar la Lógica del Workflow:**
    -   **Trigger:** Un nodo "Cron" que se ejecuta todos los días a las 7:00 AM.
    -   **Recopilar Noticias:** Un nodo "RSS Feed Read" para obtener los titulares de una fuente de noticias (ej. BBC, Reuters).
    -   **Recopilar Clima:** Un nodo "HTTP Request" para obtener el pronóstico del tiempo desde un servicio gratuito como `wttr.in`.
    -   **Procesar con IA:** Un nodo "Gemini" que recibirá los datos de los pasos anteriores.
    -   **Formatear Prompt:** El prompt para Gemini estará diseñado para que actúe como "Stalker", sintetizando la información en un resumen breve y útil.
    -   **Enviar Notificación:** Un nodo "Telegram" que enviará el resumen generado por Gemini al chat del usuario.
2.  **Crear el archivo JSON del Workflow:**
    -   Crear un archivo, por ejemplo, `DailyBriefingWorkflow.json`, que contenga la definición completa de este flujo de trabajo.
3.  **Desplegar el Workflow:**
    -   Colocar el archivo JSON en el directorio de volúmenes de `n8n` (`/mnt/usbdata/docker_volumes/n8n/workflows/`) para que `n8n` lo cargue automáticamente.

---

### Paso 3: Configuración de Credenciales y Activación (Manual del Usuario)

**Justificación:** Las claves de API y tokens no deben guardarse directamente en el archivo del workflow. `n8n` tiene un almacén de credenciales seguro para esto.

**Acciones (a ser realizadas por el usuario en la interfaz de `n8n`):**
1.  **Crear Credencial de Gemini:**
    -   Ir a la sección de Credenciales en `n8n`.
    -   Crear una nueva credencial de tipo "Google Gemini API".
    -   En el campo de la clave de API, usar una **expresión** para leer la variable de entorno que pasamos al contenedor: `{{ $env["GEMINI_API_KEY"] }}`.
2.  **Crear Credencial de Telegram:**
    -   Crear una nueva credencial de tipo "Telegram API".
    -   Pegar el token del bot de Telegram.
3.  **Activar el Workflow:**
    -   Abrir el nuevo workflow "Briefing Diario" en la interfaz.
    -   Asignar las credenciales recién creadas a los nodos de Gemini y Telegram.
    -   Activar el workflow.

---

**Conclusión de la Fase 6:**
Al finalizar esta fase, el proyecto tendrá su primera automatización inteligente en funcionamiento. "Stalker" dejará de ser un concepto y se convertirá en un asistente funcional que proporciona valor diario, sentando las bases para flujos de trabajo mucho más complejos en el futuro.
