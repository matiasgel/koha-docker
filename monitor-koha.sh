#!/bin/bash

# monitor-koha.sh - Script de monitoreo para Koha Docker

echo "============================================="
echo "    MONITOREO DE KOHA DOCKER"
echo "============================================="
echo "Fecha: $(date)"
echo "Host: $(hostname)"
echo ""

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar dependencias
echo "=== VERIFICACIÓN DE DEPENDENCIAS ==="
if command_exists docker; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker: No instalado"
fi

if command_exists docker-compose; then
    echo "✅ Docker Compose: $(docker-compose --version)"
else
    echo "❌ Docker Compose: No instalado"
fi

echo ""

# Estado de contenedores
echo "=== ESTADO DE CONTENEDORES ==="
if docker-compose ps 2>/dev/null; then
    echo "✅ Contenedores listados correctamente"
else
    echo "❌ Error al listar contenedores o no hay docker-compose.yaml"
fi

echo ""

# Uso de recursos
echo "=== USO DE RECURSOS ==="
if docker stats --no-stream 2>/dev/null | head -5; then
    echo "✅ Estadísticas de recursos obtenidas"
else
    echo "❌ No se pudieron obtener estadísticas"
fi

echo ""

# Espacio en disco
echo "=== ESPACIO EN DISCO ==="
df -h / /var/lib/docker 2>/dev/null || df -h /

echo ""

# Memoria del sistema
echo "=== MEMORIA DEL SISTEMA ==="
free -h

echo ""

# Conectividad web
echo "=== CONECTIVIDAD WEB ==="
if curl -I http://localhost:8081 2>/dev/null | head -1; then
    echo "✅ Staff Interface (8081) accesible"
else
    echo "❌ Staff Interface (8081) no accesible"
fi

if curl -I http://localhost:8080 2>/dev/null | head -1; then
    echo "✅ OPAC (8080) accesible"
else
    echo "❌ OPAC (8080) no accesible"
fi

echo ""

# Verificar base de datos
echo "=== VERIFICACIÓN DE BASE DE DATOS ==="
if docker exec examples_db_1 mariadb -u root -pexample -e "SELECT COUNT(*) as Tables FROM information_schema.tables WHERE table_schema='koha_teolib';" 2>/dev/null; then
    echo "✅ Base de datos accesible"
else
    echo "❌ Base de datos no accesible"
fi

echo ""

# Logs recientes
echo "=== LOGS RECIENTES (ÚLTIMAS 5 LÍNEAS) ==="
echo "--- Koha ---"
docker-compose logs --tail=5 koha 2>/dev/null || echo "No se pudieron obtener logs de Koha"

echo ""
echo "--- Base de Datos ---"
docker-compose logs --tail=5 db 2>/dev/null || echo "No se pudieron obtener logs de BD"

echo ""

# Verificar archivos de backup
echo "=== BACKUPS DISPONIBLES ==="
if ls -lt *.tar.gz 2>/dev/null | head -5; then
    echo "✅ Backups encontrados"
else
    echo "ℹ️ No hay archivos de backup (.tar.gz) en el directorio actual"
fi

echo ""

# Procesos que usan puertos importantes
echo "=== PROCESOS EN PUERTOS ==="
echo "Puerto 8080:"
lsof -i :8080 2>/dev/null || netstat -tlnp 2>/dev/null | grep :8080 || echo "Puerto libre"

echo "Puerto 8081:"
lsof -i :8081 2>/dev/null || netstat -tlnp 2>/dev/null | grep :8081 || echo "Puerto libre"

echo ""

# Resumen final
echo "=== RESUMEN ==="
CONTAINERS_UP=$(docker-compose ps -q 2>/dev/null | wc -l)
if [ "$CONTAINERS_UP" -gt 0 ]; then
    echo "✅ $CONTAINERS_UP contenedores en ejecución"
else
    echo "❌ No hay contenedores en ejecución"
fi

# Verificar si los servicios principales están funcionando
WEB_OK=0
DB_OK=0

if curl -s http://localhost:8081 >/dev/null 2>&1; then
    WEB_OK=1
fi

if docker exec examples_db_1 mariadb -u root -pexample -e "SELECT 1;" >/dev/null 2>&1; then
    DB_OK=1
fi

if [ $WEB_OK -eq 1 ] && [ $DB_OK -eq 1 ]; then
    echo "🎉 Koha está funcionando correctamente"
elif [ $WEB_OK -eq 1 ]; then
    echo "⚠️ Web OK, pero hay problemas con la base de datos"
elif [ $DB_OK -eq 1 ]; then
    echo "⚠️ Base de datos OK, pero hay problemas con el web"
else
    echo "❌ Hay problemas con los servicios principales"
fi

echo ""
echo "============================================="
echo "Monitoreo completado - $(date)"
echo "============================================="