# Configuración del Hotspot Wi-Fi

Esta sección te guiará a través de la configuración de un punto de acceso (hotspot) Wi-Fi en tu Raspberry Pi 5. Utilizaremos `hostapd` para crear y gestionar la red inalámbrica. Un contenedor Docker dedicado (`Hotspot_DHCP_Server`) se encargará de los servicios DHCP (asignación de direcciones IP), y Pi-hole (también en un contenedor Docker) proporcionará el servicio DNS (resolución de nombres de dominio) a los dispositivos que se conecten.

La mayoría de las interfaces Wi-Fi integradas en las Raspberry Pi soportan el modo AP (Access Point), que es necesario para esta tarea. Al finalizar esta configuración, tu Raspberry Pi emitirá una nueva red Wi-Fi a la cual los clientes podrán conectarse.

## Identificar la Interfaz Wi-Fi
Primero, necesitas saber el nombre de tu interfaz de red Wi-Fi.

1.  Abre una terminal y ejecuta uno de los siguientes comandos:
    ```bash
    ip link
    ```
    o
    ```bash
    iw dev
    ```
2.  Busca en la salida una interfaz que corresponda a tu hardware Wi-Fi. Comúnmente se llama `wlan0`, pero podría tener un nombre diferente como `wlpXs0` (donde X e Y son números). Anota este nombre, ya que lo necesitarás en los siguientes pasos. Para esta guía, usaremos `wlan0` como ejemplo.

## Instalar `hostapd`
`hostapd` es el software crucial que nos permitirá convertir la interfaz Wi-Fi de la Raspberry Pi en un punto de acceso inalámbrico.

*   `hostapd`: Permite crear y gestionar el punto de acceso.

Instálalo con el siguiente comando:
```bash
sudo pacman -S hostapd
```
Confirma la instalación cuando se te solicite. El servidor DHCP y DNS serán gestionados por contenedores Docker como se describe más adelante.

## Configurar `hostapd`
`hostapd` se configura mediante un archivo de texto. Utilizaremos el archivo `hotspot_config/hostapd.conf` proporcionado en este repositorio del proyecto (asumimos que el repositorio se llama `surviving-chernarus` y está en `~/projects/surviving-chernarus`).

1.  **Copiar el archivo de configuración:**
    Desde la raíz de tu repositorio clonado (e.g., `~/projects/surviving-chernarus`), copia el archivo de configuración de `hostapd` a su ubicación estándar:
    ```bash
    # Ajusta la ruta si tu repositorio está en una ubicación diferente.
    sudo cp hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    ```

2.  **Revisar y Modificar `/etc/hostapd/hostapd.conf`:**
    Abre el archivo `/etc/hostapd/hostapd.conf` con un editor de texto (e.g., `sudo nano /etc/hostapd/hostapd.conf`).
    El archivo proporcionado en el repositorio ya tiene configuraciones base. Asegúrate de que los siguientes parámetros estén correctamente configurados y **modifica obligatoriamente la contraseña**:

    *   `interface=wlan0`: Asegúrate de que coincida con el nombre de tu interfaz Wi-Fi que identificaste anteriormente. Este es el valor por defecto en el archivo del repositorio.
    *   `ssid=rpi`: Este es el nombre de la red Wi-Fi (SSID) que se transmitirá, tal como está definido en el archivo del repositorio. Puedes cambiarlo si lo deseas.
    *   `country_code=US`: Establece el código de tu país (e.g., `ES` para España, `GB` para Reino Unido). Esto es importante para cumplir con las regulaciones locales de espectro radioeléctrico y puede optimizar el rendimiento. El archivo del repositorio usa `US` por defecto.
    *   `wpa_passphrase=CHANGEME_SET_YOUR_WPA_PASSPHRASE`: **Esta línea es un placeholder y DEBES cambiarla.**
        Debes **obligatoriamente** cambiar este valor por una contraseña fuerte y única. Consulta la página [[14-Gestion-Secretos]] para más detalles sobre cómo configurar esta contraseña de forma segura. Por ejemplo:
        ```
        wpa_passphrase=MiClaveWiFiSuperSegura123!
        ```

    **Otros parámetros importantes (generalmente ya configurados en la plantilla del repositorio):**

    *   `channel=7`: Puedes cambiar el canal Wi-Fi si es necesario. Canales comunes son 1, 6, 11 para la banda de 2.4GHz. El valor por defecto en la plantilla es `7`.
    *   `hw_mode=g`: Define el modo de hardware (e.g., `g` para 2.4GHz 802.11g). `hw_mode=g` es una opción segura para compatibilidad.

    Revisa el resto del archivo para entender otras configuraciones y ajústalas si es necesario. Guarda los cambios y cierra el editor.

3.  **Especificar archivo de configuración a `hostapd` (Verificación):**
    En Arch Linux, el servicio `hostapd` normalmente busca el archivo de configuración en `/etc/hostapd/hostapd.conf` por defecto. Si has colocado tu archivo allí, no se necesitan más pasos para este punto. Si necesitaras especificar una ruta diferente, tendrías que crear un archivo de anulación (override) para el servicio systemd de `hostapd`. Para esta guía, asumimos que se usa la ruta por defecto.

## Nuevo Section: `## Configurar Servidor DHCP (Contenedor Dedicado)`
El servidor DHCP para el hotspot (`192.168.73.0/24`) es gestionado por un contenedor Docker dedicado llamado `Hotspot_DHCP_Server`. Este enfoque modulariza los servicios.

*   **Referencia al `docker-compose.yml`:** Este servicio está definido en el archivo principal `docker-compose.yml` ubicado en la raíz del proyecto. Revisa la sección `services.dhcp_server` en ese archivo para ver su configuración detallada (imagen, `network_mode: "host"`, volúmenes, etc.).
*   **Archivo de Configuración:** La configuración del servidor DHCP se encuentra en `hotspot_config/dhcp/dhcpd.conf`. Este archivo es crucial y define cómo se asignan las IPs.
    *   **Parámetros Clave en `dhcpd.conf`:**
        *   `subnet 192.168.73.0 netmask 255.255.255.0 { ... }`: Define la subred del hotspot.
        *   `range 192.168.73.10 192.168.73.200;`: Especifica el rango de direcciones IP que se asignarán a los clientes.
        *   `option routers 192.168.73.1;`: Establece la puerta de enlace (gateway) para los clientes, que es la IP de la Raspberry Pi en la interfaz `wlan0`.
        *   `option domain-name-servers 192.168.73.1;`: Indica a los clientes que utilicen la Raspberry Pi (donde se ejecuta Pi-hole) como su servidor DNS.
    *   Es fundamental revisar este archivo y ajustarlo si tus necesidades de red son diferentes.
*   **No se requiere instalación manual de `dnsmasq` en el host para DHCP:** El contenedor Docker `Hotspot_DHCP_Server` maneja todas las funciones de DHCP para la red del hotspot. Pi-hole (en su propio contenedor) utilizará su instancia interna de `dnsmasq` únicamente para la resolución de DNS.

## Configurar Dirección IP Estática para la Interfaz del Hotspot
La interfaz Wi-Fi que actúa como hotspot (e.g., `wlan0`) necesita tener una dirección IP estática. Esta será la puerta de enlace (gateway) para los clientes del hotspot y la dirección a la que el servidor DHCP (`Hotspot_DHCP_Server`) y Pi-hole (para DNS) estarán vinculados en esta subred. Usaremos la IP `192.168.73.1`.

**Importante:** Es crucial que NetworkManager (o cualquier otro gestor de red que pudieras tener instalado) no intente gestionar esta interfaz una vez que `hostapd` esté activo, ya que `hostapd` toma control exclusivo.

Una forma de asegurar esto es configurar la IP manualmente justo antes de iniciar `hostapd`. Los siguientes comandos son temporales y se perderán al reiniciar.

1.  **Asignar la IP y levantar la interfaz (temporalmente):**
    Reemplaza `wlan0` con tu interfaz si es diferente.
    ```bash
    sudo ip link set dev wlan0 down
    sudo ip addr add 192.168.73.1/24 dev wlan0
    sudo ip link set dev wlan0 up
    ```

**Para hacer esta configuración persistente:**
La forma más robusta en Arch Linux es usar `systemd-networkd` para esta interfaz o deshabilitar su gestión por NetworkManager y usar un script.

*   **Opción 1: Usar `systemd-networkd` (Recomendado para interfaces dedicadas a servicios):**
    1.  Asegúrate de que `systemd-networkd` esté habilitado: `sudo systemctl enable --now systemd-networkd`.
    2.  Detén y deshabilita NetworkManager si no lo necesitas para otras interfaces, o configúralo para ignorar `wlan0`. Para ignorar con NetworkManager, crea el archivo `/etc/NetworkManager/conf.d/99-unmanaged-devices.conf` con:
        ```ini
        [keyfile]
        unmanaged-devices=interface-name:wlan0
        ```
        Luego reinicia NetworkManager: `sudo systemctl restart NetworkManager`.
    3.  Crea un archivo de configuración para `wlan0` en `/etc/systemd/network/`, por ejemplo, `30-hotspot-wlan0.network`:
        ```bash
        sudo nano /etc/systemd/network/30-hotspot-wlan0.network
        ```
        Añade el siguiente contenido (ajusta `wlan0` si es necesario):
        ```ini
        [Match]
        Name=wlan0

        [Network]
        Address=192.168.73.1/24
        # Opcional: si quieres que esta interfaz también tenga DNS (no usual para un simple AP)
        # DNS=8.8.8.8

        [Link]
        RequiredForOnline=no
        ```
        Guarda el archivo.
    4.  Reinicia `systemd-networkd` o reinicia la Raspberry Pi.

*   **Opción 2: Script de inicio (menos elegante pero funcional):**
    Puedes añadir los comandos `ip addr add ...` y `ip link set up ...` a un script que se ejecute antes de que `hostapd` inicie, o como parte de la unidad de servicio de `hostapd`.

Para esta guía, asumiremos que has aplicado los comandos `ip addr add` y `ip link set up` manualmente por ahora, o has configurado `systemd-networkd`.

## Configurar NAT (Network Address Translation)
NAT permite que los dispositivos conectados a tu hotspot (que estarán en la subred `192.168.73.0/24`) accedan a Internet a través de la otra conexión de red de tu Raspberry Pi (e.g., `eth0` o `wlanX` que sí tiene acceso a tu router principal).

1.  **Identificar la interfaz de salida a Internet:**
    Determina qué interfaz de red de tu Raspberry Pi está conectada a Internet. Podría ser `eth0` (conexión cableada) o `wlan1` (si usas otra interfaz Wi-Fi para conectarte a tu router). El script `setup_hotspot_nat.sh` utiliza la variable `ETH_IF` para esto, que por defecto es `eth0`.

2.  **Usar el script `setup_hotspot_nat.sh`:**
    Este repositorio incluye el script `scripts/setup_hotspot_nat.sh` para facilitar la configuración de NAT.

    *   **Revisar y adaptar el script:**
        Abre el script con un editor de texto:
        ```bash
        # Desde la raíz de tu repositorio clonado (e.g., ~/projects/surviving-chernarus)
        nano scripts/setup_hotspot_nat.sh
        ```
        Asegúrate de que las variables `WLAN_IF` (interfaz del hotspot, por defecto `wlan0`) y `ETH_IF` (interfaz con acceso a Internet, por defecto `eth0`) estén correctamente definidas al principio del script para que coincidan con tu configuración.

    *   **Hacer el script ejecutable:**
        ```bash
        # Desde la raíz de tu repositorio clonado
        chmod +x scripts/setup_hotspot_nat.sh
        ```

    *   **Ejecutar el script:**
        ```bash
        # Desde la raíz de tu repositorio clonado
        sudo ./scripts/setup_hotspot_nat.sh
        ```

    El script típicamente hará lo siguiente:
    *   Habilita el reenvío de IP en el kernel: `sudo sysctl -w net.ipv4.ip_forward=1`. (Para hacerlo permanente, esta configuración debería estar en un archivo dentro de `/etc/sysctl.d/`, por ejemplo, `99-sysctl.conf` o uno específico como `hotspot-forwarding.conf`).
    *   Configura reglas de `iptables` para el enmascaramiento (MASQUERADE) y el reenvío de paquetes entre las interfaces.

3.  **Persistencia de `iptables`:**
    Las reglas de `iptables` se pierden al reiniciar. Para hacerlas persistentes en Arch Linux:
    *   Instala `iptables-nft` (si aún no lo has hecho):
        ```bash
        sudo pacman -Syu iptables-nft
        ```
        (Nota: Arch Linux ha migrado a `nftables` como backend por defecto para `iptables`. El paquete `iptables-nft` proporciona las herramientas `iptables-save`/`iptables-restore` que interactúan con `nftables`).
    *   Guarda tus reglas actuales (después de ejecutar el script NAT y cualquier otro script que modifique `iptables`, como `redirect_to_squid.sh` o `setup_captive_portal_redirect.sh`):
        ```bash
        sudo iptables-save > /etc/iptables/iptables.rules
        # Si también configuras reglas de IPv6:
        # sudo ip6tables-save > /etc/iptables/ip6tables.rules
        ```
    *   Habilita el servicio para cargar las reglas al arrancar:
        ```bash
        sudo systemctl enable iptables.service
        # Si usas IPv6:
        # sudo systemctl enable ip6tables.service
        ```
        Es importante ejecutar `iptables-save` después de que todos los scripts que modifican las reglas (`setup_hotspot_nat.sh`, `setup_captive_portal_redirect.sh`, `redirect_to_squid.sh`) hayan sido ejecutados para guardar el estado final deseado.

## Iniciar y Habilitar Servicios
Ahora que `hostapd` está configurado en el sistema operativo anfitrión y los servicios dependientes (DHCP, DNS) están definidos en `docker-compose.yml`, podemos proceder.

1.  **Desbloquear `hostapd` (si es necesario):**
    A veces `hostapd` puede estar "enmascarado" por defecto si otras utilidades de red lo gestionan.
    ```bash
    sudo systemctl unmask hostapd
    ```
2.  **Habilitar e iniciar `hostapd`:**
    Esto lo iniciará ahora y también lo configurará para que arranque automáticamente con el sistema.
    ```bash
    sudo systemctl enable --now hostapd
    ```
3.  **Iniciar los servicios de Docker (DHCP, DNS/Pi-hole, etc.):**
    El servidor DHCP (`Hotspot_DHCP_Server`), Pi-hole (que proporciona DNS), y otros servicios del proyecto se gestionan con Docker Compose.
    Desde el directorio raíz de tu repositorio clonado (e.g., `~/projects/surviving-chernarus`), ejecuta:
    ```bash
    docker-compose up -d
    ```
    Esto iniciará todos los servicios definidos en tu archivo `docker-compose.yml` en segundo plano.

4.  **Comprobar el estado de los servicios:**
    *   **Para `hostapd`:**
        ```bash
        sudo systemctl status hostapd
        ```
        Debería mostrarse como "active (running)". Si hay errores, revisa los logs con `journalctl -u hostapd`.
    *   **Para los servicios Docker:**
        ```bash
        docker ps
        ```
        Deberías ver los contenedores como `Hotspot_DHCP_Server`, `Pihole_DNS_Filter`, `Chernarus_Entrypoint`, `Berezino_Checkpoint`, etc., con el estado "Up".
        Puedes revisar los logs de un contenedor específico si es necesario, por ejemplo: `docker logs Hotspot_DHCP_Server`.

## Pruebas Iniciales del Hotspot
Es el momento de probar si tu hotspot funciona:

1.  **Busca la red Wi-Fi:** Desde otro dispositivo (teléfono, laptop), busca redes Wi-Fi. Deberías ver el SSID `rpi` (o el que hayas configurado en `hostapd.conf`).
2.  **Conéctate a la red:** Usa la contraseña que estableciste para `wpa_passphrase` en `hostapd.conf`.
3.  **Verifica la IP:** Una vez conectado, comprueba la configuración de red en el dispositivo cliente.
    *   Debería haber obtenido una dirección IP dentro del rango DHCP definido en `hotspot_config/dhcp/dhcpd.conf` (e.g., entre `192.168.73.10` y `192.168.73.200`).
    *   La puerta de enlace (gateway) y el servidor DNS deberían ser la IP estática de tu Raspberry Pi en la interfaz `wlan0` (es decir, `192.168.73.1`).
4.  **Prueba el acceso a Internet:** Intenta navegar por alguna página web. Si la configuración de NAT es correcta, deberías tener acceso a Internet.
5.  **Verifica el filtrado DNS (Pi-hole):** Intenta acceder a un dominio conocido por ser bloqueado por Pi-hole (si tienes listas de bloqueo predeterminadas activas) o revisa el "Query Log" en la interfaz de administración de Pi-hole para ver las consultas DNS de tu dispositivo cliente.

Si todo funciona, ¡felicidades! Has configurado con éxito un hotspot Wi-Fi básico en tu Raspberry Pi 5 con Arch Linux, con DHCP y DNS gestionados por contenedores Docker. Las siguientes secciones de esta wiki se basarán en esta configuración para añadir el portal cautivo y otras funcionalidades.
Si encuentras problemas, revisa cuidadosamente los archivos de configuración y los mensajes de error en los logs del sistema (`journalctl -u hostapd`) y de los contenedores Docker (`docker logs <nombre_del_contenedor>`).
