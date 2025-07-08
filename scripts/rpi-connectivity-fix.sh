#!/bin/bash

# 🔧 Raspberry Pi Connectivity Fix Script
# Este script diagnostica y corrige problemas de conectividad con la Raspberry Pi

set -e

RPI_HOST="rpi"
RPI_IP="192.168.0.2"

echo "🔍 Diagnóstico de conectividad Raspberry Pi"
echo "=============================================="

# Test 1: SSH Connectivity
echo "📡 Probando conectividad SSH..."
if ssh -o ConnectTimeout=5 "$RPI_HOST" 'echo "SSH OK"' >/dev/null 2>&1; then
    echo "✅ SSH funciona correctamente"
    SSH_OK=true
else
    echo "❌ SSH falló"
    SSH_OK=false
fi

# Test 2: IP Resolution
echo "🌐 Verificando resolución de nombres..."
if getent hosts "$RPI_HOST" >/dev/null 2>&1; then
    RESOLVED_IP=$(getent hosts "$RPI_HOST" | awk '{print $1}')
    echo "✅ $RPI_HOST resuelve a: $RESOLVED_IP"
else
    echo "❌ No se puede resolver $RPI_HOST"
fi

# Test 3: ICMP (Ping)
echo "🏓 Probando conectividad ICMP (ping)..."
if ping -c 1 -W 3 "$RPI_IP" >/dev/null 2>&1; then
    echo "✅ Ping funciona"
    PING_OK=true
else
    echo "⚠️  Ping falló (normal en sistemas seguros)"
    PING_OK=false
fi

# Test 4: TCP Port Check
echo "🔌 Verificando puerto SSH (22)..."
if timeout 3 bash -c "</dev/tcp/$RPI_IP/22" 2>/dev/null; then
    echo "✅ Puerto SSH (22) accesible"
    TCP_OK=true
else
    echo "❌ Puerto SSH (22) no accesible"
    TCP_OK=false
fi

# Test 5: Network Information
echo "🗺️  Información de red:"
echo "   Tu IP: $(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)"
echo "   RPI IP: $RPI_IP"

if [ "$SSH_OK" = true ]; then
    echo "📊 Información de la Raspberry Pi:"
    RPI_HOSTNAME=$(ssh "$RPI_HOST" 'cat /etc/hostname' 2>/dev/null || echo "unknown")
    RPI_UPTIME=$(ssh "$RPI_HOST" 'cat /proc/uptime | cut -d" " -f1' 2>/dev/null || echo "unknown")
    RPI_LOAD=$(ssh "$RPI_HOST" 'cat /proc/loadavg | cut -d" " -f1-3' 2>/dev/null || echo "unknown")

    echo "   Hostname: $RPI_HOSTNAME"
    echo "   Uptime: ${RPI_UPTIME}s"
    echo "   Load: $RPI_LOAD"
fi

echo ""
echo "📋 Resumen del diagnóstico:"
echo "=========================="

if [ "$SSH_OK" = true ] && [ "$TCP_OK" = true ]; then
    echo "🎉 ¡La conectividad SSH está funcionando correctamente!"
    echo ""
    echo "💡 Notas importantes:"
    echo "   • SSH funciona sin problemas"
    echo "   • Puedes conectarte usando: ssh $RPI_HOST"
    if [ "$PING_OK" = false ]; then
        echo "   • Ping está deshabilitado (seguridad normal)"
    fi
    echo ""
    echo "🚀 Comandos útiles:"
    echo "   ssh $RPI_HOST                    # Conectar a la Raspberry Pi"
    echo "   ssh $RPI_HOST 'comando'          # Ejecutar comando remoto"
    echo "   scp archivo.txt $RPI_HOST:~/     # Copiar archivo"
    echo ""
    exit 0
else
    echo "⚠️  Hay problemas de conectividad que necesitan atención:"

    if [ "$SSH_OK" = false ]; then
        echo "   ❌ SSH no funciona"
        echo "      Soluciones posibles:"
        echo "      • Verificar que el servicio SSH esté corriendo en la RPi"
        echo "      • Comprobar configuración de firewall"
        echo "      • Verificar claves SSH"
    fi

    if [ "$TCP_OK" = false ]; then
        echo "   ❌ Puerto SSH no accesible"
        echo "      Soluciones posibles:"
        echo "      • La Raspberry Pi puede estar apagada"
        echo "      • Problemas de red/firewall"
        echo "      • SSH ejecutándose en puerto diferente"
    fi

    echo ""
    echo "🔧 Pasos de solución recomendados:"
    echo "1. Verificar que la Raspberry Pi esté encendida"
    echo "2. Comprobar configuración de red (/etc/hosts)"
    echo "3. Verificar configuración SSH"

    exit 1
fi
