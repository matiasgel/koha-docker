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

# Paso 4: Restaurar base de datos (equivalente a Get-Content koha-database.sql | docker exec -i ...)
echo "📥 Paso 4: Restaurando base de datos..."
cat koha-database.sql | docker exec -i examples-db-1 mariadb -u root -pexample koha_teolib

if [ $? -eq 0 ]; then
    echo "✅ Base de datos restaurada exitosamente"
else
    echo "❌ Error al restaurar la base de datos"
    exit 1
fi

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
