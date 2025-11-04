#!/bin/bash
# =============================================================================
# KOHA DOCKER - CONFIGURACIÓN DE RED
# =============================================================================
# Este script configura automáticamente el acceso a Koha desde toda la red
# local, permitiendo el tráfico en puertos 8080 y 8081
#
# USO: sudo ./network-setup.sh
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

echo -e "${BLUE}"
echo "=================================================="
echo "   KOHA DOCKER - CONFIGURACIÓN DE RED"
echo "=================================================="
echo -e "${NC}"

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse como root (sudo)"
fi

# Obtener interfaz de red activa
ACTIVE_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [[ -z "$ACTIVE_INTERFACE" ]]; then
    error "No se pudo detectar interfaz de red activa"
fi

# Obtener IP local
LOCAL_IP=$(ip addr show "$ACTIVE_INTERFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [[ -z "$LOCAL_IP" ]]; then
    error "No se pudo obtener la IP local"
fi

log "🌐 Interfaz de red: $ACTIVE_INTERFACE"
log "📍 IP local: $LOCAL_IP"
log "🔌 Puertos Koha: 8080 (OPAC), 8081 (Staff)"

echo ""
log "🔐 Configurando firewall y red..."
echo ""

# Función para permitir puertos en UFW
setup_ufw() {
    log "Configurando UFW (Uncomplicated Firewall)..."
    
    # Verificar si UFW está activo
    if ufw status | grep -q "Status: active"; then
        log "✅ UFW está activo"
        
        # Permitir puertos
        info "Permitiendo puerto 8080 (OPAC)..."
        ufw allow 8080/tcp || warning "No se pudo configurar puerto 8080"
        
        info "Permitiendo puerto 8081 (Staff Interface)..."
        ufw allow 8081/tcp || warning "No se pudo configurar puerto 8081"
        
        log "✅ Puertos permitidos en UFW"
    else
        warning "UFW no está activo. Considera activarlo: sudo ufw enable"
    fi
}

# Función para permitir puertos en firewalld
setup_firewalld() {
    log "Configurando firewalld..."
    
    if systemctl is-active --quiet firewalld; then
        log "✅ firewalld está activo"
        
        info "Permitiendo puerto 8080..."
        firewall-cmd --permanent --add-port=8080/tcp || warning "No se pudo configurar puerto 8080"
        
        info "Permitiendo puerto 8081..."
        firewall-cmd --permanent --add-port=8081/tcp || warning "No se pudo configurar puerto 8081"
        
        firewall-cmd --reload
        log "✅ Puertos permitidos en firewalld"
    else
        warning "firewalld no está activo"
    fi
}

# Función para permitir puertos en iptables
setup_iptables() {
    log "Configurando iptables..."
    
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || warning "No se pudo configurar puerto 8080"
    iptables -A INPUT -p tcp --dport 8081 -j ACCEPT 2>/dev/null || warning "No se pudo configurar puerto 8081"
    
    # Guardar configuración
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || warning "No se pudieron guardar reglas iptables"
    fi
    
    log "✅ Puertos permitidos en iptables"
}

# Detectar firewall disponible
if command -v ufw &> /dev/null; then
    setup_ufw
elif command -v firewall-cmd &> /dev/null; then
    setup_firewalld
elif command -v iptables &> /dev/null; then
    setup_iptables
else
    warning "No se detectó firewall instalado. Verifica permisos de red manualmente."
fi

# Configurar Docker para acceso remoto
log "🐳 Verificando configuración de Docker..."
echo ""

# Crear archivo de configuración de daemon si no existe
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
if [[ ! -f "$DOCKER_DAEMON_CONFIG" ]]; then
    info "Creando configuración de Docker daemon..."
    mkdir -p /etc/docker
    cat > "$DOCKER_DAEMON_CONFIG" << 'EOF'
{
  "debug": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    log "✅ Configuración de Docker creada"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ CONFIGURACIÓN DE RED COMPLETADA${NC}"
echo "=================================================="
echo ""

# Mostrar información de acceso
echo -e "${BLUE}🌐 ACCESO A KOHA:${NC}"
echo ""
echo "  Desde tu máquina actual:"
echo "  📱 OPAC (Catálogo):   http://$LOCAL_IP:8080"
echo "  🏢 Staff Interface:   http://$LOCAL_IP:8081"
echo ""
echo "  Desde otras máquinas en la red:"
echo "  📱 OPAC (Catálogo):   http://$LOCAL_IP:8080"
echo "  🏢 Staff Interface:   http://$LOCAL_IP:8081"
echo ""

# Obtener puerta de enlace (gateway) para la red
GATEWAY=$(ip route | grep default | awk '{print $3}')
NETWORK_PREFIX=$(echo $LOCAL_IP | cut -d. -f1-3)
echo -e "${BLUE}📊 INFORMACIÓN DE RED:${NC}"
echo "  Interfaz: $ACTIVE_INTERFACE"
echo "  IP local: $LOCAL_IP"
echo "  Gateway: $GATEWAY"
echo "  Red local: $NETWORK_PREFIX.0/24"
echo ""

echo -e "${GREEN}✅ PRÓXIMOS PASOS:${NC}"
echo "  1. Asegúrate de que el servidor Docker está ejecutándose: sudo systemctl status docker"
echo "  2. Inicia los servicios Koha: ./manage.sh start"
echo "  3. Verifica el estado: ./koha-status.sh"
echo "  4. Accede desde cualquier máquina en tu red usando la IP local"
echo ""

echo -e "${YELLOW}⚠️  NOTAS IMPORTANTES:${NC}"
echo "  • Si usas VPN/proxy, asegúrate de que permite el tráfico en estos puertos"
echo "  • Si tienes problemas de conectividad, verifica:"
echo "    - Docker está ejecutándose: docker ps"
echo "    - Los contenedores están en la red: docker network ls"
echo "    - Los puertos están expuestos: sudo netstat -tlnp | grep 8080"
echo "  • Contraseñas por defecto - Cambiarlas en producción"
echo ""
echo "=================================================="
