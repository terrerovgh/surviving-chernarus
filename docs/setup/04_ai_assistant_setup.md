# Guía de Configuración: Fase 6 - El Despertar de Stalker

Este documento detalla la arquitectura, implementación y configuración del primer flujo de trabajo de IA para el proyecto "Surviving Chernarus", conocido como el "Briefing Diario".

---

### **Capítulo 1: Visión General y Objetivos**

El objetivo de esta fase es dar el primer paso tangible para transformar el proyecto de un sistema de gestión de infraestructura a un verdadero **asistente personal inteligente**. El nombre clave, "El Despertar de Stalker", simboliza este hito.

El workflow implementado, el **"Briefing Diario"**, tiene una misión clara:
- **Automatizar la Recopilación de Información:** Eliminar la tarea manual de revisar múltiples fuentes de noticias y el pronóstico del tiempo cada mañana.
- **Sintetizar con Inteligencia Artificial:** Utilizar el poder de un LLM (en este caso, la API de Google Gemini) para procesar la información en bruto y convertirla en un resumen conciso, relevante y fácil de digerir.
- **Entrega Proactiva:** Enviar este resumen directamente al operador a través de un canal de mensajería instantánea (Telegram), en un horario predefinido.

Este flujo de trabajo sirve como una base sólida y un caso de uso práctico para futuras automatizaciones mucho más complejas.

---

### **Capítulo 2: Arquitectura del Flujo de Trabajo**

El workflow se ejecuta enteramente dentro de `n8n` (NWAF_Command_Center) y orquesta varias herramientas y APIs externas.

#### **Componentes Clave:**

*   **`n8n`**: El motor de automatización que aloja y ejecuta el flujo de trabajo.
*   **`Schedule Trigger`**: Un nodo de `n8n` que inicia el flujo de trabajo en un horario programado.
*   **`wttr.in`**: Un servicio web gratuito que proporciona datos meteorológicos en formato JSON.
*   **`BBC News RSS Feed`**: Una fuente de noticias estándar para obtener los últimos titulares mundiales.
*   **`Google Gemini API`**: El cerebro del proceso. Recibe los datos brutos y los transforma en un resumen inteligente.
*   **`Telegram API`**: El canal de entrega para notificar al operador.

#### **Diagrama de Flujo de Datos:**

El flujo de información se puede visualizar de la siguiente manera:

```
      +---------------------------+
      | 1. Trigger (Cada día 7am) |
      +-------------+-------------+
                    |
      +-------------v-------------+
      | 2. Recopilación de Datos  |
      |   (Ejecución en Paralelo) |
      +-------------+-------------+
                    |
    +---------------v---------------+      +----------------+
    |      HTTP Request a wttr.in   +------>|  Datos del     |
    | (Obtiene el pronóstico del    |      |  Clima (JSON)  |
    |  tiempo para Denver)          |      +----------------+
    +-------------------------------+

    +---------------v---------------+      +----------------+
    |    Lectura de Feed de BBC     +------>|  Titulares de  |
    | (Obtiene los últimos         |      |  Noticias (XML)|
    |  titulares mundiales)         |      +----------------+
    +-------------------------------+
                    |
      +-------------v-------------+      +----------------------+
      | 3. Nodo de IA (Gemini)      +------>|  API de Google Gemini|
      | - Construye un prompt con   |      | (Procesa el prompt y |
      |   los datos del clima y     |      |  genera el resumen)  |
      |   las noticias.             |      +----------------------+
      | - Envía el prompt a la API. |
      +-------------+-------------+
                    |
      +-------------v-------------+      +----------------------+
      | 4. Nodo de Notificación     +------>|    API de Telegram   |
      | - Recibe el texto generado  |      | (Envía el mensaje al |
      |   por Gemini.               |      |  chat del operador)  |
      | - Lo envía a Telegram.      |      +----------------------+
      +-------------+-------------+
                    |
      +-------------v-------------+
      | 5. Fin del Flujo            |
      +---------------------------+
```

---

### **Capítulo 3: Implementación Técnica Detallada**

#### **3.1. Configuración del Entorno**

Para que `n8n` pueda usar la clave de API de Gemini de forma segura, se realizaron dos cambios:

1.  **Archivo `.env`:** La clave `GEMINI_API_KEY` fue añadida al archivo `.env` del proyecto. Este archivo es ignorado por Git, por lo que la clave nunca se sube al repositorio.
2.  **`docker-compose.yml`:** Se modificó el servicio `n8n` para pasar la variable de entorno al contenedor:
    ```yaml
    services:
      n8n:
        # ... otras configuraciones ...
        environment:
          # ... otras variables ...
          - GEMINI_API_KEY=${GEMINI_API_KEY}
    ```
    Esto hace que la clave esté disponible dentro del entorno del contenedor de `n8n`, pero no se guarda en ningún archivo de configuración visible.

#### **3.2. Anatomía del Workflow en `n8n`**

El workflow (`DailyBriefing.json`) está compuesto por varios nodos interconectados:

*   **Nodo 1: `Schedule Trigger`**
    *   **Propósito:** Iniciar el flujo.
    *   **Configuración:** Se ejecuta una vez al día, a las 7:00 AM.

*   **Nodo 2: `Obtener Clima` (HTTP Request)**
    *   **Propósito:** Obtener datos meteorológicos.
    *   **Configuración:** Realiza una petición GET a `http://wttr.in/Denver?format=j1`, que devuelve una respuesta JSON detallada.

*   **Nodo 3: `Obtener Noticias (BBC)` (RSS Feed Read)**
    *   **Propósito:** Obtener los últimos titulares.
    *   **Configuración:** Lee el feed RSS de `http://feeds.bbci.co.uk/news/world/rss.xml`.

*   **Nodo 4: `Procesar con Gemini` (Google Gemini)**
    *   **Propósito:** El núcleo de la inteligencia. Sintetiza la información.
    *   **Configuración del Prompt:** Se ha diseñado un prompt específico para instruir al modelo:
        ```
        Eres Stalker, un asistente de IA conciso y directo. Tu operador necesita su briefing diario. Sintetiza la siguiente información en un reporte breve, útil y ligeramente motivacional. No incluyas saludos ni despedidas. Sé directo.

        **Datos del Clima:**
        {{ JSON.stringify($('Obtener Clima').item.json.current_condition[0]) }}

        **Titulares de Noticias (máximo 3):**
        1. {{ $('Obtener Noticias (BBC)').item.json.items[0].title }}
        2. {{ $('Obtener Noticias (BBC)').item.json.items[1].title }}
        3. {{ $('Obtener Noticias (BBC)').item.json.items[2].title }}
        ```
        - **`{{ ... }}`**: Estas son expresiones de `n8n` que inyectan dinámicamente los datos obtenidos en los pasos anteriores directamente en el texto del prompt.

*   **Nodo 5: `Enviar a Telegram` (Telegram)**
    *   **Propósito:** Entregar el resultado final.
    *   **Configuración:** Toma la respuesta (`response`) generada por el nodo de Gemini y la envía al Chat ID especificado en los secretos.

---

### **Capítulo 4: Guía de Activación y Uso**

Para que el workflow funcione, es necesario configurar las credenciales dentro de la interfaz de `n8n`.

1.  **Acceder a `n8n`:** Navega a `https://n8n.terrerov.com`.
2.  **Abrir el Workflow:** Ve a la sección "Workflows" y abre "Briefing Diario de Stalker".
3.  **Configurar Credencial de Gemini:**
    *   Haz clic en el nodo "Procesar con Gemini".
    *   En el campo "Credential", selecciona "Create New".
    *   **Name:** `Gemini API` (o el nombre que prefieras).
    *   **API Key:** Haz clic en el engranaje ⚙️ -> "Add Expression".
    *   Introduce la expresión: `{{ $env["GEMINI_API_KEY"] }}`.
        *   **Importante:** Esto le dice a `n8n` que no guarde la clave, sino que la lea de la variable de entorno del contenedor cada vez que se ejecute. Es el método más seguro.
    *   Guarda la credencial.
4.  **Configurar Credencial de Telegram:**
    *   Haz clic en el nodo "Enviar a Telegram".
    *   En el campo "Credential", selecciona "Create New".
    *   **Name:** `Telegram Bot` (o el que prefieras).
    *   **Access Token:** Pega aquí el token de tu bot de Telegram.
    *   Guarda la credencial.
5.  **Activar el Workflow:**
    *   En la esquina superior derecha, mueve el interruptor de "Inactive" a **"Active"**.

A partir de este momento, el workflow está operativo. Para una prueba inmediata, puedes hacer clic en **"Execute Workflow"**.
