# Lista de Tareas del Proyecto "Surviving Chernarus"

Este documento contiene la lista de tareas detallada para el proyecto "Surviving Chernarus", basada en el `PLAN.md`.

## I. Máxima Prioridad: Asistente Personal Central y Radio Temática ☢️

### 1. Chernarus Vital Optimization Protocol (Asistente Personal)
- [ ] **Objetivo:** Establecer n8n como motor de automatización e integrarlo con Google Calendar y Tasks para planificación básica, con sugerencias de IA.
- [ ] **Pasos Clave:**
    - [ ] 1.1. Configuración de n8n (Raspberry Pi):
        - [ ] Instalar n8n (Docker recomendado).
        - [ ] Asegurar la instancia (credenciales, HTTPS si/cuando sea externo).
    - [ ] 1.2. Integración con Google Calendar:
        - [ ] Crear credenciales API de Google (OAuth 2.0) con el ámbito de la API de Calendar.
        - [ ] Configurar y autenticar el nodo n8n de Google Calendar.
        - [ ] Probar la lectura y creación de eventos de calendario.
    - [ ] 1.3. Integración con Google Tasks:
        - [ ] Asegurar que la API de Google Tasks esté habilitada para tu Proyecto de Google Cloud.
        - [ ] Configurar y autenticar el nodo n8n de Google Tasks.
        - [ ] Probar la lectura y creación de tareas.
    - [ ] 1.4. Flujo de Trabajo Básico de Planificación Semanal (n8n):
        - [ ] Disparador: Manual o basado en cron (ej. semanalmente).
        - [ ] Lógica:
            - [ ] Obtener próximos eventos de calendario y tareas actuales.
            - [ ] Integración IA (Conceptual): Enviar datos a un servicio de IA con prompts para sugerir tareas y esbozar un horario semanal.
        - [ ] Salida Inicial: Enviar sugerencias de IA y plan a Telegram/email o un Google Doc.
    - [ ] 1.5. Enfoque en Seguridad: Adherirse al principio de mínimo privilegio para los ámbitos de API; gestionar de forma segura los tokens OAuth.

### 2. Radio Chernarus (Radio Personalizada)
- [ ] **Objetivo:** Configurar un servidor de streaming Icecast funcional en la Raspberry Pi, con un flujo de trabajo básico de n8n para gestionar una lista de reproducción a partir de archivos de música locales, y hacer que el stream sea accesible externamente.
- [ ] **Pasos Clave:**
    - [ ] 2.1. Configuración de Icecast (Raspberry Pi): Instalar `icecast2`, configurar `icecast.xml`, habilitar e iniciar el servicio.
    - [ ] 2.2. Streaming Orquestado Simple con n8n: Organizar archivos de música. Instalar `ezstream`. Flujo de trabajo n8n para listar archivos, crear lista de reproducción y ejecutar `ezstream`.
    - [ ] 2.3. Configuración de Acceso Externo: Configurar DDNS, configurar reenvío de puertos en el router, abrir puerto del firewall en RPi.
    - [ ] 2.4. Enfoque Inicial en Seguridad: Contraseñas fuertes para Icecast, considerar restringir el acceso a la interfaz de administración.

## II. Prioridad Media: Mejoras de Interacción, Seguridad y Gestión Avanzada 🛡️

### 3. The Chernarus Collective (Infraestructura Kubernetes)
- [ ] **Objetivo:** Establecer un clúster K3s Kubernetes (RPi master, Laptop worker).
- [ ] **Pasos Clave:**
    - [ ] Elegir K3s.
    - [ ] Preparar RPi (master) y Laptop (worker).
    - [ ] Instalar K3s en ambos.
    - [ ] Unir worker al clúster.
    - [ ] Desplegar servicio Nginx de prueba.
    - [ ] Seguridad: Network Policies, RBAC, Secrets, actualizaciones.

### 4. Chernarus Collective Central Data Store (Bases de Datos en K8s)
- [ ] **Objetivo:** Desplegar PostgreSQL y Redis en K8s (laptop worker).
- [ ] **Pasos Clave:**
    - [ ] Elegir despliegue PostgreSQL (StatefulSet).
    - [ ] Desplegar PostgreSQL (namespace, PV/PVC, Secret, StatefulSet, Service).
    - [ ] Desplegar Redis (namespace, Secret, Deployment/StatefulSet, Service).
    - [ ] Diseño inicial de esquema ("Survival Points", preferencias de usuario, metas, logs, estados de flujo de trabajo).
    - [ ] Seguridad y Backup (contraseñas fuertes, exposición limitada, pg_dump).

### 5. Verified Survivor Identification Protocol (mTLS)
- [ ] **Objetivo:** Mejorar la seguridad del servicio con mTLS usando una CA personalizada y Nginx (RPi).
- [ ] **Pasos Clave:**
    - [ ] Entender mTLS.
    - [ ] Crear CA personalizada (OpenSSL).
    - [ ] Generar certificado de servidor (Nginx) y certificado de cliente ("Verified Survivor").
    - [ ] Configurar Nginx para mTLS (`ssl_client_certificate`, `ssl_verify_client on`).
    - [ ] Probar acceso.
    - [ ] Futuro: CRL/OCSP, "Portal Cautivo".
    - [ ] Seguridad: Proteger la clave de la CA.

### 6. Chernarus Global Listening Post (Monitorización Reddit)
- [ ] **Objetivo:** Flujo de trabajo n8n para monitorizar subreddit, enviar resúmenes a Telegram.
- [ ] **Pasos Clave:**
    - [ ] Prerrequisitos (n8n, Token de Bot de Telegram/Chat ID).
    - [ ] Diseño del flujo de trabajo n8n (Cron, nodo Reddit, manejo de duplicados, filtro opcional, futuros resúmenes IA, nodo Telegram).
    - [ ] Lógica de ejemplo del flujo de trabajo.
    - [ ] Pruebas.
    - [ ] Consideraciones: Límites de tasa, manejo de errores.

### 7. Alexa, Chernarus Command Post (Integración Alexa)
- [ ] **Objetivo:** n8n envía comandos a Alexa a través de un bot de Telegram estabilizado.
- [ ] **Pasos Clave:**
    - [ ] Estabilizar el bot Telegram-a-Alexa existente (identificar configuración, depurar, mejorar fiabilidad).
    - [ ] Flujo de trabajo n8n (disparador, determinar comando Alexa, nodo Telegram para enviar comando al bot).
    - [ ] Ejemplo de flujo de trabajo.
    - [ ] Pruebas.
    - [ ] Seguridad: Token de bot seguro, considerar validación de comandos en el bot, estabilidad de la API.

## III. Prioridad Interesante/Divertida: Mejoras Temáticas y Funcionalidades Adicionales 🎪

### 8. Chernarus Local Tactical Map (Mapa de Ciudad Gamificado)
- [ ] **Objetivo:** Mapa Hugo/Leaflet con "misiones" GeoJSON generadas por n8n desde Google Calendar.
- [ ] **Pasos Clave:**
    - [ ] Configurar Hugo.
    - [ ] Página básica de mapa Leaflet.
    - [ ] Flujo de trabajo n8n (obtener eventos de Calendar, filtrar "misiones", transformar a GeoJSON, guardar en directorio estático de Hugo).
    - [ ] Cargar GeoJSON en Leaflet.
    - [ ] Despliegue.
    - [ ] Futuro: Gamificación.

### 9. Clandestine Route Dispatcher (Enrutamiento VPN Dinámico)
- [ ] **Objetivo:** Squid (en K8s) enruta dominios específicos a través de un contenedor cliente VPN en K8s (se recomienda el enfoque de sidecar proxy).
- [ ] **Pasos Clave:**
    - [ ] Cliente VPN en K8s (ej. gluetun, capacidad `NET_ADMIN`).
    - [ ] Squid en K8s.
    - [ ] Enrutamiento específico de dominio usando cliente VPN como proxy sidecar para Squid (`cache_peer`).
    - [ ] Pruebas.
    - [ ] Seguridad.

### 10. Quartermaster's Stash (Sistema de Descargas Temático)
- [ ] **Objetivo:** rtorrent/ruTorrent en K8s (laptop), n8n anuncia descargas completadas ("Alertas de Entrega de Suministros") a Telegram.
- [ ] **Pasos Clave:**
    - [ ] Desplegar rtorrent/ruTorrent en K8s (PVCs, Deployment, Services para WebUI y puertos peer).
    - [ ] Hook "execute on completion" de rtorrent para llamar a `notify_n8n.sh`.
    - [ ] Script `notify_n8n.sh` usa curl para POST a webhook n8n.
    - [ ] Flujo de trabajo n8n (Nodo Webhook, nodo Telegram para alerta temática).
    - [ ] Futuro: "Protocolos de Racionamiento" (lógica n8n avanzada).

### 11. Shelter Essential Equipment Access Protocol (Gestión IoT)
- [ ] **Objetivo:** Squid en RPi para `ssl_bump splice` (passthrough) tráfico SSL/TLS para dispositivos IoT específicos.
- [ ] **Pasos Clave:**
    - [ ] Identificar IPs de IoT.
    - [ ] Configurar Squid en RPi.
    - [ ] Configurar Squid para splicing SSL (acl `iot_devices`, `ssl_bump splice iot_devices`).
    - [ ] `iptables` para proxy transparente si es necesario.
    - [ ] Pruebas.
    - [ ] Futuro: Monitorización n8n.

## IV. Ideas Avanzadas / Futuristas (Implementar con Precaución) 🚀

### 12. Beacon Chernarus AI-Assisted Self-Repair Protocol
- [ ] **Objetivo (Inicial):** n8n detecta errores y crea issues en GitHub.
- [ ] **Pasos Clave:**
    - [ ] Identificar fuentes de error/logs.
    - [ ] Scripts de detección de errores (estado del servicio, parseo de logs).
    - [ ] Configuración de repo GitHub y PAT.
    - [ ] Flujo de trabajo n8n (Cron, nodos Execute Command/K8s, IF, función Formatear Issue GitHub con prevención de duplicados, nodo GitHub).
    - [ ] Pruebas.

## V. Otras Ideas Temáticas Divertidas (Módulos de Expansión) 🎭

### 13. Beacon Historical Archive (Logs Temáticos en Hugo)
- [ ] **Objetivo:** Sección del sitio Hugo mostrando logs temáticos de eventos del sistema desde n8n.
- [ ] **Pasos Clave:**
    - [ ] Identificar fuentes de log (eventos de flujo de trabajo n8n, entradas manuales).
    - [ ] Definir formato de log JSON estructurado.
    - [ ] Flujo de trabajo n8n para agregar/formatear logs (webhook/sub-flujo) y almacenar (archivos JSON en `hugo_site/data/` o archivo único).
    - [ ] Configuración de Hugo.
    - [ ] Plantillas Hugo para mostrar logs.
    - [ ] Automatización.
    - [ ] Tematización.

### Otras Ideas Temáticas Divertidas (Siguientes Pasos Breves en Inglés):
- [ ] **"P2P Black Market":**
    - [ ] Investigar tecnología P2P (IPFS, Syncthing).
    - [ ] Probar compartición básica de nodo.
- [ ] **"Themed Honey Pot":**
    - [ ] Instalar `endlessh` en RPi.
    - [ ] Exponer.
    - [ ] Monitorizar.
- [ ] **"Beacon Morse Code":**
    - [ ] Script para que n8n llame, convirtiendo texto a audio Morse.
- [ ] **"Chernarus Random Event Simulator":**
    - [ ] Nodo Función n8n con eventos predefinidos.
    - [ ] Enviar a Telegram/Archivo.