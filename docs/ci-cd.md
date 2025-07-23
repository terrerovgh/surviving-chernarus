# CI/CD con GitHub Actions

Esta guía explica cómo configurar y usar el sistema de integración y despliegue continuo (CI/CD) para Surviving Chernarus usando GitHub Actions.

## 📋 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Configuración Inicial](#configuración-inicial)
- [Workflows Disponibles](#workflows-disponibles)
- [Proceso de Deployment](#proceso-de-deployment)
- [Monitoreo y Logs](#monitoreo-y-logs)
- [Troubleshooting](#troubleshooting)
- [Mejores Prácticas](#mejores-prácticas)

## 📖 Descripción General

El sistema CI/CD automatiza:

- ✅ **Testing**: Validación de sintaxis, estructura y lógica
- 🚀 **Deployment**: Despliegue automático a la Raspberry Pi
- 📊 **Monitoring**: Reportes de estado y salud del sistema
- 🔄 **Rollback**: Capacidad de revertir cambios si es necesario

### Arquitectura del CI/CD

```
GitHub Repository
       |
       v
[GitHub Actions]
       |
       v
[SSH Connection]
       |
       v
[Raspberry Pi]
       |
       v
[Deploy Script]
       |
       v
[Docker Services]
```

## 🔧 Configuración Inicial

### 1. Configuración Automática

Usa el script de configuración incluido:

```bash
# Desde el directorio del proyecto
./.github/setup-github-actions.sh
```

Este script te guiará a través de:
- Generación de claves SSH
- Configuración de la Raspberry Pi
- Instrucciones para GitHub Secrets

### 2. Configuración Manual

#### Paso 1: Generar Claves SSH

```bash
# Generar par de claves
ssh-keygen -t rsa -b 4096 -C "github-actions@surviving-chernarus" -f ~/.ssh/surviving_chernarus_deploy

# Copiar clave pública a la Raspberry Pi
ssh-copy-id -i ~/.ssh/surviving_chernarus_deploy.pub terrerov@rpi.terrerov.com
```

#### Paso 2: Configurar GitHub Secrets

1. Ve a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Agrega el secret:
   - **Nombre**: `SSH_PRIVATE_KEY`
   - **Valor**: Contenido completo de `~/.ssh/surviving_chernarus_deploy`

#### Paso 3: Configurar Variables del Workflow

Edita `.github/workflows/deploy.yml` y ajusta:

```yaml
env:
  DEPLOY_HOST: rpi.terrerov.com      # Tu Raspberry Pi
  DEPLOY_USER: terrerov              # Tu usuario SSH
  DEPLOY_PATH: /opt/surviving-chernarus
  PROJECT_NAME: surviving-chernarus
```

## 🔄 Workflows Disponibles

### 1. Test Workflow (`test.yml`)

**Trigger**: Pull Requests a `main` o `develop`

**Funciones**:
- Validación de sintaxis bash
- Análisis con shellcheck
- Verificación de estructura del proyecto
- Tests de lógica de deployment
- Escaneo básico de seguridad
- Tests de compatibilidad

**Jobs**:
```
├── validate-syntax
├── validate-structure
├── test-deployment-logic
├── security-scan
├── compatibility-check
└── generate-report
```

### 2. Deploy Workflow (`deploy.yml`)

**Trigger**: 
- Push a `main`
- PR cerrado y mergeado a `main`
- Ejecución manual

**Funciones**:
- Deployment automático a producción
- Backup antes del deployment
- Tests post-deployment
- Generación de reportes
- Notificaciones de estado

**Jobs**:
```
├── test (si es PR)
├── deploy
│   ├── Backup
│   ├── Stop services
│   ├── Deploy code
│   ├── Run deployment
│   ├── Post-deployment tests
│   └── Generate report
└── notify
```

## 🚀 Proceso de Deployment

### Deployment Automático

1. **Trigger**: Push a `main` o merge de PR
2. **Backup**: Se crea backup automático del estado actual
3. **Deploy**: 
   - Detiene servicios existentes
   - Sincroniza código nuevo
   - Ejecuta `deploy.sh`
   - Inicia servicios
4. **Verify**: Tests post-deployment
5. **Report**: Genera reporte de estado

### Deployment Manual

1. Ve a **Actions** en GitHub
2. Selecciona "Deploy to Raspberry Pi"
3. Haz clic en **Run workflow**
4. Selecciona branch y ejecuta

### Estructura del Deployment

```
/opt/surviving-chernarus/
├── deploy.sh              # Script principal
├── docker-compose.yml     # Configuración de servicios
├── .env                   # Variables de entorno
├── backups/               # Backups automáticos
│   ├── 20240122_143022_github_deploy/
│   └── 20240122_150315_github_deploy/
└── logs/                  # Logs del sistema
```

## 📊 Monitoreo y Logs

### Logs de GitHub Actions

- **Workflow logs**: Disponibles en la pestaña Actions
- **Job logs**: Logs detallados por cada job
- **Step logs**: Logs específicos de cada paso

### Logs en la Raspberry Pi

```bash
# Logs del deployment
tail -f /var/log/surviving-chernarus-install.log

# Logs de Docker
sudo docker logs <container_name>

# Logs del sistema
sudo journalctl -u docker -f
```

### Monitoreo de Servicios

```bash
# Estado de containers
sudo docker ps

# Estado de servicios
sudo systemctl status docker

# Uso de recursos
htop
df -h
free -h
```

## 🔍 Troubleshooting

### Errores Comunes

#### 1. Error de Conexión SSH

**Síntoma**:
```
Permission denied (publickey)
```

**Solución**:
```bash
# Verificar clave en GitHub Secrets
# Verificar clave en Raspberry Pi
cat ~/.ssh/authorized_keys

# Probar conexión manual
ssh -i ~/.ssh/surviving_chernarus_deploy terrerov@rpi.terrerov.com
```

#### 2. Error de Permisos

**Síntoma**:
```
sudo: a password is required
```

**Solución**:
```bash
# En la Raspberry Pi, configurar sudo sin contraseña
echo "terrerov ALL=(ALL) NOPASSWD: /opt/surviving-chernarus/deploy.sh, /usr/bin/docker, /usr/bin/docker-compose" | sudo tee /etc/sudoers.d/surviving-chernarus
```

#### 3. Error de Docker

**Síntoma**:
```
Cannot connect to the Docker daemon
```

**Solución**:
```bash
# Verificar Docker
sudo systemctl status docker
sudo systemctl start docker

# Agregar usuario al grupo docker
sudo usermod -aG docker terrerov
```

#### 4. Falta de Espacio en Disco

**Síntoma**:
```
No space left on device
```

**Solución**:
```bash
# Limpiar Docker
sudo docker system prune -a

# Limpiar logs
sudo journalctl --vacuum-time=7d

# Limpiar backups antiguos
sudo find /opt/surviving-chernarus/backups -type d -mtime +30 -exec rm -rf {} +
```

### Debugging del Workflow

#### Habilitar Debug Mode

Agrega estos secrets en GitHub:
- `ACTIONS_STEP_DEBUG`: `true`
- `ACTIONS_RUNNER_DEBUG`: `true`

#### Logs Detallados

```bash
# En la Raspberry Pi, habilitar debug
export DEBUG=true
./deploy.sh deploy
```

## 🛡️ Mejores Prácticas

### Seguridad

1. **Claves SSH**:
   - Usa claves RSA de 4096 bits mínimo
   - Rota claves regularmente
   - Nunca compartas claves privadas

2. **Secrets**:
   - Usa secrets específicos por entorno
   - No hardcodees secrets en código
   - Revisa secrets regularmente

3. **Acceso**:
   - Limita permisos sudo
   - Usa fail2ban en la Raspberry Pi
   - Monitorea accesos SSH

### Performance

1. **Backups**:
   - Limita número de backups (máximo 5)
   - Comprime backups antiguos
   - Usa storage externo si es necesario

2. **Deployments**:
   - Usa rsync para transferencias eficientes
   - Minimiza downtime con rolling deployments
   - Monitorea recursos durante deployment

3. **Logs**:
   - Rota logs regularmente
   - Usa log levels apropiados
   - Centraliza logs si tienes múltiples servicios

### Reliability

1. **Testing**:
   - Ejecuta tests en cada PR
   - Usa entornos de staging
   - Automatiza tests de regresión

2. **Rollback**:
   - Mantén backups automáticos
   - Documenta procedimientos de rollback
   - Practica rollbacks regularmente

3. **Monitoring**:
   - Configura alertas de salud
   - Monitorea métricas clave
   - Usa health checks automáticos

## 📈 Métricas y KPIs

### Métricas de Deployment

- **Frequency**: Número de deployments por semana
- **Success Rate**: Porcentaje de deployments exitosos
- **Duration**: Tiempo promedio de deployment
- **Rollback Rate**: Porcentaje de rollbacks necesarios

### Métricas de Sistema

- **Uptime**: Disponibilidad de servicios
- **Response Time**: Tiempo de respuesta de servicios
- **Resource Usage**: CPU, memoria, disco
- **Error Rate**: Tasa de errores en logs

## 🔗 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SSH Key Management](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Surviving Chernarus Documentation](./)

---

**Nota**: Esta documentación se actualiza regularmente. Consulta la versión más reciente en el repositorio.