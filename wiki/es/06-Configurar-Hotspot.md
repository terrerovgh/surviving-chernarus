# Configuración del Hotspot Wi-Fi

Esta sección te guiará a través de la configuración de un punto de acceso (hotspot) Wi-Fi en tu Raspberry Pi 5. Utilizaremos `hostapd` para crear y gestionar la red inalámbrica y `dnsmasq` para proporcionar servicios DHCP (asignación de direcciones IP) y DNS (resolución de nombres de dominio) a los dispositivos que se conecten.

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

## Instalar `hostapd` y `dnsmasq`
Estas dos piezas de software son cruciales para nuestro hotspot.

*   `hostapd`: Permite convertir tu interfaz Wi-Fi en un punto de acceso.
*   `dnsmasq`: Un servidor ligero de DHCP y DNS.

Instálalos con el siguiente comando:
```bash
sudo pacman -S hostapd dnsmasq
```
Confirma la instalación cuando se te solicite.

## Configurar `hostapd`
`hostapd` se configura mediante un archivo de texto. Usaremos el archivo `hotspot_config/hostapd.conf` proporcionado en el repositorio del proyecto "Escrowed Kathy" como plantilla.

1.  **Copiar el archivo de configuración:**
    Suponiendo que has clonado el repositorio del proyecto en `~/projects/escrowed-kathy`, el comando para copiar el archivo sería:
    ```bash
    sudo cp ~/projects/escrowed-kathy/hotspot_config/hostapd.conf /etc/hostapd/hostapd.conf
    ```
    Ajusta la `ruta_al_repo` si tu proyecto está en una ubicación diferente. `/etc/hostapd/hostapd.conf` es la ubicación estándar que `hostapd` suele buscar.

2.  **Modificar `hostapd.conf`:**
    Abre el archivo `/etc/hostapd/hostapd.conf` con un editor de texto (e.g., `sudo nano /etc/hostapd/hostapd.conf`) y **modifica obligatoriamente** los siguientes parámetros:

    *   `interface=wlan0`: Cambia `wlan0` por el nombre de tu interfaz Wi-Fi que identificaste anteriormente.
    *   `ssid=NombreDeTuHotspot`: Reemplaza `NombreDeTuHotspot` por el nombre que deseas para tu red Wi-Fi (el que verán los usuarios).
    *   `wpa_passphrase=TuContraseñaSegura`: Reemplaza `TuContraseñaSegura` por una contraseña robusta de al menos 8 caracteres. Esta será la clave para acceder a tu red Wi-Fi.

    **Parámetros opcionales pero recomendados a revisar:**

    *   `channel=6`: Puedes cambiar el canal Wi-Fi. Canales comunes son 1, 6, 11 para la banda de 2.4GHz.
    *   `hw_mode=g`: Define el modo de hardware (e.g., `g` para 2.4GHz 802.11g, `a` para 5GHz 802.11a, `n` para 802.11n). Asegúrate de que tu hardware lo soporta. `hw_mode=g` es una opción segura para compatibilidad.
    *   `country_code=ES`: Descomenta esta línea (quitando el `#`) y establece el código de tu país (e.g., `ES` para España, `US` para Estados Unidos, `MX` para México). Esto es importante para cumplir con las regulaciones locales de espectro radioeléctrico y puede optimizar el rendimiento.

    Guarda los cambios y cierra el editor.

3.  **Especificar archivo de configuración a `hostapd` (Verificación):**
    En Arch Linux, el servicio `hostapd` normalmente busca el archivo de configuración en `/etc/hostapd/hostapd.conf` por defecto. Si has colocado tu archivo allí, no se necesitan más pasos para este punto. Si necesitaras especificar una ruta diferente, tendrías que crear un archivo de anulación (override) para el servicio systemd de `hostapd`. Para esta guía, asumimos que se usa la ruta por defecto.

## Configurar `dnsmasq`
`dnsmasq` proporcionará direcciones IP a los clientes que se conecten a tu hotspot y gestionará las peticiones DNS.

1.  **Respaldar la configuración original de `dnsmasq`:**
    Es una buena práctica mover el archivo de configuración por defecto para empezar con una configuración limpia.
    ```bash
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    ```

2.  **Crear un nuevo archivo `/etc/dnsmasq.conf`:**
    Usa un editor de texto para crear y editar el archivo:
    ```bash
    sudo nano /etc/dnsmasq.conf
    ```
    Añade el siguiente contenido básico. Lee los comentarios para entender cada línea:
    ```ini
    # Interfaz en la que dnsmasq escuchará.
    # Cambia wlan0 por tu interfaz de hotspot si es diferente.
    interface=wlan0

    # Rango de direcciones IP que se asignarán a los clientes,
    # la máscara de subred y el tiempo de concesión (lease time).
    # Elige una subred que NO esté en uso en tu red local principal.
    # Ejemplo: 192.168.42.50 a 192.168.42.150.
    # La IP de la Raspberry Pi en esta interfaz será 192.168.42.1 (ver más adelante).
    dhcp-range=192.168.42.50,192.168.42.150,255.255.255.0,12h

    # Servidores DNS que se proporcionarán a los clientes.
    # Puedes usar los de tu ISP, Google (8.8.8.8, 8.8.4.4), Cloudflare (1.1.1.1), etc.
    server=8.8.8.8
    server=1.1.1.1

    # No reenviar nombres simples (sin puntos) a los servidores DNS upstream.
    domain-needed

    # No reenviar direcciones de rangos privados (no ruteables) a los servidores DNS upstream.
    bogus-priv

    # No leer el archivo /etc/resolv.conf del host, ya que hemos especificado
    # los servidores DNS 'server=' directamente.
    no-resolv
    ```
    Guarda los cambios y cierra el editor.

3.  **Nota sobre configuraciones avanzadas de `dnsmasq`:**
    El repositorio del proyecto "Escrowed Kathy" podría incluir un archivo como `hotspot_config/pihole_custom_dnsmasq.conf`. Este tipo de archivos se utilizan para configuraciones más avanzadas (como la integración con Pi-hole para filtrado de anuncios) y se colocarían en el directorio `/etc/dnsmasq.d/` (e.g., `/etc/dnsmasq.d/02-pihole.conf`). Para nuestra configuración básica actual, el contenido de `/etc/dnsmasq.conf` que acabamos de crear es suficiente.

## Configurar Dirección IP Estática para la Interfaz del Hotspot
La interfaz Wi-Fi que actúa como hotspot (e.g., `wlan0`) necesita tener una dirección IP estática dentro de la subred que `dnsmasq` va a gestionar. Esta será la puerta de enlace (gateway) para los clientes del hotspot.

Usaremos la IP `192.168.42.1` como ejemplo, asumiendo que tu `dhcp-range` en `dnsmasq.conf` es `192.168.42.50,192.168.42.150,...`.

**Importante:** Es crucial que NetworkManager (o cualquier otro gestor de red) no intente gestionar esta interfaz una vez que `hostapd` esté activo, ya que `hostapd` toma control exclusivo.

Una forma de asegurar esto es configurar la IP manualmente justo antes de iniciar `hostapd`. Los siguientes comandos son temporales y se perderán al reiniciar.

1.  **Asignar la IP y levantar la interfaz:**
    Reemplaza `wlan0` con tu interfaz si es diferente, y `192.168.42.1/24` con la IP y máscara de subred (CIDR) que coincida con tu configuración de `dnsmasq`.
    ```bash
    sudo ip link set dev wlan0 down
    sudo ip addr add 192.168.42.1/24 dev wlan0
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
        Añade el siguiente contenido (ajusta `wlan0` y la IP si es necesario):
        ```ini
        [Match]
        Name=wlan0

        [Network]
        Address=192.168.42.1/24
        # Opcional: si quieres que esta interfaz también tenga DNS (no usual para un simple AP)
        # DNS=8.8.8.8
        DHCPServer=no # Deshabilitamos el servidor DHCP de systemd-networkd, ya que usaremos dnsmasq

        [Link]
        RequiredForOnline=no
        ```
        Guarda el archivo.
    4.  Reinicia `systemd-networkd` o reinicia la Raspberry Pi.

*   **Opción 2: Script de inicio (menos elegante pero funcional):**
    Puedes añadir los comandos `ip addr add ...` y `ip link set up ...` a un script que se ejecute antes de que `hostapd` inicie, o como parte de la unidad de servicio de `hostapd`.

Para esta guía, asumiremos que has aplicado los comandos `ip addr add` y `ip link set up` manualmente por ahora, o has configurado `systemd-networkd`.

## Configurar NAT (Network Address Translation)
NAT permite que los dispositivos conectados a tu hotspot (que estarán en la subred `192.168.42.0/24`) accedan a Internet a través de la otra conexión de red de tu Raspberry Pi (e.g., `eth0` o `wlanX` que sí tiene acceso a tu router principal).

1.  **Identificar la interfaz de salida a Internet:**
    Determina qué interfaz de red de tu Raspberry Pi está conectada a Internet. Podría ser `eth0` (conexión cableada) o `wlan1` (si usas otra interfaz Wi-Fi para conectarte a tu router). Llamaremos a esta `INTERFAZ_SALIDA`.

2.  **Usar el script `setup_hotspot_nat.sh`:**
    El repositorio del proyecto "Escrowed Kathy" debería incluir un script para facilitar la configuración de NAT, por ejemplo, en `scripts/setup_hotspot_nat.sh`.

    *   **Revisar y adaptar el script:**
        Abre el script con un editor de texto:
        ```bash
        nano ~/projects/escrowed-kathy/scripts/setup_hotspot_nat.sh
        ```
        Asegúrate de que las variables `IN_IFACE` (interfaz del hotspot, e.g., `wlan0`) y `OUT_IFACE` (interfaz con acceso a Internet, e.g., `eth0`) estén correctamente definidas al principio del script.

    *   **Hacer el script ejecutable:**
        ```bash
        chmod +x ~/projects/escrowed-kathy/scripts/setup_hotspot_nat.sh
        ```

    *   **Ejecutar el script:**
        ```bash
        sudo ~/projects/escrowed-kathy/scripts/setup_hotspot_nat.sh
        ```

    El script típicamente hará lo siguiente:
    *   Habilita el reenvío de IP en el kernel: `sudo sysctl -w net.ipv4.ip_forward=1` (y lo hace permanente en `/etc/sysctl.d/`).
    *   Configura reglas de `iptables` para el enmascaramiento (MASQUERADE) y el reenvío de paquetes entre las interfaces.

3.  **Persistencia de `iptables`:**
    Las reglas de `iptables` se pierden al reiniciar. Para hacerlas persistentes en Arch Linux:
    *   Instala `iptables-persistent` (que en Arch a menudo se maneja con `iptables` y su servicio systemd):
        ```bash
        sudo pacman -S iptables-nft
        ```
        (Nota: Arch Linux ha migrado a `nftables` como backend por defecto para `iptables`. El paquete `iptables-nft` proporciona las herramientas `iptables-save`/`iptables-restore` que interactúan con `nftables`).
    *   Guarda tus reglas actuales (después de ejecutar el script NAT):
        ```bash
        sudo iptables-save > /etc/iptables/iptables.rules
        sudo ip6tables-save > /etc/iptables/ip6tables.rules # Si usas IPv6
        ```
    *   Habilita el servicio para cargar las reglas al arrancar:
        ```bash
        sudo systemctl enable --now iptables.service
        sudo systemctl enable --now ip6tables.service # Si usas IPv6
        ```

## Iniciar y Habilitar Servicios
Ahora que todo está configurado, podemos iniciar y habilitar los servicios `hostapd` y `dnsmasq`.

1.  **Desbloquear `hostapd` (si es necesario):**
    A veces `hostapd` puede estar "enmascarado" por defecto si otras utilidades de red lo gestionan.
    ```bash
    sudo systemctl unmask hostapd
    ```
2.  **Habilitar e iniciar los servicios:**
    Esto los iniciará ahora y también los configurará para que arranquen automáticamente con el sistema.
    ```bash
    sudo systemctl enable --now hostapd
    sudo systemctl enable --now dnsmasq
    ```
3.  **Comprobar el estado de los servicios:**
    ```bash
    sudo systemctl status hostapd dnsmasq
    ```
    Ambos deberían mostrarse como "active (running)". Si hay errores, revisa los logs con `journalctl -u hostapd` o `journalctl -u dnsmasq` para diagnosticar el problema. Problemas comunes incluyen errores en los archivos de configuración o conflictos de interfaz.

## Pruebas Iniciales del Hotspot
Es el momento de probar si tu hotspot funciona:

1.  **Busca la red Wi-Fi:** Desde otro dispositivo (teléfono, laptop), busca redes Wi-Fi. Deberías ver el SSID (`NombreDeTuHotspot`) que configuraste.
2.  **Conéctate a la red:** Usa la contraseña (`TuContraseñaSegura`) que estableciste.
3.  **Verifica la IP:** Una vez conectado, comprueba la configuración de red en el dispositivo cliente. Debería haber obtenido una dirección IP dentro del rango DHCP que definiste en `dnsmasq.conf` (e.g., `192.168.42.50`). La puerta de enlace (gateway) y el servidor DNS deberían ser la IP estática de tu Raspberry Pi en la interfaz `wlan0` (e.g., `192.168.42.1`).
4.  **Prueba el acceso a Internet:** Intenta navegar por alguna página web. Si la configuración de NAT es correcta, deberías tener acceso a Internet.

Si todo funciona, ¡felicidades! Has configurado con éxito un hotspot Wi-Fi básico en tu Raspberry Pi 5 con Arch Linux. Las siguientes secciones de esta wiki se basarán en esta configuración para añadir el portal cautivo y otras funcionalidades.
Si encuentras problemas, revisa cuidadosamente los archivos de configuración y los mensajes de error en los logs del sistema (`journalctl`).
