#!/bin/bash
# Script de restauración para Koha

set -e

if [ $# -ne 1 ]; then
    echo "Uso: $0 <archivo_backup>"
    echo "Ejemplo: $0 koha_20241226_140000.sql.gz"
    echo "Ejemplo: $0 /ruta/completa/koha-simple-20250826-1328.zip"
    exit 1
fi

BACKUP_FILE="$1"

# Si es una ruta absoluta, usar como está; si no, asumir está en /backups/database/
if [[ "$BACKUP_FILE" = /* ]]; then
    BACKUP_PATH="$BACKUP_FILE"
else
    BACKUP_PATH="/backups/database/${BACKUP_FILE}"
fi

# Verificar que el archivo de backup existe
if [ ! -f "${BACKUP_PATH}" ]; then
    echo "ERROR: El archivo de backup ${BACKUP_PATH} no existe"
    exit 1
fi

# Determinar el tipo de archivo
if [[ "$BACKUP_FILE" == *.zip ]]; then
    echo "Detectado archivo ZIP. Usando método de restauración completo..."
    
    # Para archivos ZIP, usar el script restore-koha.sh
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    RESTORE_KOHA_SCRIPT="${SCRIPT_DIR}/../../restore-koha.sh"
    
    if [ -f "$RESTORE_KOHA_SCRIPT" ]; then
        echo "Ejecutando restore-koha.sh para restauración completa..."
        bash "$RESTORE_KOHA_SCRIPT" "$BACKUP_PATH"
        exit $?
    else
        echo "ERROR: No se encontró restore-koha.sh. Extrayendo manualmente..."
        
        # Extraer el archivo SQL del ZIP
        TEMP_DIR=$(mktemp -d)
        echo "Extrayendo ZIP en directorio temporal: $TEMP_DIR"
        
        # Extraer con conversión de paths de Windows a Linux
        unzip -q -o "$BACKUP_PATH" -d "$TEMP_DIR" || {
            echo "ERROR: Falló la extracción del ZIP"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Convertir paths con backslashes a forward slashes si es necesario
        find "$TEMP_DIR" -type f -name "*.sql" -exec bash -c 'mv "$1" "${1//\\//}"' _ {} \; 2>/dev/null || true
        
        # Buscar el archivo SQL
        SQL_FILE=$(find "$TEMP_DIR" -name "*.sql" -type f | head -1)
        if [ -z "$SQL_FILE" ]; then
            echo "ERROR: No se encontró archivo SQL en el ZIP"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        echo "Archivo SQL encontrado: $SQL_FILE"
        BACKUP_PATH="$SQL_FILE"
    fi
fi

# Verificar checksum si existe (solo para .sql.gz)
if [[ "$BACKUP_FILE" == *.sql.gz ]] && [ -f "${BACKUP_PATH}.sha256" ]; then
    echo "Verificando integridad del backup..."
    BACKUP_DIR=$(dirname "$BACKUP_PATH")
    cd "$BACKUP_DIR"
    if sha256sum -c "$(basename "$BACKUP_PATH").sha256"; then
        echo "✓ Verificación de integridad exitosa"
    else
        echo "✗ ERROR: El archivo de backup está corrupto"
        exit 1
    fi
fi

echo "ADVERTENCIA: Esta operación va a sobrescribir la base de datos actual."
echo "¿Está seguro de que desea continuar? (escriba 'YES' para confirmar)"
read -r confirmation

if [ "$confirmation" != "YES" ]; then
    echo "Operación cancelada"
    exit 0
fi

echo "$(date): Iniciando restauración desde ${BACKUP_FILE}..."

# Detener Koha temporalmente (esto debería hacerse desde docker-compose)
echo "NOTA: Asegúrese de detener el contenedor de Koha antes de continuar"

# Restaurar la base de datos
echo "$(date): Restaurando base de datos..."
if [[ "$BACKUP_FILE" == *.sql.gz ]]; then
    gunzip -c "${BACKUP_PATH}" | mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD}
else
    # Para archivos .sql sin compresión
    mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} < "${BACKUP_PATH}"
fi

if [ $? -eq 0 ]; then
    echo "$(date): Restauración completada exitosamente"
    echo "NOTA: Recuerde reiniciar el contenedor de Koha después de la restauración"
else
    echo "$(date): ERROR: Falló la restauración de la base de datos"
    exit 1
fi
