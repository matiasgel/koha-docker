#!/bin/bash
# =============================================================================
# KOHA DOCKER - INSTALACIÓN RÁPIDA EN LINUX
# =============================================================================
# Script que ejecuta todo el proceso de instalación automáticamente
# USO: curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/install-linux.sh | sudo bash
# =============================================================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

echo -e "${GREEN}"
cat << 'EOF'
 _  __     _            ____             _             
| |/ /    | |          |  _ \           | |            
| ' / ___ | |__   __ _ | | | | ___   ___| | _____ _ __ 
|  < / _ \| '_ \ / _` || | | |/ _ \ / __| |/ / _ \ '__|
| . \ (_) | | | | (_| || |_| | (_) | (__|   <  __/ |   
|_|\_\___/|_| |_|\__,_||____/ \___/ \___|_|\_\___|_|   
                                                       
EOF
echo -e "${NC}"

log "🚀 INSTALACIÓN AUTOMÁTICA DE KOHA DOCKER"
log "========================================"

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

# Verificar conexión a internet
if ! ping -c 1 github.com &> /dev/null; then
    error "Sin conexión a internet. Verificar conectividad."
    exit 1
fi

# Instalar dependencias básicas
log "📦 Instalando dependencias básicas..."
apt-get update
apt-get install -y curl wget git unzip

# Instalar Docker si no está presente
if ! command -v docker &> /dev/null; then
    log "🐳 Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    log "✅ Docker instalado"
else
    info "Docker ya está instalado"
fi

# Verificar Docker Compose
if ! docker compose version &> /dev/null; then
    error "Docker Compose no está disponible"
    exit 1
fi

# Clonar repositorio
INSTALL_DIR="/opt/koha-docker"
log "📥 Clonando repositorio Koha Docker..."

if [[ -d "$INSTALL_DIR" ]]; then
    warning "Directorio $INSTALL_DIR ya existe. ¿Sobrescribir? (s/N):"
    read -r response
    if [[ "$response" == "s" || "$response" == "S" ]]; then
        rm -rf "$INSTALL_DIR"
    else
        error "Instalación cancelada"
        exit 1
    fi
fi

git clone https://github.com/matiasgel/koha-docker.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

log "✅ Repositorio clonado en $INSTALL_DIR"

# Hacer scripts ejecutables
chmod +x setup.sh init.sh

# Configuración interactiva
log "⚙️ CONFIGURACIÓN INTERACTIVA"
log "============================"

echo ""
info "Configurar variables básicas para Koha:"
echo ""

# Dominio principal
read -p "🌐 Dominio para Staff Interface [biblioteca.local]: " DOMAIN
DOMAIN=${DOMAIN:-biblioteca.local}

# Dominio OPAC
read -p "📚 Dominio para OPAC/Catálogo [catalogo.local]: " OPAC_DOMAIN  
OPAC_DOMAIN=${OPAC_DOMAIN:-catalogo.local}

# Nombre de biblioteca
read -p "🏛️ Nombre de la biblioteca [Biblioteca Principal]: " LIBRARY_NAME
LIBRARY_NAME=${LIBRARY_NAME:-Biblioteca Principal}

# Generar passwords aleatorios
DB_PASS=$(openssl rand -base64 16)
ROOT_PASS=$(openssl rand -base64 16)
RMQ_PASS=$(openssl rand -base64 12)
ADMIN_PASS=$(openssl rand -base64 8)

# Crear archivo .env
log "📝 Creando configuración..."

cat > .env << EOF
# Configuración generada automáticamente - $(date)

# Base de datos
KOHA_DB_NAME=koha_production
KOHA_DB_USER=koha_admin
KOHA_DB_PASSWORD=$DB_PASS
MYSQL_ROOT_PASSWORD=$ROOT_PASS
MYSQL_SERVER=db
DB_NAME=koha_production
MYSQL_USER=koha_admin
MYSQL_PASSWORD=$DB_PASS

# Dominios
KOHA_DOMAIN=$DOMAIN
OPAC_DOMAIN=$OPAC_DOMAIN
KOHA_INSTANCE=production

# Puertos
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080

# RabbitMQ
MB_HOST=rabbitmq
MB_PORT=61613
MB_USER=koha
MB_PASS=$RMQ_PASS
RABBITMQ_PASSWORD=$RMQ_PASS
RABBITMQ_USER=koha

# Servicios
MEMCACHED_SERVERS=memcached:11211

# Sistema
INSTALL_DIR=$INSTALL_DIR
DATA_DIR=$INSTALL_DIR/data
BACKUP_DIR=$INSTALL_DIR/backups
LOG_DIR=/var/log/koha-docker
TIMEZONE=America/Argentina/Buenos_Aires

# Idiomas
KOHA_LANGS=es-ES en-GB

# Credenciales Koha
KOHA_ADMIN_USER=koha_admin
KOHA_ADMIN_PASSWORD=$ADMIN_PASS
KOHA_LIBRARY_NAME=$LIBRARY_NAME

# Configuración de búsqueda
ZEBRA_MARC_FORMAT=marc21
ZEBRA_LANGUAGE=es

# Red Docker
NETWORK_SUBNET=172.20.0.0/16
EOF

log "✅ Configuración creada"

# Ejecutar setup
log "🔧 Ejecutando setup (preparación del sistema)..."
./setup.sh

echo ""
warning "¿Continuar con la inicialización de servicios? (s/N):"
read -r response
if [[ "$response" != "s" && "$response" != "S" ]]; then
    info "Setup completado. Ejecutar manualmente: sudo ./init.sh"
    exit 0
fi

# Ejecutar inicialización
log "🚀 Ejecutando inicialización de servicios..."
./init.sh

# Mostrar resumen final
echo ""
echo "=================================================="
echo -e "${GREEN}🎉 INSTALACIÓN COMPLETADA EXITOSAMENTE${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}📱 ACCESO A KOHA:${NC}"
echo "  OPAC (Catálogo): http://$OPAC_DOMAIN:8080"
echo "  Staff Interface: http://$DOMAIN:8081"
echo ""
echo -e "${BLUE}🔐 CREDENCIALES:${NC}"
echo "  Usuario: koha_admin"
echo "  Contraseña: $ADMIN_PASS"
echo ""
echo -e "${BLUE}🗄️ BASE DE DATOS:${NC}"
echo "  Usuario: koha_admin"
echo "  Contraseña: $DB_PASS"
echo ""
echo -e "${BLUE}🔧 GESTIÓN:${NC}"
echo "  Estado: koha-status.sh"
echo "  Gestión: $INSTALL_DIR/manage.sh {start|stop|restart|status|logs}"
echo ""
echo -e "${YELLOW}⚠️ PRÓXIMOS PASOS:${NC}"
echo "1. Acceder al Staff Interface: http://$DOMAIN:8081"
echo "2. Completar asistente web de Koha"
echo "3. Configurar biblioteca y parámetros"
echo ""
echo -e "${GREEN}✅ ¡Koha Docker está listo para usar!${NC}"
echo "=================================================="

# Guardar credenciales
cat > "$INSTALL_DIR/CREDENCIALES.txt" << EOF
CREDENCIALES DE KOHA DOCKER
===========================
Fecha de instalación: $(date)
Servidor: $(hostname)

ACCESO WEB:
- OPAC: http://$OPAC_DOMAIN:8080
- Staff: http://$DOMAIN:8081

CREDENCIALES KOHA:
- Usuario: koha_admin
- Contraseña: $ADMIN_PASS

BASE DE DATOS:
- Usuario: koha_admin
- Contraseña: $DB_PASS
- Root: $ROOT_PASS

RABBITMQ:
- Usuario: koha
- Contraseña: $RMQ_PASS

COMANDOS ÚTILES:
- Estado: koha-status.sh
- Gestión: $INSTALL_DIR/manage.sh
- Logs: docker compose logs -f
EOF

chmod 600 "$INSTALL_DIR/CREDENCIALES.txt"
info "💾 Credenciales guardadas en: $INSTALL_DIR/CREDENCIALES.txt"