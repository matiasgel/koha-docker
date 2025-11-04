#!/bin/bash
# Script para limpiar redes Docker conflictivas

echo "🧹 Limpiando redes Docker conflictivas..."

# Detener todos los contenedores de koha si existen
echo "Deteniendo contenedores existentes..."
docker stop $(docker ps -a -q --filter "name=koha") 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=mariadb") 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=rabbitmq") 2>/dev/null || true
docker stop $(docker ps -a -q --filter "name=memcached") 2>/dev/null || true

# Eliminar contenedores
echo "Eliminando contenedores..."
docker rm $(docker ps -a -q --filter "name=koha") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=mariadb") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=rabbitmq") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "name=memcached") 2>/dev/null || true

# Eliminar redes conflictivas
echo "Eliminando redes conflictivas..."
docker network rm koha-network 2>/dev/null || true
docker network rm koha-backend 2>/dev/null || true
docker network rm linux_koha-network 2>/dev/null || true
docker network rm koha-docker_koha-network 2>/dev/null || true

# Limpiar redes no utilizadas
echo "Limpiando redes no utilizadas..."
docker network prune -f

echo "✅ Limpieza completada"
echo "Ahora puedes ejecutar: sudo ./init.sh"