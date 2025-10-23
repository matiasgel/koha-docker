#!/bin/bash

# ==========================================================
# SCRIPT DE BACKUP COMPLETO PARA KOHA DOCKER PRODUCCIÓN
# ==========================================================

set -euo pipefail

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar que Docker esté funcionando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker no está funcionando"
        exit 1
    fi
}

# Crear directorio de backup
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    if [[ ! -w "$BACKUP_DIR" ]]; then
        log_error "No se puede escribir en $BACKUP_DIR"
        exit 1
    fi
}

# Backup de base de datos
backup_database() {
    log_info "Iniciando backup de base de datos..."
    
    # Obtener variables de entorno
    DB_USER=$(docker exec koha-db-prod printenv MARIADB_USER)
    DB_NAME=$(docker exec koha-db-prod printenv MARIADB_DATABASE)
    
    # Backup completo de todas las bases de datos
    docker exec koha-db-prod mariadb-dump \
        -u root \
        -p"$MARIADB_ROOT_PASSWORD" \
        --all-databases \
        --routines \
        --triggers \
        --single-transaction \
        --master-data=2 \
        --flush-logs > "$BACKUP_DIR/db_full_backup_$DATE.sql"
    
    # Backup específico de Koha
    docker exec koha-db-prod mariadb-dump \
        -u root \
        -p"$MARIADB_ROOT_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        "$DB_NAME" > "$BACKUP_DIR/db_koha_backup_$DATE.sql"
    
    # Comprimir backups de BD
    gzip "$BACKUP_DIR/db_full_backup_$DATE.sql"
    gzip "$BACKUP_DIR/db_koha_backup_$DATE.sql"
    
    log_success "Backup de base de datos completado"
}

# Backup de volúmenes
backup_volumes() {
    log_info "Iniciando backup de volúmenes..."
    
    # Backup de configuración Koha
    docker run --rm \
        -v koha-etc:/data:ro \
        -v "$BACKUP_DIR:/backup" \
        alpine:latest \
        tar czf "/backup/koha_etc_backup_$DATE.tar.gz" -C /data .
    
    # Backup de datos Koha
    docker run --rm \
        -v koha-var:/data:ro \
        -v "$BACKUP_DIR:/backup" \
        alpine:latest \
        tar czf "/backup/koha_var_backup_$DATE.tar.gz" -C /data .
    
    # Backup de uploads
    docker run --rm \
        -v koha-uploads:/data:ro \
        -v "$BACKUP_DIR:/backup" \
        alpine:latest \
        tar czf "/backup/koha_uploads_backup_$DATE.tar.gz" -C /data .
    
    # Backup de plugins
    docker run --rm \
        -v koha-plugins:/data:ro \
        -v "$BACKUP_DIR:/backup" \
        alpine:latest \
        tar czf "/backup/koha_plugins_backup_$DATE.tar.gz" -C /data .
    
    log_success "Backup de volúmenes completado"
}

# Backup de configuración
backup_config() {
    log_info "Iniciando backup de configuración..."
    
    cd "$(dirname "$SCRIPT_DIR")"
    
    # Backup de archivos de configuración (excluyendo datos sensibles)
    tar czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" \
        --exclude='.env' \
        --exclude='ssl/*.key' \
        --exclude='ssl/*.pem' \
        config/ \
        docker-compose.prod-linux.yaml \
        scripts/ \
        .env.production
    
    log_success "Backup de configuración completado"
}

# Backup de logs (últimos 7 días)
backup_logs() {
    log_info "Iniciando backup de logs..."
    
    # Crear directorio temporal para logs
    TEMP_LOG_DIR=$(mktemp -d)
    
    # Copiar logs recientes
    docker run --rm \
        -v koha-logs:/logs:ro \
        -v "$TEMP_LOG_DIR:/temp" \
        alpine:latest \
        sh -c "find /logs -name '*.log' -mtime -7 -exec cp {} /temp/ \;"
    
    docker run --rm \
        -v mariadb-logs:/logs:ro \
        -v "$TEMP_LOG_DIR:/temp" \
        alpine:latest \
        sh -c "find /logs -name '*.log' -mtime -7 -exec cp {} /temp/ \;"
    
    # Comprimir logs
    if [[ -n "$(ls -A "$TEMP_LOG_DIR")" ]]; then
        tar czf "$BACKUP_DIR/logs_backup_$DATE.tar.gz" -C "$TEMP_LOG_DIR" .
        log_success "Backup de logs completado"
    else
        log_warning "No se encontraron logs recientes"
    fi
    
    # Limpiar directorio temporal
    rm -rf "$TEMP_LOG_DIR"
}

# Crear archivo de información del backup
create_backup_info() {
    log_info "Creando archivo de información del backup..."
    
    cat > "$BACKUP_DIR/backup_info_$DATE.txt" << EOF
Backup de Koha Docker Producción
================================
Fecha: $(date)
Hostname: $(hostname)
Usuario: $(whoami)

Información del Sistema:
- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
- Kernel: $(uname -r)
- Uptime: $(uptime)

Información de Docker:
- Versión: $(docker --version)
- Contenedores activos: $(docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2)

Información de la Base de Datos:
- Versión MariaDB: $(docker exec koha-db-prod mariadb --version)
- Tamaño BD: $(docker exec koha-db-prod mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' FROM information_schema.tables WHERE table_schema='$KOHA_DB_NAME';" | tail -n 1)

Archivos de Backup Generados:
$(ls -lh "$BACKUP_DIR"/*_$DATE.*)

Espacio en Disco:
$(df -h "$BACKUP_DIR")
EOF
    
    log_success "Archivo de información creado"
}

# Limpiar backups antiguos
cleanup_old_backups() {
    log_info "Limpiando backups antiguos (>$RETENTION_DAYS días)..."
    
    # Contar archivos antes
    OLD_COUNT=$(find "$BACKUP_DIR" -name "*backup_*.gz" -mtime +$RETENTION_DAYS | wc -l)
    
    if [[ $OLD_COUNT -gt 0 ]]; then
        find "$BACKUP_DIR" -name "*backup_*.gz" -mtime +$RETENTION_DAYS -delete
        find "$BACKUP_DIR" -name "*backup_*.txt" -mtime +$RETENTION_DAYS -delete
        log_success "Eliminados $OLD_COUNT backups antiguos"
    else
        log_info "No hay backups antiguos que eliminar"
    fi
}

# Verificar integridad de backups
verify_backups() {
    log_info "Verificando integridad de backups..."
    
    # Verificar que los archivos se crearon
    BACKUP_FILES=(
        "db_full_backup_$DATE.sql.gz"
        "db_koha_backup_$DATE.sql.gz"
        "koha_etc_backup_$DATE.tar.gz"
        "koha_var_backup_$DATE.tar.gz"
        "config_backup_$DATE.tar.gz"
    )
    
    FAILED=0
    for file in "${BACKUP_FILES[@]}"; do
        if [[ -f "$BACKUP_DIR/$file" ]]; then
            # Verificar que el archivo no esté corrupto
            case "$file" in
                *.gz)
                    if ! gzip -t "$BACKUP_DIR/$file" 2>/dev/null; then
                        log_error "Archivo corrupto: $file"
                        ((FAILED++))
                    fi
                    ;;
            esac
        else
            log_error "Archivo faltante: $file"
            ((FAILED++))
        fi
    done
    
    if [[ $FAILED -eq 0 ]]; then
        log_success "Todos los backups verificados correctamente"
    else
        log_error "$FAILED archivos de backup tienen problemas"
        return 1
    fi
}

# Enviar notificación (opcional)
send_notification() {
    if [[ -n "${NOTIFICATION_EMAIL:-}" ]]; then
        log_info "Enviando notificación por email..."
        
        SUBJECT="Backup Koha Docker - $(hostname) - $DATE"
        BODY="Backup completado exitosamente en $(hostname) el $(date)"
        
        echo "$BODY" | mail -s "$SUBJECT" "$NOTIFICATION_EMAIL" 2>/dev/null || \
            log_warning "No se pudo enviar la notificación por email"
    fi
}

# Función principal
main() {
    log_info "=== INICIANDO BACKUP COMPLETO DE KOHA DOCKER ==="
    log_info "Fecha: $(date)"
    log_info "Directorio de backup: $BACKUP_DIR"
    
    # Cargar variables de entorno
    if [[ -f "$(dirname "$SCRIPT_DIR")/.env" ]]; then
        source "$(dirname "$SCRIPT_DIR")/.env"
    else
        log_error "Archivo .env no encontrado"
        exit 1
    fi
    
    check_docker
    create_backup_dir
    
    # Ejecutar backups
    backup_database
    backup_volumes
    backup_config
    backup_logs
    create_backup_info
    verify_backups
    cleanup_old_backups
    send_notification
    
    # Calcular tamaño total del backup
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR"/*_$DATE.* | awk '{sum+=$1} END {print sum "B"}')
    
    log_success "=== BACKUP COMPLETADO EXITOSAMENTE ==="
    log_info "Tamaño total del backup: $TOTAL_SIZE"
    log_info "Archivos generados en: $BACKUP_DIR"
    
    # Mostrar resumen
    echo ""
    echo "Archivos generados:"
    ls -lh "$BACKUP_DIR"/*_$DATE.*
}

# Manejo de señales
trap 'log_error "Backup interrumpido"; exit 130' INT TERM

# Ejecutar función principal
main "$@"