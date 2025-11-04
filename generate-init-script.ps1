# =============================================================================
# GENERADOR DEL SCRIPT DE INICIALIZACIÓN LINUX
# =============================================================================
# Crea el script init.sh que será ejecutado en Linux para inicializar Koha

$initScriptContent = @'
#!/bin/bash
# =============================================================================
# SCRIPT DE INICIALIZACIÓN KOHA LINUX
# =============================================================================
# Inicializa los volúmenes persistentes y levanta Koha en producción

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}" >&2; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

# Cargar variables de entorno
if [[ ! -f .env ]]; then
    error "Archivo .env no encontrado"
    exit 1
fi

source .env

log "🚀 Iniciando inicialización de Koha Docker"

# Verificar que estamos en el directorio correcto
if [[ ! -f docker-compose.yml ]]; then
    error "docker-compose.yml no encontrado. ¿Estás en el directorio correcto?"
    exit 1
fi

# Crear volúmenes persistentes si no existen
log "💾 Creando volúmenes persistentes..."
docker volume create koha-etc 2>/dev/null || true
docker volume create koha-var 2>/dev/null || true  
docker volume create koha-logs 2>/dev/null || true
docker volume create koha-uploads 2>/dev/null || true
docker volume create koha-plugins 2>/dev/null || true
docker volume create koha-covers 2>/dev/null || true
docker volume create mariadb-data 2>/dev/null || true
docker volume create rabbitmq-data 2>/dev/null || true
docker volume create memcached-data 2>/dev/null || true

# Verificar si hay contenedores corriendo
if docker compose ps | grep -q "Up"; then
    warning "Hay contenedores corriendo. ¿Detener y reiniciar? (s/N)"
    read -r response
    if [[ "$response" == "s" || "$response" == "S" ]]; then
        log "🛑 Deteniendo servicios existentes..."
        docker compose down
    else
        error "No se puede continuar con servicios corriendo"
        exit 1
    fi
fi

# Limpiar contenedores huérfanos
log "🧹 Limpiando contenedores huérfanos..."
docker compose down --remove-orphans 2>/dev/null || true

# Descargar imágenes necesarias
log "📥 Descargando imágenes Docker..."
docker compose pull

# Crear redes si no existen
log "🌐 Configurando redes Docker..."
docker network create koha-network 2>/dev/null || true

# Iniciar base de datos primero
log "🗄️ Iniciando base de datos..."
docker compose up -d db

# Esperar a que la base de datos esté lista
log "⏳ Esperando que la base de datos esté lista..."
timeout=60
counter=0
while ! docker compose exec db mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        error "Timeout esperando la base de datos"
        docker compose logs db
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
echo ""
info "Base de datos lista"

# Iniciar RabbitMQ
log "🐰 Iniciando RabbitMQ..."
docker compose up -d rabbitmq

# Esperar RabbitMQ
log "⏳ Esperando RabbitMQ..."
timeout=30
counter=0
while ! docker compose exec rabbitmq rabbitmqctl status > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        error "Timeout esperando RabbitMQ"
        docker compose logs rabbitmq
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
echo ""
info "RabbitMQ listo"

# Configurar usuario de RabbitMQ
log "🔧 Configurando usuario RabbitMQ..."
docker compose exec rabbitmq rabbitmqctl add_user koha "$RABBITMQ_PASSWORD" 2>/dev/null || true
docker compose exec rabbitmq rabbitmqctl set_permissions koha ".*" ".*" ".*"
docker compose exec rabbitmq rabbitmqctl set_user_tags koha administrator

# Iniciar Memcached
log "🗃️ Iniciando Memcached..."
docker compose up -d memcached

# Esperar un poco más
log "⏳ Esperando estabilización de servicios..."
sleep 10

# Iniciar Koha
log "📚 Iniciando Koha..."
docker compose up -d koha

# Esperar a que Koha esté listo
log "⏳ Esperando que Koha esté listo..."
timeout=180
counter=0
while ! curl -s http://localhost:8080 > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        error "Timeout esperando Koha"
        log "Mostrando logs de Koha:"
        docker compose logs koha | tail -50
        exit 1
    fi
    sleep 5
    counter=$((counter + 5))
    echo -n "."
done
echo ""

# Verificar estado de todos los servicios
log "📊 Verificando estado de servicios..."
docker compose ps

# Mostrar información de acceso
log "✅ Koha inicializado exitosamente!"
echo ""
info "=== INFORMACIÓN DE ACCESO ==="
info "OPAC (Catálogo Público): http://$KOHA_DOMAIN:8080"
info "Staff Interface (Administración): http://$KOHA_DOMAIN:8081"
echo ""
info "=== CREDENCIALES INICIALES ==="
info "Usuario: $KOHA_ADMIN_USER"
info "Contraseña: $KOHA_ADMIN_PASSWORD"
echo ""
warning "=== PRÓXIMOS PASOS ==="
warning "1. Acceder al Staff Interface para completar la instalación"
warning "2. Seguir el asistente web de instalación"
warning "3. Configurar la biblioteca y parámetros iniciales"
echo ""

# Configurar servicio systemd
if systemctl list-unit-files | grep -q koha-docker.service; then
    log "🔧 Habilitando servicio systemd..."
    systemctl enable koha-docker
    systemctl start koha-docker
    info "Servicio systemd configurado y habilitado"
else
    warning "Servicio systemd no encontrado, instalar manualmente si es necesario"
fi

# Crear script de monitoreo básico
log "📊 Configurando monitoreo básico..."
cat > /usr/local/bin/koha-status.sh << 'MONITOR_EOF'
#!/bin/bash
echo "=== ESTADO DE KOHA DOCKER ==="
echo "Fecha: $(date)"
echo ""

cd /opt/koha-docker 2>/dev/null || cd .

echo "--- Servicios Docker ---"
docker compose ps

echo ""
echo "--- Uso de Recursos ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "--- Volúmenes ---"
docker volume ls | grep koha

echo ""
echo "--- Logs Recientes ---"
echo "Últimas 5 líneas del log de Koha:"
docker compose logs koha | tail -5

echo ""
echo "--- Conectividad ---"
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ OPAC accesible"
else
    echo "❌ OPAC no accesible"
fi

if curl -s http://localhost:8081 > /dev/null; then
    echo "✅ Staff Interface accesible"  
else
    echo "❌ Staff Interface no accesible"
fi
MONITOR_EOF

chmod +x /usr/local/bin/koha-status.sh

log "✅ Inicialización completada"
log "Ejecuta 'koha-status.sh' para ver el estado del sistema"

# Mostrar resumen final
echo ""
echo "================================================"
echo "🎉 KOHA DOCKER INICIADO EXITOSAMENTE"
echo "================================================"
echo "📱 Acceso OPAC: http://$KOHA_DOMAIN:8080"  
echo "🏢 Acceso Staff: http://$KOHA_DOMAIN:8081"
echo "👤 Usuario: $KOHA_ADMIN_USER"
echo "🔑 Contraseña: $KOHA_ADMIN_PASSWORD"
echo "📊 Estado: koha-status.sh"
echo "📋 Logs: docker compose logs [servicio]"
echo "================================================"
'@

# Escribir el script a un archivo temporal para luego copiarlo
$initScriptContent | Out-File -FilePath "init-template.sh" -Encoding UTF8

Write-Host "✅ Plantilla init.sh creada" -ForegroundColor Green