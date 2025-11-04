# 🐧 Instalación de Koha Docker en Linux - Guía Completa

## 📋 Resumen de Mejoras Incluidas

Esta versión modificada de Koha Docker incluye:
- ✅ **Soporte completo en español (es-ES)**
- 🚀 **Scripts de backup automatizados**
- 📚 **Documentación completa en español**
- 🔧 **Configuración optimizada para producción**
- 💾 **Herramientas de migración y restauración**

---

## 🖥️ Instalación en Linux

### 📋 Prerequisitos del Sistema

#### 1. Instalar Docker
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io docker-compose

# CentOS/RHEL/Rocky Linux
sudo dnf install -y docker docker-compose

# Arch Linux
sudo pacman -S docker docker-compose

# Habilitar y iniciar Docker
sudo systemctl enable docker
sudo systemctl start docker

# Agregar usuario al grupo docker (opcional)
sudo usermod -aG docker $USER
# Cerrar sesión y volver a iniciar para aplicar cambios
```

#### 2. Verificar Instalación
```bash
docker --version
docker-compose --version
sudo docker run hello-world
```

### 🚀 Instalación Rápida

#### Paso 1: Clonar el Repositorio
```bash
# Clonar tu repositorio modificado
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker
```

#### Paso 2: Configurar Permisos
```bash
# Hacer ejecutables los scripts (si es necesario)
chmod +x examples/*.sh
chmod +x prod/scripts/*.sh
```

#### Paso 3: Instalación de Desarrollo/Testing
```bash
# Ir al directorio de ejemplos
cd examples

# Iniciar todos los servicios
sudo docker-compose up -d

# Verificar que los servicios estén corriendo
sudo docker-compose ps

# Ver logs si hay problemas
sudo docker-compose logs -f koha
```

#### Paso 4: Esperar Inicialización
```bash
# Esperar 2-3 minutos para inicialización completa
sleep 180

# Verificar acceso web
curl -I http://localhost:8081
```

### 🔑 Acceso al Sistema

- **Staff Interface**: http://localhost:8081
- **OPAC Público**: http://localhost:8080
- **Credenciales Web Installer**:
  - Usuario: `koha_teolib`
  - Contraseña: `example`

---

## 🏭 Instalación de Producción

### 📁 Preparar Entorno de Producción
```bash
# Ir al directorio de producción
cd prod

# Copiar y personalizar variables de entorno
cp .env.example .env
nano .env
```

### 🔧 Configurar Variables de Entorno
```bash
# Editar archivo .env con valores de producción
cat << 'EOF' > .env
# Base de Datos
KOHA_DB_PASSWORD=tu_password_super_segura_aqui
MARIADB_ROOT_PASSWORD=password_root_muy_segura

# RabbitMQ
RABBITMQ_PASSWORD=password_rabbitmq_segura

# Configuración General
KOHA_DOMAIN=biblioteca.tudominio.com
TZ=America/Mexico_City
KOHA_LANGS=es-ES

# Seguridad
KOHA_ADMIN_EMAIL=admin@tudominio.com
EOF
```

### 🚀 Iniciar Producción
```bash
# Iniciar servicios de producción
sudo docker-compose -f docker-compose.prod.yaml up -d

# Verificar estado
sudo docker-compose -f docker-compose.prod.yaml ps

# Ver logs
sudo docker-compose -f docker-compose.prod.yaml logs -f
```

---

## 🛠️ Scripts de Backup para Linux

### 📝 Crear Script de Backup Adaptado para Linux
```bash
# Crear script de backup simple para Linux
cat << 'EOF' > backup-simple-linux.sh
#!/bin/bash

# backup-simple-linux.sh - Backup rápido para Linux
BACKUP_NAME="koha-simple-$(date +%Y%m%d-%H%M)"

echo "🔄 Iniciando backup de Koha..."

# Crear directorio de backup
mkdir -p "$BACKUP_NAME"

# Backup de base de datos
echo "🗄️ Backup de base de datos..."
sudo docker exec examples_db_1 mariadb-dump -u root -pexample koha_teolib > "$BACKUP_NAME/koha-database.sql"

# Copiar configuración
echo "📄 Copiando configuración..."
cp docker-compose.yaml "$BACKUP_NAME/"
cp rabbitmq_plugins "$BACKUP_NAME/"

# Crear README
cat << 'README_EOF' > "$BACKUP_NAME/README.txt"
Backup Simple de Koha Docker
============================
Fecha: $(date)
Host: $(hostname)

Restauración en Linux:
1. sudo docker-compose up -d db
2. sleep 30
3. cat koha-database.sql | sudo docker exec -i examples_db_1 mariadb -u root -pexample koha_teolib
4. sudo docker-compose up -d

Credenciales:
- Usuario: koha_teolib
- Contraseña: example
README_EOF

# Comprimir
echo "📦 Comprimiendo..."
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME/"

# Limpiar directorio temporal
rm -rf "$BACKUP_NAME"

echo "✅ Backup completado: $BACKUP_NAME.tar.gz"
ls -lh "$BACKUP_NAME.tar.gz"
EOF

chmod +x backup-simple-linux.sh
```

### 🔄 Script de Restauración para Linux
```bash
# Crear script de restauración para Linux
cat << 'EOF' > restore-simple-linux.sh
#!/bin/bash

# restore-simple-linux.sh
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Error: Especifica el archivo de backup"
    echo "Uso: $0 backup-file.tar.gz"
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
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1

cd "$RESTORE_DIR"

echo "📁 Archivos extraídos en: $(pwd)"

# Verificar archivos necesarios
if [ ! -f "koha-database.sql" ] || [ ! -f "docker-compose.yaml" ]; then
    echo "❌ Error: Archivos de backup incompletos"
    exit 1
fi

# Parar servicios existentes
echo "🛑 Parando servicios existentes..."
sudo docker-compose down 2>/dev/null || true

# Iniciar base de datos
echo "🗄️ Iniciando base de datos..."
sudo docker-compose up -d db

# Esperar inicialización
echo "⏳ Esperando inicialización de base de datos..."
sleep 30

# Verificar que la BD esté lista
for i in {1..10}; do
    if sudo docker exec examples_db_1 mariadb -u root -pexample -e "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ Base de datos lista"
        break
    fi
    echo "⏳ Esperando BD... intento $i/10"
    sleep 10
done

# Restaurar base de datos
echo "📥 Restaurando base de datos..."
cat koha-database.sql | sudo docker exec -i examples_db_1 mariadb -u root -pexample koha_teolib

# Iniciar todos los servicios
echo "🚀 Iniciando todos los servicios..."
sudo docker-compose up -d

# Verificar estado
echo "✅ Verificando servicios..."
sudo docker-compose ps

echo "🎉 Restauración completada!"
echo "🌐 Koha Staff: http://localhost:8081"
echo "🌐 OPAC: http://localhost:8080"
EOF

chmod +x restore-simple-linux.sh
```

---

## 📦 Comandos de Backup y Restauración

### 💾 Hacer Backup
```bash
# Backup rápido
./backup-simple-linux.sh

# El archivo se guardará como: koha-simple-YYYYMMDD-HHMM.tar.gz
```

### 🔄 Restaurar Backup
```bash
# Restaurar desde backup
./restore-simple-linux.sh koha-simple-20251022-1430.tar.gz
```

### 📋 Backup Manual (Comandos Individuales)
```bash
# Solo base de datos
sudo docker exec examples_db_1 mariadb-dump -u root -pexample koha_teolib > backup-db.sql

# Solo configuración
tar -czf config-backup.tar.gz docker-compose.yaml rabbitmq_plugins examples/

# Volúmenes completos
sudo docker run --rm -v examples_mariadb-koha:/data -v $(pwd):/backup alpine tar czf /backup/volumes-backup.tar.gz -C /data .
```

---

## 🔧 Configuración del Sistema

### 🌐 Configurar Idioma Español
El idioma español ya está preconfigurado en los archivos docker-compose con:
```yaml
environment:
  KOHA_LANGS: "es-ES"
```

### 🔒 Configuración de Firewall
```bash
# Ubuntu/Debian - UFW
sudo ufw allow 8080
sudo ufw allow 8081

# CentOS/RHEL - Firewalld
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload

# Verificar puertos
sudo netstat -tlnp | grep -E ':(8080|8081)'
```

### 📁 Permisos y Directorios
```bash
# Crear directorios para datos persistentes (producción)
sudo mkdir -p /opt/koha-docker/{data,logs,backups}
sudo chown -R $USER:$USER /opt/koha-docker

# Configurar backups automáticos con cron
echo "0 2 * * * cd /path/to/koha-docker && ./backup-simple-linux.sh" | crontab -
```

---

## 🚨 Solución de Problemas en Linux

### 🔍 Verificar Estado de Servicios
```bash
# Ver todos los contenedores
sudo docker ps -a

# Ver logs específicos
sudo docker-compose logs koha
sudo docker-compose logs db

# Verificar recursos del sistema
sudo docker stats

# Verificar espacio en disco
df -h
sudo docker system df
```

### 🛠️ Problemas Comunes y Soluciones

#### Puerto Ocupado
```bash
# Verificar qué proceso usa el puerto
sudo netstat -tlnp | grep :8081
sudo lsof -i :8081

# Cambiar puertos en docker-compose.yaml si es necesario
sed -i 's/8081:8081/8082:8081/' docker-compose.yaml
```

#### Base de Datos No Responde
```bash
# Reiniciar solo la base de datos
sudo docker-compose restart db

# Verificar logs de la base de datos
sudo docker-compose logs db

# Verificar conexión manualmente
sudo docker exec examples_db_1 mariadb -u root -pexample -e "SHOW DATABASES;"
```

#### Falta de Memoria
```bash
# Verificar memoria disponible
free -h

# Limpiar contenedores e imágenes no utilizadas
sudo docker system prune -a

# Aumentar memoria swap si es necesario
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📊 Monitoreo y Mantenimiento

### 📈 Scripts de Monitoreo
```bash
# Crear script de monitoreo
cat << 'EOF' > monitor-koha.sh
#!/bin/bash

echo "=== Estado de Koha Docker ==="
echo "Fecha: $(date)"
echo

echo "=== Contenedores ==="
sudo docker-compose ps

echo -e "\n=== Uso de Recursos ==="
sudo docker stats --no-stream

echo -e "\n=== Espacio en Disco ==="
df -h

echo -e "\n=== Conectividad Web ==="
curl -I http://localhost:8081 2>/dev/null | head -1
curl -I http://localhost:8080 2>/dev/null | head -1

echo -e "\n=== Logs Recientes ==="
sudo docker-compose logs --tail=10 koha
EOF

chmod +x monitor-koha.sh
```

### 🔄 Mantenimiento Automático
```bash
# Agregar a crontab para mantenimiento
cat << 'EOF' | crontab -
# Backup diario a las 2 AM
0 2 * * * cd /path/to/koha-docker && ./backup-simple-linux.sh

# Monitoreo cada hora
0 * * * * cd /path/to/koha-docker && ./monitor-koha.sh >> /var/log/koha-monitor.log

# Limpieza semanal de Docker
0 3 * * 0 docker system prune -f
EOF
```

---

## ✅ Verificación Final

### 🎯 Checklist de Instalación Exitosa
```bash
# 1. Verificar servicios corriendo
sudo docker-compose ps

# 2. Verificar acceso web
curl -s http://localhost:8081 | grep -i koha

# 3. Verificar base de datos
sudo docker exec examples_db_1 mariadb -u root -pexample -e "USE koha_teolib; SHOW TABLES;" | wc -l

# 4. Verificar idioma español instalado
sudo docker exec examples_koha_1 ls -la /usr/share/koha/opac/htdocs/opac-tmpl/bootstrap/ | grep es-ES

# 5. Hacer backup de prueba
./backup-simple-linux.sh
```

### 🎉 ¡Instalación Completada!

Si todos los comandos anteriores funcionan correctamente, tienes:
- ✅ **Koha 24.11** funcionando con soporte en español
- ✅ **Base de datos** MariaDB operativa
- ✅ **Sistema de backup** configurado
- ✅ **Monitoreo** básico implementado
- ✅ **Documentación** completa disponible

**Accesos:**
- **Staff Interface**: http://localhost:8081
- **OPAC Público**: http://localhost:8080
- **Credenciales**: koha_teolib / example

---

## 📚 Documentación Adicional

Para información más detallada, consulta:
- [📋 Guía de Instalación Completa](GUIA_INSTALACION_KOHA.md)
- [💾 Guía de Backup y Migración](backup-migration.md)
- [📄 Documentación de Backup](README-BACKUP.md)
- [🐳 Configuración Docker](examples/docker-compose.yaml)