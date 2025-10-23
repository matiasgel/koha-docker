#!/bin/bash

# ==========================================================
# SCRIPT DE GESTIÓN KOHA DOCKER - DEBIAN 13
# ==========================================================

INSTALL_DIR="/opt/koha-docker"
DOCKER_COMPOSE="docker compose"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de logging
log() { echo -e "${GREEN}[INFO] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}" >&2; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Verificar que estamos en el directorio correcto
check_directory() {
    if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
        error "No se encuentra docker-compose.yml en $INSTALL_DIR"
        error "¿Está instalado Koha Docker correctamente?"
        exit 1
    fi
    cd "$INSTALL_DIR"
}

# Función para mostrar estado
show_status() {
    log "📊 Estado de los servicios Koha Docker"
    echo ""
    
    if $DOCKER_COMPOSE ps | grep -q "Up"; then
        info "✅ Servicios activos:"
        $DOCKER_COMPOSE ps
    else
        warning "❌ No hay servicios ejecutándose"
    fi
    
    echo ""
    info "🔧 Estado del servicio systemd:"
    systemctl status koha-docker --no-pager -l
    
    echo ""
    info "💾 Uso de volúmenes:"
    docker system df
    
    echo ""
    info "🌐 URLs de acceso:"
    echo "  - Staff Interface: http://localhost:8081"
    echo "  - OPAC: http://localhost:8080"
    echo "  - RabbitMQ Management: http://localhost:15672"
}

# Función para iniciar servicios
start_services() {
    log "🚀 Iniciando servicios Koha Docker..."
    
    # Verificar que Docker esté corriendo
    if ! systemctl is-active --quiet docker; then
        log "🐳 Iniciando Docker..."
        systemctl start docker
    fi
    
    # Iniciar vía systemd
    systemctl start koha-docker
    
    log "⏳ Esperando que los servicios se inicialicen..."
    sleep 10
    
    # Verificar estado
    if $DOCKER_COMPOSE ps | grep -q "Up"; then
        log "✅ Servicios iniciados correctamente"
        show_status
    else
        error "❌ Error al iniciar servicios"
        $DOCKER_COMPOSE logs
        exit 1
    fi
}

# Función para parar servicios
stop_services() {
    log "🛑 Deteniendo servicios Koha Docker..."
    systemctl stop koha-docker
    log "✅ Servicios detenidos"
}

# Función para reiniciar servicios
restart_services() {
    log "🔄 Reiniciando servicios Koha Docker..."
    systemctl restart koha-docker
    sleep 10
    show_status
}

# Función para ver logs
show_logs() {
    local service="$1"
    
    if [[ -n "$service" ]]; then
        log "📋 Logs del servicio: $service"
        $DOCKER_COMPOSE logs -f "$service"
    else
        log "📋 Logs de todos los servicios"
        $DOCKER_COMPOSE logs -f
    fi
}

# Función para hacer backup
backup_now() {
    log "💾 Iniciando backup manual..."
    
    if ! $DOCKER_COMPOSE ps | grep -q "koha-backup.*Up"; then
        warning "Servicio de backup no está corriendo, iniciando backup manual..."
        docker run --rm \
            --network koha-prod_koha-network \
            -v koha-prod_mariadb_data:/var/lib/mysql:ro \
            -v "$(pwd)/backups":/backups \
            -e MYSQL_ROOT_PASSWORD="$(grep MARIADB_ROOT_PASSWORD .env | cut -d'=' -f2)" \
            alpine:3.18 sh -c "
                apk add --no-cache mariadb-client gzip tar &&
                BACKUP_DATE=\$(date +%Y%m%d_%H%M%S) &&
                BACKUP_DIR=\"/backups/manual_backup_\$BACKUP_DATE\" &&
                mkdir -p \"\$BACKUP_DIR\" &&
                echo 'Backing up database...' &&
                mariadb-dump -h mariadb -u root -p\"\$MYSQL_ROOT_PASSWORD\" --all-databases --single-transaction --routines --triggers > \"\$BACKUP_DIR/database.sql\" &&
                echo 'Backup completado en: '\$BACKUP_DIR
            "
    else
        docker exec koha-backup /backup.sh
    fi
    
    log "✅ Backup completado"
}

# Función para restaurar backup
restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        error "Debe especificar el archivo de backup"
        echo "Uso: $0 restore /ruta/al/backup.sql"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Archivo de backup no encontrado: $backup_file"
        exit 1
    fi
    
    warning "⚠️ Esta operación restaurará la base de datos"
    warning "⚠️ Se perderán todos los datos actuales"
    read -p "¿Continuar? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        info "Operación cancelada"
        exit 0
    fi
    
    log "🔄 Restaurando backup desde: $backup_file"
    
    # Parar Koha temporalmente
    $DOCKER_COMPOSE stop koha
    
    # Restaurar base de datos
    docker exec -i koha-mariadb mariadb -u root -p"$(grep MARIADB_ROOT_PASSWORD .env | cut -d'=' -f2)" < "$backup_file"
    
    # Reiniciar servicios
    $DOCKER_COMPOSE start koha
    
    log "✅ Backup restaurado correctamente"
}

# Función para actualizar sistema
update_system() {
    log "🔄 Actualizando Koha Docker..."
    
    # Hacer backup antes de actualizar
    warning "Haciendo backup automático antes de actualizar..."
    backup_now
    
    # Pull de nuevas imágenes
    $DOCKER_COMPOSE pull
    
    # Reiniciar con nuevas imágenes
    $DOCKER_COMPOSE up -d
    
    log "✅ Sistema actualizado"
}

# Función para limpiar sistema
cleanup_system() {
    log "🧹 Limpiando sistema..."
    
    # Limpiar contenedores parados
    docker container prune -f
    
    # Limpiar imágenes no utilizadas
    docker image prune -f
    
    # Limpiar volúmenes no utilizados
    docker volume prune -f
    
    # Limpiar redes no utilizadas
    docker network prune -f
    
    # Limpiar logs antiguos
    find /var/log/koha-docker -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    log "✅ Limpieza completada"
}

# Función para generar reporte del sistema
system_report() {
    log "📊 Generando reporte del sistema..."
    
    local report_file="/tmp/koha-system-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=========================================="
        echo "REPORTE DEL SISTEMA KOHA DOCKER"
        echo "Fecha: $(date)"
        echo "=========================================="
        echo ""
        
        echo "INFORMACIÓN DEL SISTEMA:"
        echo "------------------------"
        uname -a
        lsb_release -a 2>/dev/null || cat /etc/os-release
        echo ""
        
        echo "DOCKER:"
        echo "-------"
        docker version
        echo ""
        
        echo "SERVICIOS:"
        echo "----------"
        $DOCKER_COMPOSE ps
        echo ""
        
        echo "RECURSOS:"
        echo "---------"
        docker stats --no-stream
        echo ""
        
        echo "VOLÚMENES:"
        echo "----------"
        docker volume ls
        echo ""
        
        echo "ESPACIO EN DISCO:"
        echo "-----------------"
        df -h
        echo ""
        
        echo "MEMORIA:"
        echo "--------"
        free -h
        echo ""
        
        echo "CONFIGURACIÓN:"
        echo "--------------"
        grep -v PASSWORD .env 2>/dev/null || echo "No se puede leer .env"
        
    } > "$report_file"
    
    log "✅ Reporte generado: $report_file"
    info "Para ver el reporte: cat $report_file"
}

# Función para mostrar ayuda
show_help() {
    echo -e "${CYAN}Koha Docker - Script de Gestión para Debian 13${NC}"
    echo ""
    echo "Uso: $0 [comando] [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status              Mostrar estado de los servicios"
    echo "  start               Iniciar todos los servicios"
    echo "  stop                Detener todos los servicios"
    echo "  restart             Reiniciar todos los servicios"
    echo "  logs [servicio]     Mostrar logs (opcionalmente de un servicio específico)"
    echo "  backup              Realizar backup manual"
    echo "  restore <archivo>   Restaurar desde backup"
    echo "  update              Actualizar el sistema"
    echo "  cleanup             Limpiar sistema (contenedores, imágenes, etc.)"
    echo "  report              Generar reporte del sistema"
    echo "  help                Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 status"
    echo "  $0 logs koha"
    echo "  $0 restore /opt/koha-docker/backups/backup.sql"
    echo ""
    echo "Servicios disponibles para logs:"
    echo "  koha, mariadb, memcached, rabbitmq, nginx, backup"
}

# Función principal
main() {
    # Verificar que se ejecuta con permisos adecuados
    if [[ $EUID -ne 0 ]] && [[ "$1" != "help" ]] && [[ "$1" != "status" ]]; then
        error "Este comando requiere permisos de sudo"
        exit 1
    fi
    
    # Verificar directorio (excepto para help)
    if [[ "$1" != "help" ]]; then
        check_directory
    fi
    
    case "$1" in
        "status")
            show_status
            ;;
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "logs")
            show_logs "$2"
            ;;
        "backup")
            backup_now
            ;;
        "restore")
            restore_backup "$2"
            ;;
        "update")
            update_system
            ;;
        "cleanup")
            cleanup_system
            ;;
        "report")
            system_report
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            error "Comando desconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"