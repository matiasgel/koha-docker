#!/bin/bash
# Script de restauración simple para Koha en Linux
# Traducción de comandos PowerShell a Linux/bash

echo "=== Restauración Simple de Koha en Linux ==="
echo "Fecha: $(date)"
echo "Host: $(hostname)"
echo ""

# Verificar que Docker esté instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker no está instalado"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: Docker Compose no está instalado"
    exit 1
fi

echo "✅ Docker y Docker Compose están disponibles"
echo ""

# Verificar archivos necesarios
required_files=("koha-database.sql" "docker-compose.yaml" "rabbitmq_plugins")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: Archivo requerido no encontrado: $file"
        exit 1
    fi
done

echo "✅ Todos los archivos de backup están presentes"
echo ""

# Paso 1: Iniciar base de datos
echo "🚀 Paso 1: Iniciando base de datos..."
docker-compose up -d db

# Paso 2: Esperar inicialización (equivalente a Start-Sleep -Seconds 30)
echo "⏳ Paso 2: Esperando 30 segundos para que la base de datos se inicialice..."
sleep 30

# Paso 3: Verificar conexión a la base de datos
echo "🔍 Paso 3: Verificando conexión a la base de datos..."
if docker exec examples-db-1 mariadb -u root -pexample -e "SELECT 1;" &> /dev/null; then
    echo "✅ Base de datos está lista"
else
    echo "⚠️ Base de datos aún no está lista, esperando 15 segundos más..."
    sleep 15
fi

#!/bin/bash

# restore-simple-linux.sh - Restauración para Linux
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Error: Especifica el archivo de backup"
    echo "Uso: $0 backup-file.tar.gz"
    echo ""
    echo "Ejemplo:"
    echo "  $0 koha-simple-20251022-1430.tar.gz"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: El archivo $BACKUP_FILE no existe"
    exit 1
fi

echo "🔄 Restaurando Koha desde $BACKUP_FILE..."

# Extraer backup
RESTORE_DIR="koha-restore-$(date +%Y%m%d-%H%M)"
mkdir -p "$RESTORE_DIR"

echo "📁 Extrayendo backup..."
if tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1; then
    echo "✅ Backup extraído correctamente"
else
    echo "❌ Error al extraer backup"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

cd "$RESTORE_DIR"
echo "📂 Trabajando en: $(pwd)"

# Verificar archivos necesarios
if [ ! -f "koha-database.sql" ]; then
    echo "❌ Error: koha-database.sql no encontrado"
    exit 1
fi

if [ ! -f "docker-compose.yaml" ]; then
    echo "⚠️ Advertencia: docker-compose.yaml no encontrado, usando configuración actual"
fi

# Parar servicios existentes
echo "🛑 Parando servicios existentes..."
docker-compose down 2>/dev/null || true

# Iniciar base de datos
echo "🗄️ Iniciando base de datos..."
docker-compose up -d db

# Esperar inicialización
echo "⏳ Esperando inicialización de base de datos..."
sleep 30

# Verificar que la BD esté lista
echo "🔍 Verificando conectividad de base de datos..."
for i in {1..10}; do
    if docker exec examples_db_1 mariadb -u root -pexample -e "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ Base de datos lista"
        break
    fi
    echo "⏳ Esperando BD... intento $i/10"
    sleep 10
    
    if [ $i -eq 10 ]; then
        echo "❌ Error: Base de datos no responde después de 100 segundos"
        exit 1
    fi
done

# Restaurar base de datos
echo "📥 Restaurando base de datos..."
if cat koha-database.sql | docker exec -i examples_db_1 mariadb -u root -pexample koha_teolib; then
    echo "✅ Base de datos restaurada correctamente"
else
    echo "❌ Error al restaurar base de datos"
    exit 1
fi

# Iniciar todos los servicios
echo "🚀 Iniciando todos los servicios..."
docker-compose up -d

# Esperar que los servicios se inicialicen
echo "⏳ Esperando inicialización de servicios..."
sleep 20

# Verificar estado
echo "✅ Verificando estado de servicios..."
docker-compose ps

# Verificar conectividad web
echo "🌐 Verificando acceso web..."
sleep 10

if curl -s http://localhost:8081 >/dev/null 2>&1; then
    echo "✅ Staff Interface accesible en http://localhost:8081"
else
    echo "⚠️ Staff Interface aún no responde, puede necesitar más tiempo"
fi

if curl -s http://localhost:8080 >/dev/null 2>&1; then
    echo "✅ OPAC accesible en http://localhost:8080"
else
    echo "⚠️ OPAC aún no responde, puede necesitar más tiempo"
fi

echo ""
echo "🎉 Restauración completada!"
echo "📂 Archivos temporales en: $(pwd)"
echo "🌐 Staff Interface: http://localhost:8081"
echo "🌐 OPAC Público: http://localhost:8080"
echo "🔑 Credenciales: koha_teolib / example"
echo ""
echo "💡 Para limpiar archivos temporales:"
echo "   rm -rf $(pwd)"

# Paso 5: Iniciar todos los servicios
echo "🚀 Paso 5: Iniciando todos los servicios..."
docker-compose up -d

# Paso 6: Verificar estado
echo "⏳ Paso 6: Esperando inicialización de servicios..."
sleep 10

echo "📊 Estado de los contenedores:"
docker-compose ps

echo ""
echo "🎉 ¡Restauración completada!"
echo ""
echo "🌐 URLs de acceso:"
echo "   - Staff Interface: http://localhost:8081"
echo "   - OPAC (Catálogo público): http://localhost:8080"
echo ""
echo "👤 Credenciales:"
echo "   - Usuario: koha_teolib"
echo "   - Contraseña: example"
echo ""
echo "💡 Notas:"
echo "   - Puede tomar unos minutos para que todos los servicios estén completamente disponibles"
echo "   - Si hay problemas, revisa los logs con: docker-compose logs"
