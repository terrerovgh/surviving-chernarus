# Configuración de Red Básica en Arch Linux

Una configuración de red adecuada es fundamental para cualquier sistema, y más aún para un proyecto como Escrowed Kathy que depende de la conectividad para ofrecer servicios de hotspot y portal cautivo. Esta sección cubre los pasos esenciales para configurar la red en tu Raspberry Pi 5 con Arch Linux, utilizando NetworkManager.

## Herramientas de Red
Arch Linux sigue una filosofía minimalista, por lo que es posible que algunas herramientas de red comunes no estén instaladas por defecto.

1.  **Instalar NetworkManager:** Es la herramienta recomendada para gestionar las conexiones de red de forma dinámica y sencilla.
    ```bash
    sudo pacman -S networkmanager
    ```
2.  **Habilitar y Arrancar NetworkManager:** Para que NetworkManager se inicie automáticamente con el sistema y comience a funcionar de inmediato:
    ```bash
    sudo systemctl enable --now NetworkManager
    ```
    Esto asegura que NetworkManager se inicie en cada arranque y también lo inicia en la sesión actual.
3.  **Opcional: Herramientas adicionales para Wi-Fi:** Aunque NetworkManager maneja la mayoría de las configuraciones Wi-Fi, en casos de necesitar diagnósticos o configuraciones manuales avanzadas, `iw` y `wireless_tools` pueden ser útiles.
    ```bash
    sudo pacman -S iw wireless_tools
    ```
    Para la mayoría de los usuarios, NetworkManager será suficiente.

## Configurar Conexión Wi-Fi (usando NetworkManager)
NetworkManager facilita la conexión a redes inalámbricas.

1.  **Listar interfaces de red:** Identifica el nombre de tu interfaz Wi-Fi.
    ```bash
    nmcli device
    ```
    o también puedes usar:
    ```bash
    ip link
    ```
    Busca una interfaz con un nombre como `wlan0` o `wlpXsY`.
2.  **Escanear redes Wi-Fi disponibles:**
    ```bash
    nmcli dev wifi list
    ```
    Esto mostrará una lista de las redes Wi-Fi detectadas, junto con su SSID, modo, canal, velocidad y seguridad.
3.  **Conectarse a una red Wi-Fi:** Reemplaza `"NombreDeTuRed"` con el SSID de tu red y `"TuContraseña"` con la contraseña de la misma.
    ```bash
    nmcli dev wifi connect "NombreDeTuRed" password "TuContraseña"
    ```
    Si la red no tiene contraseña (red abierta), puedes omitir la parte de `password`. Si necesitas especificar la interfaz (si tienes varias), puedes añadir `ifname nombre-interfaz` antes de `connect`.
4.  **Verificar la conexión:** Una vez conectado, comprueba si tienes acceso a Internet.
    ```bash
    ping archlinux.org
    ```
    Si recibes respuestas, ¡estás conectado! Presiona `Ctrl+C` para detener el ping.

## Configurar Conexión Ethernet (usando NetworkManager)
La conexión Ethernet (cableada) suele ser más sencilla, ya que NetworkManager a menudo la configura automáticamente.

1.  **Conectar el cable:** Asegúrate de que el cable Ethernet esté conectado desde tu Raspberry Pi 5 a tu router o switch.
2.  **Comprobar la conexión:** NetworkManager debería detectar y configurar la conexión automáticamente. Puedes verificar el estado de tus dispositivos de red:
    ```bash
    nmcli device status
    ```
    Busca tu interfaz Ethernet (comúnmente `eth0` o un nombre similar como `enpXsY`) y verifica que su estado sea "connected" o "conectado".
3.  **Verificar la dirección IP:** Para ver la dirección IP asignada a tu interfaz Ethernet:
    ```bash
    ip addr show dev eth0
    ```
    (Reemplaza `eth0` con el nombre real de tu interfaz Ethernet si es diferente). Deberías ver una dirección IP asignada por DHCP de tu red local.

## Configurar una Dirección IP Estática (Opcional pero Recomendado para un Servidor)
Para un servidor o un dispositivo que ofrecerá servicios de red (como nuestro hotspot y portal cautivo), es altamente recomendable configurar una dirección IP estática. Esto asegura que la dirección IP de la Raspberry Pi no cambie después de reiniciar, facilitando el acceso a sus servicios.

**Importante:** Esta IP estática es para la conexión de la Raspberry Pi a tu red local (para que puedas acceder a ella vía SSH, por ejemplo), NO para la interfaz del hotspot que crearemos más adelante. La configuración de la red del hotspot se tratará en una sección posterior.

Usaremos `nmcli` para modificar una conexión existente y asignarle una IP estática. Este ejemplo es para una conexión Ethernet.

1.  **Identificar el nombre de la conexión activa:**
    ```bash
    nmcli connection show
    ```
    Busca el nombre de tu conexión Ethernet activa (por ejemplo, `Wired connection 1` o el nombre de tu red Wi-Fi si lo haces para Wi-Fi).
2.  **Modificar la conexión para usar una IP estática:**
    Reemplaza `MiConexionEthernet` con el nombre real de tu conexión obtenido en el paso anterior.
    Reemplaza `192.168.1.XX` con una dirección IP que esté libre dentro de tu rango de red local y que quieras asignar a la Raspberry Pi.
    Reemplaza `192.168.1.1` con la dirección IP de tu router (gateway).
    Ajusta los servidores DNS si es necesario (ej. `8.8.8.8` es Google DNS, `1.1.1.1` es Cloudflare DNS).

    ```bash
    sudo nmcli connection modify MiConexionEthernet \
        ipv4.method manual \
        ipv4.addresses 192.168.1.XX/24 \
        ipv4.gateway 192.168.1.1 \
        ipv4.dns "8.8.8.8,1.1.1.1"
    ```
    El `/24` después de la dirección IP es la máscara de subred en notación CIDR (equivalente a 255.255.255.0).
3.  **Reactivar la conexión para aplicar los cambios:**
    ```bash
    sudo nmcli connection down MiConexionEthernet
    sudo nmcli connection up MiConexionEthernet
    ```
    O, a veces, un simple `sudo nmcli connection up MiConexionEthernet` es suficiente si la conexión ya estaba activa y solo se modificó. También puedes reiniciar la red con `sudo systemctl restart NetworkManager` o reiniciar la Raspberry Pi.

**Nota:** La configuración de la dirección IP para la interfaz de red que actuará como hotspot (por ejemplo, `uap0` que crearemos más adelante) será diferente y se gestionará directamente en la configuración del software del hotspot.

**Nota Adicional para el Hotspot:** La configuración de la interfaz `wlan0` para el hotspot (con IP estática `192.168.73.1/24`) se detalla en la página `[[06-Configurar-Hotspot]]`. El método allí descrito (usando `systemd-networkd` o configuración manual de IP) es independiente de la gestión de NetworkManager para las interfaces cliente de la Raspberry Pi (como `eth0` o `wlan0` si se usa para conectarse a otra red Wi-Fi).

## Verificar Configuración de Red
Después de cualquier cambio, es bueno verificar que todo funcione como se espera. Aquí algunos comandos útiles:

*   **Mostrar todas las direcciones IP de todas las interfaces:**
    ```bash
    ip addr
    ```
*   **Probar la conectividad a Internet:**
    ```bash
    ping -c 4 google.com
    ```
*   **Ver el estado de los dispositivos de red gestionados por NetworkManager:**
    ```bash
    nmcli device status
    ```
*   **Ver todas las conexiones configuradas en NetworkManager y su estado:**
    ```bash
    nmcli connection show
    ```

Con estos pasos, tu Raspberry Pi 5 debería tener una configuración de red funcional y, opcionalmente, una IP estática para facilitar los siguientes pasos del proyecto.
