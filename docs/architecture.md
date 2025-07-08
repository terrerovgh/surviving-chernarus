# Arquitectura del Colectivo Chernarus

## Visión General

El sistema opera en un clúster híbrido (K3s + Docker Compose) distribuido en dos nodos:

- **rpi (Master, 192.168.0.2):** Raspberry Pi 5. Orquesta el clúster, servicios de red (hostapd, nftables, Pi-hole, Traefik).
- **lenlab (Worker, 192.168.0.3):** Laptop Lenovo. Ejecuta cargas pesadas (PostgreSQL, n8n, Prometheus, Grafana, Squid, Hugo, proyectos web).

## Servicios Principales

- **Traefik:** Ingress Controller y reverse proxy
- **PostgreSQL:** Base de datos central
- **n8n:** Orquestador de automatización
- **Pi-hole:** DNS seguro
- **Squid:** Proxy (Berezino Checkpoint)
- **Hugo:** Dashboard estático
- **Prometheus/Grafana:** Monitoreo

## Topología de Red

```
Internet (Cloudflare)
   │
   ▼
Traefik (rpi)
   ├── HQ Dashboard (Hugo)
   ├── n8n Engine
   ├── Web Projects (*.terrerov.com)
   └── Pi-hole DNS
        │
        └── PostgreSQL, Squid, Prometheus, Grafana
```

## Automatización y CI/CD

- **n8n**: Workflows internos
- **GitHub Actions**: CI/CD
- **Scripts**: Despliegue, backups, monitoreo

## Seguridad

- SSL en todos los servicios
- Firewall y Pi-hole como defensa
- Backups automáticos y cifrados

## Última actualización: Julio 2025
