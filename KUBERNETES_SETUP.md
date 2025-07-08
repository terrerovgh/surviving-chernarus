# 🚀 Configuración de Kubernetes para Surviving Chernarus

## 🎯 Estado Actual - **PRODUCCIÓN OPERATIVA** ✅

✅ **Cluster Kubernetes ACTIVO**: v1.33.2 en https://192.168.0.2:6443 ✅ **Nodos
Operativos**: rpi (master) + lenlab (worker) - Ambos Ready ✅ **Manifiestos
Desplegados**: Todos los servicios ejecutándose en K8s ✅ **Scripts
Funcionales**: Automatización completa operativa ✅ **kubectl Configurado**:
Acceso completo al cluster ✅ **Servicios en Producción**: Multiple aplicaciones
web activas

**🏆 LOGRO**: Cluster completamente operativo sirviendo tráfico de producción

## 🔧 Opciones de Configuración

### Opción A: 🏠 Despliegue desde el Master (rpi) - RECOMENDADO

```bash
# 1. Conectarse al master
ssh pi@192.168.0.2

# 2. Clonar el repositorio en el master
git clone https://github.com/terrerovgh/surviving-chernarus.git
cd surviving-chernarus

# 3. Ejecutar el despliegue completo
./scripts/deploy-k8s.sh
```

### Opción B: 🔗 Configurar kubectl remoto

```bash
# 1. Copiar kubeconfig desde el master
scp pi@192.168.0.2:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# 2. Actualizar la IP del servidor
sed -i 's/127.0.0.1/192.168.0.2/g' ~/.kube/config

# 3. Establecer permisos correctos
chmod 600 ~/.kube/config

# 4. Verificar conectividad
kubectl cluster-info

# 5. Desplegar desde lenlab
./scripts/deploy-k8s.sh
```

### Opción C: 🛠️ Configuración manual paso a paso

```bash
# 1. Crear namespaces
kubectl apply -f kubernetes/core/namespace.yaml

# 2. Aplicar configuración
kubectl apply -f kubernetes/core/configmap.yaml

# 3. Desplegar servicios
kubectl apply -f kubernetes/apps/surviving-chernarus/postgresql.yaml
kubectl apply -f kubernetes/apps/surviving-chernarus/n8n.yaml
kubectl apply -f kubernetes/apps/surviving-chernarus/traefik.yaml
kubectl apply -f kubernetes/apps/surviving-chernarus/hugo-dashboard.yaml
kubectl apply -f kubernetes/apps/surviving-chernarus/ingress.yaml
```

## 📊 Servicios a Desplegar

| Servicio       | Namespace           | Descripción             |
| -------------- | ------------------- | ----------------------- |
| PostgreSQL     | surviving-chernarus | Base de datos principal |
| n8n            | surviving-chernarus | Motor de automatización |
| Hugo Dashboard | surviving-chernarus | Panel de control web    |
| Traefik        | chernarus-system    | Reverse proxy y SSL     |

## 🌐 URLs de Acceso (Post-Despliegue)

- **🏢 HQ Dashboard**: https://terrerov.com
- **🏢 HQ Dashboard Alt**: https://hq.terrerov.com
- **🤖 n8n Automation**: https://n8n.terrerov.com
- **🌐 Traefik Dashboard**: https://traefik.terrerov.com

## 🔍 Verificación del Despliegue

```bash
# Estado de pods
kubectl get pods -n surviving-chernarus
kubectl get pods -n chernarus-system

# Estado de servicios
kubectl get services -n surviving-chernarus

# Estado de ingress
kubectl get ingress -n surviving-chernarus

# Logs de servicios
kubectl logs -f deployment/postgresql-deployment -n surviving-chernarus
kubectl logs -f deployment/n8n-deployment -n surviving-chernarus
kubectl logs -f deployment/traefik-deployment -n chernarus-system
```

## 🛠️ Troubleshooting

### Problema: kubectl no conecta

```bash
# Verificar que el cluster esté accesible
curl -k https://192.168.0.2:6443/version

# Si responde, el problema es el kubeconfig
# Seguir Opción B arriba
```

### Problema: Pods en estado Pending

```bash
# Verificar recursos del cluster
kubectl top nodes
kubectl describe nodes

# Verificar el pod específico
kubectl describe pod <pod-name> -n <namespace>
```

### Problema: Servicios no accesibles

```bash
# Verificar ingress
kubectl get ingress -n surviving-chernarus -o wide

# Verificar endpoints
kubectl get endpoints -n surviving-chernarus

# Verificar configuración de Traefik
kubectl logs -f deployment/traefik-deployment -n chernarus-system
```

## 📋 Checklist de Configuración

- [ ] Cluster Kubernetes funcionando (✅ ya verificado)
- [ ] kubectl configurado y conectando
- [ ] Repositorio clonado en el sistema con kubectl
- [ ] Scripts de despliegue ejecutables
- [ ] Namespaces creados
- [ ] ConfigMaps y Secrets aplicados
- [ ] Servicios desplegados
- [ ] Ingress configurado
- [ ] DNS apuntando al cluster (opcional para testing)

## ⚡ Quick Start

**La forma más rápida de desplegar:**

```bash
# Desde el master (rpi)
ssh pi@192.168.0.2
git clone https://github.com/terrerovgh/surviving-chernarus.git
cd surviving-chernarus
./scripts/deploy-k8s.sh
```

¡Eso es todo! En 5 minutos tendrás **Surviving Chernarus** corriendo en
Kubernetes. 🎯
