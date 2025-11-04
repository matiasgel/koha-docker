#!/bin/bash
# =============================================================================
# GENERADOR DE ARCHIVO .env CON PASSWORDS SEGUROS
# =============================================================================
# Genera un archivo .env listo para usar con passwords aleatorios seguros

set -e

info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }

echo "🔐 Generador de configuración Koha Docker"
echo "========================================"

# Verificar si ya existe .env
if [[ -f .env ]]; then
    warning "Ya existe un archivo .env"
    echo "¿Sobrescribir? (s/N): "
    read -r response
    if [[ "$response" != "s" && "$response" != "S" ]]; then
        echo "Operación cancelada"
        exit 1
    fi
fi

# Generar passwords seguros
info "Generando passwords seguros..."
DB_PASS=$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-16)
ROOT_PASS=$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-16)
RMQ_PASS=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-12)
ADMIN_PASS=$(openssl rand -base64 12 | tr -d '=+/' | cut -c1-8)

# Solicitar configuración básica
echo ""
info "Configuración básica:"
read -p "Dominio para Staff Interface [localhost]: " DOMAIN
DOMAIN=${DOMAIN:-localhost}

read -p "Dominio para OPAC [localhost]: " OPAC_DOMAIN
OPAC_DOMAIN=${OPAC_DOMAIN:-localhost}

read -p "Nombre de la biblioteca [Biblioteca Principal]: " LIBRARY_NAME
LIBRARY_NAME=${LIBRARY_NAME:-Biblioteca Principal}

# Crear archivo .env
info "Creando archivo .env..."

cat > .env << EOF
# Configuracion Koha Docker - Generado: $(date)

# Base de datos
KOHA_DB_NAME=koha_production
KOHA_DB_USER=koha_admin
KOHA_DB_PASSWORD=$DB_PASS
MYSQL_ROOT_PASSWORD=$ROOT_PASS
MARIADB_ROOT_PASSWORD=$ROOT_PASS
MYSQL_SERVER=db
DB_NAME=koha_production
MYSQL_USER=koha_admin
MYSQL_PASSWORD=$DB_PASS

# Dominios
KOHA_DOMAIN=$DOMAIN
OPAC_DOMAIN=$OPAC_DOMAIN
KOHA_INSTANCE=production

# Puertos
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080
KOHA_INTRANET_PREFIX=
KOHA_INTRANET_SUFFIX=
KOHA_OPAC_PREFIX=
KOHA_OPAC_SUFFIX=

# Servicios
MEMCACHED_SERVERS=memcached:11211
MB_HOST=rabbitmq
MB_PORT=61613
MB_USER=koha
MB_PASS=$RMQ_PASS
RABBITMQ_PASSWORD=$RMQ_PASS
RABBITMQ_USER=koha

# Sistema
INSTALL_DIR=/opt/koha-docker
DATA_DIR=/opt/koha-docker/data
DATA_PATH=/opt/koha-docker/data
BACKUP_DIR=/opt/koha-docker/backups
LOG_DIR=/var/log/koha-docker
TIMEZONE=America/Argentina/Buenos_Aires

# Idiomas
KOHA_LANGS="es-ES en-GB"

# Busqueda
ZEBRA_MARC_FORMAT=marc21
ZEBRA_LANGUAGE=es

# Credenciales Koha
KOHA_ADMIN_USER=koha_admin
KOHA_ADMIN_PASSWORD=$ADMIN_PASS
KOHA_LIBRARY_NAME="$LIBRARY_NAME"

# SSL
SSL_ENABLED=true
SSL_CERT_PATH=/opt/koha-docker/ssl/cert.pem
SSL_KEY_PATH=/opt/koha-docker/ssl/key.pem

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"

# Red Docker
NETWORK_SUBNET=172.20.0.0/16

# Logs
LOG_LEVEL=INFO

# Monitoreo
MONITORING_ENABLED=true
EOF

log "✅ Archivo .env creado exitosamente"
echo ""
echo "🔐 CREDENCIALES GENERADAS:"
echo "========================="
echo "DB Usuario: koha_admin"
echo "DB Password: $DB_PASS"
echo "MySQL Root: $ROOT_PASS"
echo "RabbitMQ: koha / $RMQ_PASS"
echo "Koha Admin: koha_admin / $ADMIN_PASS"
echo ""
warning "⚠️ GUARDAR ESTAS CREDENCIALES EN LUGAR SEGURO"
echo ""
log "Próximo paso: sudo ./setup.sh"