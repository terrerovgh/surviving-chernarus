# 10. Arranque de Servicios y Pruebas

## Introducción
Esta sección describe cómo iniciar todos los servicios del proyecto "Escrowed Kathy" utilizando el archivo `docker-compose.yml` centralizado y cómo realizar pruebas básicas para asegurar que los componentes principales funcionan correctamente.

## Navegación al Directorio del Proyecto
Todas las operaciones de Docker Compose deben ejecutarse desde el directorio raíz del proyecto.
```bash
cd ~/projects/escrowed-kathy # Ajusta la ruta si es necesario
```

## Arranque de Todos los Servicios
Para iniciar todos los servicios definidos en el archivo `docker-compose.yml` (Captive Portal, Squid Proxy, Pi-hole, DHCP Server, etc.) en segundo plano, ejecuta:
```bash
sudo docker compose up -d
```
Si es la primera vez o si has realizado cambios que requieren reconstruir las imágenes (como modificar un Dockerfile o archivos copiados en una imagen), puedes añadir la opción `--build`:
```bash
sudo docker compose up -d --build
```

## Verificación del Estado de los Contenedores
Para ver todos los contenedores en ejecución y su estado:
```bash
sudo docker compose ps
```
Deberías ver servicios como `chernarus_entrypoint`, `berezino_checkpoint`, `pihole`, `dhcp_server`, `dashboard_placeholder`, y `logging_placeholder` en estado "running" o "up".

## Pruebas de Funcionamiento por Componente

### 1. Servidor DHCP (`dhcp_server`)
*   **Configuración Previa:** Asegúrate de que `hotspot_config/dhcp/dhcpd.conf` está correctamente configurado para tu interfaz Wi-Fi (e.g., `wlan0`) y el rango de IPs deseado. El comando en `docker-compose.yml` para `dhcp_server` también debe especificar la interfaz correcta.
*   **Prueba:** Conecta un dispositivo cliente a la red Wi-Fi del hotspot (`Chernarus_Beacon`).
*   **Verificación:** El dispositivo debería obtener una dirección IP dentro del rango especificado en `dhcpd.conf`. Verifica la configuración de red en el cliente.
*   **Logs:** `sudo docker compose logs dhcp_server`

### 2. Pi-hole DNS (`pihole`)
*   **Acceso a la Interfaz Web:** Abre un navegador en un dispositivo conectado a la red del Raspberry Pi (puede ser el mismo RPi si tiene entorno gráfico, o un PC en la misma red que el RPi, accediendo por la IP del RPi en `eth0` o la IP que tenga en la red local, no la del hotspot). Navega a `http://<IP_DEL_RPI>:8081/admin/`. Reemplaza `<IP_DEL_RPI>` con la dirección IP de tu Raspberry Pi en la red donde tienes acceso (no la IP del hotspot `192.168.73.1` directamente, a menos que estés accediendo desde un cliente ya conectado al hotspot y con DNS funcionando).
*   **Contraseña:** La contraseña por defecto es la que se encuentra en la variable `WEBPASSWORD` en `docker-compose.yml` (recuerda cambiarla).
*   **Funcionalidad DNS:** Los clientes conectados al hotspot deberían usar Pi-hole para la resolución DNS (esto se configura en el `dhcpd.conf` del `dhcp_server`, que debe entregar la IP del contenedor Pi-hole como servidor DNS, o la IP del host RPi si el puerto 53 está mapeado directamente). Intenta navegar a algunos sitios web. Verifica las consultas en el Query Log de Pi-hole.
*   **Deshabilitar DHCP de Pi-hole:** Si estás usando el contenedor `dhcp_server` dedicado, asegúrate de que la función de servidor DHCP de Pi-hole esté deshabilitada (Settings -> DHCP -> Desmarcar "DHCP server enabled").
*   **Logs:** `sudo docker compose logs pihole`

### 3. Portal Cautivo (`chernarus_entrypoint`)
*   **Redirección:** Con un cliente recién conectado al Wi-Fi, intenta acceder a un sitio web HTTP (por ejemplo, `http://neverssl.com`). Deberías ser redirigido a la página del portal cautivo.
*   **Acceso Directo (si la redirección falla o para prueba aislada):** La página del portal es servida en el puerto `8080` del host Raspberry Pi. Puedes intentar accederla directamente desde el RPi o un cliente en la red del hotspot: `http://192.168.73.1:8080` (asumiendo que `192.168.73.1` es la IP del RPi en la interfaz `wlan0`).
*   **Descarga del Certificado:** Verifica que el enlace para descargar el certificado CA en la página del portal funcione y que el archivo correcto (`myCA.pem` o `.crt`) se descargue.
*   **Logs:** `sudo docker compose logs chernarus_entrypoint`

### 4. Squid Proxy (`berezino_checkpoint`)
*   **Configuración Previa:** Asegúrate de haber generado e instalado tu certificado CA (`myCA.pem`) en `squid_Berezino_Checkpoint/certs/` y una copia para descarga en `captive_portal_Chernarus_Entrypoint/html/`.
*   **Instalación del Certificado en Cliente:** Después de descargar el certificado CA desde el portal, instálalo y confía en él en el dispositivo cliente.
*   **Prueba de Navegación HTTPS:** Intenta navegar a sitios HTTPS. Si Squid está funcionando y el certificado CA está correctamente instalado y confiado en el cliente, la navegación debería ser transparente sin errores de certificado.
*   **Verificación en Logs de Squid:** Revisa los logs de acceso de Squid para ver el tráfico que pasa a través de él.
    ```bash
    sudo docker compose exec berezino_checkpoint tail -f /var/log/squid/access.log
    ```
    (Presiona `Ctrl+C` para detener)
*   **Logs del Contenedor:** `sudo docker compose logs berezino_checkpoint`

### 5. Placeholders (`dashboard_placeholder`, `logging_placeholder`)
*   **Dashboard:** El placeholder de Nginx debería estar accesible en el puerto `8082` del host Raspberry Pi: `http://<IP_DEL_RPI>:8082`. Mostrará la página de bienvenida de Nginx.
*   **Logging:** Este servicio no tiene una funcionalidad visible por defecto, solo se mantiene en ejecución. `sudo docker compose logs logging_placeholder`

## Detener Servicios
Para detener todos los servicios:
```bash
sudo docker compose down
```
Para detener y eliminar volúmenes anónimos (no los volúmenes nombrados como los de Pi-hole, ni los datos en rutas de host como los de Squid en `/mnt/usbdata`):
```bash
sudo docker compose down -v
```

Esta guía de arranque y pruebas debería ayudarte a verificar la configuración inicial de "Operación: The Perimeter".
