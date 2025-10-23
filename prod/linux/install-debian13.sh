#!/bin/bash

# ==========================================================
# INSTALADOR DE KOHA DOCKER PARA DEBIAN 13
# ==========================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

# Verificar Debian 13
if ! grep -q "Debian GNU/Linux 13" /etc/os-release; then
    warning "Este script está optimizado para Debian 13. Continuando de todos modos..."
fi

log "🚀 Iniciando instalación de Koha Docker para Debian 13"

# Variables de configuración
INSTALL_DIR="/opt/koha-docker"
DATA_DIR="/opt/koha-docker/data"
LOGS_DIR="/var/log/koha-docker"
BACKUP_DIR="/opt/koha-docker/backups"
CONFIG_DIR="/etc/koha-docker"
USER_GROUP="koha-docker"
SERVICE_USER="koha"

# Crear usuario del sistema
log "👤 Creando usuario del sistema..."
if ! getent group $USER_GROUP > /dev/null 2>&1; then
    groupadd $USER_GROUP
fi

if ! getent passwd $SERVICE_USER > /dev/null 2>&1; then
    useradd -r -g $USER_GROUP -s /bin/bash -d $INSTALL_DIR $SERVICE_USER
fi

# Actualizar sistema (mínimo en Debian 13)
log "📦 Actualizando lista de paquetes..."
apt-get update

# Instalar herramientas básicas que faltan en Debian 13 básico
log "🛠️ Instalando herramientas básicas para Debian 13..."
apt-get install -y \
    curl \
    wget \
    git \
    nano \
    htop \
    unzip \
    gzip \
    tar \
    cron \
    logrotate \
    ca-certificates \
    gnupg \
    lsb-release

# Verificar Docker
log "🐳 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado. Por favor instala Docker primero."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    if ! docker compose version &> /dev/null; then
        error "Docker Compose no está disponible."
        exit 1
    else
        info "Usando Docker Compose V2 (docker compose)"
        DOCKER_COMPOSE="docker compose"
    fi
else
    info "Usando Docker Compose V1 (docker-compose)"
    DOCKER_COMPOSE="docker-compose"
fi

# Verificar que Docker esté corriendo
if ! systemctl is-active --quiet docker; then
    log "🔄 Iniciando Docker..."
    systemctl start docker
    systemctl enable docker
fi

# Agregar usuario al grupo docker
log "👥 Configurando permisos de Docker..."
usermod -aG docker $SERVICE_USER

# Crear estructura de directorios
log "📁 Creando estructura de directorios..."
directories=(
    "$INSTALL_DIR"
    "$DATA_DIR/mariadb"
    "$DATA_DIR/koha/etc"
    "$DATA_DIR/koha/var"
    "$DATA_DIR/koha/uploads"
    "$DATA_DIR/koha/covers"
    "$DATA_DIR/rabbitmq"
    "$LOGS_DIR/koha"
    "$LOGS_DIR/mariadb"
    "$LOGS_DIR/nginx"
    "$BACKUP_DIR"
    "$CONFIG_DIR"
    "$INSTALL_DIR/ssl"
    "$INSTALL_DIR/config/nginx/sites"
    "$INSTALL_DIR/config/mariadb"
    "$INSTALL_DIR/config/rabbitmq"
    "$INSTALL_DIR/config/koha"
    "$INSTALL_DIR/scripts"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    chown $SERVICE_USER:$USER_GROUP "$dir"
done

# Descargar archivos del repositorio
log "📥 Descargando configuración desde GitHub..."
cd $INSTALL_DIR

# Clonar o descargar archivos
if [[ -d ".git" ]]; then
    info "Repositorio ya existe, actualizando..."
    sudo -u $SERVICE_USER git pull
else
    info "Clonando repositorio..."
    sudo -u $SERVICE_USER git clone https://github.com/matiasgel/koha-docker.git .
fi

# Copiar configuración específica para Debian 13
log "⚙️ Configurando archivos para Debian 13..."
cp prod/linux/.env.debian13 .env
cp prod/linux/docker-compose.debian13.yml docker-compose.yml

# Crear configuración de MariaDB
cat > config/mariadb/my.cnf << 'EOF'
[mysqld]
# Configuración optimizada para Koha en Debian 13
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Performance
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 200
query_cache_size = 64M
query_cache_type = 1

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1

# Security
bind-address = 0.0.0.0
skip-name-resolve

[client]
default-character-set = utf8mb4
EOF

# Crear configuración de RabbitMQ
cat > config/rabbitmq/enabled_plugins << 'EOF'
[rabbitmq_management,rabbitmq_stomp].
EOF

cat > config/rabbitmq/rabbitmq.conf << 'EOF'
# Configuración RabbitMQ para Koha
loopback_users.guest = false
listeners.tcp.default = 5672
management.listener.port = 15672
management.listener.ssl = false
default_user = pjnadmin_rabbit
default_pass = pjnadmin_rabbit_2024!
EOF

# Crear configuración básica de Nginx
cat > config/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > config/nginx/sites/koha.conf << 'EOF'
server {
    listen 80;
    server_name biblioteca.local catalogo.local;
    
    location / {
        proxy_pass http://koha:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /staff {
        proxy_pass http://koha:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Crear script de backup
cat > scripts/backup.sh << 'EOF'
#!/bin/bash

# Script de backup automático
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/koha_backup_$BACKUP_DATE"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

mkdir -p "$BACKUP_DIR"

# Backup de base de datos
echo "Realizando backup de base de datos..."
mariadb-dump -h mariadb -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/database.sql"

# Backup de configuración
echo "Backing up configuration..."
tar -czf "$BACKUP_DIR/koha_config.tar.gz" -C /etc/koha .
tar -czf "$BACKUP_DIR/koha_data.tar.gz" -C /var/lib/koha .

# Limpiar backups antiguos
find /backups -name "koha_backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +

echo "Backup completado: $BACKUP_DIR"
EOF

chmod +x scripts/backup.sh

# Crear script de inicialización de base de datos
cat > scripts/init-db.sql << 'EOF'
-- Optimizaciones para Koha en producción
SET GLOBAL innodb_buffer_pool_size = 1073741824;
SET GLOBAL query_cache_size = 67108864;
SET GLOBAL max_connections = 200;

-- Crear usuario adicional para monitoreo
CREATE USER IF NOT EXISTS 'pjnadmin_monitor'@'%' IDENTIFIED BY 'pjnadmin_monitor_2024!';
GRANT SELECT ON *.* TO 'pjnadmin_monitor'@'%';
FLUSH PRIVILEGES;
EOF

# Configurar logrotate
cat > /etc/logrotate.d/koha-docker << 'EOF'
/var/log/koha-docker/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 koha koha-docker
    postrotate
        docker compose -f /opt/koha-docker/docker-compose.yml restart koha > /dev/null 2>&1 || true
    endscript
}
EOF

# Crear servicio systemd
cat > /etc/systemd/system/koha-docker.service << 'EOF'
[Unit]
Description=Koha Docker Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/koha-docker
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
User=koha
Group=koha-docker

[Install]
WantedBy=multi-user.target
EOF

# Configurar permisos
log "🔒 Configurando permisos..."
chown -R $SERVICE_USER:$USER_GROUP $INSTALL_DIR
chown -R $SERVICE_USER:$USER_GROUP $DATA_DIR
chown -R $SERVICE_USER:$USER_GROUP $LOGS_DIR
chown -R $SERVICE_USER:$USER_GROUP $BACKUP_DIR

# Configurar firewall básico (si ufw está disponible)
if command -v ufw &> /dev/null; then
    log "🔥 Configurando firewall básico..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw --force enable
fi

# Habilitar servicios
log "🔄 Habilitando servicios..."
systemctl daemon-reload
systemctl enable koha-docker
systemctl enable cron

# Configurar variables de entorno personalizadas
log "⚙️ Configurando variables de entorno..."
cat >> .env << 'EOF'

# ==========================================================
# CONFIGURACIÓN PERSONALIZADA DESPUÉS DE LA INSTALACIÓN
# ==========================================================
# Cambia estas variables según tus necesidades:

# Dominio de tu biblioteca
# KOHA_DOMAIN=tu-biblioteca.com
# OPAC_DOMAIN=catalogo.tu-biblioteca.com

# Configuración de email
# SMTP_HOST=smtp.tu-proveedor.com
# SMTP_PORT=587
# SMTP_USER=koha@tu-biblioteca.com
# SMTP_PASSWORD=tu_password_email

# Ruta de backups (debe existir)
# BACKUP_PATH=/ruta/a/tus/backups

# Zona horaria
# TIMEZONE=America/Argentina/Buenos_Aires
EOF

# Mostrar información final
log "✅ Instalación completada!"
echo ""
info "📁 Directorio de instalación: $INSTALL_DIR"
info "💾 Directorio de datos: $DATA_DIR"
info "📋 Directorio de logs: $LOGS_DIR"
info "💿 Directorio de backups: $BACKUP_DIR"
echo ""
warning "⚠️ IMPORTANTE: Antes de iniciar los servicios:"
warning "1. Edita el archivo $INSTALL_DIR/.env con tus configuraciones"
warning "2. Cambia las contraseñas por defecto"
warning "3. Configura tu dominio y SSL si es necesario"
echo ""
info "🚀 Para iniciar Koha Docker:"
info "   cd $INSTALL_DIR"
info "   sudo systemctl start koha-docker"
echo ""
info "🔧 Para gestionar los servicios:"
info "   sudo systemctl status koha-docker"
info "   sudo systemctl stop koha-docker"
info "   sudo systemctl restart koha-docker"
echo ""
info "📊 Para ver logs:"
info "   sudo docker compose logs -f"
echo ""
info "🌐 Una vez iniciado, accede a:"
info "   - Staff Interface: http://localhost:8081"
info "   - OPAC: http://localhost:8080"
info "   - RabbitMQ Management: http://localhost:15672"
echo ""
info "🔑 Credenciales iniciales:"
info "   - Usuario: pjnadmin_koha"
info "   - Contraseña: pjnadmin_db_2024!"
echo ""
log "📖 Consulta la documentación completa en:"
log "   https://github.com/matiasgel/koha-docker"