#!/bin/bash

# Script para inicializar la instancia de Koha

set -e

echo "Inicializando instancia de Koha..."

# Variables de entorno
INSTANCE_NAME=${KOHA_INSTANCE:-default}
DB_HOST=${MYSQL_SERVER:-db}
DB_NAME=${DB_NAME:-koha_production}
DB_USER=${MYSQL_USER:-koha_prod}
DB_PASS=${MYSQL_PASSWORD}

echo "Configurando instancia: $INSTANCE_NAME"
echo "Base de datos: $DB_HOST/$DB_NAME"

# Esperar que la base de datos esté disponible
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1" > /dev/null 2>&1; do
    echo "Esperando que la base de datos esté disponible..."
    sleep 5
done

echo "Base de datos disponible, continuando..."

# Verificar si la instancia ya existe
if [ ! -d "/etc/koha/sites/$INSTANCE_NAME" ]; then
    echo "Creando nueva instancia de Koha: $INSTANCE_NAME"
    
    # Crear la instancia
    koha-create --create-db \
        --request-db "$DB_HOST:3306/$DB_NAME" \
        --database "$DB_NAME" \
        --dbuser "$DB_USER" \
        --dbpass "$DB_PASS" \
        --adminuser admin \
        --adminpass admin \
        --lang es-ES \
        "$INSTANCE_NAME"
else
    echo "La instancia $INSTANCE_NAME ya existe"
fi

# Configurar puertos
echo "Configurando puertos para $INSTANCE_NAME"
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:8080>/" /etc/apache2/sites-available/$INSTANCE_NAME.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:8081>/" /etc/apache2/sites-available/$INSTANCE_NAME-intra.conf

# Habilitar la instancia
a2ensite $INSTANCE_NAME
a2ensite $INSTANCE_NAME-intra

# Reiniciar Apache
service apache2 reload

echo "Instancia de Koha inicializada correctamente"
