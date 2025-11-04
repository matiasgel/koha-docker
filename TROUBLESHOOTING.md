# 🔧 Solución de Problemas Comunes - Koha Docker

## ❌ Error: "Pool overlaps with other one on this address space"

**Problema:** Conflicto de redes Docker existentes.

**Solución:**
```bash
# Limpiar redes conflictivas
chmod +x clean-docker.sh
sudo ./clean-docker.sh

# Luego ejecutar init.sh nuevamente
sudo ./init.sh
```

## ❌ Error: "MARIADB_ROOT_PASSWORD variable is not set"

**Problema:** Variables de entorno faltantes.

**Solución:**
```bash
# Verificar que existe .env
ls -la .env

# Si no existe, crear uno
cp .env.example .env

# O generar automáticamente con passwords seguros
chmod +x generate-env.sh
./generate-env.sh

# Verificar que las variables están definidas
grep MARIADB_ROOT_PASSWORD .env
```

## ❌ Error: "DATA_PATH variable is not set"

**Problema:** Variable DATA_PATH no configurada.

**Solución:**
```bash
# Agregar al archivo .env
echo "DATA_PATH=/opt/koha-docker/data" >> .env

# O regenerar .env completo
./generate-env.sh
```

## ❌ Error: "docker-compose.yml not found"

**Problema:** Archivo docker-compose no encontrado.

**Solución:**
```bash
# Verificar ubicación actual
pwd
# Debe mostrar: /home/usuario/koha-docker

# Si estás en subdirectorio, ir al directorio raíz
cd /home/usuario/koha-docker

# Verificar que existe el archivo
ls -la docker-compose.yml
```

## ❌ Error: "Network linux_koha-network Error"

**Problema:** Docker Compose ejecutándose desde subdirectorio.

**Solución:**
```bash
# Ir al directorio raíz del proyecto
cd /home/usuario/koha-docker

# NO ejecutar desde subdirectorios como prod/linux/

# Ejecutar limpieza
sudo ./clean-docker.sh

# Luego inicializar
sudo ./init.sh
```

## 🧹 Limpieza Completa del Sistema

Si hay muchos problemas, ejecutar limpieza completa:

```bash
cd /home/usuario/koha-docker

# Detener todos los servicios
sudo docker compose down --remove-orphans 2>/dev/null || true

# Limpiar completamente
sudo ./clean-docker.sh

# Limpiar sistema Docker
sudo docker system prune -f

# Recrear configuración
cp .env.example .env
nano .env  # Editar passwords y configuración

# Ejecutar setup nuevamente
sudo ./setup.sh

# Inicializar servicios
sudo ./init.sh
```

## 📋 Verificación del Estado

```bash
# Verificar variables de entorno
grep -E "(MARIADB|DATA_PATH|KOHA_DB)" .env

# Verificar redes Docker
docker network ls | grep koha

# Verificar volúmenes
docker volume ls | grep koha

# Estado de servicios
docker compose ps
```

## 🔍 Debug Avanzado

```bash
# Ver logs detallados durante inicialización
sudo ./init.sh 2>&1 | tee init.log

# Verificar conectividad de red
docker network inspect koha-network

# Verificar variables cargadas
docker compose config

# Logs de servicios específicos
docker compose logs db
docker compose logs rabbitmq
docker compose logs koha
```