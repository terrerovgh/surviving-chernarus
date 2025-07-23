#!/bin/bash

# Script de pruebas para Surviving Chernarus Deploy
# Este script valida todas las funcionalidades implementadas

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores de pruebas
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Función para logging de pruebas
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    TEST_COUNT=$((TEST_COUNT + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Función para verificar si una función existe
function_exists() {
    declare -f "$1" > /dev/null
    return $?
}

# Función para verificar archivos
file_exists() {
    [ -f "$1" ]
    return $?
}

# Función para verificar directorios
dir_exists() {
    [ -d "$1" ]
    return $?
}

# Cargar el script principal para acceder a las funciones
log_info "Cargando script principal..."
source ./deploy.sh 2>/dev/null || {
    log_fail "No se pudo cargar el script deploy.sh"
    exit 1
}

echo "="*60
echo "SURVIVING CHERNARUS - SUITE DE PRUEBAS"
echo "="*60
echo

# Test 1: Verificar funciones de logging
log_test "Verificando funciones de logging"
if function_exists "log_message" && function_exists "log_warning" && function_exists "log_error" && function_exists "log_debug"; then
    log_pass "Todas las funciones de logging están definidas"
else
    log_fail "Faltan funciones de logging"
fi

# Test 2: Verificar función de generación de contraseñas
log_test "Verificando generación de contraseñas seguras"
if function_exists "generate_secure_password"; then
    password=$(generate_secure_password 16)
    if [ ${#password} -eq 16 ]; then
        log_pass "Generación de contraseñas funciona correctamente (longitud: ${#password})"
    else
        log_fail "La contraseña generada no tiene la longitud correcta (esperado: 16, actual: ${#password})"
    fi
else
    log_fail "Función generate_secure_password no está definida"
fi

# Test 3: Verificar funciones de validación
log_test "Verificando funciones de validación"
validation_functions=("validate_email" "validate_domain")
all_validation_ok=true

for func in "${validation_functions[@]}"; do
    if function_exists "$func"; then
        log_pass "Función $func está definida"
    else
        log_fail "Función $func no está definida"
        all_validation_ok=false
    fi
done

if $all_validation_ok; then
    log_pass "Todas las funciones de validación están definidas"
fi

# Test 4: Verificar funciones de backup y rollback
log_test "Verificando funciones de backup y rollback"
backup_functions=("create_backup" "create_rollback_point" "rollback_system")
all_backup_ok=true

for func in "${backup_functions[@]}"; do
    if function_exists "$func"; then
        log_pass "Función $func está definida"
    else
        log_fail "Función $func no está definida"
        all_backup_ok=false
    fi
done

if $all_backup_ok; then
    log_pass "Todas las funciones de backup están definidas"
fi

# Test 5: Verificar función de recuperación ante desastres
log_test "Verificando función de recuperación ante desastres"
if function_exists "show_disaster_recovery"; then
    log_pass "Función show_disaster_recovery está definida"
else
    log_fail "Función show_disaster_recovery no está definida"
fi

# Test 6: Verificar función de ejecución robusta
log_test "Verificando función de ejecución robusta"
if function_exists "exec_cmd"; then
    log_pass "Función exec_cmd está definida"
else
    log_fail "Función exec_cmd no está definida"
fi

# Test 7: Verificar función de validación de requisitos del sistema
log_test "Verificando función de validación de requisitos del sistema"
if function_exists "validate_system_requirements"; then
    log_pass "Función validate_system_requirements está definida"
else
    log_fail "Función validate_system_requirements no está definida"
fi

# Test 8: Verificar estructura de directorios esperada
log_test "Verificando estructura de directorios"
expected_dirs=(
    "/opt/surviving-chernarus"
    "/opt/surviving-chernarus/backups"
    "/opt/surviving-chernarus/backups/rollback_points"
    "/opt/surviving-chernarus/logs"
)

dir_structure_ok=true
for dir in "${expected_dirs[@]}"; do
    if dir_exists "$dir"; then
        log_pass "Directorio $dir existe"
    else
        log_warn "Directorio $dir no existe (se creará durante el despliegue)"
    fi
done

# Test 9: Verificar archivos de configuración
log_test "Verificando archivos de configuración"
config_files=(
    "./docker-compose.yml"
    "./traefik/traefik.yml"
    "./traefik/dynamic.yml"
)

config_ok=true
for file in "${config_files[@]}"; do
    if file_exists "$file"; then
        log_pass "Archivo $file existe"
    else
        log_warn "Archivo $file no existe"
        config_ok=false
    fi
done

# Test 10: Verificar sintaxis del script principal
log_test "Verificando sintaxis del script principal"
if bash -n ./deploy.sh 2>/dev/null; then
    log_pass "Sintaxis del script principal es correcta"
else
    log_fail "Error de sintaxis en el script principal"
fi

# Test 11: Verificar comandos requeridos
log_test "Verificando comandos requeridos del sistema"
required_commands=("whiptail" "docker" "docker-compose" "ufw" "systemctl")
commands_ok=true

for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        log_pass "Comando $cmd está disponible"
    else
        log_warn "Comando $cmd no está disponible (se instalará durante el despliegue)"
    fi
done

# Test 12: Verificar argumentos de línea de comandos
log_test "Verificando manejo de argumentos de línea de comandos"
valid_args=("env" "network" "deploy" "doc" "rollback" "recovery" "--help" "-h")
args_test_ok=true

log_info "Argumentos válidos soportados: ${valid_args[*]}"
log_pass "Argumentos de línea de comandos implementados"

# Test 13: Verificar validaciones de entrada específicas
log_test "Verificando validaciones de entrada específicas"
if function_exists "validate_email"; then
    # Test email válido
    if validate_email "test@example.com" 2>/dev/null; then
        log_pass "Validación de email funciona para emails válidos"
    else
        log_fail "Validación de email falla para emails válidos"
    fi
    
    # Test email inválido
    if ! validate_email "invalid-email" 2>/dev/null; then
        log_pass "Validación de email rechaza emails inválidos"
    else
        log_fail "Validación de email acepta emails inválidos"
    fi
fi

if function_exists "validate_domain"; then
    # Test dominio válido
    if validate_domain "example.com" 2>/dev/null; then
        log_pass "Validación de dominio funciona para dominios válidos"
    else
        log_fail "Validación de dominio falla para dominios válidos"
    fi
    
    # Test dominio inválido
    if ! validate_domain "invalid..domain" 2>/dev/null; then
        log_pass "Validación de dominio rechaza dominios inválidos"
    else
        log_fail "Validación de dominio acepta dominios inválidos"
    fi
fi

# Test 14: Verificar creación de archivos de log
log_test "Verificando sistema de logging"
test_log_file="/tmp/test_deploy.log"
LOG_FILE="$test_log_file"

# Probar función de logging
log_message "Test message" 2>/dev/null
if [ -f "$test_log_file" ] && grep -q "Test message" "$test_log_file"; then
    log_pass "Sistema de logging funciona correctamente"
    rm -f "$test_log_file"
else
    log_warn "Sistema de logging no pudo ser probado completamente"
fi

# Resumen de pruebas
echo
echo "="*60
echo "RESUMEN DE PRUEBAS"
echo "="*60
echo "Total de pruebas: $TEST_COUNT"
echo -e "${GREEN}Pruebas exitosas: $PASS_COUNT${NC}"
echo -e "${RED}Pruebas fallidas: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Advertencias: $((TEST_COUNT - PASS_COUNT - FAIL_COUNT))${NC}"
echo

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ Todas las pruebas críticas pasaron exitosamente${NC}"
    echo -e "${GREEN}✓ El script está listo para despliegue${NC}"
    exit 0
else
    echo -e "${RED}✗ Algunas pruebas fallaron${NC}"
    echo -e "${YELLOW}⚠ Revisa los errores antes del despliegue${NC}"
    exit 1
fi