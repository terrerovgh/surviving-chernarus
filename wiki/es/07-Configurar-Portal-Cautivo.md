# Configuración del Portal Cautivo

## Introducción
Un portal cautivo es una página web a la que se redirige a los usuarios recién conectados a una red Wi-Fi antes de que se les conceda acceso completo a Internet. Su propósito en este proyecto es mostrar una página de bienvenida, que podría incluir información, términos y condiciones, o un formulario de login (aunque la implementación de un login completo está fuera del alcance de esta configuración básica).

El portal cautivo se ejecutará como un servicio Docker, utilizando la configuración y los archivos proporcionados en el repositorio del proyecto "Escrowed Kathy", **definido ahora en el archivo `docker-compose.yml` principal del proyecto.** Esto simplifica la gestión y el despliegue del servidor web que servirá la página del portal.

## Navegar al Directorio del Portal Cautivo
Para trabajar con los archivos de configuración del portal cautivo, primero debes navegar al **directorio raíz del proyecto clonado.**

1.  Abre una terminal en tu Raspberry Pi.
2.  Cambia al directorio `captive_portal_Chernarus_Entrypoint`. Si clonaste el proyecto en `~/projects/escrowed-kathy`, el comando sería:
    ```bash
    cd ~/projects/escrowed-kathy
    ```
    Ajusta la `ruta_al_repo` si tu proyecto está en una ubicación diferente.

## Revisar la Configuración en el `docker-compose.yml` Principal
El archivo `docker-compose.yml` **en la raíz del proyecto** define cómo se construye y ejecuta el servicio del portal cautivo (`chernarus_entrypoint`).

1.  Busca la definición del servicio `chernarus_entrypoint` dentro de este archivo.
2.  **Explicación breve del servicio:**
    Este servicio utiliza una imagen de Nginx para servir las páginas estáticas del portal. Los archivos HTML se montan desde `./captive_portal_Chernarus_Entrypoint/html/`.

3.  **Puertos expuestos:**
    Revisa la sección `ports` en el `docker-compose.yml` para el servicio `chernarus_entrypoint`. Generalmente, el portal estará configurado para ser accesible en el puerto 80 (HTTP estándar) de la dirección IP de la Raspberry Pi *dentro de la red del hotspot* (o un puerto específico como `8080` mapeado al puerto 80 del contenedor). Por ejemplo, si la IP de tu RPi en la interfaz del hotspot es `192.168.100.1` y el puerto mapeado es `8080`, el portal será accesible en `http://192.168.100.1:8080`. La redirección de los clientes a esta dirección se configurará más adelante.

## Personalizar la Página del Portal (Opcional)
La apariencia y el contenido de la página que se muestra a los usuarios conectados se encuentran en el subdirectorio `html/` dentro de `captive_portal_Chernarus_Entrypoint/` (relativo a la raíz del proyecto).

1.  **Archivos del portal:**
    *   El archivo principal suele ser `index.html`.
    *   Puede haber otros archivos como `style.css` para los estilos, imágenes, y `script.js` para cualquier funcionalidad JavaScript.
2.  **Modificación:**
    Puedes modificar estos archivos (HTML, CSS, JavaScript) para personalizar completamente la apariencia, el mensaje de bienvenida, añadir logotipos, o cambiar la funcionalidad del portal según tus necesidades.
3.  **Archivo `.gitkeep`:**
    Si encuentras un archivo llamado `.gitkeep` en el directorio `html/`, este es un archivo vacío que se utiliza para asegurar que el directorio se incluya en el repositorio Git aunque esté vacío. Puedes eliminarlo de forma segura una vez que añadas tus propios archivos al directorio `html/`.

## Construir y Ejecutar el Contenedor del Portal Cautivo
Con la configuración lista, puedes construir la imagen de Docker (si es necesario) y ejecutar el contenedor. Debes estar en el directorio raíz del proyecto.

1.  **Construir la imagen (opcional si `up --build` se usa después):**
    Si el `docker-compose.yml` principal define cómo construir el servicio `chernarus_entrypoint` (o si usa una imagen pre-construida), Docker Compose puede manejarlo. Para construir solo este servicio explícitamente:
    ```bash
    sudo docker compose build chernarus_entrypoint
    ```
    Este paso toma la configuración del servicio `chernarus_entrypoint` en el `docker-compose.yml` y construye la imagen localmente si es necesario. Opcionalmente, puedes omitir este paso si utilizas `sudo docker compose up -d --build chernarus_entrypoint`, lo cual construirá la imagen si no existe antes de iniciar el contenedor.

2.  **Iniciar los servicios del portal cautivo:**
    Para iniciar el servicio del portal cautivo (`chernarus_entrypoint`) en segundo plano (detached mode), usa:
    ```bash
    sudo docker compose up -d chernarus_entrypoint
    ```
    Si no ejecutaste `build` antes y la imagen necesita ser construida, el comando `sudo docker compose up -d --build chernarus_entrypoint` construirá la imagen y luego iniciará el contenedor.
    Si deseas iniciar todos los servicios definidos en el `docker-compose.yml` (incluyendo el portal, Squid, Pi-hole, etc.), puedes ejecutar `sudo docker compose up -d` desde la raíz del proyecto.

## Verificar que el Portal está Funcionando
Después de iniciar el servicio, verifica que esté corriendo correctamente.

1.  **Ver los contenedores Docker en ejecución:**
    ```bash
    sudo docker ps
    ```
    Deberías ver un contenedor listado que corresponda a tu servicio de portal cautivo (el nombre será `Chernarus_Entrypoint` o similar, como se define en `container_name` en el `docker-compose.yml`). Asegúrate de que su estado sea "Up" o "Running".

2.  **Ver los logs del contenedor:**
    Si necesitas solucionar problemas o ver la salida del servidor web dentro del contenedor, puedes ver sus logs. Primero, identifica el nombre del servicio en tu archivo `docker-compose.yml` (es `chernarus_entrypoint`).
    ```bash
    sudo docker compose logs -f chernarus_entrypoint
    ```
    La opción `-f` sigue la salida del log en tiempo real. Presiona `Ctrl+C` para detener.

3.  **Prueba local (opcional):**
    En este punto, el portal cautivo está funcionando en la Raspberry Pi, pero los clientes conectados al hotspot aún no son redirigidos automáticamente a él. Sin embargo, puedes probar si el servidor web del portal está sirviendo la página accediendo a él localmente desde la Raspberry Pi.
    Si el portal está configurado para el puerto 8080 en el host (como es por defecto en la configuración centralizada):
    ```bash
    curl http://localhost:8080
    ```
    Deberías ver el código HTML de tu `index.html` como respuesta.

Con el portal cautivo funcionando como un contenedor Docker, el siguiente paso será configurar las reglas de redirección de tráfico para que los usuarios conectados al hotspot sean dirigidos a esta página antes de obtener acceso a Internet. Esto se cubrirá en la sección de configuración de `iptables` o el software de redirección pertinente.
