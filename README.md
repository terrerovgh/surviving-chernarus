# 🌟 Surviving Chernarus

<div align="center">

![Version](https://img.shields.io/badge/version-1.5.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Docker](https://img.shields.io/badge/docker-ready-blue.svg)
![Kubernetes](https://img.shields.io/badge/kubernetes-active-green.svg)
![GitHub Copilot](https://img.shields.io/badge/github_copilot-optimized-purple.svg)
![Infrastructure](https://img.shields.io/badge/infrastructure-hybrid-orange.svg)
![Status](https://img.shields.io/badge/status-production-green.svg)

**Plataforma de infraestructura híbrida completamente operativa con cluster
Kubernetes activo, automatización avanzada, SSL automático, monitoreo en tiempo
real y deployment en producción**

**📊 Estado Actual (Julio 2025)**: ✅ PRODUCCIÓN - Cluster Kubernetes v1.33.2
activo con 2 nodos (rpi + lenlab)

[📖 Documentación](#-documentación) • [🚀 Inicio Rápido](#-inicio-rápido) •
[☸️ Kubernetes](#️-kubernetes) • [📊 Monitoring](#-monitoring) •
[🤝 Contribuir](#-contribuir)

</div>

---

- **Load Balancing**: Traefik con detección automática de servicios ✅
## 🎯 ¿Qué es Surviving Chernarus?

Surviving Chernarus es una plataforma de infraestructura híbrida **completamente
operativa en producción** que combina lo mejor de Docker Compose y Kubernetes
para crear un entorno de hosting completo, automatizado y escalable.

**🏆 Estado Actual**: Sistema desplegado y funcionando con cluster Kubernetes
v1.33.2 activo en 2 nodos físicos (Raspberry Pi 5 + servidor x86), sirviendo
múltiples aplicaciones web con SSL automático, monitoreo en tiempo real y
backups automatizados.

### ✨ Características Principales

🔒 **SSL Automático**: Certificados Let's Encrypt con renovación automática vía
Cloudflare ✅ **ACTIVO** 🌐 **Reverse Proxy Inteligente**: Traefik v2 con
configuración dinámica ✅ **OPERATIVO** 📡 **Multi-Proyecto**: Hosting
simultáneo de múltiples sitios web ✅ **FUNCIONANDO** 🤖 **Automatización
Total**: Workflows n8n + GitHub Actions + scripts personalizados ✅
**DESPLEGADO** 📊 **Monitoreo Avanzado**: Stack Prometheus + Grafana con alertas
automáticas ✅ **MONITOREANDO** 💾 **Backups Automáticos**: Sistema de backup
cifrado y programado ✅ **RESPALDANDO** 🐳 **Containerización**: Soporte
completo Docker Compose + Kubernetes ✅ **HÍBRIDO** 🍓 **Cluster Productivo**:
Raspberry Pi 5 + servidor x86 en clúster Kubernetes ✅ **v1.33.2 ACTIVO** 🧠
**AI-Optimized**: Workspace configurado para GitHub Copilot y agentes de IA ✅
**OPTIMIZADO**

---

## 🏗️ Arquitectura del Sistema

<div align="center">

```mermaid
graph TB
    subgraph "☁️ Internet"
        CF[Cloudflare DNS + Proxy]
    end

    subgraph "🌐 Edge Layer"
        TR[Traefik Reverse Proxy<br/>SSL Termination]
    end

    subgraph "🎯 Application Layer"
        HUGO[HQ Dashboard<br/>Hugo Static Site]
        N8N[Automation Engine<br/>n8n Workflows]
        WEB[Web Projects<br/>*.example.com]
        PH[DNS Security<br/>Pi-hole]
    end

    subgraph "🗄️ Data Layer"
        PG[PostgreSQL<br/>Central Database]
        SQUID[Squid Proxy<br/>Berezino Checkpoint]
    end

    subgraph "📊 Monitoring Layer"
        PROM[Prometheus<br/>Metrics Collection]
        GRAF[Grafana<br/>Dashboards]
        BACKUP[Backup System<br/>Automated & Encrypted]
    end

    subgraph "☸️ Infrastructure"
        RPI[rpi - Raspberry Pi 5<br/>Control Plane]
        LENLAB[lenlab - x86 Server<br/>Worker Node]
    end

    CF --> TR
    TR --> HUGO
    TR --> N8N
    TR --> WEB
    TR --> PH

    HUGO --> PG
    N8N --> PG
    WEB --> PG
    WEB --> SQUID

    PROM --> GRAF
    PG --> BACKUP
    N8N --> BACKUP

    RPI -.-> LENLAB
```

</div>

### 🌐 Topología de Red - **ESTADO ACTUAL: PRODUCCIÓN** ✅

- **Master Node (rpi)**: Raspberry Pi 5 - Control plane Kubernetes v1.33.2,
  servicios de red (`rpi.terrerov.com` - 192.168.0.2) ✅ **READY**
- **Worker Node (lenlab)**: Servidor x86 - Cargas pesadas, bases de datos
  (`lenlab.terrerov.com` - 192.168.0.3) ✅ **READY**
- **Networking**: Flannel CNI para comunicación pod-to-pod ✅ **OPERATIVO**
- **Load Balancing**: Traefik con detección automática de servicios ✅
  **BALANCEANDO**

**📊 Cluster Status:**

```bash
NAME     STATUS   ROLES           VERSION   INTERNAL-IP      HOSTNAME
rpi      Ready    control-plane   v1.33.2   192.168.0.2     rpi.terrerov.com
lenlab   Ready    worker          v1.33.2   192.168.0.3     lenlab.terrerov.com
```

### 🌍 Acceso a Servicios

Todos los servicios web están accesibles a través de nombres de dominio:

- **🏠 Dashboard Principal**: `http://terrerov.com`
- **🤖 Automatización N8N**: `http://n8n.terrerov.com`
- **⚡ Traefik Dashboard**: `http://traefik.terrerov.com:8080`
- **🛡️ Pi-hole Admin**: `http://pihole.terrerov.com`

---

## 🚀 Inicio Rápido

### 📋 Prerrequisitos

- **Kubernetes Cluster**: K3s/K8s con kubectl configurado ✅ **DISPONIBLE**
- **Docker & Docker Compose**: v20.10+ (para desarrollo local) ✅ **INSTALADO**
- **Git**: Para clonar el repositorio ✅ **DISPONIBLE**
- **Bash**: Scripts de automatización ✅ **LISTO**

### ⚡ Despliegue en Kubernetes (Producción) - **MÉTODO ACTIVO**

```bash
# 1. Clonar el repositorio
git clone https://github.com/terrerovgh/surviving-chernarus.git
cd surviving-chernarus

# 2. Configurar acceso kubectl (si es desde worker node)
./scripts/get-kubeconfig.sh

# 3. Desplegar en Kubernetes
./scripts/deploy-k8s.sh

# 4. Verificar estado
kubectl get pods -n surviving-chernarus
kubectl get ingress -A
```

### 🐳 Desarrollo Local con Docker

```bash
# Para desarrollo y testing local
cp .env.example .env
# Editar .env con tus valores
./scripts/process-configs.sh
docker-compose up -d
```

### 🎯 Acceder a los Servicios - **URLS DE PRODUCCIÓN** 🌐

**Servicios en Producción (terrerov.com):**

- 🌐 **HQ Dashboard**: https://terrerov.com ✅ **ACTIVO**
- 🤖 **n8n Automation**: https://n8n.terrerov.com ✅ **FUNCIONANDO**
- 🎨 **Cuba Tattoo Studio**: https://cts.terrerov.com ✅ **ONLINE**
- 📊 **Traefik Dashboard**: https://traefik.terrerov.com ✅ **MONITOREANDO**

**Desarrollo Local:**

- 🌐 **Traefik Dashboard**: http://rpi.terrerov.com:8080
- 🤖 **n8n Automation**: http://rpi.terrerov.com:5678 (via Traefik)
- 📊 **Grafana Monitoring**: http://rpi.terrerov.com:3000 (via Traefik)
- 🛡️ **Pi-hole Admin**: http://rpi.terrerov.com/admin
- 🗄️ **PostgreSQL**: lenlab.terrerov.com:5432

---

## ☸️ Despliegue Kubernetes

### 🏗️ Configuración del Cluster

```bash
# Configurar master node (Raspberry Pi)
./scripts/k8s-setup-master.sh

# Obtener comando de join
sudo kubeadm token create --print-join-command

# Agregar worker node
./scripts/k8s-setup-worker.sh <token> <hash>

# Verificar cluster
./scripts/cluster-status.sh
```

### 📊 Estado del Cluster

```bash
kubectl get nodes -o wide
# NAME     STATUS   ROLES           AGE   VERSION   INTERNAL-IP
# rpi      Ready    control-plane   1h    v1.33.2   192.168.0.2
# lenlab   Ready    <none>          45m   v1.33.2   192.168.0.3
```

---

## ⚙️ Configuración

### 🔧 Variables de Entorno

Copia `.env.example` a `.env` y configura:

```bash
# === Configuración Principal ===
DOMAIN=tu-dominio.com
EMAIL=tu-email@dominio.com

# === Base de Datos ===
POSTGRES_DB=chernarus_db
POSTGRES_USER=chernarus_user
POSTGRES_PASSWORD=tu_password_seguro

# === Cloudflare ===
CLOUDFLARE_EMAIL=tu-email@cloudflare.com
CLOUDFLARE_API_TOKEN=tu_api_token

# === Monitoreo ===
GRAFANA_ADMIN_PASSWORD=admin_password
TELEGRAM_BOT_TOKEN=bot_token_opcional
```

### 🌐 Configuración de Resolución de Dominios

**✅ CONFIGURACIÓN COMPLETADA** - Los nombres de dominio están configurados y funcionando:

```bash
# Verificar resolución de nombres
ping rpi.terrerov.com      # ✅ 192.168.0.2 (Master Node)
ping lenlab.terrerov.com   # ✅ 192.168.0.3 (Worker Node)
ping terrerov.com          # ✅ rpi.terrerov.com (Servicios Web)
ping n8n.terrerov.com      # ✅ rpi.terrerov.com (Automatización)
```

**🎯 Dominios Configurados**:
- `rpi.terrerov.com` → Master Node (192.168.0.2)
- `lenlab.terrerov.com` → Worker Node (192.168.0.3)
- `master.terrerov.com` → Alias para Master Node
- `worker.terrerov.com` → Alias para Worker Node
- Todos los servicios web → `rpi.terrerov.com`

**🔧 Para reconfigurar en otro nodo**:
```bash
./scripts/setup-domain-resolution.sh
```

### 📁 Estructura del Proyecto

```
surviving-chernarus/
├── 📄 docker-compose.yml          # Stack principal de servicios
├── 📄 docker-compose-debug.yml    # Stack de desarrollo
├── 📁 services/                   # Configuraciones de servicios
│   ├── 📁 traefik/               # Reverse proxy config
│   ├── 📁 pihole/                # DNS security config
│   ├── 📁 hugo_site/             # Dashboard estático
│   └── 📁 squid/                 # Proxy configuration
├── 📁 kubernetes/                 # Manifests de Kubernetes
│   ├── 📁 core/                  # Servicios core
│   └── 📁 apps/                  # Aplicaciones
├── 📁 scripts/                    # Scripts de automatización
├── 📁 docs/                       # Documentación completa
├── 📁 .vscode/                    # Configuración VS Code
└── 📁 .github/                    # CI/CD workflows
```

---

## 🛠️ Desarrollo y Workspace

### 💻 VS Code Optimizado

El proyecto incluye configuración completa para desarrollo con VS Code:

- ⚙️ **Settings.json**: Configuración optimizada para infraestructura
- 🧩 **Extensions**: Recomendaciones automáticas (Docker, Kubernetes, YAML)
- 🏃 **Tasks**: Tareas predefinidas para deploy, testing, monitoreo
- 🐛 **Debugging**: Configuración para shell, Python, Docker
- ✂️ **Snippets**: Templates para Docker Compose, Kubernetes, scripts

```bash
# Abrir workspace optimizado
code surviving-chernarus.code-workspace
```

### 🤖 GitHub Copilot Ready

Configuración específica para maximizar la efectividad de GitHub Copilot:

- 📝 Asociaciones de archivos optimizadas
- 🎯 Contexto rico del proyecto en documentación
- 🔧 Snippets específicos de la infraestructura
- 📊 Schemas YAML para mejor autocompletado

### 🚀 Tareas Disponibles

Ejecuta `Ctrl+Shift+P` → "Tasks: Run Task":

- **🚀 Deploy Chernarus Services**: Despliegue completo
- **📊 Chernarus Health Check**: Verificación de estado
- **🏗️ Setup Kubernetes Master**: Configuración de K8s
- **💾 Full Chernarus Backup**: Backup completo
- **🔍 Diagnose Network Issues**: Diagnósticos de red

---

## 📊 Monitoreo y Observabilidad

### 📈 Stack de Monitoreo

- **Prometheus**: Recolección de métricas
- **Grafana**: Dashboards y visualización
- **AlertManager**: Gestión de alertas
- **n8n**: Automatización de respuestas

### 🚨 Alertas Automáticas

- 📧 Email notifications
- 📱 Telegram alerts
- 🔄 Auto-healing workflows
- 📊 Performance monitoring

### 🔍 Health Checks

```bash
# Verificar estado completo
./scripts/health-check.sh

# Monitorear servicios
./scripts/monitor-services.sh

# Diagnósticos de red
./scripts/diagnose-traefik.sh
```

---

## 💾 Backup y Recuperación

### 🔄 Backup Automático

```bash
# Backup completo manual
./scripts/backup-chernarus.sh

# Programar backups automáticos
crontab -e
# 0 2 * * * /path/to/surviving-chernarus/scripts/backup-chernarus.sh
```

### 📦 Contenido del Backup

- 🗄️ Volúmenes de Docker
- ☸️ Configuraciones de Kubernetes
- ⚙️ Archivos de configuración
- 📝 Workflows de n8n
- 🔑 Certificados SSL

### 🔄 Restauración

```bash
# Restaurar desde backup
./scripts/restore-chernarus.sh backup_20250708_120000.tar.gz
```

---

## 🔒 Seguridad

### 🛡️ Características de Seguridad

- **SSL/TLS**: Certificados automáticos Let's Encrypt
- **DNS Security**: Pi-hole para bloqueo de dominios maliciosos
- **Network Isolation**: Redes Docker segregadas
- **Secret Management**: Gestión segura de credenciales
- **Firewall**: Configuración restrictiva por defecto
- **Updates**: Actualizaciones automáticas de seguridad

### 🔐 Best Practices

- 🔑 Todas las credenciales en `.env`
- 🌐 SSL en todos los servicios públicos
- 🔄 Backups cifrados automáticos
- 📊 Monitoreo de eventos de seguridad
- 🚫 Acceso restringido por IP cuando sea posible

---

## 📖 Documentación

### 📚 Documentos Principales

- 📄 **[Configuración del Workspace](docs/workspace-configuration.md)**: VS
  Code, Copilot, desarrollo
- 📄 **[Setup de Kubernetes](docs/kubernetes-cluster-setup.md)**: Configuración
  completa del cluster
- 📄 **[Arquitectura del Proyecto](docs/architecture.md)**: Diseño y topología
- 📄 **[Reglas del Proyecto](docs/project_rules.md)**: Directrices y estándares
- 📄 **[Reglas de Usuario](docs/user_rules.md)**: Configuración para Copilot

### 🔗 Enlaces Útiles

- 🐳 [Docker Compose Reference](https://docs.docker.com/compose/)
- ☸️ [Kubernetes Documentation](https://kubernetes.io/docs/)
- 🌐 [Traefik Documentation](https://doc.traefik.io/traefik/)
- 🤖 [n8n Documentation](https://docs.n8n.io/)

---

## 🧪 Testing y CI/CD

### 🔄 Pipeline Automático

GitHub Actions configurado para:

- ✅ **Linting**: ShellCheck, YAML validation
- 🧪 **Testing**: Docker Compose testing
- 🔒 **Security**: Container scanning
- 🚀 **Deploy**: Automated deployment
- 📊 **Monitoring**: Health checks automáticos

### 🏃 Ejecutar Tests

```bash
# Tests locales
./scripts/test-compose.sh

# Validar configuraciones
./scripts/validate-configs.sh

# Test de conectividad
./scripts/test-network.sh
```

---

## 🚨 Troubleshooting

### 🔍 Problemas Comunes

#### Docker no inicia servicios

```bash
# Verificar logs
docker-compose logs

# Reiniciar servicios
docker-compose restart

# Rebuild si es necesario
docker-compose up -d --build
```

#### Problemas de red Kubernetes

```bash
# Verificar nodos
kubectl get nodes

# Verificar pods
kubectl get pods -A

# Reiniciar networking
sudo systemctl restart kubelet
```

#### Problemas de SSL

```bash
# Verificar Traefik
curl -s http://rpi.terrerov.com:8080/api/rawdata | jq '.routers'

# Renovar certificados
docker-compose restart traefik
```

### 📞 Obtener Ayuda

1. 📖 Revisar la documentación en `docs/`
2. 🔍 Buscar en issues existentes
3. 🆕 Crear un nuevo issue con template
4. 💬 Discutir en Discussions

---

## 🤝 Contribuir

### 🌟 Contribuciones Bienvenidas

- 🐛 **Bug reports**: Usa el template de issue
- ✨ **Features**: Propón nuevas funcionalidades
- 📝 **Documentación**: Mejora la documentación
- 🧪 **Testing**: Añade más tests
- 🎨 **UI/UX**: Mejora dashboards y interfaces

### 🔄 Proceso de Contribución

1. 🍴 Fork el repositorio
2. 🌱 Crea una feature branch (`git checkout -b feature/amazing-feature`)
3. 💝 Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. 📤 Push a la branch (`git push origin feature/amazing-feature`)
5. 🔄 Abre un Pull Request

### 📋 Guidelines

- Seguir las convenciones de código existentes
- Añadir tests para nuevas funcionalidades
- Actualizar documentación según sea necesario
- Usar commits descriptivos

---

## 📜 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo
[LICENSE](LICENSE) para detalles.

---

## 🙏 Reconocimientos

- **Traefik**: Por el excelente reverse proxy
- **n8n**: Por la plataforma de automatización
- **Prometheus & Grafana**: Por el stack de monitoreo
- **Kubernetes**: Por la orquestación de containers
- **GitHub Copilot**: Por acelerar el desarrollo

---

## 📊 Estadísticas del Proyecto

![GitHub stars](https://img.shields.io/github/stars/terrerovgh/surviving-chernarus?style=social)
![GitHub forks](https://img.shields.io/github/forks/terrerovgh/surviving-chernarus?style=social)
![GitHub issues](https://img.shields.io/github/issues/terrerovgh/surviving-chernarus)
![GitHub pull requests](https://img.shields.io/github/issues-pr/terrerovgh/surviving-chernarus)

---

<div align="center">

**⭐ Si este proyecto te ha sido útil, considera darle una estrella ⭐**

**Desarrollado con ❤️ por [Víctor Terrero](https://github.com/terrerovgh)**

**🏠 [example.com](https://example.com) • 📧
[admin@example.com](mailto:admin@example.com)**

</div>
