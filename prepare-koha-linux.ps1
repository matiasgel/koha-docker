# Script de preparacion Koha Linux desde Windows
param(
    [string]$DomainName = "biblioteca.local",
    [string]$OpacDomain = "catalogo.local", 
    [string]$InstallPath = "/opt/koha-docker",
    [string]$OutputDir = "koha-linux-deployment"
)

$ErrorActionPreference = "Stop"

function Write-Info { param([string]$msg) Write-Host $msg -ForegroundColor Blue }
function Write-Success { param([string]$msg) Write-Host $msg -ForegroundColor Green }
function Write-Warning { param([string]$msg) Write-Host $msg -ForegroundColor Yellow }

function Generate-Password { 
    param([int]$Length = 16)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return (-join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] }))
}

Write-Success "PREPARACION KOHA LINUX DESDE WINDOWS"
Write-Success "===================================="

# Crear directorio de salida
if (Test-Path $OutputDir) {
    Write-Warning "El directorio $OutputDir ya existe. Sobrescribir? (s/N)"
    $response = Read-Host
    if ($response -ne "s" -and $response -ne "S") {
        Write-Host "Operacion cancelada" -ForegroundColor Red
        exit 1
    }
    Remove-Item -Recurse -Force $OutputDir
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Write-Info "Directorio creado: $OutputDir"

# Generar passwords
$dbPass = Generate-Password 20
$rootPass = Generate-Password 20  
$rmqPass = Generate-Password 16
$adminPass = Generate-Password 12

Write-Info "Generando configuracion..."

# Crear archivo .env
$envFile = @"
# Configuracion Koha Linux Production
KOHA_DB_NAME=koha_production
KOHA_DB_USER=koha_admin
KOHA_DB_PASSWORD=$dbPass
MYSQL_ROOT_PASSWORD=$rootPass

KOHA_DOMAIN=$DomainName
OPAC_DOMAIN=$OpacDomain
KOHA_INSTANCE=production

KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080

RABBITMQ_PASSWORD=$rmqPass
RABBITMQ_USER=koha

INSTALL_DIR=$InstallPath
DATA_DIR=$InstallPath/data
BACKUP_DIR=$InstallPath/backups

TIMEZONE=America/Argentina/Buenos_Aires
KOHA_LANGS=es-ES en-GB

KOHA_ADMIN_USER=koha_admin
KOHA_ADMIN_PASSWORD=$adminPass
KOHA_LIBRARY_NAME=Biblioteca Principal
"@

$envFile | Out-File -FilePath "$OutputDir\.env" -Encoding UTF8
Write-Success "Archivo .env creado"

# Crear directorios necesarios
$dirs = @("config", "scripts", "ssl", "volumes")
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path "$OutputDir\$dir" -Force | Out-Null
}

# Copiar archivos si existen
if (Test-Path "prod\linux\docker-compose.prod-linux.yaml") {
    Copy-Item "prod\linux\docker-compose.prod-linux.yaml" "$OutputDir\docker-compose.yml"
    Write-Success "Docker Compose copiado"
}

if (Test-Path "prod\linux\config") {
    Copy-Item -Recurse "prod\linux\config\*" "$OutputDir\config\" -ErrorAction SilentlyContinue
    Write-Success "Configuraciones copiadas"
}

if (Test-Path "files") {
    Copy-Item -Recurse "files" "$OutputDir\files"
    Write-Success "Archivos base copiados"
}

# Script de setup
$setupScript = @'
#!/bin/bash
set -e

echo "Iniciando setup Koha Docker..."

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Ejecutar como root (sudo)"
   exit 1
fi

if [[ ! -f .env ]]; then
    echo "ERROR: Archivo .env no encontrado"
    exit 1
fi

source .env

echo "Actualizando sistema..."
apt-get update
apt-get install -y curl wget git nano htop unzip tar cron ca-certificates gnupg

echo "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

echo "Creando usuario del sistema..."
groupadd koha-docker 2>/dev/null || true
useradd -r -g koha-docker -s /bin/bash -d $INSTALL_DIR koha 2>/dev/null || true

echo "Creando directorios..."
mkdir -p $INSTALL_DIR
mkdir -p $DATA_DIR  
mkdir -p $BACKUP_DIR
mkdir -p $INSTALL_DIR/ssl

cp -r . $INSTALL_DIR/
cd $INSTALL_DIR

chown -R koha:koha-docker $INSTALL_DIR
chmod +x *.sh 2>/dev/null || true

echo "Generando certificados SSL..."
if [[ ! -f ssl/cert.pem ]]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=AR/ST=Buenos Aires/L=Buenos Aires/O=Koha/CN=$KOHA_DOMAIN"
    
    chmod 600 ssl/key.pem
    chmod 644 ssl/cert.pem
fi

echo "Configurando servicio systemd..."
cat > /etc/systemd/system/koha-docker.service << EOF
[Unit]
Description=Koha Docker Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=koha

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable koha-docker

echo "Setup completado!"
echo "Ejecutar: sudo ./init.sh"
'@

$setupScript | Out-File -FilePath "$OutputDir\setup.sh" -Encoding UTF8

# Script de inicializacion  
$initScript = @'
#!/bin/bash
set -e

echo "Iniciando Koha Docker..."

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Ejecutar como root (sudo)"
   exit 1
fi

source .env

if [[ ! -f docker-compose.yml ]]; then
    echo "ERROR: docker-compose.yml no encontrado"
    exit 1
fi

echo "Creando volumenes..."
docker volume create koha-etc 2>/dev/null || true
docker volume create koha-var 2>/dev/null || true
docker volume create koha-logs 2>/dev/null || true
docker volume create mariadb-data 2>/dev/null || true
docker volume create rabbitmq-data 2>/dev/null || true

echo "Limpiando contenedores..."
docker compose down --remove-orphans 2>/dev/null || true

echo "Descargando imagenes..."
docker compose pull

echo "Iniciando base de datos..."
docker compose up -d db

echo "Esperando base de datos..."
for i in {1..30}; do
    if docker compose exec db mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
        break
    fi
    sleep 2
    echo -n "."
done
echo " OK"

echo "Iniciando RabbitMQ..."
docker compose up -d rabbitmq

echo "Esperando RabbitMQ..."
for i in {1..15}; do
    if docker compose exec rabbitmq rabbitmqctl status > /dev/null 2>&1; then
        break
    fi  
    sleep 2
    echo -n "."
done
echo " OK"

echo "Configurando RabbitMQ..."
docker compose exec rabbitmq rabbitmqctl add_user koha "$RABBITMQ_PASSWORD" 2>/dev/null || true
docker compose exec rabbitmq rabbitmqctl set_permissions koha ".*" ".*" ".*"

echo "Iniciando servicios restantes..."
docker compose up -d

echo "Esperando Koha..."
for i in {1..60}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        break
    fi
    sleep 3
    echo -n "."
done
echo " OK"

echo "Estado de servicios:"
docker compose ps

echo "=================================="
echo "KOHA INICIADO EXITOSAMENTE"
echo "=================================="
echo "OPAC: http://$KOHA_DOMAIN:8080"
echo "Staff: http://$KOHA_DOMAIN:8081"
echo "Usuario: $KOHA_ADMIN_USER"  
echo "Password: $KOHA_ADMIN_PASSWORD"
echo "=================================="
'@

$initScript | Out-File -FilePath "$OutputDir\init.sh" -Encoding UTF8

# Script de gestion
$manageScript = @'
#!/bin/bash
ACTION=$1

case $ACTION in
    start)
        echo "Iniciando Koha..."
        docker compose up -d
        ;;
    stop)
        echo "Deteniendo Koha..."
        docker compose down
        ;;
    restart)
        echo "Reiniciando Koha..."
        docker compose restart
        ;;
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs ${2:-}
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs [servicio]}"
        exit 1
        ;;
esac
'@

$manageScript | Out-File -FilePath "$OutputDir\manage.sh" -Encoding UTF8

Write-Success "Preparacion completada!"
Write-Info "Archivos listos en: $OutputDir"
Write-Success ""
Write-Warning "CREDENCIALES GENERADAS:"
Write-Host "DB Admin: koha_admin / $dbPass" -ForegroundColor White
Write-Host "MySQL Root: root / $rootPass" -ForegroundColor White  
Write-Host "RabbitMQ: koha / $rmqPass" -ForegroundColor White
Write-Host "Koha Admin: koha_admin / $adminPass" -ForegroundColor White
Write-Success ""
Write-Info "PROXIMOS PASOS:"
Write-Host "1. Transferir '$OutputDir' al servidor Linux" -ForegroundColor White
Write-Host "2. En Linux: sudo chmod +x *.sh" -ForegroundColor White
Write-Host "3. En Linux: sudo ./setup.sh" -ForegroundColor White  
Write-Host "4. En Linux: sudo ./init.sh" -ForegroundColor White