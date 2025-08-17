# Registro de Despliegue: Fase 2 - El Centro de Mando

**Fecha:** `2025-08-17`
**Operador:** `Stalker`
**Objetivo Cumplido:** Se ha desplegado y verificado la pila de servicios principal: `CoastalHighway_Router` (Traefik), `Elektrozavodsk_Databank` (PostgreSQL) y `NWAF_Command_Center` (n8n).

---

### Cronología de Acciones

#### 1. Creación de la Infraestructura como Código

-   **Acción:** Se creó el archivo `docker-compose.yml` definiendo los tres servicios principales, la red segura y los volúmenes persistentes.
-   **Comando:** `write_file`
-   **Resultado:** Archivo `docker-compose.yml` creado en la raíz del proyecto.

#### 2. Gestión de Secretos y Configuración

-   **Acción:** Se instaló la utilidad `htpasswd` para generar credenciales de autenticación. El paquete `apache-tools` no fue encontrado; se identificó y se instaló el paquete `apache`.
-   **Comandos:**
    ```bash
    sudo pacman -S --noconfirm apache-tools  # Fallido
    sudo pacman -Fyx htpasswd
    sudo pacman -S --noconfirm apache
    ```
-   **Resultado:** `htpasswd` instalado.

-   **Acción:** Se generó el hash de la contraseña para la autenticación básica del dashboard de Traefik.
-   **Comando:** `htpasswd -nb terrerov '100A.soledad2'`
-   **Resultado:** Hash `terrerov:$apr1$yVOqitXN$KGz6yKoaBJVmZomOm0lJB/` generado.

-   **Acción:** Se crearon los archivos `.env` (con todas las credenciales y dominios) y `.gitignore`.
-   **Comandos:** `write_file` (para ambos archivos).
-   **Resultado:** Secretos externalizados y excluidos del control de versiones.

#### 3. Configuración de Traefik (`CoastalHighway_Router`)

-   **Acción:** Se creó el archivo de configuración estática `traefik.yml` y el archivo `acme.json` para los certificados.
-   **Comandos:**
    ```bash
    write_file # para traefik.yml
    sudo mv /home/terrerov/surviving-chernarus/traefik.yml /mnt/usbdata/docker_volumes/traefik/traefik.yml
    touch /mnt/usbdata/docker_volumes/traefik/acme.json && chmod 600 /mnt/usbdata/docker_volumes/traefik/acme.json
    ```
-   **Resultado:** Configuración de Traefik completada.

-   **Acción:** Se añadió la variable de entorno `CF_API_TOKEN` al `.env` y al `docker-compose.yml`.
-   **Comandos:** `echo "..." >> .env` y `replace` en `docker-compose.yml`.
-   **Resultado:** Token de Cloudflare configurado.

#### 4. Despliegue y Depuración

-   **Acción:** Primer intento de despliegue.
-   **Comando:** `docker compose -f ... up -d`
-   **Resultado:** **Fallido.** Error al descargar la imagen `n8n-community/n8n`.

-   **Acción:** Corrección del nombre de la imagen. Se buscó en la web el nombre correcto (`n8nio/n8n`) y se actualizó el `docker-compose.yml`.
-   **Comandos:** `google_web_search`, `replace`.
-   **Resultado:** `docker-compose.yml` corregido.

-   **Acción:** Segundo intento de despliegue.
-   **Comando:** `docker compose -f ... up -d`
-   **Resultado:** **Fallido.** Error de sintaxis YAML (`did not find expected '-' indicator`) debido a una duplicación de contenido.

-   **Acción:** Corrección del `docker-compose.yml`. Se reescribió el archivo completo para asegurar una sintaxis limpia.
-   **Comando:** `write_file` (sobrescribiendo).
-   **Resultado:** `docker-compose.yml` validado.

-   **Acción:** Tercer intento de despliegue.
-   **Comando:** `docker compose -f ... up -d`
-   **Resultado:** **Éxito.** Las imágenes se descargaron y los contenedores se iniciaron.

#### 5. Verificación y Depuración Final

-   **Acción:** Se revisaron los logs de Traefik.
-   **Comando:** `docker compose -f ... logs traefik`
-   **Resultado:** Se detectó un error de credenciales de Cloudflare. La variable de entorno `CF_API_TOKEN` era incorrecta; Traefik esperaba `CF_DNS_API_TOKEN`.

-   **Acción:** Se corrigió el nombre de la variable de entorno en `.env` y `docker-compose.yml`.
-   **Comandos:** `replace` (en ambos archivos).
-   **Resultado:** Configuración de credenciales corregida.

-   **Acción:** Se forzó la recreación de la pila de servicios para aplicar los cambios.
-   **Comando:** `docker compose -f ... up -d --force-recreate`
-   **Resultado:** Servicios reiniciados con la configuración correcta. Los logs de Traefik dejaron de mostrar errores de autenticación.
