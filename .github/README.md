# GitHub Actions para Surviving Chernarus

Este directorio contiene los workflows de GitHub Actions para automatizar el despliegue del proyecto Surviving Chernarus en tu Raspberry Pi.

## 🚀 Configuración Inicial

### 1. Configurar Secrets en GitHub

Para que GitHub Actions pueda conectarse a tu Raspberry Pi, necesitas configurar los siguientes secrets en tu repositorio:

1. Ve a tu repositorio en GitHub
2. Navega a **Settings** → **Secrets and variables** → **Actions**
3. Agrega los siguientes secrets:

#### Secrets Requeridos

| Secret | Descripción | Ejemplo |
|--------|-------------|----------|
| `SSH_PRIVATE_KEY` | Clave privada SSH para conectarse a la Raspberry Pi | Contenido completo de tu archivo `~/.ssh/id_rsa` |

### 2. Configurar SSH en la Raspberry Pi

#### Generar par de claves SSH (si no tienes)

```bash
# En tu máquina local
ssh-keygen -t rsa -b 4096 -C "github-actions@surviving-chernarus"
```

#### Copiar la clave pública a la Raspberry Pi

```bash
# Copiar clave pública a la Raspberry Pi
ssh-copy-id terrerov@rpi.terrerov.com

# O manualmente:
cat ~/.ssh/id_rsa.pub | ssh terrerov@rpi.terrerov.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### Configurar SSH en la Raspberry Pi

```bash
# En la Raspberry Pi
sudo nano /etc/ssh/sshd_config

# Asegurar que estas líneas estén configuradas:
PubkeyAuthentication yes
PasswordAuthentication no  # Opcional: deshabilitar autenticación por contraseña
PermitRootLogin no

# Reiniciar SSH
sudo systemctl restart ssh
```

### 3. Configurar el usuario en la Raspberry Pi

```bash
# En la Raspberry Pi, asegurar que el usuario terrerov tenga permisos sudo
sudo usermod -aG sudo terrerov

# Configurar sudo sin contraseña para operaciones de deploy (opcional)
echo "terrerov ALL=(ALL) NOPASSWD: /opt/surviving-chernarus/deploy.sh, /usr/bin/docker, /usr/bin/docker-compose" | sudo tee /etc/sudoers.d/surviving-chernarus
```

## 🔄 Workflows Disponibles

### 1. Deploy Workflow (`deploy.yml`)

**Trigger:** Se ejecuta automáticamente cuando:

- Se hace push al branch `main`
- Se cierra un Pull Request que se mergea a `main`
- Se ejecuta manualmente desde GitHub Actions

**Proceso:**

1. **Test**: Valida la sintaxis del script y ejecuta tests
2. **Deploy**:
   - Crea backup del deployment actual
   - Para los servicios en ejecución
   - Despliega el nuevo código
   - Ejecuta el script de deploy
   - Realiza tests post-deployment
3. **Report**: Genera reporte del deployment
4. **Notify**: Envía notificaciones del estado

## 📋 Variables de Entorno

El workflow utiliza las siguientes variables que puedes modificar en el archivo `deploy.yml`:

```yaml
env:
  DEPLOY_HOST: rpi.terrerov.com      # Hostname o IP de tu Raspberry Pi
  DEPLOY_USER: terrerov              # Usuario SSH
  DEPLOY_PATH: /opt/surviving-chernarus  # Ruta de instalación
  PROJECT_NAME: surviving-chernarus  # Nombre del proyecto
```

## 🛠️ Uso Manual

### Ejecutar Deployment Manualmente

1. Ve a tu repositorio en GitHub
2. Navega a **Actions**
3. Selecciona el workflow "Deploy to Raspberry Pi"
4. Haz clic en **Run workflow**
5. Selecciona el branch y haz clic en **Run workflow**

### Monitorear el Deployment

1. En la pestaña **Actions**, verás el progreso del workflow
2. Haz clic en el workflow en ejecución para ver los logs detallados
3. Cada job muestra su progreso y logs en tiempo real

## 🔍 Troubleshooting

### Errores Comunes

#### 1. Error de conexión SSH

```
Permission denied (publickey)
```

**Solución:**

- Verifica que la clave privada esté correctamente configurada en GitHub Secrets
- Asegúrate de que la clave pública esté en `~/.ssh/authorized_keys` en la Raspberry Pi
- Verifica que el servicio SSH esté ejecutándose: `sudo systemctl status ssh`

#### 2. Error de permisos

```
sudo: a password is required
```

**Solución:**

- Configura sudo sin contraseña para el usuario (ver sección de configuración)
- O modifica el workflow para usar `sudo -S` con contraseña

#### 3. Error de Docker

```
Cannot connect to the Docker daemon
```

**Solución:**

- Asegúrate de que Docker esté instalado y ejecutándose
- Agrega el usuario al grupo docker: `sudo usermod -aG docker terrerov`
- Reinicia la sesión SSH

### Logs y Debugging

#### Ver logs del deployment en la Raspberry Pi

```bash
# Logs del sistema
sudo journalctl -u docker -f

# Logs de la aplicación
tail -f /var/log/surviving-chernarus-install.log

# Logs de containers
sudo docker logs <container_name>
```

#### Verificar estado de los servicios

```bash
# Estado de Docker
sudo systemctl status docker

# Containers en ejecución
sudo docker ps

# Estado de la red
sudo ufw status
ip addr show
```

## 🔒 Seguridad

### Mejores Prácticas

1. **Claves SSH:**
   - Usa claves RSA de al menos 4096 bits
   - Nunca compartas tu clave privada
   - Rota las claves regularmente

2. **Secrets de GitHub:**
   - Nunca hardcodees secrets en el código
   - Usa secrets específicos para cada entorno
   - Revisa regularmente los secrets configurados

3. **Acceso SSH:**
   - Deshabilita autenticación por contraseña
   - Usa fail2ban para proteger contra ataques de fuerza bruta
   - Cambia el puerto SSH por defecto (opcional)

4. **Firewall:**
   - Mantén UFW configurado y activo
   - Solo abre los puertos necesarios
   - Monitorea conexiones sospechosas

## 📈 Monitoreo y Alertas

### Configurar Notificaciones

Puedes extender el workflow para enviar notificaciones a:

#### Slack

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

#### Discord

```yaml
- name: Notify Discord
  if: always()
  uses: sarisia/actions-status-discord@v1
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK }}
```

#### Email

```yaml
- name: Send Email
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 587
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: "Deployment Failed - Surviving Chernarus"
    to: admin@example.com
    from: github-actions@example.com
```

## 🔄 Rollback

En caso de que un deployment falle, puedes hacer rollback:

### Rollback Manual

```bash
# Conectarse a la Raspberry Pi
ssh terrerov@rpi.terrerov.com

# Ver backups disponibles
ls -la /opt/surviving-chernarus/backups/

# Restaurar backup
sudo ./deploy.sh rollback
```

### Rollback Automático

El workflow crea automáticamente backups antes de cada deployment. Si el deployment falla, puedes crear un workflow adicional para rollback automático.

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SSH Key Management](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Docker Documentation](https://docs.docker.com/)
- [Surviving Chernarus Documentation](../docs/)

---

**Nota:** Asegúrate de probar el workflow en un entorno de desarrollo antes de usarlo en producción.
