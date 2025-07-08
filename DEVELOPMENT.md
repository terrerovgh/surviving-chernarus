# Surviving Chernarus - Desarrollo y Configuración

## Flujos de Desarrollo

### Configuración Inicial

```bash
cp .env.example .env  # O copiar el .env base
# Editar .env con tus valores reales
./scripts/process-configs.sh  # Procesa plantillas con variables de entorno
./scripts/process-configs.sh --validate  # Valida configuración crítica
```

### Levantar Entorno Local

```bash
./scripts/process-configs.sh && docker-compose up -d
# Verificar estado y logs
docker-compose ps
docker-compose logs -f
```

### Variables de Entorno Clave (ejemplo)

- YOUR_DOMAIN_NAME=terrerov.com
- ADMIN_EMAIL=terrerov@gmail.com
- POSTGRES_HOST=database_server
- POSTGRES_USER=chernarus_op
- POSTGRES_PASSWORD=\*\*\*
- N8N_ENCRYPTION_KEY=\*\*\*
- TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL=terrerov@gmail.com
- CLOUDFLARE_API_TOKEN=\*\*\*
- PIHOLE_WEBPASSWORD=\*\*\*
- GRAFANA_ADMIN_PASSWORD=\*\*\*

### Scripts Útiles

- `scripts/process-configs.sh`: Procesa plantillas y valida configuración
- `scripts/deploy-project.sh`: Despliega proyectos web
- `scripts/deploy-rpi.sh`: Despliegue en producción (Raspberry Pi)
- `scripts/backup-chernarus.sh` y `restore-chernarus.sh`: Backups y restauración
- `scripts/monitor-services.sh`: Monitoreo de servicios

### Despliegue en Producción

```bash
# En el nodo rpi
./scripts/deploy-rpi.sh
kubectl get pods -A
kubectl get ingress -A
```

## Estructura de Carpetas

- `/services/`: Configuración de servicios (nginx, traefik, pihole, squid, etc.)
- `/scripts/`: Scripts de automatización y mantenimiento
- `/docs/`: Documentación y reglas
- `/src/`: Código fuente de proyectos
- `/kubernetes/`: Manifiestos y configuraciones K8s

## Buenas Prácticas

- Mantener `.env` actualizado y seguro
- Usar scripts para automatizar tareas
- Validar configuración antes de desplegar
- Documentar cambios relevantes

## Última actualización: Julio 2025
