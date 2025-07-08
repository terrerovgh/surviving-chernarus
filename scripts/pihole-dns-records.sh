#!/bin/bash
# Generar listado de DNS para configurar manualmente en Pi-hole

echo "🛡️ === CONFIGURACIÓN MANUAL DNS PARA PI-HOLE ==="
echo "Fecha: $(date)"
echo ""

# Obtener IPs del cluster
RPI_IP=$(kubectl get nodes -o wide | grep rpi | awk '{print $6}')
LENLAB_IP=$(kubectl get nodes -o wide | grep lenlab | awk '{print $6}')
TRAEFIK_HTTP_PORT=$(kubectl get svc traefik-service -n chernarus-system -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30273")
TRAEFIK_HTTPS_PORT=$(kubectl get svc traefik-service -n chernarus-system -o jsonpath='{.spec.ports[1].nodePort}' 2>/dev/null || echo "31822")
PIHOLE_NODEPORT=$(kubectl get svc pihole-service -n surviving-chernarus -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30767")

echo "📋 === INFORMACIÓN DEL CLUSTER ==="
echo "• Nodo maestro (rpi): $RPI_IP"
echo "• Nodo worker (lenlab): $LENLAB_IP"
echo "• Traefik HTTP port: $TRAEFIK_HTTP_PORT"
echo "• Traefik HTTPS port: $TRAEFIK_HTTPS_PORT"
echo "• Pi-hole DNS port: $PIHOLE_NODEPORT"
echo ""

echo "🌐 === CONFIGURACIÓN DNS LOCAL ==="
echo "Todos los dominios *.terrerov.com deben apuntar a la IP del nodo maestro"
echo "donde está ejecutándose Traefik (el reverse proxy)."
echo ""

echo "📝 === LISTADO PARA PI-HOLE ADMIN INTERFACE ==="
echo "Ve a: http://localhost:8081/admin/settings.php?tab=dns"
echo "O: https://pihole.terrerov.com/admin/settings.php?tab=dns"
echo "Contraseña: 100A.soledad1"
echo ""

echo "En la sección 'Local DNS Records', agrega estos registros:"
echo ""
echo "DOMINIO                    →    IP"
echo "─────────────────────────────────────────────"

# Dominios principales que apuntan al nodo maestro (donde está Traefik)
domains=(
    "terrerov.com"
    "www.terrerov.com"
    "hq.terrerov.com"
    "n8n.terrerov.com"
    "traefik.terrerov.com"
    "pihole.terrerov.com"
    "api.terrerov.com"
    "admin.terrerov.com"
    "dashboard.terrerov.com"
    "monitoring.terrerov.com"
    "grafana.terrerov.com"
    "prometheus.terrerov.com"
    "registry.terrerov.com"
    "vault.terrerov.com"
    "jenkins.terrerov.com"
    "kibana.terrerov.com"
    "portainer.terrerov.com"
)

for domain in "${domains[@]}"; do
    printf "%-25s →    %s\n" "$domain" "$RPI_IP"
done

echo ""
echo "🔧 === CÓMO AGREGAR EN PI-HOLE ==="
echo "1. Ve a la interfaz web de Pi-hole: http://localhost:8081/admin/"
echo "2. Inicia sesión con contraseña: 100A.soledad1"
echo "3. Ve a Settings → DNS → Local DNS Records"
echo "4. Para cada dominio de arriba:"
echo "   - Domain: [nombre del dominio]"
echo "   - IP Address: $RPI_IP"
echo "   - Click 'Add'"
echo ""

echo "📋 === FORMATO PARA COPIAR/PEGAR ==="
echo "Si Pi-hole permite importar en formato hosts, usa este formato:"
echo ""

for domain in "${domains[@]}"; do
    echo "$RPI_IP $domain"
done

echo ""
echo "🔍 === VERIFICACIÓN ==="
echo "Después de configurar, puedes probar con:"
echo "• nslookup terrerov.com $RPI_IP:$PIHOLE_NODEPORT"
echo "• nslookup n8n.terrerov.com $RPI_IP:$PIHOLE_NODEPORT"
echo ""

echo "📖 === ARCHIVO LOCAL PARA REFERENCIA ==="
echo "También se guarda en: /tmp/pihole-dns-records.txt"

# Guardar en archivo para referencia
cat > /tmp/pihole-dns-records.txt << EOF
# Configuración DNS local para Pi-hole
# Proyecto: Surviving Chernarus
# Fecha: $(date)
#
# Todos estos dominios deben apuntar a: $RPI_IP
# (IP del nodo maestro donde está Traefik)

EOF

for domain in "${domains[@]}"; do
    echo "$RPI_IP $domain" >> /tmp/pihole-dns-records.txt
done

echo "✅ Archivo guardado en: /tmp/pihole-dns-records.txt"
echo ""

echo "🚀 === ACCESO A PI-HOLE ==="
echo "• Web Interface: http://localhost:8081/admin/"
echo "• Contraseña: 100A.soledad1"
echo "• URL alternativa: https://pihole.terrerov.com/admin/"
echo ""

echo "🎯 === RESULTADO ESPERADO ==="
echo "Una vez configurado, desde tu red local:"
echo "• terrerov.com → $RPI_IP (Traefik → Hugo Dashboard)"
echo "• n8n.terrerov.com → $RPI_IP (Traefik → N8N)"
echo "• pihole.terrerov.com → $RPI_IP (Traefik → Pi-hole Web)"
echo ""
echo "Desde internet público:"
echo "• *.terrerov.com → Tu IP pública (via Cloudflare)"
echo ""

echo "🛡️ === CONFIGURACIÓN COMPLETADA ==="
