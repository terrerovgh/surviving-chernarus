# Plan de Pruebas y Verificación del Sistema

Este documento describe el plan de pruebas conceptual para el sistema "Operación: The Perimeter". Cada fase de prueba asume que las fases anteriores han sido completadas y verificadas exitosamente.

## I. Entorno de Pruebas

*   **Hardware:** Raspberry Pi 5 con adaptador Wi-Fi funcional (para `wlan0`), conectado a internet a través de `eth0` (o interfaz WAN configurada).
*   **Software:** Raspberry Pi OS (actualizado), Pi-hole (instalado en el host), Docker, Docker Compose, Python 3, `requests` (Python), `nftables`, `hostapd`, `curl`, `jq`.
*   **Cliente de Pruebas:** Un dispositivo con Wi-Fi (laptop, smartphone) para conectarse al hotspot.
*   **Configuraciones del Proyecto:** Clonadas desde el repositorio (`/opt/surviving-chernarus`), con los scripts y archivos de configuración relevantes aplicados.

## II. Prerrequisitos Generales para las Pruebas

1.  **Raspberry Pi Configurado:** IP estática en `eth0` (si aplica) y `wlan0` (`192.168.73.1`).
2.  **Pi-hole (Host) Instalado y Funcionando:** Pi-hole instalado en el sistema operativo base del Raspberry Pi y funcionando como resolvedor DNS para el propio Pi y la red del hotspot. La configuración de DHCP para `wlan0` y el DNS personalizado para `*.terrerov.com` están aplicados (`/etc/dnsmasq.d/02-chernarus-hotspot-dhcp.conf`, `/etc/dnsmasq.d/03-terrerov-domain.conf`).
3.  **Servicios Base Activos:** `hostapd` configurado y activo. Docker service activo.
4.  **Variables de Entorno Configuradas:** El archivo `.env` en la raíz del proyecto (`/opt/surviving-chernarus/.env`) está creado a partir de `.env.example` y contiene los valores correctos para `PIHOLE_WEBPASSWORD`, `TZ`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_NAME`, y `CLOUDFLARE_RECORD_NAME`.
5.  **Scripts `nftables` Aplicados:** Los scripts de `nftables` (`/opt/surviving-chernarus/scripts/setup_hotspot_nat_nft.sh`, `/opt/surviving-chernarus/scripts/setup_captive_portal_redirect_nft.sh`, `/opt/surviving-chernarus/scripts/redirect_to_squid_nft.sh`) han sido ejecutados en el orden correcto.
6.  **Reglas `nftables` Persistentes:** El conjunto de reglas de `nftables` ha sido guardado en `/etc/nftables.conf` y el servicio `nftables` está habilitado para cargar las reglas al arranque (`sudo systemctl enable nftables.service`).
7.  **Contenedores Docker en Ejecución:** Los contenedores Docker para `chernarus_entrypoint` (Nginx portal), `berezino_checkpoint` (Squid), y `pihole` (Pi-hole Dockerizado, si se mantiene para pruebas de `.env`) están en ejecución.
8.  **Certificado CA Generado y Distribuido:** El certificado CA (`myCA.pem`) ha sido generado y colocado en `squid_Berezino_Checkpoint/certs/`. Una copia del certificado público (`myCA.crt` o el mismo `.pem` si es solo el cert público) está en `captive_portal_Chernarus_Entrypoint/html/` y el enlace en `index.html` es correcto.

## III. Casos de Prueba Detallados

---
**Test Case 1: Conexión al Hotspot Wi-Fi (`Chernarus_Beacon`)**
*   **Pasos:**
    1.  En el dispositivo cliente, buscar redes Wi-Fi.
    2.  Conectarse al SSID `rpi` (o el configurado en `hostapd.conf`) usando la contraseña definida.
*   **Resultados Esperados:**
    1.  El cliente se conecta exitosamente a la red Wi-Fi.
    2.  El cliente recibe una dirección IP del rango `192.168.73.10` - `192.168.73.200`.
    3.  El cliente recibe `192.168.73.1` como la dirección del gateway y del servidor DNS.

---
**Test Case 2: Funcionalidad Básica de Red (NAT y DNS del Host)**
*   **Pasos:**
    1.  Con un cliente conectado al hotspot, intentar hacer ping a una IP externa (ej. `8.8.8.8`).
    2.  Intentar resolver un dominio público (ej. `ping google.com`).
*   **Resultados Esperados:**
    1.  El ping a `8.8.8.8` es exitoso (NAT funciona).
    2.  `google.com` se resuelve y el ping es exitoso (DNS del host y NAT funcionan).

---
**Test Case 3: Verificación de Reglas `nftables`**
*   **Pasos:**
    1.  En la Raspberry Pi, ejecutar `sudo nft list ruleset`.
*   **Resultados Esperados:**
    1.  El output refleja las reglas intencionadas por `setup_hotspot_nat_nft.sh`, `setup_captive_portal_redirect_nft.sh`, y `redirect_to_squid_nft.sh`.
    2.  **Tablas y Cadenas:** Existencia de tablas (ej. `firewall_table`, `nat_table`) y cadenas (`input`, `forward`, `prerouting`, `postrouting`) con sus políticas base correctas.
    3.  **Reglas de Input (firewall_table):**
        *   Aceptar tráfico en `lo`.
        *   Aceptar `ct state established,related`.
        *   Aceptar DHCP (udp dport 67) en `WLAN_IF` (variable del script, ej. `wlan0`).
        *   Aceptar DNS (udp/tcp dport 53) en `WLAN_IF`.
        *   Aceptar TCP al puerto del portal (ej. 8080) en `RPI_WLAN_IP` (variable del script, ej. `192.168.73.1`) desde `WLAN_IF`.
        *   Aceptar TCP a los puertos de Squid (ej. 3128, 3129) en `127.0.0.1` desde `WLAN_IF`.
    4.  **Reglas de Forward (firewall_table):**
        *   Aceptar tráfico de `WLAN_IF` a `ETH_IF` (variables del script).
        *   Aceptar `ct state established,related` de `ETH_IF` a `WLAN_IF`.
    5.  **Reglas de NAT Prerouting (nat_table):**
        *   DNAT para redirección HTTP al portal (ej. `iifname "wlan0" tcp dport 80 dnat to 192.168.73.1:8080`) con alta precedencia (insertado al principio).
        *   Reglas `return` para bypass de servicios locales en `RPI_WLAN_IP` (DNS, DHCP, Portal) antes de las reglas de Squid.
        *   DNAT para redirección HTTP a Squid (ej. `iifname "wlan0" ip daddr != 192.168.73.1 tcp dport 80 dnat to 127.0.0.1:3128`).
        *   DNAT para redirección HTTPS a Squid (ej. `iifname "wlan0" ip daddr != 192.168.73.1 tcp dport 443 dnat to 127.0.0.1:3129`).
    6.  **Reglas de NAT Postrouting (nat_table):**
        *   Regla de `masquerade` para el tráfico saliente de `HOTSPOT_NET` (variable del script, ej. `192.168.73.0/24`) por `ETH_IF`.

---
**Test Case 4: Redirección al Portal Cautivo (`Chernarus_Entrypoint`)**
*   **Pasos:**
    1.  Con un cliente nuevo, intentar acceder a un sitio web **HTTP** (ej. `http://neverssl.com`).
*   **Resultados Esperados:**
    1.  Redirección al portal cautivo (`http://192.168.73.1:8080`).
    2.  Página del portal visible con enlace de descarga del certificado.

---
**Test Case 5: Descarga e Instalación del Certificado CA**
*   **Pasos:**
    1.  Desde el portal, descargar el certificado CA.
    2.  Instalar y confiar en el certificado en el cliente.
*   **Resultados Esperados:**
    1.  Descarga correcta.
    2.  Instalación y confianza sin errores.

---
**Test Case 6: Proxy Transparente Squid (`Berezino_Checkpoint`) para HTTPS**
*   **Pasos:**
    1.  Con cliente con CA confiable, acceder a un sitio **HTTPS** (ej. `https://google.com`).
    2.  Verificar certificado del sitio en el navegador.
    3.  Monitorear logs de Squid (`sudo docker logs -f Berezino_Checkpoint`).
*   **Resultados Esperados:**
    1.  Sitio HTTPS carga sin advertencias.
    2.  Emisor del certificado es "BerezinoCheckpointCA".
    3.  Logs de Squid muestran "bump" para conexiones HTTPS.

---
**Test Case 7: Resolución DNS vía Pi-hole del Host y Dominio Personalizado (`*.terrerov.com`)**
*   **Pasos:**
    1.  En el cliente, realizar consultas DNS para dominios públicos (ej. `google.com`).
    2.  Verificar logs de consulta en la interfaz web del Pi-hole del **host**.
    3.  Intentar resolver `test.terrerov.com` y `another.terrerov.com` (usando `ping`, `nslookup`, `dig`).
*   **Resultados Esperados:**
    1.  Dominios públicos se resuelven.
    2.  Consultas DNS aparecen en logs del Pi-hole del host.
    3.  `test.terrerov.com` y `another.terrerov.com` resuelven a `192.168.73.1`.

---
**Test Case 8: Verificación Script DDNS de Cloudflare**
*   **Pasos:**
    1.  Verificar que `.env` tiene `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_NAME`, `CLOUDFLARE_RECORD_NAME`.
    2.  Ejecutar manualmente: `source /opt/surviving-chernarus/.env && python3 /opt/surviving-chernarus/scripts/cloudflare_ddns.py`.
    3.  Observar salida del script.
    4.  Verificar registro DNS 'A' en el panel de Cloudflare.
    5.  (Opcional avanzado) Simular cambio de IP pública y re-ejecutar.
    6.  Verificar configuración del cron job (ej. `sudo crontab -l`).
*   **Resultados Esperados:**
    1.  Script informa éxito o IP sin cambios.
    2.  Registro DNS 'A' en Cloudflare coincide con IP pública del RPi.
    3.  (Opcional) Registro se actualiza tras cambio simulado de IP.
    4.  Cron job configurado según documentación.

---
**Test Case 9: Verificación de Configuración Centralizada (`.env`)**
*   **Pasos:**
    1.  Modificar `PIHOLE_WEBPASSWORD` en `.env`.
    2.  Reiniciar contenedor Pi-hole Dockerizado (si se usa para este test): `cd /opt/surviving-chernarus && sudo docker-compose restart pihole` (asumiendo `pihole` es el nombre del servicio en un docker-compose unificado o el específico del Pi-hole Dockerizado).
    3.  Probar login en interfaz web del Pi-hole **Dockerizado** (`http://192.168.73.1:8081/admin/`, si el puerto está mapeado) con nueva contraseña.
    4.  (Conceptual) Cambiar `CLOUDFLARE_RECORD_NAME` en `.env`. Ejecutar DDNS y verificar que opera sobre el nuevo registro.
*   **Resultados Esperados:**
    1.  Login en Pi-hole Dockerizado funciona con nueva contraseña.
    2.  Script DDNS usa nuevos valores de `.env`.

---
## IV. Pruebas de Estrés y Larga Duración (Conceptuales)

*   **Conexión de Múltiples Clientes:** Conectar varios dispositivos, verificar estabilidad y rendimiento.
*   **Uso Continuado:** Dejar sistema funcionando 24-48h con tráfico normal, verificar estabilidad, logs.
*   **Reinicios:** Verificar que servicios y reglas `nftables` se restauran tras reinicio del RPi.

Este plan de pruebas cubre las funcionalidades clave. Ajustes pueden ser necesarios.
