#!/bin/bash
# =============================================================================
# KOHA DOCKER - GESTIÓN SIMPLIFICADA
# =============================================================================
# Script para gestionar Koha Docker de forma sencilla
#
# USO: ./manage.sh {start|stop|restart|status|logs|backup|update}
# =============================================================================

set -e

# Directorio base
BASE_DIR="$(dirname "$(readlink -f "$0")")"
cd "$BASE_DIR"

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

show_header() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "         KOHA DOCKER - GESTIÓN"
    echo "=================================================="
    echo -e "${NC}"
}

show_status() {
    show_header
    log "📊 Estado de servicios Koha Docker:"
    echo ""
    
    if docker compose ps --format "table" 2>/dev/null; then
        echo ""
        log "🐳 Contenedores Docker:"
        docker ps --filter "label=com.docker.compose.project=koha-docker" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo ""
        log "💾 Uso de volúmenes:"
        docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}"
        
        echo ""
        log "🌐 Servicios disponibles:"
        local IP=$(hostname -I | awk '{print $1}')
        echo "  📱 OPAC: http://$IP:8080"
        echo "  🏢 Staff: http://$IP:8081"
        echo "  🐰 RabbitMQ: http://$IP:15672"
    else
        warning "Los servicios Koha Docker no están ejecutándose"
    fi
    
    echo ""
    if systemctl is-active --quiet koha-docker 2>/dev/null; then
        log "✅ Servicio systemd: ACTIVO"
    else
        warning "Servicio systemd: INACTIVO"
    fi
}

start_services() {
    show_header
    log "🚀 Iniciando servicios Koha Docker..."
    
    # Verificar .env
    if [[ ! -f .env ]]; then
        error "Archivo .env no encontrado. Ejecuta ./setup.sh primero."
    fi
    
    # Iniciar servicios
    docker compose up -d
    
    # Habilitar servicio systemd si existe
    if [[ -f /etc/systemd/system/koha-docker.service ]]; then
        systemctl enable koha-docker >/dev/null 2>&1
        systemctl start koha-docker >/dev/null 2>&1
        log "✅ Servicio systemd habilitado"
    fi
    
    log "⏳ Esperando inicialización de servicios..."
    sleep 10
    
    # Verificar estado
    if docker compose ps | grep -q "Up"; then
        log "✅ Servicios iniciados correctamente"
        local IP=$(hostname -I | awk '{print $1}')
        echo ""
        echo "🌐 Acceso disponible en:"
        echo "  📱 OPAC: http://$IP:8080"
        echo "  🏢 Staff: http://$IP:8081"
    else
        error "Error al iniciar servicios"
    fi
}

stop_services() {
    show_header
    log "🛑 Deteniendo servicios Koha Docker..."
    
    docker compose down
    
    # Detener servicio systemd
    if systemctl is-active --quiet koha-docker 2>/dev/null; then
        systemctl stop koha-docker >/dev/null 2>&1
        log "✅ Servicio systemd detenido"
    fi
    
    log "✅ Servicios detenidos"
}

restart_services() {
    show_header
    log "🔄 Reiniciando servicios Koha Docker..."
    stop_services
    sleep 5
    start_services
}

show_logs() {
    show_header
    log "📋 Mostrando logs de servicios (Ctrl+C para salir):"
    echo ""
    docker compose logs -f --tail=50
}

backup_data() {
    show_header
    log "💾 Creando backup de Koha Docker..."
    
    if [[ ! -f ./backup-koha.ps1 ]]; then
        error "Script de backup no encontrado"
    fi
    
    # Crear backup usando script PowerShell (adaptado para Linux)
    BACKUP_DIR="/opt/koha-backups"
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +"%Y%m%d-%H%M")
    BACKUP_NAME="koha-docker-$TIMESTAMP"
    
    log "📦 Exportando base de datos..."
    docker compose exec -T db mariadb-dump -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2)" koha_production > "$BACKUP_DIR/$BACKUP_NAME-database.sql"
    
    log "📁 Comprimiendo volúmenes..."
    tar -czf "$BACKUP_DIR/$BACKUP_NAME-volumes.tar.gz" -C volumes .
    
    log "📄 Guardando configuración..."
    cp .env "$BACKUP_DIR/$BACKUP_NAME.env"
    
    log "✅ Backup completado: $BACKUP_DIR/$BACKUP_NAME.*"
    echo "   📊 Archivos creados:"
    ls -lh "$BACKUP_DIR/$BACKUP_NAME"* | awk '{print "     " $9 " - " $5}'
}

update_system() {
    show_header
    log "🔄 Actualizando Koha Docker..."
    
    # Hacer backup antes de actualizar
    warning "Creando backup automático antes de actualizar..."
    backup_data
    
    log "📥 Actualizando código fuente..."
    git pull
    
    log "🐳 Actualizando imágenes Docker..."
    docker compose pull
    
    log "🔄 Reiniciando servicios con nuevas imágenes..."
    docker compose up -d --force-recreate
    
    log "✅ Sistema actualizado correctamente"
}

show_help() {
    show_header
    echo "Uso: $0 {comando}"
    echo ""
    echo "Comandos disponibles:"
    echo "  start    - Iniciar servicios Koha"
    echo "  stop     - Detener servicios Koha"
    echo "  restart  - Reiniciar servicios Koha"
    echo "  status   - Mostrar estado de servicios"
    echo "  logs     - Mostrar logs en tiempo real"
    echo "  backup   - Crear backup completo"
    echo "  update   - Actualizar sistema"
    echo "  help     - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./manage.sh start      # Iniciar Koha"
    echo "  ./manage.sh status     # Ver estado"
    echo "  ./manage.sh logs       # Ver logs"
    echo ""
}

# Verificar que estamos en el directorio correcto
if [[ ! -f docker-compose.yml ]]; then
    error "Este script debe ejecutarse desde el directorio raíz de koha-docker"
fi

# Procesar comando
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    backup)
        backup_data
        ;;
    update)
        update_system
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Comando desconocido: $1. Use './manage.sh help' para ver comandos disponibles."
        ;;
esac