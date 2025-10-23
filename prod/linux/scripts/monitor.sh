#!/bin/bash

# ==========================================================
# SCRIPT DE MONITOREO PARA KOHA DOCKER PRODUCCIÓN
# ==========================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Función para mostrar estado de servicios
check_services() {
    echo "=== ESTADO DE SERVICIOS DOCKER ==="
    
    SERVICES=("koha-prod" "koha-db-prod" "koha-memcached-prod" "koha-rabbitmq-prod" "koha-nginx-prod")
    
    for service in "${SERVICES[@]}"; do
        if docker ps --filter "name=$service" --format "table {{.Names}}\t{{.Status}}" | grep -q "$service"; then
            STATUS=$(docker ps --filter "name=$service" --format "{{.Status}}")
            if [[ $STATUS == *"Up"* ]]; then
                log_success "$service: $STATUS"
            else
                log_warning "$service: $STATUS"
            fi
        else
            log_error "$service: No está ejecutándose"
        fi
    done
    echo ""
}

# Función para mostrar uso de recursos
check_resources() {
    echo "=== USO DE RECURSOS ==="
    
    # Memoria del sistema
    echo "Memoria del Sistema:"
    free -h
    echo ""
    
    # Espacio en disco
    echo "Espacio en Disco:"
    df -h | grep -E "(Filesystem|/dev/|/opt)"
    echo ""
    
    # Uso de Docker
    echo "Uso de Recursos por Contenedor:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | head -10
    echo ""
}

# Función para verificar salud de la base de datos
check_database() {
    echo "=== ESTADO DE LA BASE DE DATOS ==="
    
    if docker exec koha-db-prod mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        log_success "Conexión a MariaDB: OK"
        
        # Tamaño de la base de datos
        DB_SIZE=$(docker exec koha-db-prod mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size_MB' FROM information_schema.tables WHERE table_schema='$KOHA_DB_NAME';" | tail -n 1)
        echo "Tamaño BD Koha: ${DB_SIZE} MB"
        
        # Conexiones activas
        CONNECTIONS=$(docker exec koha-db-prod mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SHOW STATUS LIKE 'Threads_connected';" | tail -n 1 | awk '{print $2}')
        echo "Conexiones activas: $CONNECTIONS"
        
        # Uptime de la BD
        UPTIME=$(docker exec koha-db-prod mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SHOW STATUS LIKE 'Uptime';" | tail -n 1 | awk '{print $2}')
        UPTIME_HOURS=$((UPTIME / 3600))
        echo "Uptime BD: ${UPTIME_HOURS} horas"
        
    else
        log_error "No se puede conectar a MariaDB"
    fi
    echo ""
}

# Función para verificar Koha
check_koha() {
    echo "=== ESTADO DE KOHA ==="
    
    # Verificar OPAC
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        log_success "OPAC (Puerto 8080): Accesible"
    else
        log_error "OPAC (Puerto 8080): No accesible"
    fi
    
    # Verificar Staff Interface
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200"; then
        log_success "Staff Interface (Puerto 8081): Accesible"
    else
        log_error "Staff Interface (Puerto 8081): No accesible"
    fi
    
    echo ""
}

# Función para verificar logs recientes
check_logs() {
    echo "=== LOGS RECIENTES (ÚLTIMOS 10 ERRORES) ==="
    
    # Logs de Koha
    echo "Errores en Koha:"
    docker logs koha-prod --since=1h 2>&1 | grep -i error | tail -5 || echo "No hay errores recientes"
    
    # Logs de MariaDB
    echo ""
    echo "Errores en MariaDB:"
    docker logs koha-db-prod --since=1h 2>&1 | grep -i error | tail -5 || echo "No hay errores recientes"
    
    # Logs de Nginx
    echo ""
    echo "Errores en Nginx:"
    docker logs koha-nginx-prod --since=1h 2>&1 | grep -i error | tail -5 || echo "No hay errores recientes"
    
    echo ""
}

# Función para verificar backups
check_backups() {
    echo "=== ESTADO DE BACKUPS ==="
    
    BACKUP_DIR="/opt/koha-docker/backups"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.gz 2>/dev/null | head -1)
        
        if [[ -n "$LATEST_BACKUP" ]]; then
            BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP" | cut -d' ' -f1)
            BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
            log_success "Último backup: $BACKUP_DATE ($BACKUP_SIZE)"
            
            # Verificar si el backup es reciente (menos de 25 horas)
            if [[ $(find "$LATEST_BACKUP" -mtime -1) ]]; then
                log_success "Backup reciente: OK"
            else
                log_warning "Backup antiguo: >24 horas"
            fi
        else
            log_warning "No se encontraron backups"
        fi
        
        # Mostrar espacio disponible para backups
        BACKUP_SPACE=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $4}')
        echo "Espacio disponible para backups: $BACKUP_SPACE"
    else
        log_error "Directorio de backups no encontrado"
    fi
    echo ""
}

# Función para verificar SSL
check_ssl() {
    echo "=== ESTADO DE CERTIFICADOS SSL ==="
    
    SSL_CERT="/opt/koha-docker/ssl/cert.pem"
    
    if [[ -f "$SSL_CERT" ]]; then
        EXPIRY_DATE=$(openssl x509 -in "$SSL_CERT" -noout -enddate | cut -d= -f2)
        EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
        
        if [[ $DAYS_LEFT -gt 30 ]]; then
            log_success "Certificado SSL válido por $DAYS_LEFT días"
        elif [[ $DAYS_LEFT -gt 0 ]]; then
            log_warning "Certificado SSL expira en $DAYS_LEFT días"
        else
            log_error "Certificado SSL expirado"
        fi
    else
        log_warning "Certificado SSL no encontrado"
    fi
    echo ""
}

# Función para mostrar puertos abiertos
check_ports() {
    echo "=== PUERTOS EN USO ==="
    
    PORTS=("80:HTTP" "443:HTTPS" "3306:MySQL" "15672:RabbitMQ")
    
    for port_info in "${PORTS[@]}"; do
        PORT=$(echo "$port_info" | cut -d: -f1)
        SERVICE=$(echo "$port_info" | cut -d: -f2)
        
        if netstat -tuln | grep -q ":$PORT "; then
            log_success "$SERVICE (Puerto $PORT): Abierto"
        else
            log_warning "$SERVICE (Puerto $PORT): Cerrado"
        fi
    done
    echo ""
}

# Función para generar reporte de salud
generate_health_score() {
    echo "=== PUNTUACIÓN DE SALUD DEL SISTEMA ==="
    
    SCORE=0
    MAX_SCORE=10
    
    # Verificar servicios (3 puntos)
    RUNNING_SERVICES=$(docker ps --filter "name=koha-" --format "{{.Names}}" | wc -l)
    if [[ $RUNNING_SERVICES -ge 4 ]]; then
        ((SCORE += 3))
    elif [[ $RUNNING_SERVICES -ge 2 ]]; then
        ((SCORE += 2))
    elif [[ $RUNNING_SERVICES -ge 1 ]]; then
        ((SCORE += 1))
    fi
    
    # Verificar BD (2 puntos)
    if docker exec koha-db-prod mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        ((SCORE += 2))
    fi
    
    # Verificar acceso web (2 puntos)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        ((SCORE += 1))
    fi
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200"; then
        ((SCORE += 1))
    fi
    
    # Verificar backup reciente (2 puntos)
    BACKUP_DIR="/opt/koha-docker/backups"
    if [[ -d "$BACKUP_DIR" ]]; then
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.gz 2>/dev/null | head -1)
        if [[ -n "$LATEST_BACKUP" && $(find "$LATEST_BACKUP" -mtime -1) ]]; then
            ((SCORE += 2))
        fi
    fi
    
    # Verificar SSL (1 punto)
    SSL_CERT="/opt/koha-docker/ssl/cert.pem"
    if [[ -f "$SSL_CERT" ]]; then
        EXPIRY_DATE=$(openssl x509 -in "$SSL_CERT" -noout -enddate | cut -d= -f2)
        EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
        if [[ $DAYS_LEFT -gt 0 ]]; then
            ((SCORE += 1))
        fi
    fi
    
    # Mostrar resultado
    PERCENTAGE=$((SCORE * 100 / MAX_SCORE))
    
    if [[ $PERCENTAGE -ge 90 ]]; then
        log_success "Salud del Sistema: $SCORE/$MAX_SCORE ($PERCENTAGE%) - EXCELENTE"
    elif [[ $PERCENTAGE -ge 70 ]]; then
        echo -e "${YELLOW}[BUENO]${NC} Salud del Sistema: $SCORE/$MAX_SCORE ($PERCENTAGE%) - BUENO"
    elif [[ $PERCENTAGE -ge 50 ]]; then
        log_warning "Salud del Sistema: $SCORE/$MAX_SCORE ($PERCENTAGE%) - REGULAR"
    else
        log_error "Salud del Sistema: $SCORE/$MAX_SCORE ($PERCENTAGE%) - CRÍTICO"
    fi
    echo ""
}

# Función principal
main() {
    clear
    echo "================================================================"
    echo "           MONITOR DE KOHA DOCKER PRODUCCIÓN"
    echo "================================================================"
    echo "Fecha: $(date)"
    echo "Hostname: $(hostname)"
    echo "================================================================"
    echo ""
    
    # Cargar variables de entorno
    if [[ -f "/opt/koha-docker/.env" ]]; then
        source /opt/koha-docker/.env
    else
        log_warning "Archivo .env no encontrado, algunas verificaciones pueden fallar"
    fi
    
    # Ejecutar todas las verificaciones
    check_services
    check_resources
    check_database
    check_koha
    check_ssl
    check_ports
    check_backups
    check_logs
    generate_health_score
    
    echo "================================================================"
    echo "           MONITOREO COMPLETADO"
    echo "================================================================"
}

# Opciones de línea de comandos
case "${1:-full}" in
    "services")
        check_services
        ;;
    "resources")
        check_resources
        ;;
    "database")
        if [[ -f "/opt/koha-docker/.env" ]]; then
            source /opt/koha-docker/.env
        fi
        check_database
        ;;
    "koha")
        check_koha
        ;;
    "ssl")
        check_ssl
        ;;
    "backups")
        check_backups
        ;;
    "logs")
        check_logs
        ;;
    "health")
        if [[ -f "/opt/koha-docker/.env" ]]; then
            source /opt/koha-docker/.env
        fi
        generate_health_score
        ;;
    "full"|*)
        main
        ;;
esac