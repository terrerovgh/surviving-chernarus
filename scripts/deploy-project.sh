#!/bin/bash

# deploy-project.sh - Script para desplegar nuevos proyectos web
# Uso: ./scripts/deploy-project.sh <nombre-proyecto> <dominio> <tipo-proyecto>

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging con colores
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

title() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🚀 CHERNARUS PROJECT DEPLOYER${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar argumentos
if [ $# -lt 3 ]; then
    title
    error "Uso: $0 <nombre-proyecto> <dominio> <tipo-proyecto>"
    echo ""
    echo "Tipos de proyecto soportados:"
    echo "  - astro          (Sitio estático con Astro)"
    echo "  - react          (Aplicación React)"
    echo "  - vue            (Aplicación Vue.js)"
    echo "  - nextjs         (Aplicación Next.js)"
    echo "  - static         (HTML/CSS/JS estático)"
    echo "  - hugo           (Sitio estático con Hugo)"
    echo ""
    echo "Ejemplo:"
    echo "  $0 mi-proyecto miproyecto.terrerov.com astro"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_DOMAIN="$2"
PROJECT_TYPE="$3"

# Variables de configuración
BASE_DIR="/tmp/chernarus"
PROJECTS_DIR="$BASE_DIR/data/projects"
NGINX_CONFIGS_DIR="/home/terrerov/surviving-chernarus/services/projects"
DOCKER_COMPOSE_FILE="/home/terrerov/surviving-chernarus/docker-compose.yml"

title

log "📋 Configuración del proyecto:"
log "   Nombre: $PROJECT_NAME"
log "   Dominio: $PROJECT_DOMAIN"
log "   Tipo: $PROJECT_TYPE"
echo ""

# Verificar que el tipo de proyecto es válido
case $PROJECT_TYPE in
    astro|react|vue|nextjs|static|hugo)
        log "✅ Tipo de proyecto válido: $PROJECT_TYPE"
        ;;
    *)
        error "❌ Tipo de proyecto no soportado: $PROJECT_TYPE"
        exit 1
        ;;
esac

# Crear directorio del proyecto
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
log "📁 Creando directorio del proyecto: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

# Crear configuración de nginx
NGINX_CONFIG="$NGINX_CONFIGS_DIR/nginx-$PROJECT_NAME.conf"
log "⚙️ Creando configuración de nginx: $NGINX_CONFIG"

cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    server_name $PROJECT_DOMAIN;
    root /usr/share/nginx/html;
    index index.html index.htm;

    # Configuración para $PROJECT_TYPE
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    }

    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs específicos del proyecto
    access_log /var/log/nginx/$PROJECT_NAME-access.log;
    error_log /var/log/nginx/$PROJECT_NAME-error.log;

    # Configuración de compresión
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
}
EOF

# Crear página de ejemplo según el tipo de proyecto
log "🎨 Creando página de ejemplo para $PROJECT_TYPE"

case $PROJECT_TYPE in
    astro|react|vue|nextjs)
        cat > "$PROJECT_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME - Proyecto $PROJECT_TYPE</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        .container {
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        .tech-badge {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 0.5rem 1rem;
            border-radius: 25px;
            margin: 0.5rem;
            border: 1px solid rgba(255, 255, 255, 0.3);
        }
        .deploy-info {
            margin-top: 2rem;
            padding: 1rem;
            background: rgba(0, 0, 0, 0.2);
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 $PROJECT_NAME</h1>
        <div class="tech-badge">$PROJECT_TYPE</div>
        <div class="tech-badge">Nginx</div>
        <div class="tech-badge">Docker</div>
        <div class="tech-badge">Traefik</div>

        <div class="deploy-info">
            <h3>✅ Proyecto desplegado exitosamente</h3>
            <p><strong>Dominio:</strong> <code>$PROJECT_DOMAIN</code></p>
            <p><strong>Tipo:</strong> $PROJECT_TYPE</p>
            <p><strong>Desplegado en:</strong> $(date)</p>
        </div>

        <p style="margin-top: 2rem; opacity: 0.8;">
            Reemplaza este archivo con tu proyecto $PROJECT_TYPE compilado
        </p>
    </div>
</body>
</html>
EOF
        ;;
    static)
        cat > "$PROJECT_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME - Sitio Estático</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #74b9ff 0%, #0984e3 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        .container {
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📄 $PROJECT_NAME</h1>
        <h2>Sitio Web Estático</h2>
        <p>Dominio: <code>$PROJECT_DOMAIN</code></p>
        <p>Desplegado en: $(date)</p>
    </div>
</body>
</html>
EOF
        ;;
    hugo)
        cat > "$PROJECT_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME - Hugo Site</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #ff7675 0%, #d63031 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        .container {
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚡ $PROJECT_NAME</h1>
        <h2>Hugo Static Site</h2>
        <p>Dominio: <code>$PROJECT_DOMAIN</code></p>
        <p>Desplegado en: $(date)</p>
    </div>
</body>
</html>
EOF
        ;;
esac

# Agregar entrada al /etc/hosts si no existe
log "🌐 Verificando entrada en /etc/hosts"
if ! grep -q "$PROJECT_DOMAIN" /etc/hosts; then
    warn "⚠️  Es necesario agregar la entrada al /etc/hosts:"
    echo "   sudo echo '127.0.0.1 $PROJECT_DOMAIN' >> /etc/hosts"

    # Intentar agregar automáticamente
    if [ "$EUID" -eq 0 ]; then
        echo "127.0.0.1 $PROJECT_DOMAIN" >> /etc/hosts
        log "✅ Entrada agregada automáticamente al /etc/hosts"
    else
        warn "⚠️  Ejecuta como root o agrega manualmente:"
        echo "   echo '127.0.0.1 $PROJECT_DOMAIN' | sudo tee -a /etc/hosts"
    fi
fi

# Mostrar información de cómo agregar al docker-compose
log "📝 Para completar el despliegue, agrega el siguiente servicio al docker-compose.yml:"
echo ""
echo "  ${PROJECT_NAME//-/_}_website:"
echo "    image: nginx:alpine"
echo "    container_name: ${PROJECT_NAME}_website"
echo "    volumes:"
echo "      - $PROJECT_DIR:/usr/share/nginx/html:ro"
echo "      - $NGINX_CONFIG:/etc/nginx/conf.d/default.conf:ro"
echo "      - \${LOGS_PATH}/nginx:/var/log/nginx"
echo "    networks:"
echo "      - chernarus_network"
echo "    labels:"
echo "      - traefik.enable=true"
echo "      - traefik.http.routers.${PROJECT_NAME}.rule=Host(\`$PROJECT_DOMAIN\`)"
echo "      - traefik.http.routers.${PROJECT_NAME}.entrypoints=websecure"
echo "      - traefik.http.routers.${PROJECT_NAME}.tls=true"
echo "      - traefik.http.routers.${PROJECT_NAME}.tls.certresolver=cloudflare"
echo "      - traefik.http.services.${PROJECT_NAME}.loadbalancer.server.port=80"
echo ""

log "✅ Proyecto $PROJECT_NAME configurado exitosamente!"
log "📁 Archivos creados:"
log "   - $PROJECT_DIR/index.html"
log "   - $NGINX_CONFIG"
echo ""
log "🔄 Próximos pasos:"
log "   1. Agrega el servicio al docker-compose.yml"
log "   2. Ejecuta: docker-compose up -d $PROJECT_NAME"
log "   3. Visita: https://$PROJECT_DOMAIN"
echo ""
