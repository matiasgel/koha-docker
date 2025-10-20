#!/bin/bash
# Script de monitoreo para los servicios de Koha

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Monitor de Servicios Koha ==="
echo "$(date)"
echo

# Función para verificar estado del servicio
check_service() {
    local service_name=$1
    local container_name="prod_${service_name}_1"
    
    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        echo -e "${GREEN}✓${NC} $service_name: En ejecución"
        
        # Verificar health check si está disponible
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-health-check")
        if [ "$health_status" != "no-health-check" ]; then
            if [ "$health_status" = "healthy" ]; then
                echo -e "  ${GREEN}✓${NC} Health check: Saludable"
            else
                echo -e "  ${YELLOW}⚠${NC} Health check: $health_status"
            fi
        fi
    else
        echo -e "${RED}✗${NC} $service_name: No está en ejecución"
    fi
}

# Verificar servicios
check_service "koha"
check_service "db"
check_service "rabbitmq"
check_service "memcached"

echo
echo "=== Estadísticas de Uso ==="

# Verificar uso de disco de volúmenes
echo "Uso de disco de volúmenes:"
if [ -d "volumes/mariadb/data" ]; then
    db_size=$(du -sh volumes/mariadb/data 2>/dev/null | cut -f1 || echo "N/A")
    echo "  - Base de datos: $db_size"
fi

if [ -d "volumes/koha/logs" ]; then
    logs_size=$(du -sh volumes/koha/logs 2>/dev/null | cut -f1 || echo "N/A")
    echo "  - Logs de Koha: $logs_size"
fi

if [ -d "volumes/mariadb/backups" ]; then
    backup_size=$(du -sh volumes/mariadb/backups 2>/dev/null | cut -f1 || echo "N/A")
    backup_count=$(find volumes/mariadb/backups -name "*.sql.gz" 2>/dev/null | wc -l || echo "0")
    echo "  - Backups: $backup_size ($backup_count archivos)"
fi

echo
echo "=== URLs de Acceso ==="
echo "  - OPAC: http://localhost:8080"
echo "  - Interfaz Staff: http://localhost:8081"
echo "  - RabbitMQ Management: http://localhost:15672"
echo "  - Base de datos: localhost:3306"

echo
echo "=== Logs Recientes ==="
echo "Para ver logs en tiempo real:"
echo "  docker-compose -f docker-compose.prod.yaml logs -f koha"
echo "  docker-compose -f docker-compose.prod.yaml logs -f db"
echo "  docker-compose -f docker-compose.prod.yaml logs -f rabbitmq"
