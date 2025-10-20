#!/bin/bash
# Script de backup automático para Koha

set -e

# Configuración
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Crear directorio de backups si no existe
mkdir -p ${BACKUP_DIR}/database
mkdir -p ${BACKUP_DIR}/koha-files

echo "$(date): Iniciando backup de Koha..."

# Backup de la base de datos
echo "$(date): Creando backup de la base de datos..."
mysqldump -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-database \
    --databases ${BACKUP_DATABASE} \
    | gzip > ${BACKUP_DIR}/database/koha_${DATE}.sql.gz

# Verificar que el backup se creó correctamente
if [ -f "${BACKUP_DIR}/database/koha_${DATE}.sql.gz" ]; then
    echo "$(date): Backup de base de datos creado exitosamente: koha_${DATE}.sql.gz"
    
    # Calcular checksum para verificación
    cd ${BACKUP_DIR}/database
    sha256sum koha_${DATE}.sql.gz > koha_${DATE}.sql.gz.sha256
    
    # Crear un enlace simbólico al backup más reciente
    ln -sf koha_${DATE}.sql.gz latest.sql.gz
    ln -sf koha_${DATE}.sql.gz.sha256 latest.sql.gz.sha256
else
    echo "$(date): ERROR: No se pudo crear el backup de la base de datos"
    exit 1
fi

# Limpiar backups antiguos
echo "$(date): Limpiando backups antiguos (más de ${RETENTION_DAYS} días)..."
find ${BACKUP_DIR}/database -name "koha_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
find ${BACKUP_DIR}/database -name "koha_*.sql.gz.sha256" -type f -mtime +${RETENTION_DAYS} -delete

echo "$(date): Backup completado exitosamente"

# Mostrar estadísticas del backup
echo "$(date): Estadísticas del backup:"
echo "  - Tamaño: $(du -h ${BACKUP_DIR}/database/koha_${DATE}.sql.gz | cut -f1)"
echo "  - Ubicación: ${BACKUP_DIR}/database/koha_${DATE}.sql.gz"
echo "  - Checksum: $(cat ${BACKUP_DIR}/database/koha_${DATE}.sql.gz.sha256)"
