# Surviving Chernarus - Mejoras de Seguridad y Recuperación

## Resumen de Mejoras Implementadas

Este documento detalla las mejoras de seguridad, validaciones, manejo de errores y funcionalidades de recuperación implementadas en el script de despliegue.

## 1. Mejoras de Seguridad

### Generación Segura de Contraseñas
- **Función**: `generate_secure_password()`
- **Características**:
  - Utiliza OpenSSL cuando está disponible
  - Fallback a /dev/urandom para sistemas sin OpenSSL
  - Contraseñas de longitud configurable (32 caracteres por defecto)
  - Caracteres especiales incluidos para mayor complejidad

### Validaciones de Entrada
- **Email**: Validación con regex para formato correcto
- **Dominio**: Verificación de formato DNS válido
- **IP**: Validación de formato y rangos de octetos
- **Contraseñas**: Longitud mínima obligatoria
- **Hostname**: Caracteres permitidos y longitud máxima

### Configuración de Firewall (UFW)
- Backup automático de configuraciones existentes
- Reglas específicas para Docker y servicios
- Configuración de políticas por defecto seguras
- Manejo de tráfico Docker en after.rules

## 2. Validaciones y Manejo de Errores

### Sistema de Logging Mejorado
```bash
# Funciones de logging con timestamps
log_message()   # Información general
log_warning()   # Advertencias
log_error()     # Errores críticos
log_debug()     # Información de depuración
```

### Validaciones del Sistema
- **Arquitectura**: Verificación de compatibilidad (x86_64, aarch64)
- **Espacio en disco**: Mínimo 10GB requerido
- **Memoria RAM**: Mínimo 2GB requerido
- **Sistema operativo**: Ubuntu/Debian soportados
- **Conectividad**: Verificación de acceso a Internet

### Ejecución Robusta de Comandos
- **Función**: `exec_cmd()`
- **Características**:
  - Logging automático de comandos ejecutados
  - Manejo de códigos de error
  - Prompts interactivos para continuar en caso de fallo
  - Timeout configurable

## 3. Sistema de Backup y Rollback

### Puntos de Rollback Automáticos
- **Función**: `create_rollback_point()`
- **Ubicación**: `/opt/surviving-chernarus/backups/rollback_points/`
- **Contenido**:
  - Estado del sistema en formato JSON
  - Timestamp de creación
  - Información de servicios activos
  - Configuraciones de red

### Backups Automáticos
- **Función**: `create_backup()`
- **Archivos respaldados**:
  - Configuraciones de red (`/etc/network/interfaces`, `/etc/hosts`)
  - Configuraciones UFW (`/etc/ufw/`)
  - Variables de entorno (`.env`)
  - Configuraciones Docker

### Restauración del Sistema
- **Función**: `rollback_system()`
- **Capacidades**:
  - Selección interactiva de puntos de rollback
  - Restauración de configuraciones de red
  - Restauración de reglas UFW
  - Parada segura de servicios Docker
  - Prompt para reinicio del sistema

## 4. Plan de Recuperación ante Desastres

### Documentación Automática
- **Función**: `show_disaster_recovery()`
- **Información incluida**:
  - Ubicaciones de backups
  - Procedimientos de recuperación manual
  - Contactos de emergencia
  - Verificaciones post-recuperación

### Ubicaciones de Archivos Críticos
```
/opt/surviving-chernarus/
├── backups/
│   ├── rollback_points/     # Puntos de restauración
│   ├── network/             # Backups de red
│   ├── ufw/                 # Backups de firewall
│   └── env/                 # Backups de variables
├── logs/
│   └── deploy.log           # Log principal
└── docker-compose.yml       # Configuración de servicios
```

## 5. Nuevas Opciones del Menú

### Menú Principal Actualizado
1. Configurar variables de entorno (.env)
2. Configurar red (requiere sudo)
3. Desplegar servicios
4. Ver documentación
5. **Rollback del sistema** *(NUEVO)*
6. **Plan de recuperación ante desastres** *(NUEVO)*
7. Salir

### Argumentos de Línea de Comandos
```bash
./deploy.sh env        # Configurar variables
./deploy.sh network    # Configurar red
./deploy.sh deploy     # Desplegar servicios
./deploy.sh doc        # Mostrar documentación
./deploy.sh rollback   # Realizar rollback (requiere sudo)
./deploy.sh recovery   # Mostrar plan de recuperación
./deploy.sh --help     # Mostrar ayuda
```

## 6. Procedimientos de Recuperación

### Recuperación Automática
1. Ejecutar: `sudo ./deploy.sh rollback`
2. Seleccionar punto de restauración
3. Confirmar restauración
4. Reiniciar sistema si es necesario

### Recuperación Manual
1. **Restaurar red**:
   ```bash
   sudo cp /opt/surviving-chernarus/backups/network/* /etc/
   sudo systemctl restart networking
   ```

2. **Restaurar UFW**:
   ```bash
   sudo cp -r /opt/surviving-chernarus/backups/ufw/* /etc/ufw/
   sudo ufw reload
   ```

3. **Restaurar servicios**:
   ```bash
   cd /opt/surviving-chernarus
   docker-compose down
   cp backups/env/.env.backup .env
   docker-compose up -d
   ```

## 7. Verificaciones Post-Recuperación

### Checklist de Verificación
- [ ] Conectividad de red funcional
- [ ] Servicios Docker en ejecución
- [ ] Acceso web a servicios
- [ ] Configuración UFW activa
- [ ] Logs sin errores críticos

### Comandos de Verificación
```bash
# Verificar red
ping -c 3 8.8.8.8

# Verificar servicios
docker ps
docker-compose ps

# Verificar UFW
sudo ufw status

# Verificar logs
tail -f /opt/surviving-chernarus/logs/deploy.log
```

## 8. Contactos de Emergencia

### Información de Soporte
- **Documentación**: Este archivo y comentarios en el código
- **Logs**: `/opt/surviving-chernarus/logs/deploy.log`
- **Backups**: `/opt/surviving-chernarus/backups/`
- **Configuración**: `/opt/surviving-chernarus/.env`

### Comandos de Diagnóstico
```bash
# Estado general del sistema
sudo ./deploy.sh recovery

# Verificar servicios
docker ps -a
docker-compose logs

# Verificar red
ip addr show
sudo ufw status verbose

# Verificar espacio en disco
df -h
```

## 9. Mejores Prácticas

### Antes del Despliegue
1. Realizar backup completo del sistema
2. Verificar requisitos del sistema
3. Probar en entorno de desarrollo
4. Documentar configuración actual

### Durante el Despliegue
1. Monitorear logs en tiempo real
2. Verificar cada paso antes de continuar
3. Mantener terminal de respaldo abierto
4. No interrumpir procesos críticos

### Después del Despliegue
1. Verificar todos los servicios
2. Probar acceso externo
3. Revisar logs por errores
4. Documentar cambios realizados
5. Crear punto de rollback manual

---

**Nota**: Este documento debe mantenerse actualizado con cualquier cambio en el sistema de despliegue.