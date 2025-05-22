# Instalación de Dependencias del Proyecto

Para poner en marcha el proyecto Escrowed Kathy, necesitamos instalar algunas herramientas esenciales en nuestra Raspberry Pi 5 con Arch Linux. Estas herramientas incluyen `git` para la gestión del código fuente, y `Docker` junto con `Docker Compose` para la gestión de los servicios del proyecto de manera contenerizada.

## Instalar Git
Git es un sistema de control de versiones distribuido, fundamental para descargar (clonar) el código fuente del proyecto desde su repositorio.

1.  **Instalar Git:**
    Abre una terminal y ejecuta el siguiente comando para instalar Git utilizando `pacman`:
    ```bash
    sudo pacman -S git
    ```
    Cuando se te pregunte, confirma la instalación presionando `Y` y luego Enter.

2.  **Verificar la instalación (opcional):**
    Para asegurarte de que Git se ha instalado correctamente, puedes verificar su versión:
    ```bash
    git --version
    ```
    Esto debería mostrar la versión de Git instalada.

## Instalar Docker
Docker es una plataforma de código abierto que permite automatizar el despliegue, escalado y gestión de aplicaciones dentro de contenedores.

1.  **Instalar Docker:**
    Ejecuta el siguiente comando para instalar Docker:
    ```bash
    sudo pacman -S docker
    ```
    Confirma la instalación cuando se te solicite.

2.  **Habilitar y Arrancar el Servicio Docker:**
    Para que Docker se inicie automáticamente cada vez que arranque el sistema y para iniciarlo inmediatamente, usa:
    ```bash
    sudo systemctl enable --now docker
    ```
    Este comando combina `sudo systemctl enable docker` (habilitar en el arranque) y `sudo systemctl start docker` (iniciar ahora).

3.  **Verificar que Docker está corriendo:**
    Puedes comprobar el estado del servicio Docker con:
    ```bash
    sudo systemctl status docker
    ```
    Debería mostrar "active (running)". También puedes ejecutar:
    ```bash
    sudo docker ps
    ```
    Este comando lista los contenedores activos (que inicialmente estará vacío). Si no da un error, Docker está funcionando.

## Instalar Docker Compose
Docker Compose es una herramienta para definir y ejecutar aplicaciones Docker multi-contenedor. Utiliza archivos YAML para configurar los servicios de la aplicación.

1.  **Instalar Docker Compose:**
    En Arch Linux, Docker Compose se instala generalmente como un paquete separado llamado `docker-compose`.
    ```bash
    sudo pacman -S docker-compose
    ```
    Confirma la instalación.

2.  **Verificar la instalación:**
    Para comprobar que Docker Compose se ha instalado correctamente, ejecuta:
    ```bash
    docker-compose --version
    ```
    Esto debería mostrar la versión de Docker Compose instalada.

## Añadir Usuario al Grupo Docker (Importante)
Por defecto, los comandos `docker` requieren privilegios de superusuario (`sudo`). Para ejecutar comandos `docker` sin necesidad de anteponer `sudo` cada vez, debes añadir tu usuario al grupo `docker`.

1.  **Añadir tu usuario al grupo `docker`:**
    Reemplaza `tu_usuario` con tu nombre de usuario actual (por ejemplo, `alarm` si estás usando el usuario por defecto de Arch Linux ARM). Si no estás seguro de tu nombre de usuario, puedes usar la variable `$USER` que generalmente contiene el nombre del usuario actual.
    ```bash
    sudo usermod -aG docker $USER
    ```
    Si prefieres especificar el usuario directamente (e.g., `alarm`):
    ```bash
    sudo usermod -aG docker alarm
    ```

2.  **Aplicar los cambios de grupo:**
    **¡MUY IMPORTANTE!** Para que este cambio de pertenencia a grupo tenga efecto, necesitas cerrar sesión y volver a iniciarla, o reiniciar tu Raspberry Pi.
    ```bash
    # Opción 1: Cerrar sesión y volver a iniciarla
    # Opción 2: Reiniciar
    sudo reboot
    ```
    Después de volver a iniciar sesión o reiniciar, deberías poder ejecutar comandos `docker` (como `docker ps`) sin `sudo`.

## Clonar el Repositorio del Proyecto "Escrowed Kathy"
Una vez que todas las dependencias están instaladas y configuradas, puedes clonar el repositorio del proyecto Escrowed Kathy.

1.  **Crear un directorio para tus proyectos (opcional):**
    Es una buena práctica mantener tus proyectos organizados.
    ```bash
    mkdir -p ~/projects
    cd ~/projects
    ```
    El comando `mkdir -p` crea el directorio si no existe, y no muestra error si ya existe.

2.  **Clonar el repositorio:**
    Utiliza `git clone` para descargar el proyecto. Deberás reemplazar `URL_DEL_REPOSITORIO_AQUI` con la URL real del repositorio del proyecto Escrowed Kathy.
    ```bash
    git clone URL_DEL_REPOSITORIO_AQUI
    ```
    Por ejemplo, si el repositorio estuviera en GitHub bajo el usuario "ejemplo" y el nombre "escrowed-kathy", el comando sería:
    ```bash
    # Ejemplo: git clone https://github.com/ejemplo/escrowed-kathy.git
    ```

3.  **Navegar al directorio del proyecto:**
    Una vez clonado, accede al directorio del proyecto. El nombre del directorio será usualmente el mismo que el nombre del repositorio.
    ```bash
    cd nombre-del-repositorio # ej. cd escrowed-kathy
    ```

Con estos pasos, tendrás todas las dependencias necesarias instaladas y el código fuente del proyecto listo para la configuración y el despliegue de los servicios.
