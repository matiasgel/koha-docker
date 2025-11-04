#!/bin/bash
# =============================================================================
# KOHA DOCKER - SETUP COMPLETO DESDE CERO  
# =============================================================================
# Este script limpia todas las imágenes y contenedores de Koha existentes,
# crea la estructura de directorios para volúmenes persistentes y prepara
# el entorno para una instalación limpia de Koha en producción Linux.
#
# USO: sudo ./setup.sh
# 
# REQUISITOS:
# - Ejecutar como root (sudo)  
# - Docker y Docker Compose instalados
# - Repositorio koha-docker clonado
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

log "🚀 KOHA DOCKER - SETUP COMPLETO DESDE CERO"
log "=========================================="

# Verificar Docker
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    if ! docker-compose --version &> /dev/null; then
        error "Docker Compose no está disponible"
        exit 1
    else
        info "Usando docker-compose (v1)"
        DOCKER_COMPOSE="docker-compose"
    fi
else
    info "Usando docker compose (v2)"
    DOCKER_COMPOSE="docker compose"
fi

# Cargar configuración si existe
if [[ -f .env ]]; then
    log "📋 Cargando configuración desde .env"
    source .env
else
    warning "Archivo .env no encontrado, usando valores por defecto"
    # Valores por defecto
    INSTALL_DIR="/opt/koha-docker"
    DATA_DIR="/opt/koha-docker/data"
    BACKUP_DIR="/opt/koha-docker/backups"
    LOG_DIR="/var/log/koha-docker"
fi

log "🧹 LIMPIANDO INSTALACIÓN ANTERIOR DE KOHA"
log "========================================="

# Detener y eliminar contenedores de Koha existentes
info "Deteniendo contenedores de Koha..."
$DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=koha") 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=mariadb") 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=rabbitmq") 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=memcached") 2>/dev/null || true

# Eliminar contenedores de Koha
info "Eliminando contenedores de Koha..."
docker rm $(docker ps -a -q --filter "name=koha") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=mariadb") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=rabbitmq") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=memcached") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=db") 2>/dev/null || true

# Eliminar volúmenes de Koha (CUIDADO: Esto elimina todos los datos)
warning "¿Eliminar volúmenes existentes de Koha? Esto ELIMINARÁ TODOS LOS DATOS (s/N):"
read -r response
if [[ "$response" == "s" || "$response" == "S" ]]; then
    info "Eliminando volúmenes de Koha..."
    docker volume rm $(docker volume ls -q | grep koha) 2>/dev/null || true
    docker volume rm $(docker volume ls -q | grep mariadb) 2>/dev/null || true  
    docker volume rm $(docker volume ls -q | grep rabbitmq) 2>/dev/null || true
    docker volume rm $(docker volume ls -q | grep memcached) 2>/dev/null || true
    log "✅ Volúmenes eliminados"
else
    info "Conservando volúmenes existentes"
fi

# Eliminar imágenes de Koha (opcional)
warning "¿Eliminar imágenes Docker de Koha para forzar descarga fresca? (s/N):"
read -r response
if [[ "$response" == "s" || "$response" == "S" ]]; then
    info "Eliminando imágenes de Koha..."
    docker rmi $(docker images | grep koha | awk '{print $3}') 2>/dev/null || true
    docker rmi $(docker images | grep mariadb | awk '{print $3}') 2>/dev/null || true
    docker rmi $(docker images | grep rabbitmq | awk '{print $3}') 2>/dev/null || true
    docker rmi $(docker images | grep memcached | awk '{print $3}') 2>/dev/null || true
    log "✅ Imágenes eliminadas"
fi

# Limpiar contenedores huérfanos y caché
info "Limpiando sistema Docker..."
docker system prune -f
docker network prune -f

log "🏗️ CREANDO ESTRUCTURA DE DIRECTORIOS"
log "===================================="

# Crear usuario del sistema para Koha
info "Creando usuario del sistema..."
groupadd koha-docker 2>/dev/null || true
useradd -r -g koha-docker -s /bin/bash -d "$INSTALL_DIR" koha 2>/dev/null || true

# Crear estructura de directorios
info "Creando estructura de directorios..."

# Directorio principal de instalación
mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

# Directorios para volúmenes persistentes
mkdir -p "$DATA_DIR/koha/etc"
mkdir -p "$DATA_DIR/koha/var"
mkdir -p "$DATA_DIR/koha/logs"
mkdir -p "$DATA_DIR/koha/uploads"
mkdir -p "$DATA_DIR/koha/plugins"
mkdir -p "$DATA_DIR/koha/covers"

# Directorios para base de datos
mkdir -p "$DATA_DIR/mariadb/data"
mkdir -p "$DATA_DIR/mariadb/logs"
mkdir -p "$DATA_DIR/mariadb/conf"

# Directorios para RabbitMQ
mkdir -p "$DATA_DIR/rabbitmq/data"
mkdir -p "$DATA_DIR/rabbitmq/logs"
mkdir -p "$DATA_DIR/rabbitmq/conf"

# Directorios para Memcached
mkdir -p "$DATA_DIR/memcached"

# Directorios para SSL
mkdir -p "$INSTALL_DIR/ssl"

# Directorios para configuración
mkdir -p "$INSTALL_DIR/config"
mkdir -p "$INSTALL_DIR/scripts"

log "✅ Estructura de directorios creada"

# Establecer permisos correctos
info "Estableciendo permisos..."
chown -R koha:koha-docker "$INSTALL_DIR"
chown -R koha:koha-docker "$DATA_DIR"
chown -R koha:koha-docker "$LOG_DIR"

# Permisos específicos para directorios de datos
chmod 755 "$DATA_DIR"
chmod 755 "$DATA_DIR"/koha
chmod 755 "$DATA_DIR"/mariadb
chmod 755 "$DATA_DIR"/rabbitmq

# Permisos para MariaDB (necesita permisos específicos)
chmod 750 "$DATA_DIR"/mariadb/data
chown -R 999:999 "$DATA_DIR"/mariadb/data

log "✅ Permisos establecidos"

log "🐳 PREPARANDO ENTORNO DOCKER"
log "============================"

# Crear redes Docker si no existen
info "Creando redes Docker..."
docker network create koha-network --subnet=172.20.0.0/16 2>/dev/null || true
docker network create koha-backend --subnet=172.21.0.0/16 2>/dev/null || true

# Crear volúmenes Docker persistentes
info "Creando volúmenes Docker..."
docker volume create koha-etc 2>/dev/null || true
docker volume create koha-var 2>/dev/null || true
docker volume create koha-logs 2>/dev/null || true
docker volume create koha-uploads 2>/dev/null || true
docker volume create koha-plugins 2>/dev/null || true
docker volume create koha-covers 2>/dev/null || true
docker volume create mariadb-data 2>/dev/null || true
docker volume create mariadb-conf 2>/dev/null || true
docker volume create rabbitmq-data 2>/dev/null || true
docker volume create rabbitmq-conf 2>/dev/null || true

log "✅ Volúmenes Docker creados"

log "🔧 CONFIGURANDO SISTEMA"
log "======================"

# Generar certificados SSL auto-firmados
info "Generando certificados SSL..."
if [[ ! -f "$INSTALL_DIR/ssl/cert.pem" ]]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$INSTALL_DIR/ssl/key.pem" \
        -out "$INSTALL_DIR/ssl/cert.pem" \
        -subj "/C=AR/ST=Buenos Aires/L=Buenos Aires/O=Koha Library/CN=${KOHA_DOMAIN:-localhost}"
    
    chmod 600 "$INSTALL_DIR/ssl/key.pem"
    chmod 644 "$INSTALL_DIR/ssl/cert.pem"
    chown koha:koha-docker "$INSTALL_DIR/ssl"/*
    
    log "✅ Certificados SSL generados"
else
    info "Certificados SSL ya existen"
fi

# Crear configuración de MariaDB optimizada
info "Creando configuración de MariaDB..."
cat > "$DATA_DIR/mariadb/conf/my.cnf" << 'EOF'
[mysqld]
# Configuración básica
bind-address = 0.0.0.0
port = 3306
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid
datadir = /var/lib/mysql

# Configuración de memoria (ajustar según RAM disponible)
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
key_buffer_size = 128M
max_connections = 200
table_open_cache = 400

# Configuración de caracteres para Koha
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Configuración de logs
log-error = /var/log/mysql/error.log
slow-query-log = 1
slow-query-log-file = /var/log/mysql/slow.log
long_query_time = 2

# Configuración InnoDB
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

[client]
default-character-set = utf8mb4
port = 3306
socket = /var/run/mysqld/mysqld.sock

[mysql]
default-character-set = utf8mb4
EOF

# Crear configuración de RabbitMQ
info "Creando configuración de RabbitMQ..."
cat > "$DATA_DIR/rabbitmq/conf/rabbitmq.conf" << 'EOF'
# Configuración básica RabbitMQ para Koha
loopback_users.guest = false
listeners.tcp.default = 5672
management.tcp.port = 15672

# Configuración de logs
log.file.level = info
log.console = true
log.console.level = info

# Habilitar plugins necesarios
plugins.directories.1 = /opt/rabbitmq/plugins
EOF

# Crear archivo de plugins habilitados para RabbitMQ
echo "rabbitmq_stomp." > "$DATA_DIR/rabbitmq/conf/enabled_plugins"

# Crear servicio systemd
info "Creando servicio systemd..."
cat > /etc/systemd/system/koha-docker.service << EOF
[Unit]
Description=Koha Docker Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PWD
ExecStart=/usr/bin/$DOCKER_COMPOSE up -d
ExecStop=/usr/bin/$DOCKER_COMPOSE down
TimeoutStartSec=300
User=koha
Group=koha-docker

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable koha-docker

log "✅ Servicio systemd configurado"

# Crear script de monitoreo
info "Creando script de monitoreo..."
cat > /usr/local/bin/koha-status.sh << 'EOF'
#!/bin/bash
echo "========================================="
echo "ESTADO DE KOHA DOCKER"
echo "========================================="
echo "Fecha: $(date)"
echo ""

cd /opt/koha-docker 2>/dev/null || cd .

echo "--- Servicios Docker ---"
docker compose ps 2>/dev/null || docker-compose ps

echo ""
echo "--- Uso de Recursos ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null || echo "No se pueden obtener estadísticas"

echo ""
echo "--- Volúmenes ---"
docker volume ls | grep -E "(koha|mariadb|rabbitmq|memcached)" | head -10

echo ""
echo "--- Estado de Red ---"
docker network ls | grep koha

echo ""
echo "--- Conectividad ---"
if timeout 5 curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ OPAC (puerto 8080) accesible"
else
    echo "❌ OPAC (puerto 8080) no accesible"
fi

if timeout 5 curl -s http://localhost:8081 > /dev/null 2>&1; then
    echo "✅ Staff Interface (puerto 8081) accesible"
else
    echo "❌ Staff Interface (puerto 8081) no accesible"
fi

echo ""
echo "--- Logs Recientes (últimas 5 líneas) ---"
docker compose logs koha 2>/dev/null | tail -5 || echo "No hay logs disponibles"
EOF

chmod +x /usr/local/bin/koha-status.sh

# Crear script de gestión rápida
info "Creando script de gestión..."
cat > "$INSTALL_DIR/manage.sh" << 'EOF'
#!/bin/bash
ACTION=$1
SERVICE=$2

case $ACTION in
    start)
        echo "🚀 Iniciando Koha Docker..."
        docker compose up -d
        ;;
    stop)
        echo "🛑 Deteniendo Koha Docker..."
        docker compose down
        ;;
    restart)
        echo "🔄 Reiniciando Koha Docker..."
        docker compose restart ${SERVICE:-}
        ;;
    status)
        echo "📊 Estado de Koha Docker:"
        docker compose ps
        ;;
    logs)
        if [[ -n "$SERVICE" ]]; then
            docker compose logs -f "$SERVICE"
        else
            docker compose logs -f
        fi
        ;;
    update)
        echo "🔄 Actualizando imágenes Docker..."
        docker compose pull
        docker compose up -d
        ;;
    clean)
        echo "🧹 Limpiando logs y cachés..."
        docker system prune -f
        ;;
    backup)
        echo "💾 Iniciando backup..."
        ./scripts/backup.sh 2>/dev/null || echo "Script de backup no encontrado"
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|update|clean|backup} [servicio]"
        echo ""
        echo "Ejemplos:"
        echo "  $0 start           # Iniciar todos los servicios"
        echo "  $0 logs koha       # Ver logs del servicio Koha"
        echo "  $0 restart db      # Reiniciar solo la base de datos"
        exit 1
        ;;
esac
EOF

chmod +x "$INSTALL_DIR/manage.sh"
chown koha:koha-docker "$INSTALL_DIR/manage.sh"

log "🎉 SETUP COMPLETADO EXITOSAMENTE"
log "==============================="
echo ""
info "📁 Estructura creada en: $INSTALL_DIR"
info "💾 Datos persistentes en: $DATA_DIR"  
info "📋 Logs del sistema en: $LOG_DIR"
info "🔐 Certificados SSL en: $INSTALL_DIR/ssl"
echo ""
warning "PRÓXIMOS PASOS:"
warning "1. Verificar/editar el archivo .env con la configuración"
warning "2. Ejecutar: sudo ./init.sh para inicializar los servicios"
warning "3. Acceder vía web para completar la instalación de Koha"
echo ""
info "📊 Monitoreo: koha-status.sh"
info "🔧 Gestión: $INSTALL_DIR/manage.sh {start|stop|status|logs}"
echo ""
log "✅ Sistema listo para inicialización"