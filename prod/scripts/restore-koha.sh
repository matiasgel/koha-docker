#!/bin/bash
# restore-koha.sh
# Script de restauración de Koha para Linux

set -e

if [ $# -ne 1 ]; then
    echo "Uso: $0 <archivo_backup.zip>"
    echo "Ejemplo: $0 koha-backup-20231226-140000.zip"
    exit 1
fi

BACKUP_FILE="$1"

echo "🔄 Iniciando restauración de Koha..."

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: El archivo de backup no existe: $BACKUP_FILE"
    exit 1
fi

original_location=$(pwd)

cleanup() {
    cd "$original_location"
}
trap cleanup EXIT

# Extraer backup
extract_path="koha-restore-$(date +'%Y%m%d-%H%M')"
echo "📁 Extrayendo backup en: $extract_path"

unzip -q "$BACKUP_FILE" -d "$extract_path"
cd "$extract_path"

# Buscar el directorio del backup
backup_content=$(ls -d */ 2>/dev/null | head -1)
if [ -n "$backup_content" ]; then
    cd "$backup_content"
    echo "📂 Contenido encontrado en: $backup_content"
fi

# Verificar archivos necesarios
required_files=("docker-compose-backup.yaml" "rabbitmq_plugins-backup" "koha-database-backup.sql")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: Archivo requerido no encontrado: $file"
        exit 1
    fi
done

# Restaurar configuración
echo "📄 Restaurando configuración..."
cp "docker-compose-backup.yaml" "docker-compose.yaml"
cp "rabbitmq_plugins-backup" "rabbitmq_plugins"

# Verificar que Docker esté funcionando
echo "🐳 Verificando Docker..."
if ! docker --version >/dev/null 2>&1; then
    echo "❌ Error: Docker no está disponible o no está funcionando"
    exit 1
fi

# Limpiar contenedores existentes (si los hay)
echo "🧹 Limpiando contenedores existentes..."
docker-compose down >/dev/null 2>&1 || true

# Iniciar base de datos
echo "🗄️ Iniciando base de datos..."
docker-compose up -d db

# Esperar que la base de datos se inicialice
echo "⏳ Esperando inicialización de base de datos (30 segundos)..."
sleep 30

# Verificar que la BD esté funcionando
if ! docker exec examples-db-1 mariadb -u root -pexample -e "SELECT 1;" >/dev/null 2>&1; then
    echo "⏳ BD aún no lista, esperando 15 segundos más..."
    sleep 15
fi

# Restaurar base de datos
echo "📥 Restaurando base de datos..."
docker exec -i examples-db-1 mariadb -u root -pexample < "koha-database-backup.sql"

if [ $? -ne 0 ]; then
    echo "❌ Error al restaurar la base de datos"
    exit 1
fi

# Iniciar todos los servicios
echo "🚀 Iniciando todos los servicios..."
docker-compose up -d

# Esperar que los servicios se inicialicen
echo "⏳ Esperando inicialización de servicios..."
sleep 15

# Verificar estado
echo "✅ Verificando estado de los servicios..."
docker-compose ps

# Verificar acceso web
echo "🌐 Verificando acceso web..."
if curl -s --max-time 10 http://localhost:8081 >/dev/null 2>&1; then
    echo "✅ Koha responde correctamente en puerto 8081"
else
    echo "⚠️ Koha aún no responde en puerto 8081, puede necesitar más tiempo"
fi

echo ""
echo "🎉 Restauración completada exitosamente!"
echo "🌐 Accede a Koha en: http://localhost:8081"
echo "🌐 OPAC disponible en: http://localhost:8080"
echo "📁 Archivos restaurados en: $(pwd)"

echo ""
echo "📋 Credenciales de acceso:"
echo "   Usuario: koha_teolib"
echo "   Contraseña: example"
