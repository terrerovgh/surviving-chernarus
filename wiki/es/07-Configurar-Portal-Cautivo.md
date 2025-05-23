# Configuración del Portal Cautivo

## Introducción
Un portal cautivo es una página web a la que se redirige a los usuarios recién conectados a una red Wi-Fi antes de que se les conceda acceso completo a Internet. Su propósito en este proyecto es mostrar una página de bienvenida para guiar a los usuarios, especialmente para la descarga e instalación del certificado CA necesario para el proxy Squid.

El portal cautivo, denominado `chernarus_entrypoint` en la configuración, se ejecuta como un servicio Docker. Está gestionado como parte del archivo principal `docker-compose.yml` ubicado en el directorio raíz del proyecto. Esto centraliza la gestión de todos los servicios Docker del proyecto.

## Revisar la Definición del Servicio en Docker Compose
El servicio del portal cautivo, llamado `chernarus_entrypoint`, está definido en el archivo `docker-compose.yml` principal, que se encuentra en el **directorio raíz del proyecto**. No hay un `docker-compose.yml` separado solo para el portal dentro de `captive_portal_Chernarus_Entrypoint/`.

Puedes revisar la definición de este servicio abriendo el `docker-compose.yml` principal con un editor de texto. Busca la sección `services.chernarus_entrypoint`.

**Puntos Clave de la Configuración del Servicio `chernarus_entrypoint`:**

*   **Imagen:** Utiliza la imagen estándar `nginx:alpine`, que es una versión ligera de Nginx.
    ```yaml
    image: nginx:alpine
    ```
*   **Volumen para Contenido HTML:** Monta el directorio local `captive_portal_Chernarus_Entrypoint/html` (relativo a la raíz del proyecto) en `/usr/share/nginx/html` dentro del contenedor. Esto significa que Nginx servirá los archivos que coloques en `captive_portal_Chernarus_Entrypoint/html/`.
    ```yaml
    volumes:
      - ./captive_portal_Chernarus_Entrypoint/html:/usr/share/nginx/html:ro
    ```
    El modo `ro` (read-only) es una buena práctica de seguridad, ya que el contenedor no necesita escribir en este volumen.
*   **Puertos Expuestos:** La configuración de puertos es crucial para la accesibilidad del portal. En el `docker-compose.yml` principal, debería verse así:
    ```yaml
    ports:
      - "192.168.73.1:8080:80"
    ```
    *   Esto significa que el puerto 80 del contenedor Nginx (donde Nginx escucha por defecto) se mapea al puerto `8080` de la dirección IP `192.168.73.1` en la Raspberry Pi.
    *   `192.168.73.1` es la dirección IP de la Raspberry Pi en la interfaz del hotspot (`wlan0`).
    *   Por lo tanto, el portal cautivo será accesible en `http://192.168.73.1:8080` para los clientes conectados al hotspot.
    *   La redirección de los clientes nuevos a esta dirección se configura mediante `iptables` (ver `[[09-Configurar-Redireccion-Trafico]]`).

## Personalizar la Página del Portal (Opcional)
La apariencia y el contenido de la página que se muestra a los usuarios conectados se definen en los archivos estáticos (HTML, CSS, imágenes, etc.) ubicados en el directorio `captive_portal_Chernarus_Entrypoint/html/` (relativo a la raíz del proyecto).

1.  **Navegar al Directorio de Contenido:**
    Para modificar estos archivos, navega a este directorio:
    ```bash
    # Desde la raíz de tu repositorio clonado (e.g., ~/projects/surviving-chernarus)
    cd captive_portal_Chernarus_Entrypoint/html/
    ```
2.  **Archivos del Portal:**
    *   El archivo principal es `index.html`. Este es el archivo que se sirve por defecto.
    *   Puede haber otros archivos como `style.css` para los estilos, imágenes (e.g., `logo.png`), y el certificado CA para descarga (e.g., `myCA.pem`).
3.  **Modificación:**
    Puedes editar estos archivos directamente para personalizar completamente la apariencia, el mensaje de bienvenida, añadir logotipos, actualizar el enlace de descarga del certificado CA, o cambiar la funcionalidad del portal según tus necesidades.
    *   **Importante:** Asegúrate de que el enlace para descargar el certificado CA en `index.html` (si lo modificas) apunte correctamente al nombre del archivo del certificado que has colocado en este directorio.
4.  **Archivo `.gitkeep`:**
    Si encuentras un archivo llamado `.gitkeep` en el directorio `html/`, este es un archivo vacío que se utiliza para asegurar que el directorio se incluya en el repositorio Git aunque inicialmente esté vacío. Puedes eliminarlo de forma segura una vez que añadas tus propios archivos al directorio `html/`.

Como el contenido HTML se monta como un volumen en el contenedor Nginx, cualquier cambio que guardes en estos archivos se reflejará inmediatamente en el portal servido (es posible que necesites refrescar la caché de tu navegador para ver los cambios). No es necesario reconstruir o reiniciar el contenedor Nginx para cambios en el contenido HTML/CSS/JS.

## Iniciar el Servicio del Portal Cautivo
El servicio `chernarus_entrypoint` (Nginx) se gestiona mediante el archivo `docker-compose.yml` principal ubicado en el directorio raíz del proyecto.

**Importante:** Todos los comandos `docker-compose` deben ejecutarse desde el **directorio raíz de tu repositorio clonado** (e.g., `~/projects/surviving-chernarus`), no desde el subdirectorio `captive_portal_Chernarus_Entrypoint/`.

1.  **Iniciar todos los servicios del proyecto (Recomendado):**
    La forma más sencilla de asegurar que todas las dependencias y servicios relacionados se inicien correctamente es ejecutar:
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker-compose up -d
    ```
    Esto iniciará el portal cautivo (`chernarus_entrypoint`) junto con Pi-hole, Squid, el servidor DHCP y cualquier otro servicio definido en el `docker-compose.yml` principal. La imagen `nginx:alpine` se descargará si aún no está presente localmente.

2.  **Iniciar solo el servicio del portal cautivo (Opcional):**
    Si deseas iniciar o reiniciar específicamente el servicio del portal cautivo (y ya tienes otros servicios necesarios como las redes Docker creadas por una ejecución previa de `docker-compose up`), puedes hacerlo con:
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker-compose up -d chernarus_entrypoint
    ```

3.  **Nota sobre la construcción de imágenes:**
    Dado que el servicio `chernarus_entrypoint` utiliza una imagen estándar (`nginx:alpine`) sin un `Dockerfile` personalizado en este proyecto, no es necesario ejecutar `docker-compose build chernarus_entrypoint`. Si en el futuro se personalizara la imagen de Nginx con un `Dockerfile` propio, entonces sí se podría usar `sudo docker-compose up -d --build chernarus_entrypoint` para reconstruir la imagen antes de iniciar el servicio.

## Verificar que el Portal está Funcionando
Después de iniciar el servicio `chernarus_entrypoint` (preferiblemente con `sudo docker-compose up -d` desde la raíz del proyecto), verifica que esté corriendo correctamente.

1.  **Ver los contenedores Docker en ejecución:**
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker ps
    ```
    Deberías ver el contenedor `Chernarus_Entrypoint` (o el nombre que le asigne Docker Compose basado en el nombre del directorio del proyecto y el nombre del servicio) en la lista, con el estado "Up" o "Running".

2.  **Ver los logs del contenedor:**
    Si necesitas solucionar problemas o ver la salida del servidor web Nginx dentro del contenedor:
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker-compose logs -f chernarus_entrypoint
    ```
    La opción `-f` sigue la salida del log en tiempo real. Presiona `Ctrl+C` para detener. Busca mensajes de error si el portal no parece estar funcionando.

3.  **Prueba de Acceso Local:**
    Puedes probar si el servidor Nginx está sirviendo la página del portal accediendo a él desde la propia Raspberry Pi. Dado que el servicio está vinculado a `192.168.73.1:8080`:
    ```bash
    curl http://192.168.73.1:8080
    ```
    También puedes intentar acceder desde un navegador web en la Raspberry Pi (si tienes entorno gráfico) o desde otro dispositivo conectado a la misma red que la Raspberry Pi (si la configuración de red lo permite, aunque el objetivo principal es para clientes del hotspot).
    Deberías ver el código HTML de tu `index.html` (ubicado en `captive_portal_Chernarus_Entrypoint/html/`) como respuesta.

## Nota Final sobre Redirección y Contenido

*   **Redirección de Tráfico:** Con el portal cautivo funcionando, el siguiente paso crucial es configurar las reglas de `iptables` para redirigir automáticamente a los nuevos usuarios del hotspot a `http://192.168.73.1:8080`. Esto se detalla en el script `scripts/setup_captive_portal_redirect.sh` y se explica en la página `[[09-Configurar-Redireccion-Trafico]]`.
*   **Contenido Servido:** Nginx dentro del contenedor `chernarus_entrypoint` sirve el contenido estático (HTML, CSS, imágenes, certificado CA para descarga) desde el directorio local `captive_portal_Chernarus_Entrypoint/html/` (relativo a la raíz del proyecto, y mapeado al volumen `/usr/share/nginx/html` en el contenedor). La configuración interna de Nginx es la estándar de la imagen `nginx:alpine` para servir archivos desde ese directorio raíz.
