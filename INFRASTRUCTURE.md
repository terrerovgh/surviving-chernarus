# 🌐 Surviving Chernarus - Infrastructure Documentation

## 📊 Estado Actual - PRODUCCIÓN ACTIVA

**Cluster Kubernetes**: ✅ v1.33.2 - 2 nodos operativos **Última
Actualización**: Julio 8, 2025 **Estado de Servicios**: 🟢 Todos operativos

Infraestructura híbrida completamente desplegada y operativa con cluster
Kubernetes de 2 nodos, automatización avanzada, monitoreo en tiempo real,
backups automáticos y seguridad multicapa.

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

## Servicios Principales - **ESTADO DE PRODUCCIÓN**

- **Traefik**: Reverse proxy, SSL, routing ✅ **OPERATIVO**
- **PostgreSQL**: Base de datos central ✅ **FUNCIONANDO**
- **n8n**: Orquestador de automatización ✅ **EJECUTANDO WORKFLOWS**
- **Pi-hole**: DNS seguro ✅ **FILTRANDO AMENAZAS**
- **Squid**: Proxy de red ✅ **PROXY ACTIVO**
- **Hugo**: Sitio estático (HQ) ✅ **SIRVIENDO CONTENIDO**
- **Prometheus/Grafana**: Monitoreo y métricas ✅ **RECOLECTANDO DATOS**

## Nodos y Red - **CLUSTER ACTIVO**

- **RPI Master:** 192.168.0.2 ✅ Ready (Control Plane Kubernetes v1.33.2)
- **Lenlab Worker:** 192.168.0.3 ✅ Ready (Worker Node, cargas pesadas)
- **Subred:** 192.168.0.0/24
- **CNI**: Flannel ✅ Pod-to-pod communication
- **Ingress**: Traefik ✅ SSL automático con Cloudflare

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
