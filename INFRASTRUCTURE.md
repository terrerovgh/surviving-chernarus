# 🌐 Surviving Chernarus - Infrastructure Documentation

## Resumen

Infraestructura modular y escalable para proyectos web personales, con automatización, monitoreo, backups y seguridad avanzada.

## Arquitectura

```
┌──────────────────────────────────────────────────────────────┐
│                    INTERNET (Cloudflare)                    │
└───────────────┬──────────────────────────────────────────────┘
                │ (DNS + SSL Proxy)
                ▼
┌──────────────────────────────────────────────────────────────┐
│                  Traefik Reverse Proxy                      │
│        (Auto SSL Let's Encrypt, Cloudflare DNS, 80/443)     │
└─────┬─────────────┬──────────────────────┬─────────────┬─────┘
      ▼             ▼                      ▼             ▼
  HQ Dashboard   n8n Engine           Web Projects   Pi-hole DNS
  (Hugo)        (n8n.terrerov.com)    (*.terrerov)   (DNS seguro)
      │             │                      │             │
      └─────┬───────┴──────────────┬──────┘             │
            ▼                      ▼                    │
      PostgreSQL DB           Squid Proxy               │
      (Internal)              (Berezino Checkpoint)     │
            │                                          │
            └─────────────┬────────────────────────────┘
                          ▼
                    Backups/Monitoring
                (Prometheus, Grafana, scripts)
```

## Servicios Principales

- **Traefik**: Reverse proxy, SSL, routing
- **PostgreSQL**: Base de datos central
- **n8n**: Orquestador de automatización
- **Pi-hole**: DNS seguro
- **Squid**: Proxy de red
- **Hugo**: Sitio estático (HQ)
- **Prometheus/Grafana**: Monitoreo y métricas

## Nodos y Red

- **RPI Master:** 192.168.0.2 (servicios de red, orquestación)
- **Lenlab Worker:** 192.168.0.3 (cargas pesadas, DB, IA)
- **Subred:** 192.168.0.0/24

## Seguridad y Backups

- Credenciales y secretos en `.env`
- SSL en todos los servicios
- Backups automáticos y cifrados
- Firewall y Pi-hole como primera línea de defensa

## Automatización y CI/CD

- n8n para flujos internos
- GitHub Actions para despliegue
- Scripts para mantenimiento y monitoreo

## Última actualización: Julio 2025
