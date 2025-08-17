# Guía de Configuración: 02 - Pila de Servicios Principal

**Objetivo:** Desplegar el núcleo de servicios del proyecto (`Traefik`, `PostgreSQL`, `n8n`) utilizando Docker Compose.

---

### 1. Crear el Archivo de Orquestación

Crea el archivo `docker-compose.yml` en la raíz del proyecto (`/home/terrerov/surviving-chernarus/`) con el siguiente contenido:

```yaml
services:
  traefik:
    image: traefik:latest
    container_name: CoastalHighway_Router
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - secure_network
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /mnt/usbdata/docker_volumes/traefik/traefik.yml:/traefik.yml:ro
      - /mnt/usbdata/docker_volumes/traefik/acme.json:/acme.json
    environment:
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`${TRAEFIK_DOMAIN}`)"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.tls=true"
      - "traefik.http.routers.traefik.tls.certresolver=cloudflare"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=${HTTP_BASIC_AUTH}"

  postgres:
    image: postgres:latest
    container_name: Elektrozavodsk_Databank
    restart: unless-stopped
    networks:
      - secure_network
    volumes:
      - /mnt/usbdata/docker_volumes/elektrozavodsk_db:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}

  n8n:
    image: n8nio/n8n:latest
    container_name: NWAF_Command_Center
    restart: unless-stopped
    networks:
      - secure_network
    volumes:
      - /mnt/usbdata/docker_volumes/n8n:/home/node/.n8n
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_PASSWORD=${N8N_PASSWORD}
    depends_on:
      - postgres
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(`${N8N_DOMAIN}`)"
      - "traefik.http.routers.n8n.tls=true"
      - "traefik.http.routers.n8n.tls.certresolver=cloudflare"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

networks:
  secure_network:
    driver: bridge
```

### 2. Configurar Secretos y Dominios

1.  **Crear el archivo `.env`** en la misma carpeta. Rellénalo con tus datos.
    ```env
    # Dominios
    TRAEFIK_DOMAIN=traefik.yourdomain.com
    N8N_DOMAIN=n8n.yourdomain.com

    # Autenticación para Traefik (generar con htpasswd)
    HTTP_BASIC_AUTH=user:$apr1$....

    # Credenciales PostgreSQL
    POSTGRES_USER=your_db_user
    POSTGRES_PASSWORD=your_secure_password
    POSTGRES_DB=your_db_name

    # Credenciales n8n
    N8N_USER=your_n8n_user
    N8N_PASSWORD=your_secure_n8n_password

    # Secreto para Cloudflare
    CF_DNS_API_TOKEN=your_cloudflare_api_token
    ```

2.  **Crear `.gitignore`** para proteger tus secretos.
    ```
    .env
    acme.json
    ```

### 3. Configurar Traefik

1.  **Crear `traefik.yml`** en `/mnt/usbdata/docker_volumes/traefik/`.
    ```yaml
    global:
      checkNewVersion: true
    log:
      level: INFO
    entryPoints:
      web:
        address: ":80"
        http:
          redirections:
            entryPoint:
              to: websecure
              scheme: https
      websecure:
        address: ":443"
    api:
      dashboard: true
    providers:
      docker:
        endpoint: "unix:///var/run/docker.sock"
        exposedByDefault: false
    certificatesResolvers:
      cloudflare:
        acme:
          email: "your-email@example.com"
          storage: "acme.json"
          dnsChallenge:
            provider: cloudflare
    ```

2.  **Crear `acme.json`** y asignarle permisos.
    ```bash
    touch /mnt/usbdata/docker_volumes/traefik/acme.json
    chmod 600 /mnt/usbdata/docker_volumes/traefik/acme.json
    ```

### 4. Desplegar la Pila

Desde el directorio `/home/terrerov/surviving-chernarus/`, ejecuta:
```bash
docker compose up -d
```
---
**Configuración de Servicios Principales Completada.**
