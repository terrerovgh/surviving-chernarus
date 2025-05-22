# Configuración del Proxy Squid

## Introducción
Squid es un popular servidor proxy de almacenamiento en caché para la web que soporta HTTP, HTTPS, FTP, y más. En el proyecto Escrowed Kathy, Squid se utiliza para filtrar el tráfico de los usuarios conectados al hotspot, permitiendo un control más granular sobre el acceso a Internet, realizar caché de contenido para mejorar la velocidad de navegación en accesos repetidos, y potencialmente para inspeccionar el tráfico SSL/TLS.

Al igual que el portal cautivo, Squid se ejecutará como un servicio Docker, utilizando la configuración y los archivos proporcionados en el repositorio del proyecto.

## Navegar al Directorio del Proxy Squid
Para trabajar con los archivos de configuración de Squid, primero debes navegar al directorio correspondiente dentro del repositorio clonado.

1.  Abre una terminal en tu Raspberry Pi.
2.  Cambia al directorio `squid_Berezino_Checkpoint`. Si clonaste el proyecto en `~/projects/escrowed-kathy`, el comando sería:
    ```bash
    cd ~/projects/escrowed-kathy/squid_Berezino_Checkpoint
    ```
    Ajusta la `ruta_al_repo` si tu proyecto está en una ubicación diferente.

## Revisar la Configuración de Docker Compose (`docker-compose.yml`)
El archivo `docker-compose.yml` en este directorio define cómo se construye y ejecuta el servicio de Squid.

1.  Revisa el contenido de este archivo:
    ```bash
    cat docker-compose.yml
    ```
2.  **Servicio Definido:** Este archivo `docker-compose.yml` define el servicio de Squid. Puede incluir la construcción de una imagen personalizada de Docker basada en un Dockerfile en el mismo directorio.
3.  **Puertos Expuestos:** Squid, por defecto, escuchará en el puerto `3128` para las peticiones de proxy. El archivo `docker-compose.yml` expondrá este puerto desde el contenedor al host de la Raspberry Pi (por ejemplo, `ports: - "3128:3128"`).
4.  **Volúmenes Montados:** Es crucial observar los volúmenes montados:
    *   `./squid.conf:/etc/squid/squid.conf`: Esto mapea el archivo local `squid.conf` al archivo de configuración dentro del contenedor de Squid. Cualquier cambio en tu `squid.conf` local se reflejará en el contenedor (generalmente después de un reinicio del servicio).
    *   `./certs:/etc/squid/certs`: Este directorio se monta para almacenar los certificados SSL/TLS necesarios si Squid está configurado para inspección de HTTPS (bump SSL).

## Revisar y Personalizar la Configuración de Squid (`squid.conf`)
El comportamiento de Squid se controla principalmente a través del archivo `squid.conf`.

1.  El archivo `squid.conf` en el directorio actual es la configuración principal que se utilizará. Revísalo cuidadosamente:
    ```bash
    nano squid.conf
    ```
2.  **Parámetros Comunes a Revisar:**
    *   `http_port 3128`: Define el puerto y la modalidad en la que Squid escucha. Puede haber directivas adicionales como `transparent` o `intercept` si se configura un proxy transparente. Para inspección SSL, podrías ver `http_port 3129 intercept` y `https_port 3130 ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=/etc/squid/certs/myCA.pem`.
    *   `acl`: Las Listas de Control de Acceso (ACLs) son fundamentales en Squid. Definen criterios (como redes de origen, dominios de destino, tipos de archivo) para luego permitir o denegar el acceso.
    *   `http_access`: Estas directivas utilizan las ACLs para tomar decisiones sobre qué tráfico permitir o denegar. El orden de las reglas `http_access` es importante.
    *   `cache_dir ufs /var/spool/squid 100 16 256`: Define el tipo, la ubicación, el tamaño y la estructura del directorio de caché de Squid.
    *   `ssl_bump`: Si el proyecto realiza inspección HTTPS, encontrarás directivas como `ssl_bump peek all`, `ssl_bump splice all`, o `ssl_bump bump all` junto con la configuración de los certificados. `sslcrtd_program` también es relevante aquí, ya que se utiliza para generar certificados dinámicamente.

3.  **Inspección HTTPS (Bump SSL):**
    *   La presencia de la carpeta `certs/` y el archivo `README_SQUID.md` sugiere que este proyecto está configurado para, o al menos soporta, la inspección de tráfico SSL/TLS. Esto permite a Squid desencriptar, inspeccionar y potencialmente filtrar o modificar tráfico HTTPS.
    *   **Consulta `README_SQUID.md`:** Este archivo contiene detalles cruciales sobre la configuración específica de la inspección SSL/TLS para este proyecto, incluyendo cómo generar o manejar los certificados necesarios.
    *   **Importancia de los Certificados en `certs/`:** Para que la inspección SSL funcione, Squid necesita actuar como una Autoridad Certificadora (CA) intermedia. Los certificados y la clave privada de esta CA se almacenan en el directorio `certs/`.
    *   **Advertencia sobre Inspección HTTPS:** La inspección SSL/TLS implica que Squid "rompe" la encriptación extremo a extremo. Para que esto funcione sin errores de certificado en los navegadores de los clientes, el certificado de la CA de Squid debe ser importado y confiado por cada dispositivo cliente que utilice el proxy. Esto tiene implicaciones de seguridad y privacidad que deben ser consideradas.

## Manejo de Certificados (para Inspección SSL/TLS)
Como se mencionó, la inspección SSL/TLS requiere una gestión adecuada de los certificados.

1.  **Directorio `certs/`:**
    Has observado que `certs/` contiene un archivo `.gitkeep`. Esto significa que el directorio está intencionadamente vacío en el repositorio y necesitas colocar o generar tus propios archivos de certificado aquí.
2.  **Generación/Obtención de Certificados:**
    *   Sigue las instrucciones detalladas en `README_SQUID.md` para generar tu propia Autoridad Certificadora (CA) y el certificado correspondiente que Squid usará. Típicamente, esto involucra el uso de herramientas como OpenSSL.
    *   El archivo principal que necesitarás es el certificado de tu CA (e.g., `myCA.pem` o `myCA.der`) y su clave privada. El certificado público de la CA deberá ser distribuido e instalado en los dispositivos cliente para evitar advertencias de seguridad.

## Construir y Ejecutar el Contenedor de Squid
Una vez que hayas revisado y personalizado tu `squid.conf` y preparado los certificados necesarios (si aplica):

1.  **Construir la imagen de Docker (si es necesario):**
    Si el `docker-compose.yml` define una `build: .` o similar, Docker Compose construirá la imagen basada en el Dockerfile local.
    ```bash
    sudo docker-compose build
    ```
    Este paso puede tardar un poco la primera vez.

2.  **Iniciar el servicio de Squid:**
    Para iniciar Squid en segundo plano (detached mode):
    ```bash
    sudo docker-compose up -d
    ```
    Si no ejecutaste `build` antes, puedes combinar los pasos con `sudo docker-compose up -d --build`.

## Verificar que Squid está Funcionando
Después de iniciar el servicio, comprueba que esté operando correctamente.

1.  **Ver los contenedores Docker en ejecución:**
    ```bash
    sudo docker ps
    ```
    Deberías ver un contenedor listado para Squid (el nombre se derivará del nombre del directorio o se especificará en `docker-compose.yml`). Asegúrate de que su estado sea "Up" o "Running".

2.  **Ver los logs del contenedor de Squid:**
    Si necesitas solucionar problemas o ver la actividad de Squid, puedes ver sus logs. Identifica el nombre del servicio en tu `docker-compose.yml` (suele ser `squid` o similar).
    ```bash
    sudo docker-compose logs -f nombre_del_servicio_squid
    ```
    Reemplaza `nombre_del_servicio_squid` con el nombre real del servicio. Revisa los logs de inicio para cualquier error en `squid.conf` o problemas con los certificados. Los archivos de log principales de Squid (`access.log`, `cache.log`) se gestionan dentro del contenedor, pero errores críticos de inicio suelen aparecer en los logs de Docker.

Al igual que con el portal cautivo, el tráfico de los clientes aún no se redirige automáticamente a Squid. Esto se configurará en la siguiente sección, donde se establecerán las reglas de `iptables` para forzar el tráfico a través del proxy.
