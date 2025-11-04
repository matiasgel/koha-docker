# =============================================================================
# SCRIPT DE PREPARACIÓN KOHA LINUX DESDE WINDOWS
# =============================================================================
# Prepara todos los archivos necesarios para instalación de Koha en Linux
# desde un sistema Windows. Genera configuraciones, .env y scripts listos
# para transferir y ejecutar en el servidor Linux de destino.

param(
    [Parameter(Mandatory=$false)]
    [string]$LinuxServerIP = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "biblioteca.local",
    
    [Parameter(Mandatory=$false)]
    [string]$OpacDomain = "catalogo.local",
    
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "/opt/koha-docker",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "koha-linux-deployment"
)

$ErrorActionPreference = "Stop"

# Funciones de utilidad
function Write-ColoredOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Generate-SecurePassword {
    param([int]$Length = 16)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    return (-join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] }))
}

Write-ColoredOutput "PREPARACION DE KOHA PARA LINUX DESDE WINDOWS" "Green"
Write-ColoredOutput "=============================================" "Green"

# Crear directorio de salida
if (Test-Path $OutputDir) {
    Write-ColoredOutput "El directorio $OutputDir ya existe. Sobrescribir? (s/N)" "Yellow"
    $response = Read-Host
    if ($response -ne "s" -and $response -ne "S") {
        Write-ColoredOutput "Operacion cancelada" "Red"
        exit 1
    }
    Remove-Item -Recurse -Force $OutputDir
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Write-ColoredOutput "Creado directorio: $OutputDir" "Blue"

# Generar passwords seguros
$kohaDbPassword = Generate-SecurePassword 20
$mysqlRootPassword = Generate-SecurePassword 20
$rabbitmqPassword = Generate-SecurePassword 16
$kohaAdminPassword = Generate-SecurePassword 12

Write-ColoredOutput "Generando configuracion segura..." "Blue"

# Crear archivo .env para producción Linux
$envContent = @"
# =============================================================================
# CONFIGURACIÓN DE PRODUCCIÓN KOHA LINUX
# =============================================================================
# Generado automáticamente: $(Get-Date)

# === CONFIGURACIÓN DE BASE DE DATOS ===
KOHA_DB_NAME=koha_production
KOHA_DB_USER=koha_admin
KOHA_DB_PASSWORD=$kohaDbPassword
MYSQL_ROOT_PASSWORD=$mysqlRootPassword

# === CONFIGURACIÓN DE DOMINIO ===
KOHA_DOMAIN=$DomainName
OPAC_DOMAIN=$OpacDomain
KOHA_INSTANCE=production

# === PUERTOS Y SERVICIOS ===
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080
MEMCACHED_PORT=11211
RABBITMQ_PORT=5672
RABBITMQ_MGMT_PORT=15672

# === CREDENCIALES DE SERVICIOS ===
RABBITMQ_PASSWORD=$rabbitmqPassword
RABBITMQ_USER=koha

# === RUTAS DEL SISTEMA ===
INSTALL_DIR=$InstallPath
DATA_DIR=$InstallPath/data
BACKUP_DIR=$InstallPath/backups
LOG_DIR=/var/log/koha-docker

# === CONFIGURACIÓN REGIONAL ===
TIMEZONE=America/Argentina/Buenos_Aires
KOHA_LANGS=es-ES en-GB

# === CONFIGURACIÓN SSL ===
SSL_ENABLED=true
SSL_CERT_PATH=$InstallPath/ssl/cert.pem
SSL_KEY_PATH=$InstallPath/ssl/key.pem

# === CONFIGURACIÓN DE BACKUP ===
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"

# === CONFIGURACIÓN DE MONITOREO ===
MONITORING_ENABLED=true
LOG_LEVEL=INFO

# === CREDENCIALES INICIALES KOHA ===
KOHA_ADMIN_USER=koha_admin
KOHA_ADMIN_PASSWORD=$kohaAdminPassword
KOHA_LIBRARY_NAME=Biblioteca $(if ($DomainName -ne "biblioteca.local") { $DomainName.Split('.')[0] } else { "Principal" })
"@

$envContent | Out-File -FilePath "$OutputDir\.env" -Encoding UTF8
Write-ColoredOutput "Archivo .env creado" "Green"

# Copiar archivos de configuración necesarios
Write-ColoredOutput "📋 Copiando archivos de configuración..." "Blue"

# Crear estructura de directorios
$dirs = @("config", "scripts", "ssl", "volumes", "docker-compose")
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path "$OutputDir\$dir" -Force | Out-Null
}

# Copiar docker-compose para Linux
if (Test-Path "prod\linux\docker-compose.prod-linux.yaml") {
    Copy-Item "prod\linux\docker-compose.prod-linux.yaml" "$OutputDir\docker-compose.yml"
    Write-ColoredOutput "✅ Docker Compose copiado" "Green"
}

# Copiar configuraciones
if (Test-Path "prod\linux\config") {
    Copy-Item -Recurse "prod\linux\config\*" "$OutputDir\config\"
    Write-ColoredOutput "✅ Configuraciones copiadas" "Green"
}

# Copiar archivos base del proyecto
Copy-Item -Recurse "files" "$OutputDir\files"
Write-ColoredOutput "✅ Archivos base copiados" "Green"

# Crear script de setup inicial
$setupScript = @"
#!/bin/bash
# =============================================================================
# SCRIPT DE SETUP INICIAL KOHA LINUX
# =============================================================================
# Ejecutar este script en el servidor Linux de destino

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "`${GREEN}[`$(date +'%Y-%m-%d %H:%M:%S')] `$1`${NC}"; }
error() { echo -e "`${RED}[ERROR] `$1`${NC}" >&2; }
warning() { echo -e "`${YELLOW}[WARNING] `$1`${NC}"; }
info() { echo -e "`${BLUE}[INFO] `$1`${NC}"; }

# Verificar que se ejecuta como root
if [[ `$EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

log "🚀 Iniciando setup de Koha Docker"

# Cargar variables de entorno
if [[ ! -f .env ]]; then
    error "Archivo .env no encontrado"
    exit 1
fi

source .env

log "📦 Actualizando sistema..."
apt-get update
apt-get install -y curl wget git nano htop unzip gzip tar cron logrotate ca-certificates gnupg lsb-release

log "🐳 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    log "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

if ! docker compose version &> /dev/null; then
    error "Docker Compose no disponible"
    exit 1
fi

log "👤 Creando usuario del sistema..."
if ! getent group koha-docker > /dev/null 2>&1; then
    groupadd koha-docker
fi

if ! getent passwd koha > /dev/null 2>&1; then
    useradd -r -g koha-docker -s /bin/bash -d `$INSTALL_DIR koha
fi

log "📁 Creando estructura de directorios..."
mkdir -p `$INSTALL_DIR
mkdir -p `$DATA_DIR
mkdir -p `$BACKUP_DIR
mkdir -p `$LOG_DIR
mkdir -p `$INSTALL_DIR/ssl

# Copiar archivos a directorio final
cp -r . `$INSTALL_DIR/
cd `$INSTALL_DIR

# Establecer permisos
chown -R koha:koha-docker `$INSTALL_DIR
chmod +x scripts/*.sh

log "🔒 Generando certificados SSL auto-firmados..."
if [[ ! -f ssl/cert.pem ]]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=AR/ST=Buenos Aires/L=Buenos Aires/O=Koha/OU=IT/CN=`$KOHA_DOMAIN"
    
    chmod 600 ssl/key.pem
    chmod 644 ssl/cert.pem
fi

log "🔧 Configurando servicios del sistema..."

# Crear archivo de servicio systemd
cat > /etc/systemd/system/koha-docker.service << EOF
[Unit]
Description=Koha Docker Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=`$INSTALL_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
User=koha

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable koha-docker

log "✅ Setup inicial completado"
log "📋 Próximos pasos:"
log "   1. Revisar y ajustar .env si es necesario"
log "   2. Ejecutar: ./init.sh para inicializar Koha"
log "   3. Acceder via web para completar instalación"
"@

$setupScript | Out-File -FilePath "$OutputDir\setup.sh" -Encoding UTF8
Write-ColoredOutput "✅ Script setup.sh creado" "Green"

# Crear script de inicialización (init.sh)
$initScript = @"
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

log() { echo -e "`${GREEN}[`$(date +'%Y-%m-%d %H:%M:%S')] `$1`${NC}"; }
error() { echo -e "`${RED}[ERROR] `$1`${NC}" >&2; }
warning() { echo -e "`${YELLOW}[WARNING] `$1`${NC}"; }
info() { echo -e "`${BLUE}[INFO] `$1`${NC}"; }

# Verificar que se ejecuta como root
if [[ `$EUID -ne 0 ]]; then
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

# Verificar si hay contenedores corriendo
if docker compose ps | grep -q "Up"; then
    warning "Hay contenedores corriendo. ¿Detener y reiniciar? (s/N)"
    read -r response
    if [[ "`$response" == "s" || "`$response" == "S" ]]; then
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

# Iniciar base de datos primero
log "🗄️ Iniciando base de datos..."
docker compose up -d db

# Esperar a que la base de datos esté lista
log "⏳ Esperando que la base de datos esté lista..."
timeout=60
counter=0
while ! docker compose exec db mariadb -u root -p"`$MYSQL_ROOT_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
    if [ `$counter -ge `$timeout ]; then
        error "Timeout esperando la base de datos"
        docker compose logs db
        exit 1
    fi
    sleep 2
    counter=`$((counter + 2))
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
    if [ `$counter -ge `$timeout ]; then
        error "Timeout esperando RabbitMQ"
        docker compose logs rabbitmq
        exit 1
    fi
    sleep 2
    counter=`$((counter + 2))
    echo -n "."
done
echo ""
info "RabbitMQ listo"

# Configurar usuario de RabbitMQ
log "🔧 Configurando usuario RabbitMQ..."
docker compose exec rabbitmq rabbitmqctl add_user koha "`$RABBITMQ_PASSWORD" 2>/dev/null || true
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
    if [ `$counter -ge `$timeout ]; then
        error "Timeout esperando Koha"
        log "Mostrando logs de Koha:"
        docker compose logs koha | tail -50
        exit 1
    fi
    sleep 5
    counter=`$((counter + 5))
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
info "OPAC (Catálogo Público): http://`$KOHA_DOMAIN:8080"
info "Staff Interface (Administración): http://`$KOHA_DOMAIN:8081"
echo ""
info "=== CREDENCIALES INICIALES ==="
info "Usuario: `$KOHA_ADMIN_USER"
info "Contraseña: `$KOHA_ADMIN_PASSWORD"
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
    warning "Servicio systemd no encontrado"
fi

# Crear script de monitoreo básico
log "📊 Configurando monitoreo básico..."
cat > /usr/local/bin/koha-status.sh << 'EOF'
#!/bin/bash
echo "=== ESTADO DE KOHA DOCKER ==="
echo "Fecha: `$(date)"
echo ""

cd `$INSTALL_DIR 2>/dev/null || cd .

echo "--- Servicios Docker ---"
docker compose ps

echo ""
echo "--- Uso de Recursos ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "--- Volúmenes ---"  
docker volume ls | grep koha

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
EOF

chmod +x /usr/local/bin/koha-status.sh

log "✅ Inicialización completada"
echo ""
echo "================================================"
echo "🎉 KOHA DOCKER INICIADO EXITOSAMENTE"
echo "================================================"
echo "📱 Acceso OPAC: http://`$KOHA_DOMAIN:8080"  
echo "🏢 Acceso Staff: http://`$KOHA_DOMAIN:8081"
echo "👤 Usuario: `$KOHA_ADMIN_USER"
echo "🔑 Contraseña: `$KOHA_ADMIN_PASSWORD"
echo "📊 Estado: koha-status.sh"
echo "📋 Logs: docker compose logs [servicio]"
echo "================================================"
"@

$initScript | Out-File -FilePath "$OutputDir\init.sh" -Encoding UTF8
Write-ColoredOutput "✅ Script init.sh creado" "Green"

# Crear script de gestión adicional
$manageScript = @"
#!/bin/bash
# =============================================================================
# SCRIPT DE GESTIÓN KOHA LINUX  
# =============================================================================

ACTION=`$1

case `$ACTION in
    start)
        echo "🚀 Iniciando Koha..."
        docker compose up -d
        ;;
    stop)
        echo "🛑 Deteniendo Koha..."
        docker compose down
        ;;
    restart)
        echo "🔄 Reiniciando Koha..."
        docker compose restart
        ;;
    status)
        echo "📊 Estado de Koha:"
        docker compose ps
        ;;
    logs)
        SERVICE=`$2
        if [[ -z "`$SERVICE" ]]; then
            docker compose logs
        else
            docker compose logs "`$SERVICE"
        fi
        ;;
    backup)
        echo "💾 Creando backup..."
        ./scripts/backup-full.sh 2>/dev/null || echo "Script de backup no encontrado"
        ;;
    update)
        echo "🔄 Actualizando imágenes..."
        docker compose pull
        docker compose up -d
        ;;
    *)
        echo "Uso: `$0 {start|stop|restart|status|logs [servicio]|backup|update}"
        exit 1
        ;;
esac
"@

$manageScript | Out-File -FilePath "$OutputDir\manage.sh" -Encoding UTF8
Write-ColoredOutput "✅ Script manage.sh creado" "Green"

Write-ColoredOutput "🎯 Preparación completada exitosamente!" "Green"
Write-ColoredOutput "📦 Archivos listos en: $OutputDir" "Yellow"
Write-ColoredOutput "" "White"
Write-ColoredOutput "📋 CREDENCIALES GENERADAS:" "Yellow"
Write-ColoredOutput "=========================" "Yellow"
Write-ColoredOutput "DB Admin: koha_admin / $kohaDbPassword" "White"
Write-ColoredOutput "MySQL Root: root / $mysqlRootPassword" "White"
Write-ColoredOutput "RabbitMQ: koha / $rabbitmqPassword" "White"
Write-ColoredOutput "Koha Admin: koha_admin / $kohaAdminPassword" "White"
Write-ColoredOutput "" "White"
Write-ColoredOutput "📋 PRÓXIMOS PASOS:" "Cyan"
Write-ColoredOutput "=================" "Cyan"
Write-ColoredOutput "1. Transferir carpeta '$OutputDir' al servidor Linux" "White"
Write-ColoredOutput "2. En Linux: cd $OutputDir && sudo chmod +x setup.sh" "White"
Write-ColoredOutput "3. En Linux: sudo ./setup.sh" "White"
Write-ColoredOutput "4. En Linux: sudo ./init.sh" "White"
Write-ColoredOutput "" "White"
Write-ColoredOutput "⚠️ GUARDA ESTAS CREDENCIALES EN UN LUGAR SEGURO" "Red"