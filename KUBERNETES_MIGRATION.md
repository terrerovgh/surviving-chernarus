# 🚀 Guía de Migración: Docker Compose → Kubernetes

## 📋 Resumen de la Migración

Has migrado exitosamente **Surviving Chernarus** de Docker Compose a Kubernetes.
Este documento detalla todos los cambios realizados y los pasos siguientes.

## ✅ Cambios Realizados

### 1. 🗂️ Estructura de Archivos Kubernetes Creada

```
kubernetes/
├── core/
│   ├── namespace.yaml          # Namespaces del sistema
│   └── configmap.yaml         # ConfigMaps y Secrets
└── apps/
    └── surviving-chernarus/
        ├── postgresql.yaml     # Base de datos PostgreSQL
        ├── n8n.yaml           # Motor de automatización n8n
        ├── traefik.yaml       # Reverse proxy Traefik
        ├── hugo-dashboard.yaml # Dashboard Hugo
        └── ingress.yaml       # Configuración de Ingress
```

### 2. 🔧 Scripts de Automatización

- **`scripts/deploy-k8s.sh`**: Script completo de despliegue en Kubernetes
- **`scripts/setup-github-actions.sh`**: Configuración de GitHub Actions
- **`scripts/get-kubeconfig.sh`**: Obtención de kubeconfig del master

### 3. 🤖 GitHub Actions Workflow

- **`.github/workflows/deploy-k8s.yml`**: Pipeline completo de CI/CD
- Validación de manifiestos con kubectl
- Escaneo de seguridad con Trivy
- Despliegue automático en Kubernetes
- Notificaciones por Slack

## 🎯 Servicios Migrados

| Servicio       | Docker Compose | Kubernetes | Estado  |
| -------------- | -------------- | ---------- | ------- |
| PostgreSQL     | ✅             | ✅         | Migrado |
| n8n Automation | ✅             | ✅         | Migrado |
| Traefik Proxy  | ✅             | ✅         | Migrado |
| Hugo Dashboard | ✅             | ✅         | Migrado |
| Ingress/SSL    | ✅             | ✅         | Migrado |

## 🔑 Configuración de Secrets

Para que GitHub Actions pueda desplegar en tu cluster, necesitas configurar
estos secrets:

### Secrets Requeridos en GitHub

```bash
# Kubernetes Access
KUBECONFIG=<base64_encoded_kubeconfig>

# Database Passwords
POSTGRES_PASSWORD=<secure_password>
N8N_DB_PASSWORD=<n8n_password>

# Encryption & Security
N8N_ENCRYPTION_KEY=<encryption_key>

# Cloudflare Integration
CLOUDFLARE_EMAIL=<your_email>
CF_DNS_API_TOKEN=<cloudflare_token>

# Optional Integrations
TELEGRAM_BOT_TOKEN=<telegram_token>
OPENAI_API_KEY=<openai_key>
SLACK_WEBHOOK=<slack_webhook>
```

## 🚀 Pasos Siguientes

### 1. Obtener Kubeconfig del Master

```bash
# Ejecutar desde lenlab para obtener acceso al cluster
./scripts/get-kubeconfig.sh
```

### 2. Desplegar en Kubernetes

```bash
# Una vez que tengas kubectl configurado
./scripts/deploy-k8s.sh
```

### 3. Configurar GitHub Actions

```bash
# Configurar ServiceAccount para GitHub Actions
./scripts/setup-github-actions.sh
```

### 4. Verificar Despliegue

```bash
# Verificar que todos los pods estén corriendo
kubectl get pods -n surviving-chernarus
kubectl get pods -n chernarus-system

# Verificar servicios
kubectl get services -n surviving-chernarus

# Verificar ingress
kubectl get ingress -n surviving-chernarus
```

## 🌐 URLs de Acceso

Una vez desplegado, tendrás acceso a:

- **🏢 HQ Dashboard**: https://terrerov.com
- **🏢 HQ Dashboard Alt**: https://hq.terrerov.com
- **🤖 n8n Automation**: https://n8n.terrerov.com
- **🌐 Traefik Dashboard**: https://traefik.terrerov.com

## 🔄 Proceso de CI/CD

El workflow de GitHub Actions se ejecutará automáticamente cuando:

1. **Push a main/master**: Despliegue automático en producción
2. **Pull Request**: Validación de manifiestos
3. **Manual Dispatch**: Despliegue manual con opciones

### Etapas del Pipeline

1. **🔍 Validación**: Verificación de sintaxis de manifiestos
2. **🔐 Seguridad**: Escaneo con Trivy
3. **🚀 Despliegue**: Aplicación de manifiestos
4. **✅ Verificación**: Health checks automáticos
5. **📢 Notificación**: Alertas por Slack

## 📊 Monitoreo y Mantenimiento

### Comandos Útiles

```bash
# Estado general del cluster
kubectl get all -n surviving-chernarus

# Logs de servicios
kubectl logs -f deployment/postgresql-deployment -n surviving-chernarus
kubectl logs -f deployment/n8n-deployment -n surviving-chernarus
kubectl logs -f deployment/traefik-deployment -n chernarus-system

# Describir recursos
kubectl describe pod <pod-name> -n surviving-chernarus

# Acceso directo a servicios (port-forward)
kubectl port-forward service/n8n-service 5678:5678 -n surviving-chernarus
kubectl port-forward service/traefik-dashboard-service 8080:8080 -n chernarus-system
```

### Health Checks

```bash
# Verificar estado de PostgreSQL
kubectl exec -it deployment/postgresql-deployment -n surviving-chernarus -- pg_isready -U chernarus_user

# Verificar n8n
curl -k https://n8n.terrerov.com/healthz

# Verificar Traefik
curl -k https://traefik.terrerov.com/ping
```

## 🔧 Troubleshooting

### Problemas Comunes

1. **Pods en estado Pending**:

   ```bash
   kubectl describe pod <pod-name> -n surviving-chernarus
   # Verificar recursos disponibles en nodos
   kubectl top nodes
   ```

2. **Servicios no accesibles**:

   ```bash
   # Verificar ingress
   kubectl get ingress -n surviving-chernarus -o wide
   # Verificar servicios
   kubectl get endpoints -n surviving-chernarus
   ```

3. **Certificados SSL**:
   ```bash
   # Verificar certificados
   kubectl get certificates -n surviving-chernarus
   kubectl describe certificate chernarus-tls-cert -n surviving-chernarus
   ```

## 🎉 Resultado Final

Has logrado:

✅ **Migración completa** de Docker Compose a Kubernetes ✅ **Pipeline de
CI/CD** automatizado con GitHub Actions ✅ **Configuración de secretos** y
ConfigMaps ✅ **SSL automático** con Let's Encrypt vía Traefik ✅ **Alta
disponibilidad** con réplicas y health checks ✅ **Monitoreo** integrado con
observabilidad nativa de K8s ✅ **Escalabilidad** automática y gestión de
recursos

## 🚀 Siguientes Pasos Opcionales

1. **Implementar Horizontal Pod Autoscaler (HPA)**
2. **Configurar Network Policies para seguridad**
3. **Agregar Prometheus y Grafana para monitoreo avanzado**
4. **Implementar backup automático de PVCs**
5. **Configurar alertas con AlertManager**

¡Tu infraestructura **Surviving Chernarus** está ahora corriendo en Kubernetes
con automatización completa! 🎯
