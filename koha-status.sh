#!/bin/bash
# =============================================================================
# KOHA DOCKER - ESTADO RÁPIDO
# =============================================================================
# Script para verificar el estado de Koha Docker de forma rápida
#
# USO: ./koha-status.sh
# =============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Iconos
ICON_UP="✅"
ICON_DOWN="❌"
ICON_WARN="⚠️"
ICON_INFO="ℹ️"

echo -e "${CYAN}"
echo "██╗  ██╗ ██████╗ ██╗  ██╗ █████╗     ███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗"
echo "██║ ██╔╝██╔═══██╗██║  ██║██╔══██╗    ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝"
echo "█████╔╝ ██║   ██║███████║███████║    ███████╗   ██║   ███████║   ██║   ██║   ██║███████╗"
echo "██╔═██╗ ██║   ██║██╔══██║██╔══██║    ╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║"
echo "██║  ██╗╚██████╔╝██║  ██║██║  ██║    ███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║"
echo "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝"
echo -e "${NC}"

# Función para verificar si un servicio está ejecutándose
check_service() {
    local service_name="$1"
    local container_name="$2"
    
    if docker ps | grep -q "$container_name.*Up"; then
        echo -e "${GREEN}${ICON_UP} $service_name${NC}"
        return 0
    else
        echo -e "${RED}${ICON_DOWN} $service_name${NC}"
        return 1
    fi
}

# Función para obtener info de un contenedor
get_container_info() {
    local container_name="$1"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$container_name"; then
        docker ps --format "{{.Status}}" | head -1
    else
        echo "No ejecutándose"
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 ESTADO DE SERVICIOS KOHA DOCKER${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Verificar Docker
if ! docker info &> /dev/null; then
    echo -e "${RED}${ICON_DOWN} Docker no está ejecutándose${NC}"
    exit 1
fi

# Verificar servicios principales
services_up=0
total_services=0

echo ""
echo -e "${CYAN}🐳 CONTENEDORES:${NC}"

# Koha
if check_service "Koha (Apache + Zebra)" "koha-docker.*koha"; then
    ((services_up++))
fi
((total_services++))

# MariaDB
if check_service "MariaDB (Base de datos)" "koha-docker.*db"; then
    ((services_up++))
fi
((total_services++))

# RabbitMQ
if check_service "RabbitMQ (Cola de mensajes)" "koha-docker.*rabbitmq"; then
    ((services_up++))
fi
((total_services++))

# Memcached
if check_service "Memcached (Cache)" "koha-docker.*memcached"; then
    ((services_up++))
fi
((total_services++))

echo ""
echo -e "${CYAN}🌐 SERVICIOS WEB:${NC}"

# Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

# Verificar puertos
check_port() {
    local port=$1
    local service=$2
    local url="http://$SERVER_IP:$port"
    
    if timeout 3 bash -c "echo >/dev/tcp/$SERVER_IP/$port" 2>/dev/null; then
        echo -e "${GREEN}${ICON_UP} $service - $url${NC}"
        return 0
    else
        echo -e "${RED}${ICON_DOWN} $service - Puerto $port cerrado${NC}"
        return 1
    fi
}

web_services=0
check_port 8080 "OPAC (Catálogo público)" && ((web_services++))
check_port 8081 "Staff Interface (Interfaz bibliotecario)" && ((web_services++))
check_port 15672 "RabbitMQ Management" && ((web_services++))

echo ""
echo -e "${CYAN}💾 SISTEMA:${NC}"

# Espacio en disco
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $DISK_USAGE -gt 80 ]]; then
    echo -e "${RED}${ICON_WARN} Espacio en disco: ${DISK_USAGE}% (CRÍTICO)${NC}"
elif [[ $DISK_USAGE -gt 60 ]]; then
    echo -e "${YELLOW}${ICON_WARN} Espacio en disco: ${DISK_USAGE}% (ADVERTENCIA)${NC}"
else
    echo -e "${GREEN}${ICON_UP} Espacio en disco: ${DISK_USAGE}% (OK)${NC}"
fi

# Memoria
if command -v free &> /dev/null; then
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/($3+$7)}')
    if [[ $MEMORY_USAGE -gt 90 ]]; then
        echo -e "${RED}${ICON_WARN} Memoria RAM: ${MEMORY_USAGE}% (CRÍTICO)${NC}"
    elif [[ $MEMORY_USAGE -gt 70 ]]; then
        echo -e "${YELLOW}${ICON_WARN} Memoria RAM: ${MEMORY_USAGE}% (ADVERTENCIA)${NC}"
    else
        echo -e "${GREEN}${ICON_UP} Memoria RAM: ${MEMORY_USAGE}% (OK)${NC}"
    fi
fi

# Servicio systemd
if systemctl is-active --quiet koha-docker 2>/dev/null; then
    echo -e "${GREEN}${ICON_UP} Servicio systemd: ACTIVO${NC}"
else
    echo -e "${YELLOW}${ICON_WARN} Servicio systemd: INACTIVO${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Estado general
if [[ $services_up -eq $total_services ]] && [[ $web_services -gt 0 ]]; then
    echo -e "${GREEN}🎉 ESTADO GENERAL: TODOS LOS SERVICIOS FUNCIONANDO CORRECTAMENTE${NC}"
    echo ""
    echo -e "${CYAN}🚀 ACCESO RÁPIDO:${NC}"
    echo -e "   📱 Catálogo (OPAC): ${BLUE}http://$SERVER_IP:8080${NC}"
    echo -e "   🏢 Staff Interface: ${BLUE}http://$SERVER_IP:8081${NC}"
    echo -e "   🔑 Usuario por defecto: ${YELLOW}koha_admin${NC}"
elif [[ $services_up -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  ESTADO GENERAL: SERVICIOS PARCIALMENTE FUNCIONANDO ($services_up/$total_services)${NC}"
    echo -e "${YELLOW}   Revisa los servicios marcados con ❌${NC}"
else
    echo -e "${RED}🚨 ESTADO GENERAL: SERVICIOS NO FUNCIONANDO${NC}"
    echo -e "${RED}   Ejecuta './manage.sh start' para iniciar los servicios${NC}"
fi

echo ""
echo -e "${CYAN}🛠️  COMANDOS ÚTILES:${NC}"
echo -e "   ./manage.sh start    ${BLUE}# Iniciar servicios${NC}"
echo -e "   ./manage.sh stop     ${BLUE}# Detener servicios${NC}"
echo -e "   ./manage.sh restart  ${BLUE}# Reiniciar servicios${NC}"
echo -e "   ./manage.sh logs     ${BLUE}# Ver logs en tiempo real${NC}"
echo -e "   ./manage.sh backup   ${BLUE}# Crear backup${NC}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📅 $(date)${NC}"