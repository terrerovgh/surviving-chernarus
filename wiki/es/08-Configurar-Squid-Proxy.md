# Configuración del Proxy Squid

## Introducción
Squid es un popular servidor proxy de almacenamiento en caché para la web que soporta HTTP, HTTPS, FTP, y más. En este proyecto (denominado `berezino_checkpoint` en la configuración), Squid se utiliza para filtrar el tráfico de los usuarios conectados al hotspot, permitiendo un control más granular sobre el acceso a Internet, realizar caché de contenido para mejorar la velocidad de navegación en accesos repetidos, y para inspeccionar el tráfico SSL/TLS (SSL Bumping).

El proxy Squid se ejecuta como un servicio Docker y está gestionado como parte del archivo principal `docker-compose.yml` ubicado en el directorio raíz del proyecto. Esto centraliza la gestión de todos los servicios Docker.

## Acceder a los Archivos de Configuración de Squid
Los archivos de configuración específicos para Squid, como `squid.conf` y los certificados SSL/TLS, se encuentran en el subdirectorio `squid_Berezino_Checkpoint/`.

Para editar estos archivos:
1.  Abre una terminal en tu Raspberry Pi.
2.  Navega al directorio `squid_Berezino_Checkpoint/` dentro de tu repositorio clonado:
    ```bash
    # Ejemplo, si clonaste el proyecto en ~/projects/surviving-chernarus
    cd ~/projects/surviving-chernarus/squid_Berezino_Checkpoint/
    ```
    Desde aquí puedes editar `squid.conf` o gestionar los archivos en el subdirectorio `certs/`.
    **Nota:** Los comandos `docker-compose` para iniciar o detener el servicio Squid se ejecutan desde el **directorio raíz del proyecto**, no desde este subdirectorio.

## Revisar la Definición del Servicio en Docker Compose
El servicio del proxy Squid, llamado `berezino_checkpoint`, está definido en el archivo `docker-compose.yml` principal, que se encuentra en el **directorio raíz del proyecto**. No hay un `docker-compose.yml` separado solo para Squid dentro de `squid_Berezino_Checkpoint/`.

Puedes revisar la definición de este servicio abriendo el `docker-compose.yml` principal con un editor de texto. Busca la sección `services.berezino_checkpoint`.

**Puntos Clave de la Configuración del Servicio `berezino_checkpoint`:**

*   **Imagen:** Utiliza la imagen estándar `ubuntu/squid`.
    ```yaml
    image: ubuntu/squid
    ```
*   **Puertos Expuestos:** La configuración de puertos en el `docker-compose.yml` principal es:
    ```yaml
    ports:
      - "192.168.73.1:3128:3128"
      - "192.168.73.1:3129:3129"
    ```
    *   Esto significa que el puerto `3128` del contenedor Squid (puerto HTTP estándar de Squid) se mapea al puerto `3128` de la dirección IP `192.168.73.1` en la Raspberry Pi.
    *   Similarmente, el puerto `3129` del contenedor (configurado en `squid.conf` para intercepción SSL/HTTPS) se mapea al puerto `3129` de `192.168.73.1`.
    *   `192.168.73.1` es la dirección IP de la Raspberry Pi en la interfaz del hotspot (`wlan0`).
    *   Los clientes serán redirigidos a estos puertos mediante `iptables` (ver `[[09-Configurar-Redireccion-Trafico]]`).
*   **Volúmenes Montados:** Es crucial observar los volúmenes montados, definidos relativos a la raíz del proyecto:
    *   `./squid_Berezino_Checkpoint/squid.conf:/etc/squid/squid.conf`: Mapea el archivo local `squid_Berezino_Checkpoint/squid.conf` al archivo de configuración dentro del contenedor.
    *   `./squid_Berezino_Checkpoint/certs:/etc/squid/certs`: Mapea el directorio local `squid_Berezino_Checkpoint/certs/` para los certificados SSL/TLS.
    *   `/mnt/usbdata/Berezino_Checkpoint/cache:/var/spool/squid`: Mapea un directorio en una unidad USB (recomendado) para la caché de Squid. Asegúrate de que este directorio exista en la Raspberry Pi o ajusta la ruta.
    *   `/mnt/usbdata/Berezino_Checkpoint/logs:/var/log/squid`: Mapea un directorio en una unidad USB para los logs de Squid. Asegúrate de que este directorio exista o ajusta la ruta.
*   **Capacidades (`cap_add`):**
    *   `NET_ADMIN`: Se añade esta capacidad para permitir a Squid realizar operaciones de red avanzadas, a menudo necesarias para la intercepción transparente de tráfico.

## Revisar y Personalizar la Configuración de Squid (`squid.conf`)
El comportamiento de Squid se controla principalmente a través del archivo `squid_Berezino_Checkpoint/squid.conf` (ubicado dentro del subdirectorio `squid_Berezino_Checkpoint/` del proyecto). Este es el archivo que se monta en el contenedor.

1.  **Editar `squid_Berezino_Checkpoint/squid.conf`:**
    Navega al directorio `squid_Berezino_Checkpoint/` (como se describe en "Acceder a los Archivos de Configuración de Squid") y abre `squid.conf` con un editor de texto:
    ```bash
    # Estando en ~/projects/surviving-chernarus/squid_Berezino_Checkpoint/
    nano squid.conf
    ```
2.  **Parámetros Comunes a Revisar (la plantilla proporcionada ya incluye muchos de estos):**
    *   `http_port 192.168.73.1:3128`: Define el puerto y la modalidad en la que Squid escucha para HTTP. El archivo de configuración proporcionado en el proyecto ya especifica la IP del host y el puerto.
    *   `http_port 192.168.73.1:3129 intercept`: Para la intercepción transparente de HTTP.
    *   `https_port 192.168.73.1:3130 intercept ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=/etc/squid/certs/myCA.pem key=/etc/squid/certs/myCA.key`: Configuración para la intercepción HTTPS y SSL Bumping. (Asegúrate que los nombres `myCA.pem` y `myCA.key` coincidan con los archivos que generaste y colocaste en `squid_Berezino_Checkpoint/certs/`).
    *   `acl localnet src 192.168.73.0/24`: Define la red local del hotspot.
    *   `http_access allow localnet`: Permite el acceso desde la red local.
    *   `cache_dir ufs /var/spool/squid 100 16 256`: Define el directorio de caché.
    *   `ssl_bump peek all`, `ssl_bump bump all`: Directivas para controlar el proceso de SSL Bumping.
    *   `sslcrtd_program /usr/lib/squid/security_file_certgen -s /var/lib/squid/ssl_db -M 4MB`: Programa para generar certificados dinámicamente. Verifica la ruta si usas una imagen de Squid diferente, pero para `ubuntu/squid` suele ser esta.
    *   `dns_nameservers 192.168.73.1`: Configura Squid para usar Pi-hole como su resolutor DNS.

3.  **Inspección HTTPS (SSL Bumping):**
    *   El proyecto está configurado para la inspección de tráfico SSL/TLS. Esto permite a Squid desencriptar, inspeccionar y potencialmente filtrar o modificar tráfico HTTPS.
    *   **Consulta `squid_Berezino_Checkpoint/README_SQUID.md`:** Este archivo es **fundamental** y contiene detalles cruciales sobre la configuración específica de SSL Bumping, incluyendo cómo generar o manejar los certificados CA necesarios (`myCA.pem`, `myCA.key`), cómo configurar los permisos de estos archivos y la política de rotación de certificados.
    *   **Importancia de los Certificados en `squid_Berezino_Checkpoint/certs/`:** Para que la inspección SSL funcione, Squid necesita actuar como una Autoridad Certificadora (CA) intermedia. Los certificados y la clave privada de esta CA se almacenan en el directorio `squid_Berezino_Checkpoint/certs/`.
    *   **Advertencia sobre Inspección HTTPS:** La inspección SSL/TLS implica que Squid "rompe" la encriptación extremo a extremo. Para que esto funcione sin errores de certificado en los navegadores de los clientes, el certificado público de la CA de Squid (e.g., `myCA.pem` o `myCA.crt`) debe ser importado y confiado por cada dispositivo cliente que utilice el proxy. Esto tiene implicaciones de seguridad y privacidad que deben ser consideradas. El portal cautivo (`Chernarus_Entrypoint`) está diseñado para facilitar la distribución de este certificado a los clientes.

## Manejo de Certificados (para Inspección SSL/TLS)
Como se mencionó, la inspección SSL/TLS requiere una gestión adecuada de los certificados. El archivo `squid_Berezino_Checkpoint/README_SQUID.md` proporciona la guía más detallada y actualizada sobre este tema específico.

1.  **Directorio `squid_Berezino_Checkpoint/certs/`:**
    Este es el directorio donde debes colocar tus archivos de certificado CA (e.g., `myCA.pem` para el certificado público y `myCA.key` para la clave privada). El archivo `.gitkeep` en el repositorio asegura que la estructura del directorio exista; debes reemplazarlo o añadir tus archivos aquí.
2.  **Generación/Obtención de Certificados:**
    *   **Sigue las instrucciones detalladas en `squid_Berezino_Checkpoint/README_SQUID.md`** para generar tu propia Autoridad Certificadora (CA) y el certificado y clave correspondientes que Squid usará. Típicamente, esto involucra el uso de herramientas como OpenSSL. Este README específico cubre la creación de `myCA.pem` (que contiene el certificado público) y `myCA.key` (la clave privada), así como la generación opcional de un archivo `.der` para distribución a clientes.
    *   El certificado público de tu CA (e.g., `myCA.pem` o una versión `.crt` o `.der` del mismo) deberá ser distribuido e instalado en los dispositivos cliente para evitar advertencias de seguridad. El portal cautivo (`Chernarus_Entrypoint`) está diseñado para ayudar con esta distribución.
3.  **Permisos y Seguridad de los Certificados:**
    El archivo `squid_Berezino_Checkpoint/README_SQUID.md` también cubre aspectos importantes sobre la seguridad de estos archivos, especialmente la clave privada (`myCA.key`), y las recomendaciones de permisos de archivo.

## Iniciar el Servicio de Squid Proxy
El servicio `berezino_checkpoint` (Squid) se gestiona mediante el archivo `docker-compose.yml` principal ubicado en el directorio raíz del proyecto.

**Importante:** Todos los comandos `docker-compose` deben ejecutarse desde el **directorio raíz de tu repositorio clonado** (e.g., `~/projects/surviving-chernarus`), no desde el subdirectorio `squid_Berezino_Checkpoint/`.

1.  **Iniciar todos los servicios del proyecto (Recomendado):**
    La forma más sencilla de asegurar que todas las dependencias y servicios relacionados se inicien correctamente es ejecutar:
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker-compose up -d
    ```
    Esto iniciará el proxy Squid (`berezino_checkpoint`) junto con Pi-hole, el portal cautivo, el servidor DHCP y cualquier otro servicio definido en el `docker-compose.yml` principal. La imagen `ubuntu/squid` se descargará si aún no está presente localmente. No es necesario un paso de `build` separado ya que se utiliza una imagen preconstruida.

2.  **Iniciar solo el servicio de Squid (Opcional):**
    Si deseas iniciar o reiniciar específicamente el servicio de Squid (y ya tienes otros servicios necesarios como las redes Docker creadas por una ejecución previa de `docker-compose up`), puedes hacerlo con:
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker-compose up -d berezino_checkpoint
    ```

## Verificar que Squid está Funcionando
Después de iniciar el servicio `berezino_checkpoint` (preferiblemente con `sudo docker-compose up -d` desde la raíz del proyecto), verifica que esté operando correctamente.

1.  **Ver los contenedores Docker en ejecución:**
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker ps
    ```
    Deberías ver el contenedor `Berezino_Checkpoint` (o el nombre que le asigne Docker Compose basado en el nombre del directorio del proyecto y el nombre del servicio) en la lista, con el estado "Up".

2.  **Ver los logs del contenedor de Squid:**
    Si necesitas solucionar problemas o ver la actividad de Squid:
    ```bash
    # Desde el directorio raíz del proyecto
    sudo docker-compose logs -f berezino_checkpoint
    ```
    Revisa los logs de inicio para cualquier error en `squid.conf` o problemas con los certificados. Los logs de acceso (`access.log`) y caché (`cache.log`) de Squid se encuentran en el volumen mapeado a `/var/log/squid` (e.g., `/mnt/usbdata/Berezino_Checkpoint/logs/`), pero los errores críticos de inicio suelen aparecer en los logs de Docker.

3.  **Prueba de Conexión (Manual):**
    En este punto, el tráfico de los clientes del hotspot aún no se redirige automáticamente a Squid. Para probar Squid directamente, necesitarías configurar manualmente un dispositivo cliente (que esté conectado al hotspot Wi-Fi `rpi`):
    *   En la configuración de red del cliente, establece el proxy HTTP y HTTPS a `192.168.73.1` en el puerto `3128`.
    *   Intenta navegar. Deberías ver actividad en los logs de Squid (`access.log`).
    *   Si has configurado la inspección SSL y has instalado el certificado CA de Squid en el cliente, el tráfico HTTPS también debería funcionar.
    Esta prueba manual es solo para verificar que Squid está funcional antes de configurar la redirección transparente con `iptables`. No olvides deshacer la configuración manual del proxy en el cliente después de la prueba.

## Redirección de Tráfico a Squid
El paso final y crucial para integrar Squid completamente en el flujo de tráfico del hotspot es configurar las reglas de `iptables` que redirigirán automáticamente el tráfico web de los clientes al proxy Squid. Esta configuración se detalla en el script `scripts/redirect_to_squid.sh` y se explica en profundidad en la página `[[09-Configurar-Redireccion-Trafico]]`. Es fundamental aplicar estas reglas después de que Squid esté funcionando para activar la intercepción transparente del tráfico.
