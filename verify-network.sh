#!/bin/bash
# =============================================================================
# KOHA DOCKER - VERIFICACIÓN RÁPIDA DE CONFIGURACIÓN DE RED
# =============================================================================
# Script para verificar que todo está configurado correctamente para acceso remoto
#
# USO: ./verify-network.sh
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo -e "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║          KOHA DOCKER - VERIFICACIÓN DE CONFIGURACIÓN DE RED            ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Contador de checks
checks_passed=0
checks_total=0

# Función para hacer checks
check() {
    local name="$1"
    local command="$2"
    
    echo -n "  Verificando $name... "
    ((checks_total++))
    
    if eval "$command" &>/dev/null; then
        log "$name OK"
        ((checks_passed++))
        return 0
    else
        error "$name FALLO"
        return 1
    fi
}

echo -e "${BLUE}📋 VERIFICACIONES:${NC}"
echo ""

# 1. Verificar .env
echo "1️⃣  Configuración de Entorno:"
if [[ -f .env ]]; then
    log "Archivo .env existe"
    ((checks_passed++))
    ((checks_total++))
    
    if grep -q "KOHA_DOMAIN=0.0.0.0" .env; then
        log "KOHA_DOMAIN=0.0.0.0 configurado"
        ((checks_passed++))
    else
        warn "KOHA_DOMAIN no está en 0.0.0.0"
    fi
    ((checks_total++))
else
    error "Archivo .env no existe"
    ((checks_total++))
fi

echo ""
echo "2️⃣  Puertos Configurados:"
if grep -q "KOHA_INTRANET_PORT=8081" .env 2>/dev/null; then
    log "Puerto Staff (8081) configurado"
    ((checks_passed++))
else
    warn "Puerto Staff no configurado correctamente"
fi
((checks_total++))

if grep -q "KOHA_OPAC_PORT=8080" .env 2>/dev/null; then
    log "Puerto OPAC (8080) configurado"
    ((checks_passed++))
else
    warn "Puerto OPAC no configurado correctamente"
fi
((checks_total++))

echo ""
echo "3️⃣  Docker:"
check "Docker instalado" "command -v docker"
check "Docker Compose disponible" "docker compose version"

echo ""
echo "4️⃣  Servicios:"
if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "koha"; then
    log "Contenedor Koha ejecutándose"
    ((checks_passed++))
else
    warn "Contenedor Koha no está ejecutándose"
fi
((checks_total++))

if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "db\|mariadb"; then
    log "Contenedor Database ejecutándose"
    ((checks_passed++))
else
    warn "Contenedor Database no está ejecutándose"
fi
((checks_total++))

echo ""
echo "5️⃣  Puertos Expuestos:"
if netstat -tlnp 2>/dev/null | grep -q ":8080 " || ss -tlnp 2>/dev/null | grep -q ":8080 "; then
    log "Puerto 8080 escuchando"
    ((checks_passed++))
else
    warn "Puerto 8080 no está escuchando"
fi
((checks_total++))

if netstat -tlnp 2>/dev/null | grep -q ":8081 " || ss -tlnp 2>/dev/null | grep -q ":8081 "; then
    log "Puerto 8081 escuchando"
    ((checks_passed++))
else
    warn "Puerto 8081 no está escuchando"
fi
((checks_total++))

echo ""
echo "6️⃣  Firewall:"
if command -v ufw &>/dev/null; then
    if sudo ufw status | grep -q "8080"; then
        log "Puerto 8080 permitido en UFW"
        ((checks_passed++))
    else
        warn "Puerto 8080 no permitido en UFW"
    fi
    ((checks_total++))
else
    info "UFW no instalado (OK)"
    ((checks_passed++))
    ((checks_total++))
fi

echo ""
echo "7️⃣  Conectividad Local:"
if timeout 2 curl -s http://localhost:8080 >/dev/null 2>&1; then
    log "OPAC (8080) responde localmente"
    ((checks_passed++))
else
    warn "OPAC (8080) no responde"
fi
((checks_total++))

if timeout 2 curl -s http://localhost:8081 >/dev/null 2>&1; then
    log "Staff (8081) responde localmente"
    ((checks_passed++))
else
    warn "Staff (8081) no responde"
fi
((checks_total++))

echo ""
echo "=================================================="
echo -e "${BLUE}📊 RESULTADOS:${NC}"
echo "  Checks pasados: $checks_passed/$checks_total"
echo ""

# Mostrar IP para acceso remoto
echo -e "${CYAN}🌐 INFORMACIÓN DE ACCESO:${NC}"
LOCAL_IP=$(hostname -I | awk '{print $1}')
if [[ ! -z "$LOCAL_IP" ]]; then
    echo "  IP Local: $LOCAL_IP"
    echo "  OPAC: http://$LOCAL_IP:8080"
    echo "  Staff: http://$LOCAL_IP:8081"
else
    warn "No se pudo detectar IP local"
fi

echo ""
if [[ $checks_passed -eq $checks_total ]]; then
    echo -e "${GREEN}✓ VERIFICACIÓN COMPLETADA - TODO CORRECTO${NC}"
    echo ""
    echo "  Tu Koha Docker está correctamente configurado para acceso remoto."
    echo "  Accede desde cualquier máquina en tu red usando la IP local."
    exit 0
elif [[ $checks_passed -ge $((checks_total * 80 / 100)) ]]; then
    echo -e "${YELLOW}⚠ VERIFICACIÓN PARCIAL - REVISAR ADVERTENCIAS${NC}"
    echo ""
    echo "  La mayoría de configuraciones son correctas, pero revisa las"
    echo "  advertencias anteriores."
    exit 1
else
    echo -e "${RED}✗ VERIFICACIÓN FALLIDA${NC}"
    echo ""
    echo "  Se encontraron problemas. Ejecuta:"
    echo "    1. ./manage.sh start     # Iniciar servicios"
    echo "    2. sudo ./network-setup.sh  # Configurar firewall"
    echo "    3. ./verify-network.sh   # Verificar nuevamente"
    exit 1
fi
