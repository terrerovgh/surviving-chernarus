# Configuración del Portal Cautivo

## Introducción
Un portal cautivo es una página web a la que se redirige a los usuarios recién conectados a una red Wi-Fi antes de que se les conceda acceso completo a Internet. Su propósito en este proyecto es mostrar una página de bienvenida, que podría incluir información, términos y condiciones, o un formulario de login (aunque la implementación de un login completo está fuera del alcance de esta configuración básica).

El portal cautivo se ejecutará como un servicio Docker, utilizando la configuración y los archivos proporcionados en el repositorio del proyecto "Escrowed Kathy". Esto simplifica la gestión y el despliegue del servidor web que servirá la página del portal.

## Navegar al Directorio del Portal Cautivo
Para trabajar con los archivos de configuración del portal cautivo, primero debes navegar al directorio correspondiente dentro del repositorio clonado.

1.  Abre una terminal en tu Raspberry Pi.
2.  Cambia al directorio `captive_portal_Chernarus_Entrypoint`. Si clonaste el proyecto en `~/projects/escrowed-kathy`, el comando sería:
    ```bash
    cd ~/projects/escrowed-kathy/captive_portal_Chernarus_Entrypoint
    ```
    Ajusta la `ruta_al_repo` si tu proyecto está en una ubicación diferente.

## Revisar la Configuración de Docker Compose (`docker-compose.yml`)
El archivo `docker-compose.yml` en este directorio define cómo se construye y ejecuta el servicio del portal cautivo.

1.  Puedes revisar el contenido de este archivo usando un editor de texto o el comando `cat`:
    ```bash
    cat docker-compose.yml
    ```
2.  **Explicación breve del servicio:**
    Este archivo `docker-compose.yml` típicamente define un servicio que ejecuta un servidor web ligero (como Nginx o un simple servidor HTTP basado en Python) para servir las páginas estáticas del portal. El Dockerfile asociado (referenciado en el `docker-compose.yml`) contendrá los detalles de cómo se construye la imagen del contenedor, incluyendo la instalación del servidor web y la copia de los archivos HTML.

3.  **Puertos expuestos:**
    Revisa la sección `ports` en el `docker-compose.yml`. Generalmente, el portal estará configurado para ser accesible en el puerto 80 (HTTP estándar) de la dirección IP de la Raspberry Pi *dentro de la red del hotspot*. Por ejemplo, si la IP de tu RPi en la interfaz del hotspot es `192.168.42.1`, el portal será accesible en `http://192.168.42.1:80`. La redirección de los clientes a esta dirección se configurará más adelante.

## Personalizar la Página del Portal (Opcional)
La apariencia y el contenido de la página que se muestra a los usuarios conectados se encuentran en el subdirectorio `html/` dentro de `captive_portal_Chernarus_Entrypoint/`.

1.  **Archivos del portal:**
    *   El archivo principal suele ser `index.html`.
    *   Puede haber otros archivos como `style.css` para los estilos, imágenes, y `script.js` para cualquier funcionalidad JavaScript.
2.  **Modificación:**
    Puedes modificar estos archivos (HTML, CSS, JavaScript) para personalizar completamente la apariencia, el mensaje de bienvenida, añadir logotipos, o cambiar la funcionalidad del portal según tus necesidades.
3.  **Archivo `.gitkeep`:**
    Si encuentras un archivo llamado `.gitkeep` en el directorio `html/`, este es un archivo vacío que se utiliza para asegurar que el directorio se incluya en el repositorio Git aunque esté vacío. Puedes eliminarlo de forma segura una vez que añadas tus propios archivos al directorio `html/`.

## Construir y Ejecutar el Contenedor del Portal Cautivo
Con la configuración lista, puedes construir la imagen de Docker (si es necesario) y ejecutar el contenedor.

1.  **Construir la imagen (opcional si `up --build` se usa después):**
    Si el `docker-compose.yml` incluye una sección `build`, Docker Compose puede construir la imagen automáticamente. Sin embargo, puedes construirla explícitamente primero:
    ```bash
    sudo docker-compose build
    ```
    Este paso toma el Dockerfile en el directorio actual y construye la imagen localmente.

2.  **Iniciar los servicios del portal cautivo:**
    Para iniciar el servicio del portal cautivo en segundo plano (detached mode), usa:
    ```bash
    sudo docker-compose up -d
    ```
    Si no ejecutaste `build` antes, el comando `sudo docker-compose up -d --build` construirá la imagen y luego iniciará el contenedor.

## Verificar que el Portal está Funcionando
Después de iniciar el servicio, verifica que esté corriendo correctamente.

1.  **Ver los contenedores Docker en ejecución:**
    ```bash
    sudo docker ps
    ```
    Deberías ver un contenedor listado que corresponda a tu servicio de portal cautivo (el nombre puede derivarse del nombre del directorio o estar especificado en el `docker-compose.yml`). Asegúrate de que su estado sea "Up" o "Running".

2.  **Ver los logs del contenedor:**
    Si necesitas solucionar problemas o ver la salida del servidor web dentro del contenedor, puedes ver sus logs. Primero, identifica el nombre del servicio en tu archivo `docker-compose.yml` (suele ser algo como `web` o `captive-portal`).
    ```bash
    sudo docker-compose logs -f nombre_del_servicio_web
    ```
    Reemplaza `nombre_del_servicio_web` con el nombre real del servicio. La opción `-f` sigue la salida del log en tiempo real. Presiona `Ctrl+C` para detener.

3.  **Prueba local (opcional):**
    En este punto, el portal cautivo está funcionando en la Raspberry Pi, pero los clientes conectados al hotspot aún no son redirigidos automáticamente a él. Sin embargo, puedes probar si el servidor web del portal está sirviendo la página accediendo a él localmente desde la Raspberry Pi.
    Si el portal está configurado para el puerto 80 (HTTP estándar):
    ```bash
    curl http://localhost
    ```
    O si está en un puerto diferente (e.g., 8080), especifícalo:
    ```bash
    curl http://localhost:8080
    ```
    Deberías ver el código HTML de tu `index.html` como respuesta.

Con el portal cautivo funcionando como un contenedor Docker, el siguiente paso será configurar las reglas de redirección de tráfico para que los usuarios conectados al hotspot sean dirigidos a esta página antes de obtener acceso a Internet. Esto se cubrirá en la sección de configuración de `iptables` o el software de redirección pertinente.
