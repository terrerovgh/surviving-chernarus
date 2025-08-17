# Plan de Implementación: Fase 4 - Activación del Perímetro Defensivo

**Nombre Clave de la Fase:** `Estableciendo el Perímetro Defensivo (Defensive Perimeter Activation)`
**Operador IA:** `Stalker`
**Objetivo:** Transformar la Raspberry Pi en un punto de acceso Wi-Fi seguro (SSID `rpi`). Todo el tráfico de esta red utilizará `StarySobor_RadioPost` (Pi-hole) para el filtrado de DNS. Al finalizar esta fase, el sistema operará como un "búnker de red" portátil y controlado con filtrado a nivel de DNS.

---

### Prerrequisitos

-   Haber completado exitosamente la **Fase 3: Control de la Red**.
-   Tener `hostapd` y `dnsmasq` instalados en el sistema anfitrión para la creación del Hotspot.
-   Disponibilidad de dos interfaces de red en la Raspberry Pi (ej. `wlan0` para el Hotspot y `eth0` para la conexión a internet).

---

### Paso 1: Configuración del Hotspot Wi-Fi

**Justificación:** Crear una red Wi-Fi local y aislada (`rpi`) desde la cual se gestionará y filtrará todo el tráfico de los dispositivos cliente que se conecten.

**Acciones:**
1.  **Instalar Software Necesario:**
    -   Asegurar que `hostapd` y `dnsmasq` están instalados en el host: `sudo pacman -S hostapd dnsmasq`.
2.  **Configurar la Interfaz de Red Inalámbrica:**
    -   Asignar una IP estática a la interfaz `wlan0` (ej. `192.168.4.1`).
3.  **Configurar `hostapd`:**
    -   Crear el archivo de configuración `/etc/hostapd/hostapd.conf`.
    -   Definir el nombre de la red (SSID `rpi`), el canal, el modo y la seguridad (WPA2).
4.  **Configurar `dnsmasq`:**
    -   Crear el archivo de configuración `/etc/dnsmasq.conf`.
    -   Definir el rango de IPs a asignar por DHCP (ej. `192.168.4.10` a `192.168.4.50`).
    -   Establecer la puerta de enlace (`192.168.4.1`).
    -   **Importante:** Configurar `dnsmasq` para que anuncie el servidor DNS de `StarySobor_RadioPost` (Pi-hole) a los clientes.
5.  **Habilitar y Probar el Hotspot:**
    -   Iniciar y habilitar los servicios `hostapd` y `dnsmasq`.
    -   Conectar un dispositivo cliente a la red Wi-Fi `rpi` y verificar que recibe una IP y tiene acceso a la red local.

---

### Paso 2: Habilitar Enrutamiento

**Justificación:** Permitir que los dispositivos conectados al Hotspot accedan a internet a través de la conexión principal de la Raspberry Pi.

**Acciones:**
1.  **Habilitar IP Forwarding:**
    -   Activar el reenvío de paquetes en el kernel: `sysctl -w net.ipv4.ip_forward=1` y hacerlo persistente.
2.  **Crear Regla de `iptables` para NAT:**
    -   En la tabla `nat`, añadir una regla `POSTROUTING` para enmascarar el tráfico saliente de la red del Hotspot a través de la interfaz `eth0` (salida a internet).
3.  **Guardar y Cargar Reglas:**
    -   Utilizar `iptables-save` para guardar las reglas y `iptables-restore` para cargarlas al inicio del sistema.

---

**Conclusión de la Fase 4:**
Al completar esta fase, "Surviving Chernarus" se convierte en una fortaleza de red activa. Cualquier dispositivo que se conecte a su Wi-Fi estará automáticamente protegido por el filtrado de DNS de Pi-hole, cumpliendo el objetivo de tener un control centralizado del DNS en el entorno de red personal.

---

### Actualización del Tablero Kanban

*   **Mover a `Done`:**
    *   `Fase 4: Configurar Hotspot Wi-Fi (hostapd, dnsmasq)`
    *   `Fase 4: Habilitar Enrutamiento y NAT`