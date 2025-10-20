# Guía de Backup y Migración de Koha Docker

## Método 1: Backup Completo de Volúmenes (Recomendado)

### 📋 Preparación
```powershell
# Crear directorio de backup
mkdir koha-backup
cd koha-backup

# Crear directorio para fecha actual
$fecha = Get-Date -Format "yyyyMMdd-HHmm"
mkdir "backup-$fecha"
cd "backup-$fecha"
```

### 🗄️ 1. Backup de Base de Datos
```powershell
# Backup SQL de la base de datos
docker exec examples-db-1 mysqldump -u root -pexample --all-databases --routines --triggers > koha-database-backup.sql

# Verificar el backup
Get-Content koha-database-backup.sql | Select-Object -First 10
```

### 💾 2. Backup de Volúmenes Docker
```powershell
# Backup del volumen de MariaDB
docker run --rm -v examples_mariadb-koha:/data -v ${PWD}:/backup alpine tar czf /backup/mariadb-volume-backup.tar.gz -C /data .

# Si tienes otros volúmenes (en configuración de producción)
# docker run --rm -v koha_etc:/data -v ${PWD}:/backup alpine tar czf /backup/koha-etc-backup.tar.gz -C /data .
# docker run --rm -v koha_logs:/data -v ${PWD}:/backup alpine tar czf /backup/koha-logs-backup.tar.gz -C /data .
# docker run --rm -v koha_uploads:/data -v ${PWD}:/backup alpine tar czf /backup/koha-uploads-backup.tar.gz -C /data .
```

### 📄 3. Backup de Configuración
```powershell
# Copiar archivos de configuración
Copy-Item "../../docker-compose.yaml" -Destination "docker-compose-backup.yaml"
Copy-Item "../../rabbitmq_plugins" -Destination "rabbitmq_plugins-backup"

# Si tienes archivos .env
# Copy-Item "../../.env" -Destination "env-backup.txt"
```

### 🐳 4. Export de Imágenes Docker (Opcional)
```powershell
# Exportar imágenes si no están disponibles en Docker Hub
docker save teogramm/koha:24.11 -o koha-image.tar
docker save mariadb:11 -o mariadb-image.tar
docker save rabbitmq:3 -o rabbitmq-image.tar
docker save memcached -o memcached-image.tar
```

### 📦 5. Crear Archivo de Migración Completo
```powershell
# Comprimir todo en un solo archivo
Compress-Archive -Path "." -DestinationPath "../koha-migration-complete.zip"
```

---

## Método 2: Backup Solo de Datos Críticos (Rápido)

### 🗄️ Solo Base de Datos y Configuración
```powershell
# Crear directorio
mkdir koha-backup-simple
cd koha-backup-simple

# Backup de BD
docker exec examples-db-1 mysqldump -u root -pexample koha_teolib > koha-database.sql

# Backup de configuración
Copy-Item "../docker-compose.yaml" -Destination "."
Copy-Item "../rabbitmq_plugins" -Destination "."

# Comprimir
Compress-Archive -Path "." -DestinationPath "../koha-simple-backup.zip"
```

---

## Método 3: Backup usando Docker Compose

### 📋 Script de Backup Automatizado
```powershell
# Crear script de backup
$backupScript = @"
# Parar servicios temporalmente
docker-compose stop koha

# Backup de BD mientras el servicio está parado
docker exec examples-db-1 mysqldump -u root -pexample --all-databases > db-backup.sql

# Backup de volúmenes
docker run --rm -v examples_mariadb-koha:/data -v `${PWD}:/backup alpine tar czf /backup/volumes-backup.tar.gz -C /data .

# Reiniciar servicios
docker-compose start koha

Write-Host "Backup completado en `$(Get-Location)"
"@

$backupScript | Out-File -FilePath "backup-script.ps1" -Encoding UTF8
```

---

## 🚀 Restauración en Nueva Máquina

### 📋 Preparación de la Nueva Máquina
```powershell
# 1. Instalar Docker y Docker Compose
# 2. Crear directorio de trabajo
mkdir koha-docker
cd koha-docker

# 3. Extraer backup
Expand-Archive -Path "koha-migration-complete.zip" -DestinationPath "."
```

### 🐳 Restaurar Imágenes (si las exportaste)
```powershell
docker load -i koha-image.tar
docker load -i mariadb-image.tar
docker load -i rabbitmq-image.tar
docker load -i memcached-image.tar
```

### 📄 Restaurar Configuración
```powershell
# Copiar archivos de configuración
Copy-Item "docker-compose-backup.yaml" -Destination "docker-compose.yaml"
Copy-Item "rabbitmq_plugins-backup" -Destination "rabbitmq_plugins"
```

### 🗄️ Restaurar Base de Datos
```powershell
# Iniciar solo la base de datos primero
docker-compose up -d db

# Esperar que la BD se inicialice
Start-Sleep -Seconds 30

# Restaurar la base de datos
Get-Content koha-database-backup.sql | docker exec -i examples-db-1 mysql -u root -pexample

# O restaurar solo la BD de Koha
# Get-Content koha-database.sql | docker exec -i examples-db-1 mysql -u root -pexample koha_teolib
```

### 💾 Restaurar Volúmenes (Método Alternativo)
```powershell
# Si respaldaste volúmenes por separado
docker run --rm -v examples_mariadb-koha:/data -v ${PWD}:/backup alpine tar xzf /backup/mariadb-volume-backup.tar.gz -C /data
```

### 🚀 Iniciar Todos los Servicios
```powershell
# Iniciar todos los contenedores
docker-compose up -d

# Verificar estado
docker-compose ps

# Verificar logs
docker-compose logs koha
```

---

## ✅ Script de Backup Automatizado Completo

### 📜 Crear Script de PowerShell
```powershell
# backup-koha.ps1
param(
    [string]$BackupPath = "koha-backup"
)

$fecha = Get-Date -Format "yyyyMMdd-HHmm"
$backupDir = "$BackupPath\backup-$fecha"

Write-Host "🔄 Iniciando backup de Koha..." -ForegroundColor Green

# Crear directorio de backup
New-Item -ItemType Directory -Path $backupDir -Force
Set-Location $backupDir

Write-Host "📁 Directorio de backup creado: $backupDir" -ForegroundColor Yellow

# Backup de base de datos
Write-Host "🗄️ Haciendo backup de base de datos..." -ForegroundColor Blue
docker exec examples-db-1 mysqldump -u root -pexample --all-databases --routines --triggers > koha-database-backup.sql

# Backup de volúmenes
Write-Host "💾 Haciendo backup de volúmenes..." -ForegroundColor Blue
docker run --rm -v examples_mariadb-koha:/data -v ${PWD}:/backup alpine tar czf /backup/mariadb-volume-backup.tar.gz -C /data .

# Backup de configuración
Write-Host "📄 Haciendo backup de configuración..." -ForegroundColor Blue
Copy-Item "../../docker-compose.yaml" -Destination "docker-compose-backup.yaml"
Copy-Item "../../rabbitmq_plugins" -Destination "rabbitmq_plugins-backup"

# Crear archivo de información
$info = @"
Backup de Koha Docker
====================
Fecha: $(Get-Date)
Host Original: $env:COMPUTERNAME
Usuario: $env:USERNAME
Versión Docker: $(docker --version)
Versión Docker Compose: $(docker-compose --version)

Contenido del Backup:
- koha-database-backup.sql: Backup completo de base de datos
- mariadb-volume-backup.tar.gz: Backup del volumen de MariaDB
- docker-compose-backup.yaml: Configuración de Docker Compose
- rabbitmq_plugins-backup: Configuración de RabbitMQ

Instrucciones de Restauración:
1. Extraer archivos en nueva máquina
2. Renombrar archivos de configuración
3. Restaurar base de datos
4. Iniciar servicios con docker-compose up -d
"@

$info | Out-File -FilePath "README-BACKUP.txt" -Encoding UTF8

# Comprimir todo
Write-Host "📦 Comprimiendo backup..." -ForegroundColor Blue
Set-Location ..
Compress-Archive -Path "backup-$fecha" -DestinationPath "koha-migration-$fecha.zip"

Write-Host "✅ Backup completado: koha-migration-$fecha.zip" -ForegroundColor Green
Write-Host "📏 Tamaño del archivo: $((Get-Item "koha-migration-$fecha.zip").Length / 1MB) MB" -ForegroundColor Yellow
```

---

## 🔄 Script de Restauración Automatizado

### 📜 restore-koha.ps1
```powershell
# restore-koha.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

Write-Host "🔄 Iniciando restauración de Koha..." -ForegroundColor Green

# Extraer backup
$extractPath = "koha-restore-$(Get-Date -Format 'yyyyMMdd-HHmm')"
Expand-Archive -Path $BackupFile -DestinationPath $extractPath
Set-Location $extractPath

# Buscar el directorio del backup
$backupContent = Get-ChildItem -Directory | Select-Object -First 1
Set-Location $backupContent.Name

Write-Host "📁 Backup extraído en: $(Get-Location)" -ForegroundColor Yellow

# Restaurar configuración
Write-Host "📄 Restaurando configuración..." -ForegroundColor Blue
Copy-Item "docker-compose-backup.yaml" -Destination "docker-compose.yaml"
Copy-Item "rabbitmq_plugins-backup" -Destination "rabbitmq_plugins"

# Iniciar base de datos
Write-Host "🗄️ Iniciando base de datos..." -ForegroundColor Blue
docker-compose up -d db
Start-Sleep -Seconds 30

# Restaurar base de datos
Write-Host "📥 Restaurando base de datos..." -ForegroundColor Blue
Get-Content koha-database-backup.sql | docker exec -i examples-db-1 mysql -u root -pexample

# Iniciar todos los servicios
Write-Host "🚀 Iniciando todos los servicios..." -ForegroundColor Blue
docker-compose up -d

# Verificar estado
Write-Host "✅ Verificando estado de los servicios..." -ForegroundColor Green
docker-compose ps

Write-Host "🎉 Restauración completada!" -ForegroundColor Green
Write-Host "🌐 Accede a Koha en: http://localhost:8081" -ForegroundColor Yellow
```

---

## 📝 Uso de los Scripts

### 🔄 Para hacer Backup
```powershell
# Ejecutar desde el directorio examples/
.\backup-koha.ps1

# O especificar directorio personalizado
.\backup-koha.ps1 -BackupPath "C:\MisBackups"
```

### 🔄 Para Restaurar
```powershell
# En la nueva máquina
.\restore-koha.ps1 -BackupFile "koha-migration-20250826-1230.zip"
```

---

## ⚠️ Consideraciones Importantes

### 🔒 Seguridad
- **Cambiar contraseñas** en la nueva máquina
- **Verificar permisos** de archivos y directorios
- **Actualizar configuración** de red si es necesario

### 🌐 Red y Puertos
- Verificar que los **puertos 8080 y 8081** estén disponibles
- Configurar **firewall** si es necesario
- Actualizar **nombres de host** si es necesario

### 📏 Tamaño y Rendimiento
- El backup puede ser **grande** (depende del contenido de la BD)
- La restauración puede **tomar tiempo** dependiendo del tamaño
- Verificar **espacio en disco** suficiente

### 🔄 Verificación Post-Migración
```powershell
# Verificar servicios
docker-compose ps

# Verificar logs
docker-compose logs koha

# Verificar acceso web
# http://localhost:8081

# Verificar base de datos
docker exec examples-db-1 mysql -u root -pexample -e "SHOW DATABASES;"
```

---

## 🚀 Migración Express (Solo lo Esencial)

Si solo necesitas migrar **lo esencial** rápidamente:

```powershell
# 1. Backup mínimo
docker exec examples-db-1 mysqldump -u root -pexample koha_teolib > koha-db.sql
Copy-Item docker-compose.yaml, rabbitmq_plugins -Destination backup/

# 2. En nueva máquina
docker-compose up -d db
Start-Sleep 30
Get-Content koha-db.sql | docker exec -i examples-db-1 mysql -u root -pexample koha_teolib
docker-compose up -d
```

Esta guía te permite migrar tu instalación de Koha de manera completa y segura a cualquier otra máquina con Docker.
