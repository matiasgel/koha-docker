#!/bin/bash
# Script de instalación simplificado que usa directorio local
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}" >&2; }
info() { echo -e "${CYAN}[ℹ] $1${NC}"; }

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  KOHA DOCKER - INSTALACIÓN RÁPIDA${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"

# Limpiar contenedores existentes
info "Limpiando contenedores anteriores..."
docker ps -aq --filter "name=koha" | xargs -r docker rm -f 2>/dev/null || true
docker ps -aq --filter "name=db" | xargs -r docker rm -f 2>/dev/null || true
docker ps -aq --filter "name=rabbitmq" | xargs -r docker rm -f 2>/dev/null || true
docker ps -aq --filter "name=memcached" | xargs -r docker rm -f 2>/dev/null || true

# Limpiar volúmenes
info "Limpiando volúmenes..."
docker volume ls -q | grep -E '(koha|mariadb|rabbitmq)' | xargs -r docker volume rm -f 2>/dev/null || true

# Limpiar redes
info "Limpiando redes..."
docker network ls --filter name=koha -q | xargs -r docker network rm 2>/dev/null || true

log "Limpieza completada"

# Crear directorios locales
info "Creando estructura de directorios..."
mkdir -p data/{koha/{etc,var,logs},mariadb/{data,conf},rabbitmq/{data,conf}}
mkdir -p backups logs

# Configurar RabbitMQ
echo '[rabbitmq_stomp].' > data/rabbitmq/conf/enabled_plugins

log "Directorios creados"

# Obtener IP del servidor
SERVER_IP=$(hostname -I | awk '{print $1}')

# Crear archivo .env
info "Creando configuración..."
cat > .env << 'ENVEOF'
# Koha Configuration
KOHA_INSTANCE=library
KOHA_DB_NAME=koha_library
KOHA_DB_USER=koha_library
KOHA_DB_PASSWORD=Koha2024SecurePass

# Database Root
MYSQL_ROOT_PASSWORD=Root2024SecurePass
MARIADB_ROOT_PASSWORD=Root2024SecurePass

# Database Connection
MYSQL_SERVER=db
MYSQL_USER=koha_library
MYSQL_PASSWORD=Koha2024SecurePass
DB_NAME=koha_library

# Network
KOHA_DOMAIN=library.local
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080

# Services
MEMCACHED_SERVERS=memcached:11211
MB_HOST=rabbitmq
MB_PORT=61613
MB_USER=koha
MB_PASS=Rabbit2024SecurePass
RABBITMQ_USER=koha
RABBITMQ_PASSWORD=Rabbit2024SecurePass

# Languages
KOHA_LANGS=es-ES

# Paths (usando directorio actual)
DATA_DIR=./data
BACKUP_DIR=./backups
LOG_DIR=./logs
TIMEZONE=America/Argentina/Buenos_Aires
ENVEOF

log "Configuración creada"

# Crear redes y volúmenes
info "Limpiando redes anteriores..."
docker network rm koha-network 2>/dev/null || true
docker network rm koha-docker_koha-network 2>/dev/null || true

info "Creando red Docker..."
docker network create koha-network --subnet=172.26.0.0/16 2>/dev/null || log "Red ya existe"

info "Creando volúmenes Docker..."
for vol in koha-etc koha-var koha-logs koha-uploads koha-plugins koha-covers mariadb-data mariadb-conf rabbitmq-data rabbitmq-conf; do
    docker volume create $vol 2>/dev/null || true
done

log "Infraestructura Docker lista"

# Iniciar servicios
info "Iniciando base de datos..."
docker compose up -d db

info "Esperando MariaDB (30s)..."
for i in {1..30}; do
    if docker exec koha-db healthcheck.sh --su-mysql --connect --innodb_initialized 2>/dev/null; then
        log "MariaDB listo"
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

info "Iniciando RabbitMQ..."
docker compose up -d rabbitmq

info "Esperando RabbitMQ (20s)..."
for i in {1..20}; do
    if docker exec koha-rabbitmq rabbitmq-diagnostics ping 2>/dev/null; then
        log "RabbitMQ listo"
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

info "Iniciando Memcached y Koha..."
docker compose up -d

info "Esperando inicialización de Koha (45s)..."
sleep 45

echo ""
log "═══════════════════════════════════════════════════"
log "  INSTALACIÓN COMPLETADA"
log "═══════════════════════════════════════════════════"
echo ""

echo -e "${CYAN}🌐 ACCESO:${NC}"
echo -e "  Staff: ${GREEN}http://$SERVER_IP:8081${NC}"
echo -e "  OPAC:  ${GREEN}http://$SERVER_IP:8080${NC}"
echo ""

echo -e "${CYAN}🔑 CREDENCIALES BD:${NC}"
echo -e "  Host: ${GREEN}db${NC}"
echo -e "  Database: ${GREEN}koha_library${NC}"
echo -e "  Usuario: ${GREEN}koha_library${NC}"
echo -e "  Password: ${GREEN}Koha2024SecurePass${NC}"
echo ""

# Verificar acceso
info "Verificando acceso web..."
HTTP_8081=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 2>/dev/null || echo "000")
if [ "$HTTP_8081" = "200" ] || [ "$HTTP_8081" = "302" ]; then
    log "Puerto 8081 responde: HTTP $HTTP_8081"
else
    echo -e "${YELLOW}Puerto 8081: HTTP $HTTP_8081 (esperando...)${NC}"
fi

echo ""
log "Usa ./quick-start.sh para reiniciar servicios"
