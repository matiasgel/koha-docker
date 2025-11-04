#!/bin/bash

# backup-simple-linux.sh - Backup rápido para Linux
BACKUP_NAME="koha-simple-$(date +%Y%m%d-%H%M)"

echo "🔄 Iniciando backup de Koha..."

# Crear directorio de backup
mkdir -p "$BACKUP_NAME"

# Backup de base de datos
echo "🗄️ Backup de base de datos..."
if docker exec examples_db_1 mariadb-dump -u root -pexample koha_teolib > "$BACKUP_NAME/koha-database.sql"; then
    echo "✅ Backup de BD completado"
else
    echo "❌ Error en backup de BD"
    rm -rf "$BACKUP_NAME"
    exit 1
fi

# Copiar configuración
echo "📄 Copiando configuración..."
cp docker-compose.yaml "$BACKUP_NAME/" 2>/dev/null || echo "⚠️ docker-compose.yaml no encontrado"
cp rabbitmq_plugins "$BACKUP_NAME/" 2>/dev/null || echo "⚠️ rabbitmq_plugins no encontrado"

# Crear README
cat << 'README_EOF' > "$BACKUP_NAME/README.txt"
Backup Simple de Koha Docker
============================
Fecha: $(date)
Host: $(hostname)

Restauración en Linux:
1. docker-compose up -d db
2. sleep 30
3. cat koha-database.sql | docker exec -i examples_db_1 mariadb -u root -pexample koha_teolib
4. docker-compose up -d

Credenciales:
- Usuario: koha_teolib
- Contraseña: example
README_EOF

# Comprimir
echo "📦 Comprimiendo..."
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME/"

# Calcular tamaño
SIZE=$(du -h "$BACKUP_NAME.tar.gz" | cut -f1)

# Limpiar directorio temporal
rm -rf "$BACKUP_NAME"

echo "✅ Backup completado: $BACKUP_NAME.tar.gz"
echo "📏 Tamaño: $SIZE"
ls -lh "$BACKUP_NAME.tar.gz"