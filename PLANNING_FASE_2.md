# Plan de Implementación: Fase 2 - El Centro de Mando

**Nombre Clave de la Fase:** `Estableciendo el Centro de Mando (The Command Center Setup)`
**Operador IA:** `Stalker`
**Objetivo:** Desplegar la pila de servicios principal (Core Service Stack) utilizando Docker Compose. Al finalizar esta fase, tendremos un proxy inverso (`Traefik`) gestionando el tráfico, una base de datos persistente (`PostgreSQL`) y el motor de automatización (`n8n`) operativos y comunicándose entre sí.

---

### Prerrequisitos

-   Haber completado exitosamente la **Fase 1: El Puesto de Avanzada**.
-   El usuario `terrerov` debe haber cerrado y reabierto su sesión para que la pertenencia al grupo `docker` sea efectiva.

---

### Paso 1: Infraestructura como Código - Creación del `docker-compose.yml`

**Justificación:** Este archivo es el plano de nuestra arquitectura de microservicios. Define cada servicio, sus relaciones, volúmenes y configuración de red. Es el corazón de nuestra estrategia de IaC.

**Acciones:**
1.  **Crear el archivo `docker-compose.yml`** en el directorio `/home/terrerov/surviving-chernarus/`.
2.  **Definir una Red Personalizada:** Crearemos una red Docker (`secure_network`) para que nuestros contenedores se comuniquen de forma aislada y segura.
3.  **Definir el Servicio `CoastalHighway_Router` (Traefik):**
    -   **Imagen:** `traefik:latest`
    -   **Puertos:** Exponer los puertos `80` y `443` al anfitrión.
    -   **Volúmenes:** Mapear los archivos de configuración de Traefik (`traefik.yml`, `dynamic_conf/`), el archivo para los certificados SSL (`acme.json`) y el socket de Docker para el descubrimiento de servicios.
    -   **Labels:** Configurar el propio dashboard de Traefik para que sea accesible a través de un subdominio seguro.
4.  **Definir el Servicio `Elektrozavodsk_Databank` (PostgreSQL):**
    -   **Imagen:** `postgres:latest`
    -   **Variables de Entorno:** Cargar credenciales (`POSTGRES_USER`, `POSTGRES_PASSWORD`, etc.) desde un archivo `.env` para evitar hardcodear secretos.
    -   **Volúmenes:** Mapear el directorio de datos (`/mnt/usbdata/docker_volumes/elektrozavodsk_db`) para asegurar la persistencia de la base de datos.
    -   **Política de Reinicio:** `unless-stopped` para asegurar la resiliencia.
5.  **Definir el Servicio `NWAF_Command_Center` (n8n):**
    -   **Imagen:** `n8n-community/n8n:latest`
    -   **Variables de Entorno:** Configurar la conexión a `Elektrozavodsk_Databank` utilizando las credenciales del archivo `.env`.
    -   **Volúmenes:** Mapear el directorio de datos (`/mnt/usbdata/docker_volumes/n8n`) para la persistencia de los flujos de trabajo.
    -   **Labels:** Configurar Traefik para exponer la interfaz de n8n en un subdominio seguro.
    -   **Dependencias:** Definir que depende de `Elektrozavodsk_Databank` para asegurar un orden de arranque correcto.

---

### Paso 2: Gestión de Secretos y Configuración Específica

**Justificación:** Los secretos y credenciales nunca deben ser parte del código fuente. Utilizaremos un archivo `.env` para gestionar esta información sensible, el cual será ignorado por Git.

**Acciones:**
1.  **Crear el archivo `.env`** en `/home/terrerov/surviving-chernarus/`.
2.  **Poblar el `.env`** con las variables necesarias para la base de datos y los dominios de los servicios.
3.  **Crear un archivo `.gitignore`** y añadir `.env` para prevenir su subida accidental a un repositorio.
4.  **Crear la estructura de configuración para Traefik:**
    -   Crear el archivo de configuración estática `traefik.yml`.
    -   Crear el directorio `dynamic_conf` para configuraciones dinámicas.
    -   Crear el archivo `acme.json` (vacío) y asignarle permisos correctos (`600`) para el almacenamiento de certificados Let's Encrypt.

---

### Paso 3: Despliegue y Verificación de la Pila de Servicios

**Justificación:** Una vez definida la infraestructura, debemos desplegarla y verificar que todos los componentes funcionan como se espera.

**Acciones:**
1.  **Navegar al directorio del proyecto:** `cd /home/terrerov/surviving-chernarus/`
2.  **Levantar la Pila de Servicios:** Ejecutar `docker compose up -d` para crear e iniciar todos los contenedores en segundo plano.
3.  **Verificar el Estado:**
    -   Usar `docker compose ps` para confirmar que todos los contenedores están en estado `running`.
    -   Revisar los logs con `docker compose logs -f [nombre_del_servicio]` para detectar cualquier error en el arranque.
4.  **Validación Funcional:**
    -   Acceder a la URL configurada para el dashboard de Traefik y verificar que la interfaz carga correctamente.
    -   Acceder a la URL configurada para n8n y confirmar que se puede iniciar el proceso de configuración inicial.

---

**Conclusión de la Fase 2:**
Al finalizar esta fase, el corazón del proyecto "Surviving Chernarus" estará latiendo. Tendremos una plataforma robusta y automatizable sobre la cual podremos construir el resto de los servicios y funcionalidades.
