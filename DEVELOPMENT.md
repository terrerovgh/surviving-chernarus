# Surviving Chernarus - Desarrollo y Configuración

## 🎯 Estado Actual - PRODUCCIÓN KUBERNETES ✅

**Cluster**: Kubernetes v1.33.2 activo (rpi + lenlab) **Método de Deploy**:
Kubernetes manifests + scripts automatizados **Entorno de Desarrollo**: Docker
Compose (local) + Kubernetes (producción)

## Flujos de Desarrollo

### Configuración Inicial - **KUBERNETES READY**

```bash
cp .env.example .env  # O copiar el .env base
# Editar .env con tus valores reales
./scripts/process-configs.sh  # Procesa plantillas con variables de entorno
./scripts/process-configs.sh --validate  # Valida configuración crítica

# Para Kubernetes (PRODUCCIÓN)
./scripts/get-kubeconfig.sh  # Configurar acceso kubectl
kubectl cluster-info  # Verificar conectividad
```

### Levantar Entorno Local (Desarrollo)

```bash
./scripts/process-configs.sh && docker-compose up -d
# Verificar estado y logs
docker-compose ps
docker-compose logs -f
```

### Desplegar en Kubernetes (Producción) - **MÉTODO ACTIVO**

```bash
# Verificar estado del cluster
kubectl get nodes -o wide

# Desplegar servicios
./scripts/deploy-k8s.sh

# Verificar despliegue
kubectl get pods -n surviving-chernarus
kubectl get ingress -A
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

### Scripts Útiles - **KUBERNETES OPTIMIZADOS**

- `scripts/process-configs.sh`: Procesa plantillas y valida configuración ✅
- `scripts/deploy-k8s.sh`: **Despliegue en Kubernetes (MÉTODO PRINCIPAL)** ✅
- `scripts/get-kubeconfig.sh`: Configurar acceso kubectl ✅
- `scripts/cluster-status.sh`: Estado del cluster Kubernetes ✅
- `scripts/health-check.sh`: Health check completo del sistema ✅
- `scripts/backup-chernarus.sh` y `restore-chernarus.sh`: Backups y restauración
  ✅
- `scripts/monitor-services.sh`: Monitoreo de servicios ✅

### Despliegue en Producción - **KUBERNETES CLUSTER ACTIVO**

```bash
# Verificar cluster (SIEMPRE PRIMERO)
kubectl get nodes
kubectl get pods -A

# Desplegar en Kubernetes
./scripts/deploy-k8s.sh

# Verificar servicios
kubectl get ingress -A
kubectl get svc -A

# Logs en tiempo real
kubectl logs -f deployment/traefik -n kube-system
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
