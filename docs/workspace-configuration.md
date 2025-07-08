# 🛠️ Configuración del Workspace - Surviving Chernarus

Este documento describe la configuración optimizada del workspace para mejorar la productividad con GitHub Copilot, agentes de IA y herramientas de desarrollo modernas.

## 📋 Índice

1. [Estructura del Workspace](#estructura-del-workspace)
2. [Configuración de VS Code](#configuración-de-vs-code)
3. [GitHub Actions y CI/CD](#github-actions-y-cicd)
4. [Guía de Uso](#guía-de-uso)
5. [Extensiones Recomendadas](#extensiones-recomendadas)
6. [Troubleshooting](#troubleshooting)

## 🏗️ Estructura del Workspace

```
surviving-chernarus/
├── .vscode/                    # Configuración de VS Code
│   ├── settings.json          # Configuración principal
│   ├── extensions.json        # Extensiones recomendadas
│   ├── launch.json           # Configuraciones de debugging
│   ├── tasks.json            # Tareas predefinidas
│   └── snippets.code-snippets # Snippets personalizados
├── .github/                   # GitHub Actions y templates
│   ├── workflows/            # CI/CD pipelines
│   │   ├── ci-cd.yml        # Pipeline principal
│   │   └── k8s-health-check.yml # Health checks
│   └── ISSUE_TEMPLATE/       # Templates de issues
│       └── bug_report.yml    # Template para bugs
└── surviving-chernarus.code-workspace # Workspace principal
```

## ⚙️ Configuración de VS Code

### 📄 settings.json

Configuración principal que incluye:

```json
{
  "github.copilot.enable": true,
  "github.copilot.editor.enableAutoCompletions": true,
  "github.copilot.chat.enable": true,
  "workbench.editor.enablePreview": false,
  "files.associations": {
    "*.yml": "yaml",
    "*.yaml": "yaml",
    "*docker-compose*": "yaml",
    "Dockerfile*": "dockerfile",
    "*.sh": "shellscript",
    "*.conf": "nginx",
    "*.service": "systemd"
  }
}
```

**Características principales:**

- ✅ GitHub Copilot completamente habilitado
- ✅ Asociaciones de archivos optimizadas
- ✅ Formateo automático al guardar
- ✅ Schemas YAML para Kubernetes y Docker Compose
- ✅ Configuración optimizada para archivos de infraestructura

### 🧩 extensions.json

Extensiones recomendadas automáticamente:

| Extensión           | Propósito         | ID                                            |
| ------------------- | ----------------- | --------------------------------------------- |
| GitHub Copilot      | IA Assistant      | `GitHub.copilot`                              |
| GitHub Copilot Chat | Chat IA           | `GitHub.copilot-chat`                         |
| Docker              | Container support | `ms-azuretools.vscode-docker`                 |
| Kubernetes          | K8s management    | `ms-kubernetes-tools.vscode-kubernetes-tools` |
| YAML                | YAML syntax       | `redhat.vscode-yaml`                          |
| ShellCheck          | Shell linting     | `timonwong.shellcheck`                        |
| Prettier            | Code formatting   | `esbenp.prettier-vscode`                      |

### 🚀 launch.json

Configuraciones de debugging preconfiguradas:

1. **Shell Script Debugger**

   - Debug de scripts bash
   - Breakpoints y step-through
   - Variables inspection

2. **Python Debugger**

   - Debug de scripts Python
   - Configuración para diferentes entornos

3. **Docker Container Attach**

   - Debug dentro de containers
   - Configuración para servicios específicos

4. **Node.js/Kubernetes Apps**
   - Debug de aplicaciones en K8s
   - Port forwarding automático

### 📋 tasks.json

Tareas predefinidas optimizadas para el proyecto Surviving Chernarus:

#### 🚀 Infrastructure Deployment

- **🚀 Deploy Chernarus Services**: Deploy completo con `docker-compose up -d`
- **🛑 Stop Chernarus Services**: Parada limpia de todos los servicios
- **🔄 Restart Chernarus Services**: Reinicio de servicios activos
- **🔄 Update Chernarus Stack**: Actualización con pull de imágenes

#### 📊 Monitoring & Health Checks

- **📊 Chernarus Health Check**: Verificación completa (Docker + K8s + Red)
- **🌐 Check Traefik Dashboard**: Estado del reverse proxy y rutas
- **🗄️ PostgreSQL Health Check**: Conectividad de base de datos
- **🤖 n8n Workflow Status**: Estado del motor de automatización
- **🛡️ Pi-hole DNS Status**: Verificación del DNS seguro
- **📈 Monitoring Stack Status**: Estado de Prometheus/Grafana

#### ☸️ Kubernetes Operations

- **🏗️ Setup Kubernetes Master (rpi)**: Configuración automática del master
- **👥 Join Kubernetes Worker (lenlab)**: Agregar worker al cluster
- **Check Kubernetes Cluster Status**: Estado detallado del cluster
- **Deploy to Kubernetes**: Deploy de manifests

#### 🔧 Maintenance & Operations

- **💾 Full Chernarus Backup**: Backup completo (Docker + K8s + configs)
- **🧹 Cleanup Old Backups**: Limpieza de backups antiguos (>30 días)
- **Clean Docker Environment**: Limpieza de Docker y recursos
- **🔍 Diagnose Network Issues**: Diagnósticos de red y DNS

#### 📝 Development & Quality

- **📝 View Service Logs**: Logs en tiempo real de todos los servicios
- **Lint Shell Scripts**: ShellCheck en todos los scripts
- **Format Markdown Files**: Formateo de documentación
- **Generate Documentation**: Actualización automática de docs

### 🔧 snippets.code-snippets

Snippets personalizados optimizados para la infraestructura Chernarus:

#### Docker Compose & Chernarus Services

- `dc-service`: Template básico de servicio Docker
- `chernarus-service`: Template completo para servicios Chernarus (con Traefik labels, PostgreSQL, etc.)
- `docker-network`: Configuración de red
- `docker-volume`: Configuración de volumen

#### Kubernetes & Cluster Management

- `k8s-deployment`: Template básico de Deployment
- `k8s-chernarus-app`: Template completo para aplicaciones Chernarus con nodeSelector, recursos, health checks
- `k8s-service`: Template de Service
- `k8s-ingress`: Template de Ingress
- `k8s-namespace`: Template de Namespace

#### Shell Scripts & Automation

- `bash-header`: Header estándar para scripts Chernarus
- `chernarus-backup`: Script completo de backup para infraestructura
- `error-handling`: Manejo de errores robusto
- `logging-function`: Función de logging con colores

#### n8n Workflows & Automation

- `n8n-workflow`: Template completo de workflow n8n con triggers, HTTP requests y notificaciones Telegram

#### Monitoring & Observability

- `prometheus-alert`: Reglas de alertas específicas para servicios Chernarus
- `grafana-panel`: Configuración de panel de Grafana para monitoreo

#### Network & Proxy Configuration

- `traefik-route`: Configuración de rutas Traefik con SSL
- `nginx-server`: Server block Nginx optimizado para Chernarus
- `logging-function`: Función de logging

#### Nginx/Traefik

- `nginx-proxy`: Configuración de proxy
- `traefik-service`: Service de Traefik
- `ssl-config`: Configuración SSL

## 🚀 GitHub Actions y CI/CD

### 📄 ci-cd.yml

Pipeline completo de CI/CD que incluye:

```yaml
name: CI/CD Pipeline
on: [push, pull_request]
jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
      - name: Lint Shell Scripts
      - name: Test Docker Compose
      - name: Validate Kubernetes Manifests
      - name: Security Scan

  build-and-deploy:
    needs: lint-and-test
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Build Images
      - name: Deploy to Staging
      - name: Run Integration Tests
      - name: Deploy to Production
```

**Características:**

- ✅ Linting automático de scripts y configs
- ✅ Testing de Docker Compose y K8s
- ✅ Security scanning con Trivy
- ✅ Deploy automático por ambiente
- ✅ Rollback automático en caso de fallo

### 📄 k8s-health-check.yml

Health check automático del cluster:

```yaml
name: Kubernetes Health Check
on:
  schedule:
    - cron: "*/30 * * * *" # Cada 30 minutos
  workflow_dispatch:
```

**Funcionalidades:**

- ✅ Verificación periódica del cluster
- ✅ Alertas automáticas por Slack/Email
- ✅ Reportes de estado detallados
- ✅ Trigger manual disponible

### 📝 Issue Templates

Templates estructurados para mejor gestión:

#### bug_report.yml

```yaml
name: Bug Report
description: Reportar un bug en el sistema
body:
  - type: dropdown
    id: environment
    attributes:
      label: Environment
      options:
        - Development
        - Staging
        - Production
        - Kubernetes Cluster
```

## 📖 Guía de Uso

### 🚀 Primeros Pasos

1. **Abrir Workspace**

   ```bash
   code surviving-chernarus.code-workspace
   ```

2. **Instalar Extensiones**

   - VS Code mostrará notificación automática
   - Clic en "Install All" para extensiones recomendadas

3. **Verificar Configuración**
   - GitHub Copilot debe estar activo (ícono en status bar)
   - Autocompletado debe funcionar en archivos YAML/Shell

### 🛠️ Usando Tareas Predefinidas

1. **Ejecutar Tarea**

   ```
   Ctrl+Shift+P → "Tasks: Run Task"
   ```

2. **Tareas Comunes**
   - `🚀 Deploy Chernarus Services`: Deploy completo
   - `📊 Check Services Status`: Estado de servicios
   - `🔄 Restart Services`: Reinicio de servicios
   - `📝 View Logs`: Logs en tiempo real

### 🔧 Usando Snippets

1. **En archivos YAML**

   - Escribir `k8s-deployment` + Tab
   - Escribir `docker-service` + Tab

2. **En scripts de shell**

   - Escribir `bash-header` + Tab
   - Escribir `error-handling` + Tab

3. **En archivos de configuración**
   - Escribir `nginx-proxy` + Tab
   - Escribir `traefik-service` + Tab

### 🐛 Debugging

1. **Scripts de Shell**

   - Abrir script `.sh`
   - Colocar breakpoints (F9)
   - F5 → Seleccionar "Shell Script Debugger"

2. **Python Scripts**

   - Abrir script `.py`
   - F5 → Seleccionar "Python Debugger"

3. **Docker Containers**
   - F5 → Seleccionar "Docker Container Attach"
   - Elegir container activo

## 🔌 Extensiones Recomendadas

### 🤖 IA y Productividad

- **GitHub Copilot**: Asistente de código IA
- **GitHub Copilot Chat**: Chat para consultas de código
- **IntelliCode**: Sugerencias inteligentes

### 🐳 DevOps y Containers

- **Docker**: Gestión completa de containers
- **Kubernetes**: Management de clusters K8s
- **Remote-Containers**: Desarrollo en containers

### 📝 Lenguajes y Formatos

- **YAML**: Syntax highlighting y validación
- **ShellCheck**: Linting de scripts bash
- **Prettier**: Formateo automático
- **Markdown All in One**: Editor completo de Markdown

### 🔧 Herramientas de Desarrollo

- **GitLens**: Git supercharged
- **Python**: Soporte completo para Python
- **REST Client**: Testing de APIs
- **Thunder Client**: Cliente HTTP integrado

### 🎨 UI y Themes

- **Material Icon Theme**: Iconos Material Design
- **One Dark Pro**: Theme oscuro popular
- **Bracket Pair Colorizer**: Coloreado de brackets

## 🔍 Troubleshooting

### ❌ GitHub Copilot no funciona

**Síntomas:**

- No aparecen sugerencias automáticas
- Ícono de Copilot con error en status bar

**Soluciones:**

1. Verificar autenticación:

   ```
   Ctrl+Shift+P → "GitHub Copilot: Sign In"
   ```

2. Reiniciar extensión:

   ```
   Ctrl+Shift+P → "Developer: Reload Window"
   ```

3. Verificar configuración:
   ```json
   {
     "github.copilot.enable": true,
     "github.copilot.editor.enableAutoCompletions": true
   }
   ```

### ❌ Tareas no aparecen

**Síntomas:**

- Lista de tareas vacía
- Error al ejecutar tareas

**Soluciones:**

1. Verificar archivo `tasks.json`:

   ```bash
   ls -la .vscode/tasks.json
   ```

2. Recargar configuración:

   ```
   Ctrl+Shift+P → "Tasks: Configure Task"
   ```

3. Verificar workspace:
   ```
   File → Open Workspace → surviving-chernarus.code-workspace
   ```

### ❌ Snippets no funcionan

**Síntomas:**

- Snippets no aparecen al escribir
- Error de sintaxis en snippets

**Soluciones:**

1. Verificar archivo de snippets:

   ```bash
   cat .vscode/snippets.code-snippets
   ```

2. Validar JSON syntax:

   ```bash
   jq . .vscode/snippets.code-snippets
   ```

3. Reiniciar VS Code:
   ```
   Ctrl+Shift+P → "Developer: Reload Window"
   ```

### ❌ Debugging no funciona

**Síntomas:**

- Breakpoints ignorados
- Debugger no se inicia

**Soluciones:**

1. Verificar configuración `launch.json`
2. Instalar extensiones necesarias (ShellCheck, Python)
3. Verificar permisos de archivos:
   ```bash
   chmod +x script.sh
   ```

### ❌ CI/CD Pipeline falla

**Síntomas:**

- Actions fallan en GitHub
- Error de permisos o dependencias

**Soluciones:**

1. Verificar secrets de GitHub:

   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
   - Otros secrets necesarios

2. Verificar sintaxis de workflows:

   ```bash
   # Usar GitHub CLI para validar
   gh workflow view
   ```

3. Revisar logs detallados en GitHub Actions

## 📊 Monitoreo y Métricas

### 📈 Métricas del Workspace

La configuración incluye tracking automático de:

- Tiempo de desarrollo por tipo de archivo
- Uso de GitHub Copilot y acceptance rate
- Frequency de uso de tareas y snippets
- Errores comunes y resoluciones

### 📊 Dashboard de Productividad

VS Code con las extensiones configuradas proporciona:

- **GitLens**: Insights de contribuciones
- **Wakatime** (opcional): Tracking de tiempo
- **Code Metrics**: Complejidad de código
- **GitHub Integration**: PRs y issues integrados

## 🎯 Próximos Pasos

### 🔮 Mejoras Planificadas

1. **Extensión de Snippets**

   - Más templates para Prometheus/Grafana
   - Snippets para n8n workflows
   - Templates de backup scripts

2. **Debugging Avanzado**

   - Remote debugging para containers
   - Debugging de aplicaciones distribuidas
   - Integration con Kubernetes port-forward

3. **CI/CD Enhancements**

   - Deploy automático por ambiente
   - Testing de performance automático
   - Security scanning más detallado

4. **Workspace Sharing**
   - Configuración sincronizada por equipo
   - Settings profiles por rol
   - Onboarding automático para nuevos devs

### 🤝 Contribuciones

Para mejorar la configuración del workspace:

1. Fork del repositorio
2. Crear feature branch para mejoras
3. Testear configuración exhaustivamente
4. Submit PR con descripción detallada

---

**🎉 Con esta configuración, tienes un workspace completamente optimizado para desarrollo moderno con IA, automatización y mejores prácticas de DevOps.**
