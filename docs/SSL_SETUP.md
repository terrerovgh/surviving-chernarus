# INSTRUCCIONES PARA CONFIGURAR SSL AUTOMÁTICO CON CLOUDFLARE

## 📋 Pasos para obtener las credenciales de Cloudflare:

### 1. Acceder al panel de Cloudflare

- Ve a: https://dash.cloudflare.com/profile/api-tokens
- Inicia sesión con tu cuenta de Cloudflare

### 2. Crear un API Token

- Haz clic en "Create Token"
- Usa la plantilla "Custom token"
- Configura los permisos:
  - **Permissions**: Zone:DNS:Edit, Zone:Zone:Read
  - **Zone Resources**: Include - Specific zone - terrerov.com
  - **TTL**: Sin límite o el tiempo que prefieras

### 3. Configurar las variables de entorno

```bash
# Exportar las credenciales (reemplaza con tus valores reales)
export CLOUDFLARE_EMAIL="terrerov@gmail.com"
export CLOUDFLARE_API_TOKEN="LMO4jer71Ktw02ExegtaE1UAcNvfpw9fKzU9Ime2"

# Ejecutar el script de configuración
./scripts/configure-cloudflare-ssl.sh
```

### 4. Verificar la configuración

```bash
# Verificar que Traefik está funcionando
kubectl get pods -n chernarus-system

# Verificar los secretos
kubectl get secrets -n chernarus-system chernarus-secrets -o yaml

# Ver logs de Traefik
kubectl logs -n chernarus-system deployment/traefik
```

### 5. Aplicar los Ingress para activar SSL

```bash
# Aplicar las reglas de Ingress
kubectl apply -f kubernetes/apps/surviving-chernarus/ingress.yaml

# Verificar los certificados
kubectl get certificates -n surviving-chernarus
```

## 🌐 Dominios que se configurarán automáticamente:

- **https://terrerov.com** - Sitio principal (Hugo Dashboard)
- **https://hq.terrerov.com** - Dashboard HQ
- **https://n8n.terrerov.com** - Automatización N8N
- **https://traefik.terrerov.com** - Dashboard de Traefik

## 🔧 Configuración DNS en Cloudflare:

Asegúrate de tener estos registros DNS en Cloudflare:

```
A    terrerov.com      192.168.0.2  (o tu IP pública)
A    *.terrerov.com    192.168.0.2  (wildcard para subdominios)
```

## ⚠️ Notas importantes:

1. **Let's Encrypt tiene límites de rate**: No pruebes demasiadas veces en poco
   tiempo
2. **DNS Challenge**: Cloudflare debe ser tu proveedor DNS para el dominio
3. **Conectividad**: El cluster debe poder acceder a internet para validar los
   certificados
4. **Dominios válidos**: Los dominios deben apuntar a tu infraestructura

## 🚀 Estado actual del despliegue:

✅ Traefik configurado con soporte SSL ✅ PostgreSQL funcionando ✅ Hugo
Dashboard funcionando 🟡 N8N necesita corrección ⏳ SSL automático - esperando
credenciales de Cloudflare
