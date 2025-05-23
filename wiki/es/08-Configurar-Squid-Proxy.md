# Configuración del Proxy Squid

## Introducción
Squid es un popular servidor proxy de almacenamiento en caché para la web que soporta HTTP, HTTPS, FTP, y más. En el proyecto Escrowed Kathy, Squid se utiliza para filtrar el tráfico de los usuarios conectados al hotspot, permitiendo un control más granular sobre el acceso a Internet, realizar caché de contenido para mejorar la velocidad de navegación en accesos repetidos, y potencialmente para inspeccionar el tráfico SSL/TLS.

Al igual que el portal cautivo, Squid se ejecutará como un servicio Docker, utilizando la configuración y los archivos proporcionados en el repositorio del proyecto, **definido ahora en el archivo `docker-compose.yml` principal del proyecto.**

## Navegar al Directorio del Proxy Squid
Para trabajar con los archivos de configuración de Squid, primero debes navegar al **directorio raíz del proyecto clonado.**

1.  Abre una terminal en tu Raspberry Pi.
2.  Cambia al directorio `squid_Berezino_Checkpoint`. Si clonaste el proyecto en `~/projects/escrowed-kathy`, el comando sería:
    ```bash
    cd ~/projects/escrowed-kathy
    ```
    Ajusta la `ruta_al_repo` si tu proyecto está en una ubicación diferente.

## Revisar la Configuración en el `docker-compose.yml` Principal
El archivo `docker-compose.yml` **en la raíz del proyecto** define cómo se construye y ejecuta el servicio de Squid (`berezino_checkpoint`).

1.  Busca la definición del servicio `berezino_checkpoint` dentro de este archivo.
2.  **Servicio Definido:** Este servicio utiliza una imagen de Squid (por ejemplo, `ubuntu/squid` o una imagen personalizada) y configura los puertos y volúmenes necesarios.
3.  **Puertos Expuestos:** Squid, por defecto, escuchará en puertos como `3128` y `3129` para las peticiones de proxy. El archivo `docker-compose.yml` principal mapea estos puertos desde el contenedor al host de la Raspberry Pi (e.g., `ports: - "3128:3128" - "3129:3129"`).
4.  **Volúmenes Montados:** Es crucial observar los volúmenes montados, que ahora se definen con rutas relativas a la raíz del proyecto:
    *   `./squid_Berezino_Checkpoint/squid.conf:/etc/squid/squid.conf`: Esto mapea el archivo `squid.conf` ubicado en `squid_Berezino_Checkpoint/squid.conf` al archivo de configuración dentro del contenedor de Squid.
    *   `./squid_Berezino_Checkpoint/certs:/etc/squid/certs`: Este directorio (`squid_Berezino_Checkpoint/certs/`) se monta para almacenar los certificados SSL/TLS.
    *   También puede haber volúmenes para la caché (`/var/spool/squid`) y los logs (`/var/log/squid`), posiblemente mapeados a un disco USB.

## Revisar y Personalizar la Configuración de Squid (`squid.conf`)
El comportamiento de Squid se controla principalmente a través del archivo `squid.conf`, ubicado en `squid_Berezino_Checkpoint/squid.conf`.

1.  Revísalo cuidadosamente:
    ```bash
    nano squid_Berezino_Checkpoint/squid.conf
    ```
2.  **Parámetros Comunes a Revisar:**
    *   `http_port 3128`: Define el puerto y la modalidad en la que Squid escucha. Puede haber directivas adicionales como `transparent` o `intercept` si se configura un proxy transparente. Para inspección SSL, podrías ver `http_port 3129 intercept` y `https_port 3130 ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=/etc/squid/certs/myCA.pem`.
    *   `acl`: Las Listas de Control de Acceso (ACLs) son fundamentales en Squid. Definen criterios (como redes de origen, dominios de destino, tipos de archivo) para luego permitir o denegar el acceso.
    *   `http_access`: Estas directivas utilizan las ACLs para tomar decisiones sobre qué tráfico permitir o denegar. El orden de las reglas `http_access` es importante.
    *   `cache_dir ufs /var/spool/squid 100 16 256`: Define el tipo, la ubicación, el tamaño y la estructura del directorio de caché de Squid.
    *   `ssl_bump`: Si el proyecto realiza inspección HTTPS, encontrarás directivas como `ssl_bump peek all`, `ssl_bump splice all`, o `ssl_bump bump all` junto con la configuración de los certificados. `sslcrtd_program` también es relevante aquí, ya que se utiliza para generar certificados dinámicamente.

3.  **Inspección HTTPS (Bump SSL):**
    *   La presencia de la carpeta `squid_Berezino_Checkpoint/certs/` y el archivo `README_SQUID.md` sugiere que este proyecto está configurado para, o al menos soporta, la inspección de tráfico SSL/TLS. Esto permite a Squid desencriptar, inspeccionar y potencialmente filtrar o modificar tráfico HTTPS.
    *   **Consulta `squid_Berezino_Checkpoint/README_SQUID.md`:** Este archivo contiene detalles cruciales sobre la configuración específica de la inspección SSL/TLS para este proyecto, incluyendo cómo generar o manejar los certificados necesarios.
    *   **Importancia de los Certificados en `squid_Berezino_Checkpoint/certs/`:** Para que la inspección SSL funcione, Squid necesita actuar como una Autoridad Certificadora (CA) intermedia. Los certificados y la clave privada de esta CA se almacenan en el directorio `squid_Berezino_Checkpoint/certs/`.
    *   **Advertencia sobre Inspección HTTPS:** La inspección SSL/TLS implica que Squid "rompe" la encriptación extremo a extremo. Para que esto funcione sin errores de certificado en los navegadores de los clientes, el certificado de la CA de Squid debe ser importado y confiado por cada dispositivo cliente que utilice el proxy. Esto tiene implicaciones de seguridad y privacidad que deben ser consideradas.

## Manejo de Certificados (para Inspección SSL/TLS)
Como se mencionó, la inspección SSL/TLS requiere una gestión adecuada de los certificados.

1.  **Directorio `squid_Berezino_Checkpoint/certs/`:**
    Has observado que `squid_Berezino_Checkpoint/certs/` contiene un archivo `.gitkeep`. Esto significa que el directorio está intencionadamente vacío en el repositorio y necesitas colocar o generar tus propios archivos de certificado aquí.
2.  **Generación/Obtención de Certificados:**
    *   Sigue las instrucciones detalladas en `squid_Berezino_Checkpoint/README_SQUID.md` para generar tu propia Autoridad Certificadora (CA) y el certificado correspondiente que Squid usará. Típicamente, esto involucra el uso de herramientas como OpenSSL.
    *   El archivo principal que necesitarás es el certificado de tu CA (e.g., `myCA.pem` o `myCA.der`) y su clave privada. El certificado público de la CA deberá ser distribuido e instalado en los dispositivos cliente para evitar advertencias de seguridad.

## Construir y Ejecutar el Contenedor de Squid
Una vez que hayas revisado y personalizado tu `squid.conf` y preparado los certificados necesarios (si aplica), **asegúrate de estar en el directorio raíz del proyecto.**

1.  **Construir la imagen de Docker (si es necesario):**
    Si el `docker-compose.yml` principal define cómo construir el servicio `berezino_checkpoint` (o si usa una imagen pre-construida), Docker Compose puede manejarlo. Para construir solo este servicio explícitamente:
    ```bash
    sudo docker compose build berezino_checkpoint
    ```
    Este paso puede tardar un poco la primera vez. Opcionalmente, puedes omitir este paso si utilizas `sudo docker compose up -d --build berezino_checkpoint`, lo cual construirá la imagen si no existe antes de iniciar el contenedor.

2.  **Iniciar el servicio de Squid:**
    Para iniciar Squid (`berezino_checkpoint`) en segundo plano (detached mode):
    ```bash
    sudo docker compose up -d berezino_checkpoint
    ```
    Si no ejecutaste `build` antes y la imagen necesita ser construida, puedes combinar los pasos con `sudo docker compose up -d --build berezino_checkpoint`.
    Si deseas iniciar todos los servicios definidos en el `docker-compose.yml` (incluyendo Squid, el portal, Pi-hole, etc.), puedes ejecutar `sudo docker compose up -d` desde la raíz del proyecto.

## Verificar que Squid está Funcionando
Después de iniciar el servicio, comprueba que esté operando correctamente.

1.  **Ver los contenedores Docker en ejecución:**
    ```bash
    sudo docker ps
    ```
    Deberías ver un contenedor listado para Squid (el nombre será `Berezino_Checkpoint` o similar, como se define en `container_name` en el `docker-compose.yml`). Asegúrate de que su estado sea "Up" o "Running".

2.  **Ver los logs del contenedor de Squid:**
    Si necesitas solucionar problemas o ver la actividad de Squid, puedes ver sus logs. Identifica el nombre del servicio en tu archivo `docker-compose.yml` (es `berezino_checkpoint`).
    ```bash
    sudo docker compose logs -f berezino_checkpoint
    ```
    Revisa los logs de inicio para cualquier error en `squid.conf` o problemas con los certificados. Los archivos de log principales de Squid (`access.log`, `cache.log`) se gestionan dentro del contenedor, pero errores críticos de inicio suelen aparecer en los logs de Docker.

Al igual que con el portal cautivo, el tráfico de los clientes aún no se redirige automáticamente a Squid. Esto se configurará en la siguiente sección, donde se establecerán las reglas de `iptables` para forzar el tráfico a través del proxy.
