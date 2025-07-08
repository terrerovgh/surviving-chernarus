# Manifiestos de Kubernetes para el Colectivo Chernarus

Este directorio contiene todos los manifiestos YAML para desplegar los servicios en el clúster K3s.

- `apps/`: Contiene los manifiestos para cada aplicación principal (n8n, postgres, etc.).
- `core/`: Contiene configuraciones del clúster (Ingress, almacenamiento, etc.).

**Comando de Despliegue:** `kubectl apply -k ./apps/nombre-app` (usando Kustomize) o `kubectl apply -f ./apps/nombre-app/manifest.yaml`.

## Estructura de Directorios

```
kubernetes/
├── apps/
│   ├── postgresql/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   ├── n8n/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── traefik/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── pihole/
│       ├── kustomization.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
└── core/
    ├── namespaces.yaml
    ├── storage-class.yaml
    ├── network-policies.yaml
    └── secrets/
        ├── kustomization.yaml
        └── sealed-secrets.yaml
```

## Comandos Útiles

### Despliegue

```bash
# Aplicar todas las configuraciones core
kubectl apply -f ./core/

# Desplegar una aplicación específica
kubectl apply -k ./apps/postgresql/

# Desplegar todas las aplicaciones
find ./apps -name "kustomization.yaml" -execdir kubectl apply -k . \;
```

### Monitoreo

```bash
# Ver todos los pods
kubectl get pods -A

# Ver logs de un servicio
kubectl logs -f deployment/n8n-engine -n chernarus

# Ver eventos del clúster
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Troubleshooting

```bash
# Describir un pod problemático
kubectl describe pod <pod-name> -n <namespace>

# Acceder a un container
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Ver configuración de un servicio
kubectl get svc <service-name> -n <namespace> -o yaml
```

## TODO: Configuraciones Pendientes

- [ ] Configurar almacenamiento persistente con Longhorn
- [ ] Implementar network policies para segmentación
- [ ] Añadir HPA (Horizontal Pod Autoscaler) para servicios críticos
- [ ] Configurar backup automático con Velero
- [ ] Implementar monitoring con Prometheus Operator
