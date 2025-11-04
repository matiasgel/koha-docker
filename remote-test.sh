#!/bin/bash
# =============================================================================
# KOHA DOCKER - TEST DE ACCESO REMOTO
# =============================================================================
# Script para probar acceso a Koha desde otra máquina
#
# USO REMOTO: curl -fsSL http://IP-DEL-SERVIDOR:8080/cgi-bin/koha/mainpage.pl
# O: ./remote-test.sh <IP-DEL-SERVIDOR>
# =============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones
log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Validar argumentos
if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║    KOHA DOCKER - TEST DE ACCESO REMOTO                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "USO: $0 <IP-DEL-SERVIDOR> [puerto]"
    echo ""
    echo "EJEMPLOS:"
    echo "  $0 192.168.1.100"
    echo "  $0 192.168.1.100 8080"
    echo "  $0 biblioteca.ejemplo.com"
    echo ""
    error "Debes especificar la IP o dominio del servidor Koha"
    exit 1
fi

SERVER="$1"
OPAC_PORT="${2:-8080}"
STAFF_PORT="${3:-8081}"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    KOHA DOCKER - TEST DE ACCESO REMOTO                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

info "Servidor: $SERVER"
info "Puerto OPAC: $OPAC_PORT"
info "Puerto Staff: $STAFF_PORT"
echo ""

# 1. Verificar conectividad de red
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "1️⃣  VERIFICANDO CONECTIVIDAD DE RED"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if timeout 3 ping -c 1 "$SERVER" &> /dev/null 2>&1 || \
   timeout 3 ping -W 3 "$SERVER" &> /dev/null 2>&1; then
    log "Servidor $SERVER es alcanzable"
else
    warning "No se puede hacer ping a $SERVER (esto es normal en algunas redes)"
fi
echo ""

# 2. Verificar puerto OPAC
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "2️⃣  VERIFICANDO PUERTO OPAC ($OPAC_PORT)"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if timeout 5 bash -c "echo >/dev/tcp/$SERVER/$OPAC_PORT" 2>/dev/null; then
    log "Puerto $OPAC_PORT está ABIERTO en $SERVER"
    
    # Intentar conectar a Koha
    info "Probando conexión a OPAC..."
    if timeout 10 curl -s http://$SERVER:$OPAC_PORT/cgi-bin/koha/mainpage.pl | grep -q "Koha" 2>/dev/null; then
        log "✅ OPAC FUNCIONANDO correctamente"
        echo "   URL: http://$SERVER:$OPAC_PORT"
    elif timeout 10 curl -s http://$SERVER:$OPAC_PORT | grep -q "html" 2>/dev/null; then
        log "✅ Puerto responde (OPAC detectado)"
        echo "   URL: http://$SERVER:$OPAC_PORT"
    else
        warning "⚠️  Puerto abierto pero Koha podría estar iniciando"
        echo "   URL: http://$SERVER:$OPAC_PORT"
        echo "   Intenta en 30 segundos..."
    fi
else
    error "Puerto $OPAC_PORT CERRADO en $SERVER"
    echo "   • Firewall bloqueando?"
    echo "   • Puerto incorrecto?"
    echo "   • Servidor no ejecutándose?"
fi
echo ""

# 3. Verificar puerto Staff Interface
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "3️⃣  VERIFICANDO PUERTO STAFF ($STAFF_PORT)"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if timeout 5 bash -c "echo >/dev/tcp/$SERVER/$STAFF_PORT" 2>/dev/null; then
    log "Puerto $STAFF_PORT está ABIERTO en $SERVER"
    
    # Intentar conectar a Koha Staff
    info "Probando conexión a Staff Interface..."
    if timeout 10 curl -s http://$SERVER:$STAFF_PORT | grep -q "html" 2>/dev/null; then
        log "✅ Staff Interface FUNCIONANDO correctamente"
        echo "   URL: http://$SERVER:$STAFF_PORT"
    else
        warning "⚠️  Puerto abierto pero Staff Interface podría estar iniciando"
        echo "   URL: http://$SERVER:$STAFF_PORT"
    fi
else
    error "Puerto $STAFF_PORT CERRADO en $SERVER"
fi
echo ""

# 4. Resumen
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "📋 RESUMEN"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if timeout 5 bash -c "echo >/dev/tcp/$SERVER/$OPAC_PORT" 2>/dev/null && \
   timeout 5 bash -c "echo >/dev/tcp/$SERVER/$STAFF_PORT" 2>/dev/null; then
    
    echo -e "${GREEN}"
    echo "  🎉 ACCESO EXITOSO"
    echo -e "${NC}"
    
    info "Puedes acceder a Koha desde:"
    echo ""
    echo "  📱 OPAC (Catálogo público):"
    echo "     http://$SERVER:$OPAC_PORT"
    echo ""
    echo "  🏢 Staff Interface (Interfaz bibliotecario):"
    echo "     http://$SERVER:$STAFF_PORT"
    echo ""
    
    echo "  👤 Credenciales por defecto:"
    echo "     Usuario: koha_admin"
    echo "     Contraseña: KohaAdmin#2024\$Web456"
    
else
    echo -e "${YELLOW}"
    echo "  ⚠️  ALGUNOS SERVICIOS NO SON ACCESIBLES"
    echo -e "${NC}"
    
    echo ""
    info "Posibles causas:"
    echo "   1. Firewall bloqueando los puertos"
    echo "   2. Servidor Docker no está ejecutándose"
    echo "   3. IP o puertos incorrectos"
    echo "   4. Servicios aún inicializándose"
    echo ""
    
    info "Soluciones:"
    echo "   • Verifica la IP correcta: hostname -I"
    echo "   • Abre puertos en firewall: sudo ufw allow 8080/tcp"
    echo "   • Reinicia servicios: ./manage.sh restart"
    echo "   • Revisa logs: ./manage.sh logs"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"