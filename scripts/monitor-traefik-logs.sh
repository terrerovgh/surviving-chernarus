#!/bin/bash

echo "🔍 Monitoreo en Tiempo Real - Traefik Debug"
echo "=========================================="
echo "Monitoring Traefik logs... (Ctrl+C para salir)"
echo

# Función para mostrar timestamp
show_timestamp() {
    date '+[%Y-%m-%d %H:%M:%S]'
}

# Monitorear logs en tiempo real
docker exec traefik_proxy tail -f /var/log/traefik/traefik.log | while read line; do
    # Mostrar solo errores y warnings con timestamp
    if [[ $line =~ "level=error" ]] || [[ $line =~ "level=warn" ]]; then
        echo "$(show_timestamp) ❌ $line"
    elif [[ $line =~ "level=info" ]] && [[ $line =~ "Configuration loaded" ]]; then
        echo "$(show_timestamp) ✅ $line"
    elif [[ $line =~ "certificate obtained" ]]; then
        echo "$(show_timestamp) 🔐 $line"
    fi
done
