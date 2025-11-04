#!/bin/bash
# =============================================================================
# KOHA DOCKER - INICIALIZACIÓN DE SERVICIOS
# =============================================================================
# Este script inicializa todos los servicios de Koha Docker usando volúmenes
# persistentes. Debe ejecutarse después de setup.sh.
#
# USO: sudo ./init.sh
#
# REQUISITOS:
# - Ejecutar como root (sudo)
# - Haber ejecutado setup.sh previamente
# - Archivo .env configurado
# - Docker y Docker Compose funcionando
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}" >&2; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

log "🚀 KOHA DOCKER - INICIALIZACIÓN DE SERVICIOS"
log "============================================"

# Verificar que existe el archivo .env
if [[ ! -f .env ]]; then
    error "Archivo .env no encontrado. Crear uno basado en .env.example"
    error "Ejecutar: cp .env.example .env && nano .env"
    exit 1
fi

# Cargar variables de entorno de forma segura
set -a
while IFS= read -r line; do
    # Saltar líneas vacías, comentarios y líneas sin =
    [[ -z "$line" || "$line" =~ ^# || ! "$line" =~ = ]] && continue
    # Exportar la variable correctamente
    eval "export $line" 2>/dev/null || true
done < <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | sed 's/\r$//')
set +a
info "📋 Configuración cargada desde .env"

# Verificar Docker Compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
    info "Usando Docker Compose V2"
elif docker-compose --version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
    info "Usando Docker Compose V1"
else
    error "Docker Compose no está disponible"
    exit 1
fi

# Verificar que existe docker-compose.yml
COMPOSE_FILE="docker-compose.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
    error "No se encontró archivo docker-compose.yml"
    error "Asegúrate de estar en el directorio correcto del proyecto"
    exit 1
fi

info "Usando archivo: $COMPOSE_FILE"

# Verificar volúmenes y directorios
log "🔍 VERIFICANDO PREREQUISITOS"
log "============================"

info "Verificando estructura de directorios..."
INSTALL_DIR="${INSTALL_DIR:-/opt/koha-docker}"
DATA_DIR="${DATA_DIR:-/opt/koha-docker/data}"

if [[ ! -d "$DATA_DIR" ]]; then
    error "Directorio de datos no encontrado: $DATA_DIR"
    error "Ejecutar ./setup.sh primero"
    exit 1
fi

info "✅ Estructura de directorios verificada"

# Verificar y limpiar redes Docker si es necesario
info "Verificando redes Docker..."
if docker network ls | grep -q "koha-network"; then
    # Verificar si hay conflictos de subnet
    if docker network inspect koha-network 2>/dev/null | grep -q "172.20.0.0/16"; then
        warning "Detectado posible conflicto de red. Limpiando redes..."
        # Ejecutar limpieza automática
        chmod +x clean-docker.sh 2>/dev/null || true
        ./clean-docker.sh 2>/dev/null || true
    fi
fi

info "✅ Redes Docker verificadas"

# Detener servicios existentes si están corriendo
log "🛑 PREPARANDO INICIALIZACIÓN"
log "==========================="

if $DOCKER_COMPOSE -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    warning "Servicios corriendo detectados. ¿Detener y reiniciar? (s/N):"
    read -r response
    if [[ "$response" == "s" || "$response" == "S" ]]; then
        info "Deteniendo servicios existentes..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" down --remove-orphans
    else
        error "No se puede continuar con servicios corriendo"
        exit 1
    fi
fi

# Limpiar contenedores huérfanos
info "Limpiando contenedores huérfanos..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

log "📥 DESCARGANDO IMÁGENES DOCKER"
log "=============================="

info "Descargando/actualizando imágenes Docker..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" pull

log "🗄️ INICIALIZANDO BASE DE DATOS"
log "=============================="

# Iniciar MariaDB primero
info "Iniciando servicio de base de datos..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d db

# Esperar a que MariaDB esté listo
info "Esperando que MariaDB esté listo..."
DB_READY=false
TIMEOUT=120
COUNTER=0

while [[ $DB_READY == false && $COUNTER -lt $TIMEOUT ]]; do
    if $DOCKER_COMPOSE -f "$COMPOSE_FILE" exec db mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; then
        DB_READY=true
        echo ""
        log "✅ MariaDB está listo"
    else
        echo -n "."
        sleep 2
        COUNTER=$((COUNTER + 2))
    fi
done

if [[ $DB_READY == false ]]; then
    error "Timeout esperando MariaDB. Verificar logs:"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" logs db | tail -20
    exit 1
fi

# Verificar/crear base de datos de Koha
info "Verificando base de datos de Koha..."
DB_EXISTS=$($DOCKER_COMPOSE -f "$COMPOSE_FILE" exec db mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE '${KOHA_DB_NAME:-koha_production}'" | grep -c "${KOHA_DB_NAME:-koha_production}" || echo "0")

if [[ $DB_EXISTS -eq 0 ]]; then
    info "Creando base de datos de Koha..."
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" exec db mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "
        CREATE DATABASE IF NOT EXISTS \`${KOHA_DB_NAME:-koha_production}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '${KOHA_DB_USER:-koha_admin}'@'%' IDENTIFIED BY '${KOHA_DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${KOHA_DB_NAME:-koha_production}\`.* TO '${KOHA_DB_USER:-koha_admin}'@'%';
        FLUSH PRIVILEGES;
    "
    log "✅ Base de datos de Koha creada"
else
    info "Base de datos de Koha ya existe"
fi

log "🐰 INICIALIZANDO RABBITMQ"
log "========================"

# Iniciar RabbitMQ
info "Iniciando RabbitMQ..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d rabbitmq

# Esperar a que RabbitMQ esté listo
info "Esperando que RabbitMQ esté listo..."
RMQ_READY=false
TIMEOUT=60
COUNTER=0

while [[ $RMQ_READY == false && $COUNTER -lt $TIMEOUT ]]; do
    if $DOCKER_COMPOSE -f "$COMPOSE_FILE" exec rabbitmq rabbitmqctl status > /dev/null 2>&1; then
        RMQ_READY=true
        echo ""
        log "✅ RabbitMQ está listo"
    else
        echo -n "."
        sleep 2
        COUNTER=$((COUNTER + 2))
    fi
done

if [[ $RMQ_READY == false ]]; then
    error "Timeout esperando RabbitMQ. Verificar logs:"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" logs rabbitmq | tail -20
    exit 1
fi

# Configurar usuario de RabbitMQ para Koha
info "Configurando usuario RabbitMQ para Koha..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" exec rabbitmq rabbitmqctl add_user koha "${RABBITMQ_PASSWORD:-koha123}" 2>/dev/null || true
$DOCKER_COMPOSE -f "$COMPOSE_FILE" exec rabbitmq rabbitmqctl set_permissions koha ".*" ".*" ".*"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" exec rabbitmq rabbitmqctl set_user_tags koha administrator

# Habilitar plugin STOMP
info "Habilitando plugin STOMP en RabbitMQ..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" exec rabbitmq rabbitmq-plugins enable rabbitmq_stomp

log "🗃️ INICIALIZANDO MEMCACHED"
log "========================="

info "Iniciando Memcached..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d memcached

# Dar tiempo para que Memcached inicie
sleep 5

log "📚 INICIALIZANDO KOHA"
log "==================="

info "Iniciando servicio principal de Koha..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d koha

# Esperar a que Koha esté listo
info "Esperando que Koha esté listo (esto puede tomar varios minutos)..."
KOHA_READY=false
TIMEOUT=300
COUNTER=0

while [[ $KOHA_READY == false && $COUNTER -lt $TIMEOUT ]]; do
    # Verificar OPAC
    if timeout 5 curl -s http://localhost:8080 > /dev/null 2>&1; then
        # Verificar Staff Interface
        if timeout 5 curl -s http://localhost:8081 > /dev/null 2>&1; then
            KOHA_READY=true
            echo ""
            log "✅ Koha está listo y respondiendo"
        fi
    fi
    
    if [[ $KOHA_READY == false ]]; then
        echo -n "."
        sleep 5
        COUNTER=$((COUNTER + 5))
    fi
done

if [[ $KOHA_READY == false ]]; then
    warning "Koha tardó más de lo esperado en responder"
    info "Verificando logs de Koha:"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" logs koha | tail -30
    warning "Continuando de todos modos..."
fi

log "🔧 CONFIGURACIÓN FINAL"
log "====================="

# Verificar estado de todos los servicios
info "Verificando estado de servicios..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" ps

# Configurar servicio systemd si no está activo
if systemctl is-enabled koha-docker.service &> /dev/null; then
    info "Iniciando servicio systemd..."
    systemctl start koha-docker.service
    log "✅ Servicio systemd iniciado"
else
    warning "Servicio systemd no configurado"
fi

# Crear archivo de estado
echo "# Koha Docker inicializado exitosamente" > "$INSTALL_DIR/.koha_initialized"
echo "INIT_DATE=$(date)" >> "$INSTALL_DIR/.koha_initialized"
echo "KOHA_VERSION=${KOHA_VERSION:-24.11}" >> "$INSTALL_DIR/.koha_initialized"
echo "DB_NAME=${KOHA_DB_NAME:-koha_production}" >> "$INSTALL_DIR/.koha_initialized"

log "🎉 INICIALIZACIÓN COMPLETADA EXITOSAMENTE"
log "========================================"
echo ""
info "🌐 INFORMACIÓN DE ACCESO:"
info "========================"
info "📱 OPAC (Catálogo Público): http://${KOHA_DOMAIN:-localhost}:8080"
info "🏢 Staff Interface (Administración): http://${KOHA_DOMAIN:-localhost}:8081"
echo ""
info "🔐 CREDENCIALES:"
info "==============="
info "👤 Usuario: ${KOHA_ADMIN_USER:-koha_admin}"
info "🔑 Contraseña: ${KOHA_ADMIN_PASSWORD:-admin123}"
echo ""
info "🗄️ BASE DE DATOS:"
info "================"
info "📊 Nombre: ${KOHA_DB_NAME:-koha_production}"
info "👤 Usuario: ${KOHA_DB_USER:-koha_admin}"
info "🔑 Contraseña: ${KOHA_DB_PASSWORD}"
echo ""
warning "⚠️ PRÓXIMOS PASOS:"
warning "=================="
warning "1. Acceder al Staff Interface (puerto 8081)"
warning "2. Completar el asistente web de instalación de Koha"
warning "3. Configurar la biblioteca y parámetros del sistema"
warning "4. Importar datos iniciales si es necesario"
echo ""
info "📊 HERRAMIENTAS DE GESTIÓN:"
info "=========================="
info "🔍 Estado del sistema: koha-status.sh"
info "⚙️ Gestión de servicios: $INSTALL_DIR/manage.sh {start|stop|restart|status|logs}"
info "📋 Ver logs en tiempo real: $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f [servicio]"
echo ""

# Mostrar resumen de servicios
echo "================================================"
echo "🎊 KOHA DOCKER INICIADO EXITOSAMENTE"
echo "================================================"
echo "📅 Fecha de inicialización: $(date)"
echo "🐳 Docker Compose: $DOCKER_COMPOSE"
echo "📁 Directorio de instalación: $INSTALL_DIR"
echo "💾 Directorio de datos: $DATA_DIR"
echo "================================================"

# Ejecutar verificación final
if command -v koha-status.sh &> /dev/null; then
    echo ""
    info "🔍 Ejecutando verificación final..."
    koha-status.sh
fi