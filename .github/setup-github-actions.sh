#!/bin/bash

# Script de configuración para GitHub Actions - Surviving Chernarus
# Este script ayuda a configurar los secrets y preparar el entorno para GitHub Actions

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar dependencias
check_dependencies() {
    log_info "Verificando dependencias..."
    
    local missing_deps=()
    
    # Verificar ssh-keygen
    if ! command -v ssh-keygen &> /dev/null; then
        missing_deps+=("ssh-keygen")
    fi
    
    # Verificar ssh-copy-id
    if ! command -v ssh-copy-id &> /dev/null; then
        missing_deps+=("ssh-copy-id")
    fi
    
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Faltan las siguientes dependencias:"
        printf '  - %s\n' "${missing_deps[@]}"
        log_info "Instálalas con: sudo apt install ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "Todas las dependencias están disponibles"
}

# Función para generar claves SSH
generate_ssh_key() {
    log_info "Configurando claves SSH para GitHub Actions..."
    
    local key_path="$HOME/.ssh/surviving_chernarus_deploy"
    local email="github-actions@surviving-chernarus"
    
    # Verificar si ya existe la clave
    if [ -f "$key_path" ]; then
        log_warning "La clave SSH ya existe en $key_path"
        read -p "¿Deseas generar una nueva clave? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Usando clave existente"
            return 0
        fi
    fi
    
    # Generar nueva clave SSH
    log_info "Generando nueva clave SSH..."
    ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path" -N ""
    
    if [ $? -eq 0 ]; then
        log_success "Clave SSH generada exitosamente"
        log_info "Clave privada: $key_path"
        log_info "Clave pública: $key_path.pub"
    else
        log_error "Error al generar la clave SSH"
        exit 1
    fi
}

# Función para mostrar la clave privada para GitHub Secrets
show_private_key() {
    local key_path="$HOME/.ssh/surviving_chernarus_deploy"
    
    if [ ! -f "$key_path" ]; then
        log_error "No se encontró la clave privada en $key_path"
        return 1
    fi
    
    echo
    log_info "=== CLAVE PRIVADA PARA GITHUB SECRETS ==="
    log_warning "Copia el siguiente contenido COMPLETO para el secret SSH_PRIVATE_KEY:"
    echo
    echo "--- INICIO DE LA CLAVE ---"
    cat "$key_path"
    echo "--- FIN DE LA CLAVE ---"
    echo
    log_warning "IMPORTANTE: Esta clave es sensible. No la compartas públicamente."
    echo
}

# Función para mostrar la clave pública
show_public_key() {
    local key_path="$HOME/.ssh/surviving_chernarus_deploy.pub"
    
    if [ ! -f "$key_path" ]; then
        log_error "No se encontró la clave pública en $key_path"
        return 1
    fi
    
    echo
    log_info "=== CLAVE PÚBLICA PARA LA RASPBERRY PI ==="
    log_info "Copia esta clave a tu Raspberry Pi:"
    echo
    cat "$key_path"
    echo
}

# Función para configurar la Raspberry Pi
setup_raspberry_pi() {
    echo
    log_info "=== CONFIGURACIÓN DE LA RASPBERRY PI ==="
    
    # Solicitar información de conexión
    read -p "Ingresa la IP o hostname de tu Raspberry Pi (ej: rpi.terrerov.com): " rpi_host
    read -p "Ingresa el usuario SSH (ej: terrerov): " rpi_user
    
    if [ -z "$rpi_host" ] || [ -z "$rpi_user" ]; then
        log_error "Debes proporcionar tanto el host como el usuario"
        return 1
    fi
    
    local key_path="$HOME/.ssh/surviving_chernarus_deploy.pub"
    
    if [ ! -f "$key_path" ]; then
        log_error "No se encontró la clave pública. Genera primero las claves SSH."
        return 1
    fi
    
    log_info "Copiando clave pública a $rpi_user@$rpi_host..."
    
    # Intentar copiar la clave
    if ssh-copy-id -i "$key_path" "$rpi_user@$rpi_host"; then
        log_success "Clave pública copiada exitosamente"
    else
        log_warning "Error al copiar automáticamente. Copia manual requerida:"
        echo
        echo "Ejecuta en tu Raspberry Pi:"
        echo "mkdir -p ~/.ssh"
        echo "echo '$(cat "$key_path")' >> ~/.ssh/authorized_keys"
        echo "chmod 700 ~/.ssh"
        echo "chmod 600 ~/.ssh/authorized_keys"
        echo
    fi
    
    # Probar conexión SSH
    log_info "Probando conexión SSH..."
    if ssh -i "${key_path%.*}" -o ConnectTimeout=10 -o BatchMode=yes "$rpi_user@$rpi_host" 'echo "Conexión SSH exitosa"'; then
        log_success "Conexión SSH configurada correctamente"
    else
        log_warning "No se pudo establecer conexión SSH automáticamente"
        log_info "Verifica manualmente la conexión con:"
        echo "ssh -i ${key_path%.*} $rpi_user@$rpi_host"
    fi
}

# Función para mostrar instrucciones de GitHub
show_github_instructions() {
    echo
    log_info "=== CONFIGURACIÓN DE GITHUB SECRETS ==="
    echo
    echo "Para configurar los secrets en GitHub:"
    echo
    echo "1. Ve a tu repositorio en GitHub"
    echo "2. Navega a Settings → Secrets and variables → Actions"
    echo "3. Haz clic en 'New repository secret'"
    echo "4. Crea el siguiente secret:"
    echo
    echo "   Nombre: SSH_PRIVATE_KEY"
    echo "   Valor: [La clave privada mostrada anteriormente]"
    echo
    echo "5. Guarda el secret"
    echo
    log_info "=== CONFIGURACIÓN DEL WORKFLOW ==="
    echo
    echo "Verifica que las siguientes variables en .github/workflows/deploy.yml sean correctas:"
    echo
    echo "env:"
    echo "  DEPLOY_HOST: [tu-raspberry-pi-host]  # ej: rpi.terrerov.com"
    echo "  DEPLOY_USER: [tu-usuario-ssh]       # ej: terrerov"
    echo "  DEPLOY_PATH: /opt/surviving-chernarus"
    echo "  PROJECT_NAME: surviving-chernarus"
    echo
}

# Función para verificar configuración
verify_setup() {
    echo
    log_info "=== VERIFICACIÓN DE CONFIGURACIÓN ==="
    
    local key_path="$HOME/.ssh/surviving_chernarus_deploy"
    
    # Verificar archivos de clave
    if [ -f "$key_path" ] && [ -f "$key_path.pub" ]; then
        log_success "Claves SSH encontradas"
    else
        log_error "Claves SSH no encontradas"
        return 1
    fi
    
    # Verificar permisos
    local private_perms=$(stat -c "%a" "$key_path" 2>/dev/null || echo "unknown")
    local public_perms=$(stat -c "%a" "$key_path.pub" 2>/dev/null || echo "unknown")
    
    if [ "$private_perms" = "600" ]; then
        log_success "Permisos de clave privada correctos (600)"
    else
        log_warning "Permisos de clave privada: $private_perms (recomendado: 600)"
        chmod 600 "$key_path"
        log_info "Permisos corregidos"
    fi
    
    if [ "$public_perms" = "644" ]; then
        log_success "Permisos de clave pública correctos (644)"
    else
        log_warning "Permisos de clave pública: $public_perms (recomendado: 644)"
        chmod 644 "$key_path.pub"
        log_info "Permisos corregidos"
    fi
    
    # Verificar workflows
    if [ -f ".github/workflows/deploy.yml" ]; then
        log_success "Workflow de deploy encontrado"
    else
        log_error "Workflow de deploy no encontrado"
    fi
    
    if [ -f ".github/workflows/test.yml" ]; then
        log_success "Workflow de test encontrado"
    else
        log_warning "Workflow de test no encontrado"
    fi
}

# Función para limpiar configuración
cleanup_setup() {
    log_warning "=== LIMPIEZA DE CONFIGURACIÓN ==="
    echo
    read -p "¿Estás seguro de que deseas eliminar las claves SSH generadas? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local key_path="$HOME/.ssh/surviving_chernarus_deploy"
        
        if [ -f "$key_path" ]; then
            rm "$key_path"
            log_info "Clave privada eliminada"
        fi
        
        if [ -f "$key_path.pub" ]; then
            rm "$key_path.pub"
            log_info "Clave pública eliminada"
        fi
        
        log_success "Limpieza completada"
    else
        log_info "Limpieza cancelada"
    fi
}

# Función principal de menú
show_menu() {
    echo
    echo "=== CONFIGURACIÓN DE GITHUB ACTIONS - SURVIVING CHERNARUS ==="
    echo
    echo "Selecciona una opción:"
    echo "1. Generar claves SSH"
    echo "2. Mostrar clave privada (para GitHub Secrets)"
    echo "3. Mostrar clave pública (para Raspberry Pi)"
    echo "4. Configurar Raspberry Pi"
    echo "5. Mostrar instrucciones de GitHub"
    echo "6. Verificar configuración"
    echo "7. Limpiar configuración"
    echo "8. Configuración completa (pasos 1-5)"
    echo "9. Salir"
    echo
    read -p "Opción: " choice
    
    case $choice in
        1)
            generate_ssh_key
            ;;
        2)
            show_private_key
            ;;
        3)
            show_public_key
            ;;
        4)
            setup_raspberry_pi
            ;;
        5)
            show_github_instructions
            ;;
        6)
            verify_setup
            ;;
        7)
            cleanup_setup
            ;;
        8)
            log_info "Ejecutando configuración completa..."
            generate_ssh_key
            show_private_key
            show_public_key
            setup_raspberry_pi
            show_github_instructions
            verify_setup
            ;;
        9)
            log_info "Saliendo..."
            exit 0
            ;;
        *)
            log_error "Opción inválida"
            ;;
    esac
}

# Función principal
main() {
    echo "🚀 Configurador de GitHub Actions para Surviving Chernarus"
    echo "========================================================="
    
    # Verificar dependencias
    check_dependencies
    
    # Mostrar menú en bucle
    while true; do
        show_menu
        echo
        read -p "¿Deseas realizar otra acción? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            break
        fi
    done
    
    echo
    log_success "¡Configuración completada!"
    echo
    echo "Próximos pasos:"
    echo "1. Configura los secrets en GitHub (si no lo has hecho)"
    echo "2. Verifica las variables en .github/workflows/deploy.yml"
    echo "3. Haz commit y push de los cambios"
    echo "4. El workflow se ejecutará automáticamente en el próximo push a main"
    echo
    log_info "¡Listo para usar GitHub Actions con Surviving Chernarus!"
}

# Ejecutar función principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi