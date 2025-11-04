#!/bin/bash
# =============================================================================
# KOHA DOCKER - LIMPIAR Y REINICIAR RABBITMQ
# =============================================================================
# Script para limpiar volúmenes de RabbitMQ y reiniciar completamente
#
# USO: sudo bash reset-rabbitmq.sh
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

echo -e "${BLUE}"
echo "════════════════════════════════════════════════════════════════"
echo "      KOHA DOCKER - RESET COMPLETO DE RABBITMQ"
echo "════════════════════════════════════════════════════════════════"
echo -e "${NC}"

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
   error "Este script debe ejecutarse con sudo"
fi

INSTALL_DIR="${1:-.}"

if [[ ! -f "$INSTALL_DIR/prod/docker-compose.prod.yaml" ]]; then
    error "No se encontró prod/docker-compose.prod.yaml en $INSTALL_DIR"
fi

log "Directorio: $INSTALL_DIR"
cd "$INSTALL_DIR"

# 1. Detener servicios
log "🛑 Deteniendo servicios..."
docker compose -f prod/docker-compose.prod.yaml down 2>/dev/null || true

# 2. Limpiar volúmenes de RabbitMQ
if [[ -d "prod/volumes/rabbitmq" ]]; then
    warning "Removiendo volumen de RabbitMQ..."
    rm -rf prod/volumes/rabbitmq
    mkdir -p prod/volumes/rabbitmq/data
    mkdir -p prod/volumes/rabbitmq/logs
    chmod 777 prod/volumes/rabbitmq/data
    chmod 777 prod/volumes/rabbitmq/logs
    log "✅ Volumen limpiado"
fi

# 3. Verificar configuración
if [[ ! -f "prod/config/rabbitmq.conf" ]]; then
    error "No se encontró prod/config/rabbitmq.conf"
fi

if [[ ! -f "prod/rabbitmq_plugins" ]]; then
    error "No se encontró prod/rabbitmq_plugins"
fi

log "✅ Configuración verificada"

# 4. Limpiar redes de Docker si está corrupta
warning "Limpiando redes de Docker (si existen)..."
docker network rm koha-prod 2>/dev/null || true
docker network rm koha-network 2>/dev/null || true

# 5. Reiniciar Docker daemon
log "🔄 Reiniciando Docker daemon..."
systemctl restart docker || service docker restart || true

# 6. Esperar a que Docker esté listo
sleep 5

# 7. Iniciar solo RabbitMQ primero
log "🚀 Iniciando RabbitMQ..."
docker compose -f prod/docker-compose.prod.yaml up -d rabbitmq

# 8. Esperar a que inicie
log "⏳ Esperando que RabbitMQ esté listo..."
for i in {1..60}; do
    if docker exec koha-rabbitmq rabbitmq-diagnostics -q ping 2>/dev/null | grep -q "ok"; then
        log "✅ RabbitMQ está listo"
        break
    fi
    
    if [[ $i -eq 60 ]]; then
        error "RabbitMQ no respondió después de 60 segundos"
    fi
    
    echo -n "."
    sleep 1
done

# 9. Verificar plugins
log "🔌 Verificando plugins..."
docker exec koha-rabbitmq rabbitmq-plugins list -e | grep -E "rabbitmq_stomp|rabbitmq_management"

log "✅ Plugins activos"

# 10. Crear usuario y permisos
log "👤 Configurando usuario koha..."
docker exec koha-rabbitmq rabbitmqctl add_user koha RabbitMQ#2024\$Queue123 2>/dev/null || true
docker exec koha-rabbitmq rabbitmqctl set_permissions -p / koha ".*" ".*" ".*" 2>/dev/null || true

log "✅ Usuario configurado"

# 11. Iniciar otros servicios
log "🚀 Iniciando otros servicios..."
docker compose -f prod/docker-compose.prod.yaml up -d

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
log "✅ Reset completado"
echo ""
info "RabbitMQ ha sido reiniciado completamente"
info "Esperando que otros servicios inicien..."
echo ""
echo "Próximos pasos:"
echo "  1. Espera 2-3 minutos para que todo inicie"
echo "  2. Ejecuta: docker compose -f prod/docker-compose.prod.yaml ps"
echo "  3. Ejecuta: docker compose -f prod/docker-compose.prod.yaml logs -f"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"