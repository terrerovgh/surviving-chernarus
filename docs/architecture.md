# Arquitectura del Colectivo Chernarus

## 📊 Estado Actual - PRODUCCIÓN OPERATIVA ✅

**Cluster Status**: Kubernetes v1.33.2 - 2 nodos activos **Última
Verificación**: Julio 8, 2025 **Servicios**: Todos operativos y sirviendo
tráfico

## Visión General

El sistema opera como un **cluster híbrido Kubernetes completamente funcional**
distribuido en dos nodos físicos:

- **rpi (Master, rpi.terrerov.com):** Raspberry Pi 5 ✅ Ready. Control plane K8s,
  servicios de red (Traefik, Pi-hole).
- **lenlab (Worker, lenlab.terrerov.com):** Laptop Lenovo ✅ Ready. Cargas pesadas
  (PostgreSQL, n8n, Prometheus, Grafana, aplicaciones web).ura del Colectivo
  Chernarus

## Visión General

El sistema opera en un clúster híbrido (K3s + Docker Compose) distribuido en dos
nodos:

- **rpi (Master, rpi.terrerov.com):** Raspberry Pi 5. Orquesta el clúster, servicios
  de red (hostapd, nftables, Pi-hole, Traefik).
- **lenlab (Worker, lenlab.terrerov.com):** Laptop Lenovo. Ejecuta cargas pesadas
  (PostgreSQL, n8n, Prometheus, Grafana, Squid, Hugo, proyectos web).

## Servicios Principales - **ESTADO DE PRODUCCIÓN**

- **Traefik:** Ingress Controller y reverse proxy ✅ **OPERATIVO**
- **PostgreSQL:** Base de datos central ✅ **FUNCIONANDO**
- **n8n:** Orquestador de automatización ✅ **EJECUTANDO WORKFLOWS**
- **Pi-hole:** DNS seguro ✅ **FILTRANDO AMENAZAS**
- **Squid:** Proxy (Berezino Checkpoint) ✅ **PROXY ACTIVO**
- **Hugo:** Dashboard estático ✅ **SIRVIENDO HQ**
- **Prometheus/Grafana:** Monitoreo ✅ **RECOLECTANDO MÉTRICAS**

## Topología de Red - **CLUSTER ACTIVO**

```
Internet (Cloudflare) ✅ SSL + DNS
   │
   ▼
Traefik (Kubernetes Ingress) ✅ BALANCEANDO
   ├── HQ Dashboard (Hugo) ✅ https://terrerov.com
   ├── n8n Engine ✅ https://n8n.terrerov.com
   ├── Web Projects ✅ https://cts.terrerov.com
   └── Pi-hole DNS ✅ SEGURIDAD ACTIVA
        │
        └── PostgreSQL, Squid, Prometheus, Grafana ✅ OPERATIVOS
```

## Automatización y CI/CD - **FUNCIONANDO**

- **n8n**: Workflows internos ✅ **EJECUTANDO AUTOMACIÓN**
- **GitHub Actions**: CI/CD ✅ **DESPLEGANDO CAMBIOS**
- **Scripts**: Despliegue, backups, monitoreo ✅ **AUTOMATIZADOS**

## Seguridad - **ACTIVA**

- SSL en todos los servicios ✅ **CERTIFICADOS VÁLIDOS**
- Firewall y Pi-hole como defensa ✅ **BLOQUEANDO AMENAZAS**
- Backups automáticos y cifrados ✅ **RESPALDANDO DATOS**

## Última actualización: Julio 8, 2025 - **CLUSTER KUBERNETES PRODUCTIVO**
