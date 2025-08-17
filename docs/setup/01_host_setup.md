# Guía de Configuración: 01 - Sistema Anfitrión

**Objetivo:** Preparar y asegurar una Raspberry Pi con Arch Linux AArch64 para servir como el sistema anfitrión del proyecto "Surviving Chernarus".

Esta guía cubre la actualización del sistema, la configuración de red, el aseguramiento de SSH, la preparación del almacenamiento externo y la instalación de Docker.

---

### 1. Actualización del Sistema y Herramientas

1.  **Actualizar el Sistema:**
Asegúrate de que todos los paquetes del sistema estén actualizados.
    ```bash
    sudo pacman -Syu --noconfirm
    ```

2.  **Instalar Herramientas Esenciales:**
Instala el software necesario para la administración del sistema.
    ```bash
    sudo pacman -S --noconfirm git tmux vim htop curl ufw parted
    ```

### 2. Configuración de Red Estática

1.  **Editar el archivo de configuración de `dhcpcd`:**
Añade las siguientes líneas al final del archivo `/etc/dhcpcd.conf` para configurar una IP estática. Reemplaza los valores según tu red.
    ```ini
    interface eth0
    static ip_address=192.168.0.2/24
    static routers=192.168.0.1
    static domain_name_servers=1.1.1.1 192.168.0.2
    ```
    *Puedes usar el siguiente comando para añadirlo directamente:*
    ```bash
    {
        echo "interface eth0"
        echo "static ip_address=192.168.0.2/24"
        echo "static routers=192.168.0.1"
        echo "static domain_name_servers=1.1.1.1 192.168.0.2"
    } | sudo tee -a /etc/dhcpcd.conf
    ```

2.  **Reiniciar el Servicio de Red:**
Aplica la nueva configuración de red. Tu conexión SSH se reiniciará y deberás conectarte a la nueva IP.
    ```bash
    sudo systemctl restart dhcpcd
    ```

### 3. Aseguramiento del Acceso SSH

1.  **Modificar la Configuración de SSH:**
Edita el archivo `/etc/ssh/sshd_config` para deshabilitar el login de `root` y la autenticación por contraseña.
    ```bash
    sudo sed -i \
        -e 's/^#?PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' \
        /etc/ssh/sshd_config
    ```

2.  **Reiniciar el Servicio SSH:**
Aplica la nueva configuración de seguridad.
    ```bash
    sudo systemctl restart sshd
    ```

### 4. Configuración del Almacenamiento Externo

1.  **Particionar el Disco:**
Crea una tabla de particiones GPT y una partición `ext4` que ocupe todo el disco. **Advertencia: Esto borra todos los datos del disco.**
    ```bash
    sudo parted /dev/sda --script -- mklabel gpt mkpart primary ext4 0% 100%
    ```

2.  **Formatear la Partición:**
    ```bash
    sudo mkfs.ext4 /dev/sda1
    ```

3.  **Configurar el Montaje Automático:**
    -   Crea el punto de montaje:
        ```bash
        sudo mkdir -p /mnt/usbdata
        ```
    -   Añade el disco a `/etc/fstab` para que se monte en cada arranque:
        ```bash
        UUID=$(sudo blkid -s UUID -o value /dev/sda1)
        echo "UUID=$UUID /mnt/usbdata ext4 defaults,auto,users,rw,nofail 0 0" | sudo tee -a /etc/fstab
        ```

4.  **Montar y Asignar Permisos:**
    ```bash
    sudo mount -a
    sudo chown -R terrerov:terrerov /mnt/usbdata
    ```

### 5. Instalación de Docker

1.  **Instalar Docker y Docker Compose:**
    ```bash
    sudo pacman -S --noconfirm docker docker-compose
    ```

2.  **Añadir tu Usuario al Grupo `docker`:**
    ```bash
    sudo usermod -aG docker terrerov
    ```
    **Nota:** Deberás cerrar sesión y volver a iniciarla para que este cambio surta efecto.

3.  **Habilitar y Iniciar el Servicio Docker:**
    ```bash
    sudo systemctl enable --now docker
    ```

### 6. Configuración del Firewall

1.  **Establecer Políticas por Defecto:**
    ```bash
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    ```

2.  **Permitir Puertos Esenciales:**
    ```bash
    sudo ufw allow 22/tcp   # SSH
    sudo ufw allow 80/tcp   # HTTP
    sudo ufw allow 443/tcp  # HTTPS
    ```

3.  **Activar el Firewall:**
    ```bash
    sudo ufw enable
    ```
---
**Configuración del Anfitrión Completada.**
