# Reglas del Proyecto: Surviving Chernarus

## Filosofía y Contexto

- Ecosistema digital personal, automatizado y seguro
- Clúster híbrido: Raspberry Pi 5 (rpi) + Lenovo (lenlab)
- Servicios core: PostgreSQL, n8n, Traefik, Pi-hole, Squid, Hugo, Prometheus,
  Grafana
- Automatización: n8n, scripts, GitHub Actions
- Dominio: terrerov.com y subdominios temáticos

## Directrices de Desarrollo

1. **Seguridad:**
   - Credenciales y secretos solo en `.env`
   - SSL/TLS en todos los servicios
   - Firewall restrictivo y Pi-hole como DNS seguro
   - Backups automáticos y cifrados
2. **Automatización:**
   - n8n como cerebro central
   - CI/CD con GitHub Actions
   - Scripts para mantenimiento y monitoreo
   - Alertas vía Telegram
3. **Personalización:**
   - Interfaces temáticas y dashboards
   - Integración con servicios personales
   - Gamificación de tareas
4. **Escalabilidad y Observabilidad:**
   - Prometheus/Grafana para métricas
   - Logs centralizados
   - Health checks y auto-recuperación
   - Documentación actualizada

## Flujo de Trabajo

### Desarrollo Local (lenlab)

1. `docker-compose up -d` para levantar el stack
2. Probar cambios localmente
3. Push a GitHub activa CI/CD

### Producción (rpi + lenlab)

1. Despliegue con scripts/deploy-rpi.sh
2. Monitoreo y backups automáticos

## Última actualización: Julio 2025
