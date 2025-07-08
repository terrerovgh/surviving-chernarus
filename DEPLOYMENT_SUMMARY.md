# 🚀 Surviving Chernarus Deployment Summary

## Estado General

- **Dominio principal:** terrerov.com
- **Subdominios activos:**
  - HQ Dashboard: hq.terrerov.com
  - CubaTattooStudio: cts.terrerov.com
  - n8n Automation: n8n.terrerov.com
  - Otros proyectos: \*.terrerov.com

## Infraestructura y Servicios

- **Reverse Proxy:** Traefik v2 (SSL Let's Encrypt, Cloudflare DNS Challenge)
- **Base de datos:** PostgreSQL (chernarus_db)
- **Automatización:** n8n (conexión a PostgreSQL)
- **DNS:** Pi-hole (con Cloudflare)
- **Proxy:** Squid (Berezino Checkpoint)
- **Sitio Estático:** Hugo (HQ Dashboard)
- **Monitoreo:** Prometheus, Grafana
- **CI/CD:** GitHub Actions

## Variables de Entorno Clave

- Red: 192.168.0.0/24
- RPI Master: 192.168.0.2
- Worker: 192.168.0.3
- Cloudflare API Token: (ver .env)
- Traefik SSL Email: admin@yourdomain.com
- PostgreSQL: chernarus_op / chernarus_db
- n8n Encryption Key: Sddfe43f3fscver3

## Estructura de Datos y Volúmenes

- DATA_PATH: /tmp/chernarus/data
- BACKUP_PATH: /tmp/chernarus/backups
- LOG_PATH: /tmp/chernarus/logs
- CONFIG_PATH: /tmp/chernarus/config

## Despliegue y Mantenimiento

- Despliegue: `docker-compose up -d` o scripts/deploy-rpi.sh
- Limpieza: `docker-compose down && docker system prune -f`
- Logs: `docker-compose logs -f`
- Backups: Automáticos, retención 7 días

## Seguridad

- Todas las credenciales y secretos en `.env`
- SSL en todos los servicios expuestos
- Firewall restrictivo y Pi-hole como DNS seguro
- Backups cifrados

## Última actualización: Julio 2025
