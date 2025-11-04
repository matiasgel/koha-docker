#!/bin/bash
# =============================================================================
# KOHA DOCKER - VERIFICAR Y CONFIGURAR ACCESO DE RED
# =============================================================================
# Script para verificar que Koha es accesible desde toda la red
#
# USO: ./network-check.sh
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
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

echo -e "${BLUE}"
echo "══════════════════════════════════════════════════════════════"
echo "   KOHA DOCKER - VERIFICADOR DE ACCESO DE RED"
echo "══════════════════════════════════════════════════════════════"
echo -e "${NC}"

# Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
LOCALHOST="127.0.0.1"

log "🔍 Iniciando verificación de accesibilidad..."
echo ""

# 1. Verificar Docker
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}1️⃣  VERIFICANDO DOCKER${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if docker info &> /dev/null; then
    log "✅ Docker está activo"
else
    error "❌ Docker no está activo. Inicia Docker con: systemctl start docker"
fi

# 2. Verificar Koha
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}2️⃣  VERIFICANDO CONTENEDOR KOHA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if docker ps | grep -q koha.*Up; then
    log "✅ Contenedor Koha está en ejecución"
else
    error "❌ Contenedor Koha no está ejecutándose"
    warning "Inicia con: docker compose up -d"
fi

# 3. Verificar puertos en Docker
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}3️⃣  VERIFICANDO PUERTOS EN DOCKER${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Buscar el contenedor Koha
KOHA_CONTAINER=$(docker ps --format "table {{.Names}}" | grep koha | head -1)

if [[ -n "$KOHA_CONTAINER" ]]; then
    info "Contenedor: $KOHA_CONTAINER"
    
    PORTS=$(docker port "$KOHA_CONTAINER" 2>/dev/null | grep -E '808[01]' || true)
    
    if [[ -z "$PORTS" ]]; then
        warning "⚠️  No se encontraron puertos 8080/8081"
        echo "    Verifícalos con: docker port $KOHA_CONTAINER"
    else
        log "✅ Puertos configurados:"
        echo "$PORTS" | sed 's/^/    /'
        
        # Verificar si están en todos los interfaces
        if echo "$PORTS" | grep -q "0.0.0.0"; then
            log "✅ Escuchando en todos los interfaces (0.0.0.0)"
        elif echo "$PORTS" | grep -q "127.0.0.1"; then
            error "❌ Escuchando solo en localhost (127.0.0.1)"
            echo "    Necesitas reconfigurar docker-compose.yaml"
        fi
    fi
else
    error "❌ No se encontró contenedor Koha"
fi

# 4. Verificar conectividad local
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}4️⃣  VERIFICANDO CONECTIVIDAD LOCAL${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Prueba localhost
if timeout 3 curl -s http://localhost:8080/cgi-bin/koha/mainpage.pl > /dev/null 2>&1; then
    log "✅ OPAC accesible en http://localhost:8080"
else
    warning "⚠️  OPAC NO accesible en http://localhost:8080"
fi

if timeout 3 curl -s http://localhost:8081 > /dev/null 2>&1; then
    log "✅ Staff Interface accesible en http://localhost:8081"
else
    warning "⚠️  Staff Interface NO accesible en http://localhost:8081"
fi

# 5. Verificar conectividad desde IP del servidor
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}5️⃣  VERIFICANDO CONECTIVIDAD DESDE RED (IP: $SERVER_IP)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if timeout 3 curl -s http://$SERVER_IP:8080/cgi-bin/koha/mainpage.pl > /dev/null 2>&1; then
    log "✅ OPAC accesible desde la red en http://$SERVER_IP:8080"
else
    warning "⚠️  OPAC NO accesible desde http://$SERVER_IP:8080"
    warning "   Esto es NORMAL si estás conectado solo por localhost"
fi

if timeout 3 curl -s http://$SERVER_IP:8081 > /dev/null 2>&1; then
    log "✅ Staff Interface accesible desde la red en http://$SERVER_IP:8081"
else
    warning "⚠️  Staff Interface NO accesible desde http://$SERVER_IP:8081"
fi

# 6. Verificar puertos escuchando
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}6️⃣  VERIFICANDO PUERTOS EN ESCUCHA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v netstat &> /dev/null; then
    if netstat -tlnp 2>/dev/null | grep -E ':(8080|8081)' > /dev/null; then
        log "✅ Puertos 8080/8081 encontrados en escucha:"
        netstat -tlnp 2>/dev/null | grep -E ':(8080|8081)' | sed 's/^/    /'
    else
        warning "⚠️  Puertos 8080/8081 no encontrados en escucha"
    fi
elif command -v ss &> /dev/null; then
    if ss -tlnp 2>/dev/null | grep -E ':(8080|8081)' > /dev/null; then
        log "✅ Puertos 8080/8081 encontrados en escucha:"
        ss -tlnp 2>/dev/null | grep -E ':(8080|8081)' | sed 's/^/    /'
    fi
fi

# 7. Verificar firewall
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}7️⃣  VERIFICANDO FIREWALL${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log "✅ UFW está activo"
        
        if ufw status | grep -q "8080"; then
            log "✅ Puerto 8080 permitido en UFW"
        else
            warning "⚠️  Puerto 8080 podría estar bloqueado en UFW"
            echo "    Permite con: sudo ufw allow 8080/tcp"
        fi
        
        if ufw status | grep -q "8081"; then
            log "✅ Puerto 8081 permitido en UFW"
        else
            warning "⚠️  Puerto 8081 podría estar bloqueado en UFW"
            echo "    Permite con: sudo ufw allow 8081/tcp"
        fi
    else
        info "ℹ️  UFW está desactivo"
    fi
fi

# 8. Recomendaciones finales
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 RECOMENDACIONES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
info "✅ Para acceso desde la red:"
echo "   1. Verifica que KOHA_DOMAIN=0.0.0.0 en .env"
echo "   2. Los puertos deben estar abiertos: 8080 (OPAC) y 8081 (Staff)"
echo "   3. El firewall debe permitir estos puertos"
echo "   4. Usa la IP del servidor: http://$SERVER_IP:8080"

echo ""
info "📝 Archivo de configuración: $(pwd)/.env"
if [[ -f .env ]]; then
    if grep -q "KOHA_DOMAIN=0.0.0.0" .env; then
        log "✅ .env está configurado correctamente"
    else
        warning "⚠️  .env podría necesitar actualización"
        echo "    Edita el archivo y cambia KOHA_DOMAIN a 0.0.0.0"
    fi
fi

echo ""
info "🔓 Abrir puertos en firewall (si es necesario):"
echo "   sudo ufw allow 8080/tcp"
echo "   sudo ufw allow 8081/tcp"

echo ""
info "🔄 Reiniciar servicios:"
echo "   ./manage.sh restart"

echo ""
info "🧪 Probar acceso:"
echo "   Desde esta máquina: http://localhost:8080"
echo "   Desde otra máquina: http://$SERVER_IP:8080"

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
log "✅ Verificación completada"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"