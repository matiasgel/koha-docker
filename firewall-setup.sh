#!/bin/bash
# =============================================================================
# KOHA DOCKER - CONFIGURAR FIREWALL
# =============================================================================
# Script para permitir acceso a Koha desde la red mediante firewall
#
# USO: sudo ./firewall-setup.sh
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }
warning() { echo -e "${YELLOW}[!] $1${NC}"; }
info() { echo -e "${BLUE}[i] $1${NC}"; }

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse con sudo"
fi

echo -e "${BLUE}"
echo "════════════════════════════════════════════════════════════════"
echo "      KOHA DOCKER - CONFIGURACIÓN DE FIREWALL"
echo "════════════════════════════════════════════════════════════════"
echo -e "${NC}"

log "🔧 Configurando firewall para Koha Docker..."

# Detectar sistema
if command -v ufw &> /dev/null; then
    echo ""
    info "Sistema: Debian/Ubuntu con UFW"
    
    # Verificar estado
    if ufw status | grep -q "Status: inactive"; then
        warning "UFW está desactivado"
        read -p "¿Deseas activar UFW? (s/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            ufw --force enable
            log "UFW activado"
        fi
    fi
    
    # Permitir puertos
    info "Permitiendo puerto 8080 (OPAC)..."
    ufw allow 8080/tcp comment "Koha OPAC"
    log "✅ Puerto 8080 permitido"
    
    info "Permitiendo puerto 8081 (Staff Interface)..."
    ufw allow 8081/tcp comment "Koha Staff"
    log "✅ Puerto 8081 permitido"
    
    # Opcional: RabbitMQ Management
    read -p "¿Deseas permitir acceso a RabbitMQ Management (puerto 15672)? (s/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        ufw allow 15672/tcp comment "RabbitMQ Management"
        log "✅ Puerto 15672 permitido"
    fi
    
    # Mostrar estado
    echo ""
    info "Estado actual del firewall:"
    ufw status | grep -E '8080|8081|15672'
    
elif command -v firewall-cmd &> /dev/null; then
    echo ""
    info "Sistema: RHEL/CentOS con firewalld"
    
    firewall-cmd --permanent --add-port=8080/tcp
    firewall-cmd --permanent --add-port=8081/tcp
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    
    log "✅ Puertos 8080 y 8081 permitidos"
    
    read -p "¿Permitir RabbitMQ Management (puerto 15672)? (s/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        firewall-cmd --permanent --add-port=15672/tcp
        firewall-cmd --reload
        log "✅ Puerto 15672 permitido"
    fi
    
elif command -v iptables &> /dev/null; then
    echo ""
    warning "Sistema: iptables manual"
    
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
    
    log "✅ Reglas iptables agregadas"
    info "Nota: Las reglas son temporales. Para hacerlas permanentes, usa:"
    echo "      sudo apt-get install iptables-persistent && sudo iptables-save | sudo tee /etc/iptables/rules.v4"
    
else
    warning "No se detectó firewall conocido"
    info "Si usas un firewall personalizado, abre estos puertos manualmente:"
    echo "    • Puerto 8080/tcp (OPAC)"
    echo "    • Puerto 8081/tcp (Staff Interface)"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
log "🌐 Acceso de red configurado"
info "Puedes acceder a Koha desde:"
echo "    📱 OPAC:  http://IP-SERVIDOR:8080"
echo "    🏢 Staff: http://IP-SERVIDOR:8081"
echo ""
log "Para verificar: ./network-check.sh"