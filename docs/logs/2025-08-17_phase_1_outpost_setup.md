# Registro de Despliegue: Fase 1 - El Puesto de Avanzada

**Fecha:** `2025-08-17`
**Operador:** `Stalker`
**Objetivo Cumplido:** Se ha establecido la fundación técnica del proyecto "Surviving Chernarus". El sistema anfitrión está asegurado, el almacenamiento persistente configurado, Docker instalado y el firewall base activado.

---

### Cronología de Acciones

#### 1. Identificación del Gestor de Paquetes

-   **Acción:** Se intentó usar `apt`, pero falló. Se procedió a identificar el gestor de paquetes del sistema.
-   **Comando:** `which pacman`
-   **Resultado:** Se confirmó `pacman`. El sistema operativo es Arch Linux o derivado.

#### 2. Preparación y Aseguramiento del Sistema Anfitrión

-   **Acción:** Actualización completa del sistema.
-   **Comando:** `sudo pacman -Syu --noconfirm`
-   **Resultado:** Sistema actualizado a la última versión.

-   **Acción:** Instalación de herramientas esenciales.
-   **Comando:** `sudo pacman -S --noconfirm git tmux vim htop curl ufw parted`
-   **Resultado:** `git`, `tmux`, `vim`, `htop`, `curl`, `ufw` y `parted` instalados.

-   **Acción:** Configuración de IP estática para `eth0`.
-   **Comando:**
    ```bash
    {
        echo "interface eth0"
        echo "static ip_address=192.168.0.2/24"
        echo "static routers=192.168.0.1"
        echo "static domain_name_servers=1.1.1.1 192.168.0.2"
    } | sudo tee -a /etc/dhcpcd.conf
    ```
-   **Resultado:** Configuración aplicada.

-   **Acción:** Reinicio del servicio de red para aplicar la IP estática.
-   **Comando:** `sudo systemctl restart dhcpcd`
-   **Resultado:** El host ahora responde en `192.168.0.2`.

-   **Acción:** Aseguramiento del servicio SSH.
-   **Comando:** `sudo sed -i -e 's/^#?PermitRootLogin.*/PermitRootLogin no/' -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' -e 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config`
-   **Resultado:** Deshabilitado el login de root y la autenticación por contraseña.

-   **Acción:** Reinicio del servicio SSH.
-   **Comando:** `sudo systemctl restart sshd`
-   **Resultado:** Políticas de acceso SSH reforzadas y aplicadas.

#### 3. Configuración del Almacenamiento Persistente

-   **Acción:** Identificación del disco externo.
-   **Comando:** `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT`
-   **Resultado:** Disco identificado como `/dev/sda`.

-   **Acción:** Creación de tabla de particiones GPT y partición primaria en `/dev/sda`.
-   **Comando:** `sudo parted /dev/sda --script -- mklabel gpt mkpart primary ext4 0% 100%`
-   **Resultado:** Partición `/dev/sda1` creada.

-   **Acción:** Formateo de la nueva partición con `ext4`.
-   **Comando:** `sudo mkfs.ext4 /dev/sda1`
-   **Resultado:** Filesystem `ext4` creado en `/dev/sda1`.

-   **Acción:** Creación del punto de montaje.
-   **Comando:** `sudo mkdir -p /mnt/usbdata`
-   **Resultado:** Directorio `/mnt/usbdata` creado.

-   **Acción:** Configuración de montaje automático en `/etc/fstab`.
-   **Comando:** `echo "UUID=$(sudo blkid -s UUID -o value /dev/sda1) /mnt/usbdata ext4 defaults,auto,users,rw,nofail 0 0" | sudo tee -a /etc/fstab`
-   **Resultado:** El disco se montará automáticamente en cada arranque.

-   **Acción:** Montaje del disco y asignación de permisos.
-   **Comandos:**
    ```bash
    sudo mount -a
    sudo chown -R terrerov:terrerov /mnt/usbdata
    ```
-   **Resultado:** Disco montado y accesible por el usuario `terrerov`.

#### 4. Estructuración del Proyecto y Datos

-   **Acción:** Creación de la estructura de directorios del proyecto.
-   **Comandos:**
    ```bash
    mkdir -p /home/terrerov/surviving-chernarus
    mkdir -p /mnt/usbdata/docker_volumes/{traefik,elektrozavodsk_db,n8n,pihole,squid}
    ```
-   **Resultado:** Directorios para configuración y datos persistentes creados.

#### 5. Instalación del Entorno de Contenerización

-   **Acción:** Instalación de Docker y Docker Compose.
-   **Comandos:**
    ```bash
    sudo pacman -S --noconfirm docker docker-compose
    ```
-   **Resultado:** Docker y Docker Compose instalados.

-   **Acción:** Adición del usuario al grupo `docker` y activación del servicio.
-   **Comandos:**
    ```bash
    sudo usermod -aG docker terrerov
    sudo systemctl enable --now docker
    ```
-   **Resultado:** Docker activado y accesible para el usuario `terrerov` (tras re-logueo).

#### 6. Configuración del Firewall

-   **Acción:** Establecimiento de políticas por defecto.
-   **Comando:** `sudo ufw default deny incoming && sudo ufw default allow outgoing`
-   **Resultado:** Perímetro de seguridad inicial establecido.

-   **Acción:** Creación de reglas para permitir servicios esenciales.
-   **Comando:** `sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp`
-   **Resultado:** Puertos para SSH, HTTP y HTTPS abiertos.

-   **Acción:** Activación del firewall.
-   **Comando:** `sudo ufw enable`
-   **Resultado:** Firewall activado y reglas aplicadas.
