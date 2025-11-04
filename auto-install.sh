#!/bin/bash
# =============================================================================
# KOHA DOCKER - INSTALACIÓN COMPLETAMENTE AUTOMÁTICA
# =============================================================================
# Este script instala Koha Docker sin requerir configuración manual
# Usa contraseñas por defecto seguras
#
# USO: curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

INSTALACIÓN COMPLETAMENTE AUTOMÁTICA                                                      
EOF
echo -e "${NC}"

log "🚀 INICIANDO INSTALACIÓN AUTOMÁTICA DE KOHA DOCKER"
log "=================================================="

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

# Instalar dependencias básicas
log "📦 Instalando dependencias básicas..."
apt-get update -qq
apt-get install -y curl wget git unzip openssl > /dev/null 2>&1

# Instalar Docker si no está presente
if ! command -v docker &> /dev/null; then
    log "🐳 Instalando Docker..."
    curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
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

# Definir directorio de instalación
INSTALL_DIR="/opt/koha-docker"

# Clonar repositorio
log "📥 Clonando repositorio Koha Docker..."
if [[ -d "$INSTALL_DIR" ]]; then
    log "Actualizando repositorio existente..."
    cd "$INSTALL_DIR"
    git pull -q
else
    git clone -q https://github.com/matiasgel/koha-docker.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Crear archivo .env automáticamente con contraseñas por defecto
log "📝 Creando configuración automática..."
cp .env.production .env
chmod 600 .env

# Asegurar que está configurado para acceso de red
log "🌐 Configurando acceso desde toda la red..."
if grep -q "KOHA_DOMAIN=localhost" .env; then
    sed -i 's/KOHA_DOMAIN=localhost/KOHA_DOMAIN=0.0.0.0/g' .env
fi
if grep -q "KOHA_DOMAIN=biblioteca.local" .env; then
    sed -i 's/KOHA_DOMAIN=biblioteca.local/KOHA_DOMAIN=0.0.0.0/g' .env
fi

log "✅ Configuración creada con contraseñas por defecto"

# Hacer scripts ejecutables
chmod +x *.sh network-setup.sh

# Configurar firewall para permitir acceso remoto
log "🔐 Configurando firewall para acceso de red..."
if [[ $EUID -eq 0 ]]; then
    ./network-setup.sh || warning "No se pudo configurar firewall (continuando...)"
else
    warning "Se requieren permisos root para configurar firewall"
    warning "Ejecuta después: sudo $INSTALL_DIR/network-setup.sh"
fi

# Ejecutar setup automáticamente
log "🔧 Ejecutando setup del sistema..."
./setup.sh

echo ""
log "🚀 Ejecutando inicialización de servicios..."
./init.sh

# Mostrar resumen final
echo ""
echo "=================================================="
echo -e "${GREEN}🎉 KOHA DOCKER INSTALADO EXITOSAMENTE${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}🌐 ACCESO A KOHA:${NC}"
echo "  📱 OPAC (Catálogo): http://$(hostname -I | awk '{print $1}'):8080"
echo "  🏢 Staff Interface: http://$(hostname -I | awk '{print $1}'):8081"
echo ""
echo -e "${BLUE}🔐 CREDENCIALES POR DEFECTO:${NC}"
echo "  👤 Usuario: koha_admin"
echo "  🔑 Contraseña: KohaAdmin#2024\$Web456"
echo ""
echo -e "${BLUE}🗄️ BASE DE DATOS:${NC}"
echo "  👤 Usuario: koha_admin"
echo "  🔑 Contraseña: KohaDB#2024\$Secure789"
echo "  🔑 Root: RootDB#2024\$Strong456"
echo ""
echo -e "${BLUE}🐰 RABBITMQ:${NC}"
echo "  👤 Usuario: koha"
echo "  🔑 Contraseña: RabbitMQ#2024\$Queue123"
echo "  🌐 Management: http://$(hostname -I | awk '{print $1}'):15672"
echo ""
echo -e "${BLUE}🔧 GESTIÓN DEL SISTEMA:${NC}"
echo "  📊 Estado: koha-status.sh"
echo "  ⚙️ Gestión: $INSTALL_DIR/manage.sh {start|stop|restart|status|logs}"
echo ""
echo -e "${GREEN}✅ ¡Koha está listo para usar!${NC}"
echo "=================================================="

# Crear archivo con credenciales
cat > "$INSTALL_DIR/CREDENCIALES-DEFECTO.txt" << EOF
KOHA DOCKER - CREDENCIALES POR DEFECTO
======================================
Instalación automática: $(date)
Servidor: $(hostname)
IP: $(hostname -I | awk '{print $1}')

ACCESO WEB:
-----------
OPAC (Catálogo): http://$(hostname -I | awk '{print $1}'):8080
Staff Interface: http://$(hostname -I | awk '{print $1}'):8081

CREDENCIALES KOHA:
------------------
Usuario: koha_admin
Contraseña: KohaAdmin#2024\$Web456

BASE DE DATOS:
--------------
Usuario: koha_admin
Contraseña: KohaDB#2024\$Secure789
Root: RootDB#2024\$Strong456

RABBITMQ:
---------
Usuario: koha
Contraseña: RabbitMQ#2024\$Queue123
Management UI: http://$(hostname -I | awk '{print $1}'):15672

COMANDOS ÚTILES:
----------------
Estado: koha-status.sh
Gestión: $INSTALL_DIR/manage.sh {start|stop|restart|status|logs}
Logs: docker compose logs -f
Reinicio: systemctl restart koha-docker

PRÓXIMOS PASOS:
---------------
1. Acceder a Staff Interface: http://$(hostname -I | awk '{print $1}'):8081
2. Completar asistente web de Koha
3. Configurar biblioteca y parámetros del sistema

NOTA: Estas son contraseñas por defecto. Se recomienda cambiarlas en producción.
EOF

chmod 600 "$INSTALL_DIR/CREDENCIALES-DEFECTO.txt"
info "💾 Credenciales guardadas en: $INSTALL_DIR/CREDENCIALES-DEFECTO.txt"