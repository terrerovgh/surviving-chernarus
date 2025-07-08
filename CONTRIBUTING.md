# 🤝 Contribuir a Surviving Chernarus

¡Gracias por tu interés en contribuir a Surviving Chernarus! Este documento te guiará a través del proceso de contribución.

## 📋 Tabla de Contenidos

- [Código de Conducta](#-código-de-conducta)
- [¿Cómo Puedo Contribuir?](#-cómo-puedo-contribuir)
- [Configuración del Entorno](#-configuración-del-entorno)
- [Proceso de Contribución](#-proceso-de-contribución)
- [Estándares de Código](#-estándares-de-código)
- [Documentación](#-documentación)
- [Testing](#-testing)

## 📜 Código de Conducta

Este proyecto se adhiere al [Contributor Covenant](https://www.contributor-covenant.org/). Al participar, se espera que mantengas este código. Por favor reporta cualquier comportamiento inaceptable.

## 🎯 ¿Cómo Puedo Contribuir?

### 🐛 Reportar Bugs

Antes de crear un bug report:
- Verifica que el bug no haya sido reportado previamente
- Asegúrate de tener la información más reciente del proyecto

Usa nuestro [template de bug report](.github/ISSUE_TEMPLATE/bug_report.yml) que incluye:
- Información del entorno (rpi, lenlab, versiones)
- Componente afectado (Traefik, PostgreSQL, n8n, etc.)
- Pasos para reproducir
- Comportamiento esperado vs actual
- Logs y mensajes de error

### ✨ Sugerir Features

Usa nuestro [template de feature request](.github/ISSUE_TEMPLATE/feature_request.yml) para:
- Explicar el problema que resuelve la feature
- Describir la solución propuesta
- Considerar alternativas
- Evaluar el impacto en la arquitectura

### 🏗️ Tareas de Infraestructura

Para tareas de infraestructura, usa el [template de infrastructure task](.github/ISSUE_TEMPLATE/infrastructure_task.yml):
- Tipo de tarea (upgrade, mantenimiento, deployment)
- Nodos afectados (rpi, lenlab, ambos)
- Plan de implementación
- Evaluación de riesgo
- Plan de rollback

### 💻 Contribuciones de Código

1. **Fork** el repositorio
2. **Crea** una branch para tu feature (`git checkout -b feature/amazing-feature`)
3. **Commit** tus cambios (`git commit -m 'Add amazing feature'`)
4. **Push** a la branch (`git push origin feature/amazing-feature`)
5. **Abre** un Pull Request

## ⚙️ Configuración del Entorno

### Prerrequisitos

- **Docker & Docker Compose**: v20.10+
- **VS Code**: Recomendado con extensiones del proyecto
- **Git**: Para control de versiones
- **Bash**: Para scripts de automatización
- **Opcional**: Kubernetes cluster para testing avanzado

### Setup Inicial

```bash
# 1. Fork y clonar el repositorio
git clone https://github.com/TU_USERNAME/surviving-chernarus.git
cd surviving-chernarus

# 2. Configurar VS Code workspace
code surviving-chernarus.code-workspace

# 3. Instalar extensiones recomendadas
# VS Code mostrará una notificación automática

# 4. Configurar entorno
cp .env.example .env
# Editar .env con tus valores de desarrollo

# 5. Levantar entorno de desarrollo
docker-compose -f docker-compose-debug.yml up -d
```

### VS Code Setup

El proyecto incluye configuración completa de VS Code:

- **Settings**: Optimizado para infraestructura y GitHub Copilot
- **Extensions**: Auto-recomendación de extensiones necesarias
- **Tasks**: 20+ tareas predefinidas para desarrollo
- **Debugging**: Configurado para shell, Python, Docker
- **Snippets**: Templates para Docker, Kubernetes, scripts

## 🔄 Proceso de Contribución

### 1. Crear una Issue

Para cambios significativos, crea primero una issue para discutir la propuesta.

### 2. Branch Naming

Usa nombres descriptivos para las branches:

```bash
git checkout -b feature/add-prometheus-alerts
git checkout -b fix/traefik-ssl-issue
git checkout -b docs/update-kubernetes-guide
git checkout -b infra/upgrade-postgres-version
```

### 3. Commits

Usa commits descriptivos siguiendo [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat: add Prometheus alerting rules for n8n"
git commit -m "fix: resolve SSL certificate renewal issue"
git commit -m "docs: update Kubernetes setup guide"
git commit -m "infra: upgrade PostgreSQL to version 15"
```

**Tipos de commit:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Documentación
- `infra`: Cambios de infraestructura
- `test`: Añadir o modificar tests
- `refactor`: Refactorización de código
- `style`: Formateo, espacios en blanco, etc.
- `chore`: Mantenimiento, dependencies, etc.

### 4. Pull Request

- Usa un título descriptivo
- Describe los cambios realizados
- Referencia issues relacionadas
- Incluye screenshots si aplica
- Asegúrate de que los tests pasen

## 📏 Estándares de Código

### Shell Scripts

- Usar `#!/bin/bash` al inicio
- Incluir header estándar del proyecto
- Usar `set -euo pipefail` para manejo de errores
- Funciones de logging con colores
- Comentarios explicativos

Ejemplo usando snippet `bash-header`:

```bash
#!/bin/bash
# Script description
# Surviving Chernarus Project
# Author: tu-nombre
# Date: 2025-07-08

set -euo pipefail

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
```

### YAML Files

- Indentación de 2 espacios
- Comentarios para secciones importantes
- Usar quotes para strings que podrían ser interpretados como números
- Validar con `yamllint`

### Docker Compose

- Usar nombres descriptivos para servicios
- Incluir labels de Traefik cuando sea necesario
- Configurar restart policies apropiadas
- Usar networks específicas

### Kubernetes Manifests

- Incluir labels del proyecto: `project: surviving-chernarus`
- Usar nodeSelector para asignación específica (rpi/lenlab)
- Configurar recursos (requests/limits)
- Incluir health checks (liveness/readiness probes)

## 📚 Documentación

### Actualizaciones Requeridas

Al contribuir, actualiza:

- **README.md**: Si añades nueva funcionalidad
- **CHANGELOG.md**: Documenta tus cambios
- **docs/**: Actualiza guías relevantes
- **Comentarios en código**: Para lógica compleja

### Estilo de Documentación

- Usar Markdown
- Incluir emojis para mejor legibilidad
- Screenshots para UI changes
- Ejemplos de código con syntax highlighting
- Enlaces a documentación externa cuando sea relevante

## 🧪 Testing

### Tests Requeridos

Antes de enviar PR, ejecuta:

```bash
# Linting de shell scripts
find scripts/ -name "*.sh" -exec shellcheck {} +

# Validación de YAML
yamllint docker-compose*.yml kubernetes/

# Test de Docker Compose
docker-compose -f docker-compose-debug.yml config

# Test de conectividad (si tienes cluster K8s)
kubectl get nodes
```

### Tests Automáticos

El proyecto incluye GitHub Actions que ejecutan:

- ✅ ShellCheck en todos los scripts
- ✅ Validación de Docker Compose
- ✅ Validación de manifests Kubernetes
- ✅ Security scanning de containers
- ✅ Tests de integración

### Añadir Tests

Para nueva funcionalidad, considera añadir:

- Unit tests para scripts complejos
- Integration tests para servicios
- Health checks para nuevos endpoints
- Validation para nuevas configuraciones

## 🎯 Áreas de Contribución

### 🏗️ Infraestructura

- Nuevos servicios para el stack
- Optimizaciones de performance
- Mejoras de seguridad
- Configuraciones de alta disponibilidad

### 🤖 Automatización

- Nuevos workflows de n8n
- Scripts de mantenimiento
- Herramientas de monitoreo
- Procesos de backup/restore

### 📊 Monitoreo

- Nuevos dashboards de Grafana
- Alertas de Prometheus
- Métricas personalizadas
- Health checks mejorados

### 💻 Developer Experience

- Nuevos snippets de VS Code
- Tareas adicionales
- Configuraciones de debugging
- Templates de código

### 📚 Documentación

- Guías de troubleshooting
- Tutoriales paso a paso
- Mejores prácticas
- Arquitectura y diseño

## 🏷️ Labels de Issues

Usamos estos labels para organizar:

- `bug`: Errores que necesitan corrección
- `enhancement`: Nuevas funcionalidades
- `documentation`: Mejoras de documentación
- `infrastructure`: Tareas de infraestructura
- `good first issue`: Para nuevos contributors
- `help wanted`: Necesitamos ayuda
- `question`: Preguntas sobre el proyecto

## 🎉 Reconocimiento

Los contributors son reconocidos en:

- README.md del proyecto
- CHANGELOG.md para contribuciones significativas
- Hall of Fame (cuando se implemente)

## 📞 ¿Necesitas Ayuda?

- 🐛 **Issues**: Para bugs y features
- 💬 **Discussions**: Para preguntas generales
- 📧 **Email**: victor@terrerov.com para contacto directo

## 📋 Checklist para Contributors

Antes de enviar tu PR, verifica:

- [ ] El código sigue los estándares del proyecto
- [ ] Los tests pasan localmente
- [ ] La documentación está actualizada
- [ ] Los commits siguen la convención
- [ ] No hay secretos hardcodeados
- [ ] Los archivos nuevos tienen la licencia apropiada

---

¡Gracias por contribuir a Surviving Chernarus! 🎉

Cada contribución, sin importar su tamaño, hace que este proyecto sea mejor para toda la comunidad.

---

**Desarrollado con ❤️ por la comunidad Chernarus**
