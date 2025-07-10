# 🌐 Guía de Migración: IPs → Nombres de Dominio

## 📋 Resumen de Cambios

Se ha mejorado la infraestructura **Surviving Chernarus** para usar nombres de dominio en lugar de direcciones IP hardcodeadas, proporcionando mayor flexibilidad y mejor gestión de la red.

## 🔄 Cambios Implementados

### 1. Mapeo de Nombres de Dominio

| Componente | IP Original | Nuevo Dominio | Función |
|------------|-------------|---------------|---------|
| **rpi** | `192.168.0.2` | `rpi.terrerov.com` | Master Node Kubernetes |
| **lenlab** | `192.168.0.3` | `lenlab.terrerov.com` | Worker Node Kubernetes |

### 2. Servicios Principales

Todos los servicios web ahora apuntan a `rpi.terrerov.com`:

- `terrerov.com` → `rpi.terrerov.com`
- `hq.terrerov.com` → `rpi.terrerov.com`
- `n8n.terrerov.com` → `rpi.terrerov.com`
- `traefik.terrerov.com` → `rpi.terrerov.com`
- `pihole.terrerov.com` → `rpi.terrerov.com`

### 3. Servicios Internos Kubernetes

Los servicios internos K8s apuntan a `lenlab.terrerov.com`:

- `postgres.chernarus.local` → `lenlab.terrerov.com`
- `n8n.chernarus.local` → `lenlab.terrerov.com`
- `redis.chernarus.local` → `lenlab.terrerov.com`

## 🛠️ Archivos Modificados

### Configuraciones DNS
- `services/pihole/custom.list` - Actualizada para usar dominios
- `scripts/dns-setup-info.sh` - URLs actualizadas con nombres de dominio

### Scripts de Configuración
- `scripts/k8s-setup-master.sh` - API server con dominio y certificados
- `scripts/setup-rpi.sh` - Configuración de /etc/hosts
- `scripts/setup-lenlab.sh` - Configuración de /etc/hosts
- `scripts/chernarus-status.sh` - URLs de servicios actualizadas

### Variables de Entorno
- `.env.example` - Nuevas variables para hostnames

### Tareas VS Code
- `.vscode/tasks.json` - Comandos de ping usando dominios

## 🚀 Nuevo Script de Configuración

Se ha creado `scripts/setup-domain-resolution.sh` que:

✅ Configura automáticamente `/etc/hosts` en ambos nodos
✅ Mapea todos los servicios a sus dominios correspondientes
✅ Realiza pruebas de conectividad
✅ Proporciona instrucciones claras de configuración

## 📖 Instrucciones de Migración

### 1. Ejecutar Script de Configuración

En **ambos nodos** (rpi y lenlab):

```bash
# Ejecutar en rpi
./scripts/setup-domain-resolution.sh

# Ejecutar en lenlab
./scripts/setup-domain-resolution.sh
```

### 2. Actualizar Configuración del Router

En la configuración DHCP de tu router:

- **DNS Primario**: `rpi.terrerov.com` (192.168.0.2)
- **DNS Secundario**: `lenlab.terrerov.com` (192.168.0.3)

### 3. Verificar Conectividad

```bash
# Probar resolución de nombres
ping rpi.terrerov.com
ping lenlab.terrerov.com
ping terrerov.com

# Probar servicios
curl http://terrerov.com
curl http://n8n.terrerov.com
curl http://traefik.terrerov.com:8080
```

### 4. Actualizar Kubernetes

Si ya tienes un cluster configurado:

```bash
# Actualizar certificados del API server
sudo kubeadm init phase certs apiserver --config /path/to/kubeadm-config.yaml

# Actualizar configuración kubectl
sed -i 's|server: https://192.168.0.2:6443|server: https://rpi.terrerov.com:6443|g' ~/.kube/config
```

## 🔍 Verificación Post-Migración

### Comandos de Verificación

```bash
# 1. Estado del cluster
kubectl get nodes -o wide

# 2. Estado de servicios
kubectl get svc -A

# 3. Estado de Pi-hole DNS
dig @rpi.terrerov.com terrerov.com

# 4. Conectividad web
curl -I http://terrerov.com
```

### Indicadores de Éxito

✅ `kubectl get nodes` muestra ambos nodos como Ready
✅ `ping rpi.terrerov.com` responde desde 192.168.0.2
✅ `ping lenlab.terrerov.com` responde desde 192.168.0.3
✅ `http://terrerov.com` muestra la página principal
✅ `http://n8n.terrerov.com` accede a la interfaz de n8n

## 🆘 Resolución de Problemas

### Problema: "Name or service not known"

**Solución**: Ejecutar el script de configuración de dominios:
```bash
./scripts/setup-domain-resolution.sh
```

### Problema: Certificados SSL inválidos

**Solución**: Regenerar certificados con el nuevo dominio:
```bash
sudo kubeadm init phase certs apiserver --apiserver-cert-extra-sans=rpi.terrerov.com
```

### Problema: Servicios no accesibles

**Verificar**:
1. Estado de Traefik: `kubectl get pods -n chernarus-system`
2. Configuración DNS: `cat /etc/hosts`
3. Conectividad de red: `ping rpi.terrerov.com`

## 🔄 Rollback

Si necesitas volver a la configuración anterior:

```bash
# Restaurar /etc/hosts original
sudo cp /etc/hosts.backup /etc/hosts

# Restaurar configuración kubectl
sed -i 's|server: https://rpi.terrerov.com:6443|server: https://192.168.0.2:6443|g' ~/.kube/config
```

## ✨ Beneficios de la Migración

🎯 **Flexibilidad**: Cambiar IPs sin reconfigurar servicios
🔧 **Mantenimiento**: Configuración más clara y autodocumentada
📈 **Escalabilidad**: Fácil agregar nuevos nodos al cluster
🛡️ **Seguridad**: Mejor gestión de certificados SSL
📖 **Documentación**: URLs más legibles en logs y configuraciones

---

**Fecha de Implementación**: Julio 10, 2025
**Estado**: ✅ Implementado y Verificado
