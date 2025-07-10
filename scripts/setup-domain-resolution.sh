#!/bin/bash
# Script para configurar resolución de nombres de dominio en toda la infraestructura Chernarus
# Este script debe ejecutarse en ambos nodos (rpi y lenlab) para asegurar la resolución de nombres

set -e

echo "🌐 === CONFIGURANDO RESOLUCIÓN DE NOMBRES CHERNARUS ==="
echo "$(date)"
echo ""

# Detectar nodo actual
HOSTNAME=$(hostname)
echo "📍 Configurando en nodo: $HOSTNAME"

# Backup del archivo hosts existente
if [[ ! -f /etc/hosts.backup ]]; then
    echo "💾 Creando backup de /etc/hosts..."
    sudo cp /etc/hosts /etc/hosts.backup
fi

# Función para agregar entrada si no existe
add_host_entry() {
    local ip=$1
    local hostname=$2
    local alias=$3

    if ! grep -q "$hostname" /etc/hosts; then
        echo "➕ Agregando: $ip $hostname $alias"
        echo "$ip $hostname $alias" | sudo tee -a /etc/hosts
    else
        echo "✅ Ya existe: $hostname"
    fi
}

echo ""
echo "🔧 Configurando entradas de hosts..."

# Configurar entradas principales
add_host_entry "192.168.0.2" "rpi.terrerov.com" "rpi"
add_host_entry "192.168.0.3" "lenlab.terrerov.com" "lenlab"

# Configurar aliases de servicios (apuntan al master)
add_host_entry "192.168.0.2" "master.terrerov.com" "master"
add_host_entry "192.168.0.3" "worker.terrerov.com" "worker"

echo ""
echo "🌍 Configurando dominios de servicios..."

# Servicios principales (todos apuntan al master donde está Traefik)
SERVICES=(
    "terrerov.com"
    "www.terrerov.com"
    "hq.terrerov.com"
    "n8n.terrerov.com"
    "traefik.terrerov.com"
    "pihole.terrerov.com"
    "radio.terrerov.com"
    "monitor.terrerov.com"
    "files.terrerov.com"
    "vault.terrerov.com"
    "squid.terrerov.com"
)

for service in "${SERVICES[@]}"; do
    add_host_entry "192.168.0.2" "$service" ""
done

echo ""
echo "🛠️ Configurando servicios internos de Kubernetes..."

# Servicios internos K8s (en el worker)
INTERNAL_SERVICES=(
    "postgres.chernarus.local"
    "n8n.chernarus.local"
    "redis.chernarus.local"
)

for service in "${INTERNAL_SERVICES[@]}"; do
    add_host_entry "192.168.0.3" "$service" ""
done

echo ""
echo "📊 CONFIGURACIÓN COMPLETADA"
echo "══════════════════════════════════════════════════════════════"
echo "✅ Nombres de nodos:"
echo "   - rpi.terrerov.com      (192.168.0.2) - Master Node"
echo "   - lenlab.terrerov.com   (192.168.0.3) - Worker Node"
echo ""
echo "✅ Servicios web principales:"
for service in "${SERVICES[@]}"; do
    echo "   - $service -> rpi.terrerov.com"
done
echo ""
echo "✅ Servicios internos K8s:"
for service in "${INTERNAL_SERVICES[@]}"; do
    echo "   - $service -> lenlab.terrerov.com"
done

echo ""
echo "🧪 PROBANDO RESOLUCIÓN..."
echo "══════════════════════════════════════════════════════════════"

# Probar resolución de nombres principales
test_domains=("rpi.terrerov.com" "lenlab.terrerov.com" "terrerov.com" "n8n.terrerov.com")

for domain in "${test_domains[@]}"; do
    if ping -c 1 -W 2 "$domain" >/dev/null 2>&1; then
        echo "✅ $domain - RESUELVE"
    else
        echo "❌ $domain - NO RESUELVE"
    fi
done

echo ""
echo "🎯 PRÓXIMOS PASOS:"
echo "══════════════════════════════════════════════════════════════"
echo "1. Ejecutar este script en ambos nodos (rpi y lenlab)"
echo "2. Configurar tu router para usar rpi.terrerov.com como DNS primario"
echo "3. Verificar conectividad con: ping rpi.terrerov.com"
echo "4. Acceder a servicios usando nombres de dominio: http://terrerov.com"

echo ""
echo "📝 Para deshacer cambios:"
echo "   sudo cp /etc/hosts.backup /etc/hosts"
