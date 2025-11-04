#!/bin/bash
# Script de inicio rápido
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓] $1${NC}"; }
info() { echo -e "${CYAN}[ℹ] $1${NC}"; }

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  KOHA DOCKER - INICIO RÁPIDO${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"

# Verificar si ya están corriendo
if docker ps | grep -q "koha-prod.*Up"; then
    log "Servicios ya están corriendo"
    docker ps --filter "name=koha" --format "table {{.Names}}\t{{.Status}}"
    echo ""
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${CYAN}Acceso: ${GREEN}http://$SERVER_IP:8081${NC}"
    exit 0
fi

# Iniciar servicios
info "Iniciando base de datos..."
docker compose up -d db
sleep 3

info "Esperando MariaDB..."
for i in {1..20}; do
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
sleep 3

info "Esperando RabbitMQ..."
for i in {1..15}; do
    if docker exec koha-rabbitmq rabbitmq-diagnostics ping 2>/dev/null; then
        log "RabbitMQ listo"
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

info "Iniciando servicios restantes..."
docker compose up -d
sleep 5

log "Servicios iniciados"
docker ps --filter "name=koha" --format "table {{.Names}}\t{{.Status}}"

SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo -e "${CYAN}Acceso: ${GREEN}http://$SERVER_IP:8081${NC}"
