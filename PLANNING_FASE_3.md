# Plan de Implementación: Fase 3 - Control de la Red

**Nombre Clave de la Fase:** `Estableciendo el Control de la Red (Network Control Setup)`
**Operador IA:** `Stalker`
**Objetivo:** Desplegar los servicios de red `StarySobor_RadioPost` (Pi-hole) y `Berezino_Checkpoint` (Squid). Al finalizar esta fase, el sistema tendrá capacidad de filtrado de DNS a nivel de red y un proxy de filtrado de contenido, sentando las bases para la red segura y controlada del modo Hotspot.

---

### Prerrequisitos

-   Haber completado exitosamente la **Fase 2: El Centro de Mando**.
-   Tener un dominio (`pihole.terrerov.com`) listo para la interfaz web de Pi-hole.

---

### Paso 1: Despliegue de `StarySobor_RadioPost` (Pi-hole)

**Justificación:** Pi-hole nos proporcionará un control centralizado sobre el DNS, permitiendo el bloqueo de publicidad y rastreadores para cualquier dispositivo en la red. También resolverá el problema de DNS local que identificamos en la Fase 2.

**Acciones:**
1.  **Actualizar el archivo `.env`:**
    -   Añadir las variables para la contraseña de la interfaz web de Pi-hole (`WEBPASSWORD`) y el dominio (`PIHOLE_DOMAIN`).
2.  **Modificar el `docker-compose.yml`:**
    -   Añadir la definición del servicio `pihole`.
    -   **Imagen:** `pihole/pihole:latest`.
    -   **Puertos:** Exponer los puertos `53/tcp` y `53/udp` al anfitrión para el servicio DNS. El puerto `80` del contenedor se mapeará a un puerto no utilizado en el host (ej. `8080`) para evitar conflictos con Traefik.
    -   **Volúmenes:** Mapear los directorios de configuración persistente a `/mnt/usbdata/docker_volumes/pihole/`.
    -   **Variables de Entorno:** Cargar la contraseña y la zona horaria desde el `.env`.
    -   **Labels de Traefik:** Configurar `CoastalHighway_Router` para exponer la interfaz web de Pi-hole en su dominio seguro, apuntando al puerto interno del contenedor.
    -   **Capacidades:** Añadir `cap_add: - NET_ADMIN` para permitir que Pi-hole gestione la red.

---

### Paso 2: Despliegue de `Berezino_Checkpoint` (Squid)

**Justificación:** Squid actuará como nuestro proxy de filtrado. En esta fase, lo desplegaremos con una configuración básica, preparándolo para la intercepción transparente de tráfico en fases futuras.

**Acciones:**
1.  **Crear el archivo de configuración `squid.conf`:**
    -   Crear un archivo de configuración inicial en `/mnt/usbdata/docker_volumes/squid/squid.conf`.
    -   **Configuración inicial:**
        -   Definir el puerto del proxy (`http_port 3128`).
        -   Establecer una ACL (Lista de Control de Acceso) básica para permitir el tráfico desde la red local.
        -   Configurar la ubicación del directorio de caché.
2.  **Modificar el `docker-compose.yml`:**
    -   Añadir la definición del servicio `squid`.
    -   **Imagen:** `ubuntu/squid:latest`.
    -   **Puertos:** Exponer el puerto `3128` al anfitrión.
    -   **Volúmenes:** Mapear el archivo `squid.conf` y el directorio de caché a `/mnt/usbdata/docker_volumes/squid/`.
    -   **Política de Reinicio:** `unless-stopped`.

---

### Paso 3: Despliegue y Verificación

**Justificación:** Poner en marcha los nuevos servicios y asegurar su correcto funcionamiento antes de integrar el tráfico de la red.

**Acciones:**
1.  **Levantar los nuevos servicios:** Ejecutar `docker compose up -d` para desplegar Pi-hole y Squid.
2.  **Verificar el Estado:**
    -   Usar `docker compose ps` para confirmar que los nuevos contenedores están en estado `running`.
    -   Revisar los logs de `pihole` y `squid` para detectar errores.
3.  **Validación Funcional de Pi-hole:**
    -   Acceder a la interfaz web de Pi-hole a través de su dominio (`https://pihole.terrerov.com`).
    -   Configurar manualmente un dispositivo cliente para que use la IP de la Raspberry Pi (`192.168.0.2`) como su servidor DNS.
    -   Verificar que la publicidad es bloqueada y que las consultas aparecen en el dashboard de Pi-hole.
4.  **Validación Funcional de Squid:**
    -   Configurar manualmente un navegador web para usar la Raspberry Pi (`192.168.0.2`) en el puerto `3128` como proxy HTTP.
    -   Verificar que se puede navegar por internet y que las peticiones aparecen en los logs de acceso de Squid (`docker compose logs squid`).

---

**Conclusión de la Fase 3:**
Con esta fase completada, el proyecto tendrá un control robusto sobre el DNS y una plataforma de proxy lista para la intercepción de tráfico. Esto nos acerca significativamente al objetivo de una red personal segura y completamente gestionada.
