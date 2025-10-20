# backup-koha.ps1
param(
    [string]$BackupPath = "koha-backup"
)

$fecha = Get-Date -Format "yyyyMMdd-HHmm"
$backupDir = "$BackupPath\backup-$fecha"

Write-Host "🔄 Iniciando backup de Koha..." -ForegroundColor Green

# Crear directorio de backup
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$originalLocation = Get-Location
Set-Location $backupDir

Write-Host "📁 Directorio de backup creado: $backupDir" -ForegroundColor Yellow

try {
    # Backup de base de datos
    Write-Host "🗄️ Haciendo backup de base de datos..." -ForegroundColor Blue
    docker exec examples-db-1 mariadb-dump -u root -pexample --all-databases --routines --triggers > koha-database-backup.sql
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error en backup de base de datos"
    }

    # Backup de volúmenes
    Write-Host "💾 Haciendo backup de volúmenes..." -ForegroundColor Blue
    docker run --rm -v examples_mariadb-koha:/data -v "${PWD}:/backup" alpine tar czf /backup/mariadb-volume-backup.tar.gz -C /data .
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error en backup de volúmenes"
    }

    # Backup de configuración
    Write-Host "📄 Haciendo backup de configuración..." -ForegroundColor Blue
    Copy-Item "$originalLocation\docker-compose.yaml" -Destination "docker-compose-backup.yaml"
    Copy-Item "$originalLocation\rabbitmq_plugins" -Destination "rabbitmq_plugins-backup"

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

Comandos de restauración:
```powershell
# Restaurar configuración
Copy-Item "docker-compose-backup.yaml" -Destination "docker-compose.yaml"
Copy-Item "rabbitmq_plugins-backup" -Destination "rabbitmq_plugins"

# Iniciar BD
docker-compose up -d db
Start-Sleep -Seconds 30

# Restaurar datos
Get-Content koha-database-backup.sql | docker exec -i examples-db-1 mysql -u root -pexample

# Iniciar todos los servicios
docker-compose up -d
```
"@

    $info | Out-File -FilePath "README-BACKUP.txt" -Encoding UTF8

    # Comprimir todo
    Write-Host "📦 Comprimiendo backup..." -ForegroundColor Blue
    Set-Location ..
    Compress-Archive -Path "backup-$fecha" -DestinationPath "koha-migration-$fecha.zip" -Force

    $fileSize = [math]::Round((Get-Item "koha-migration-$fecha.zip").Length / 1MB, 2)
    
    Write-Host "✅ Backup completado exitosamente!" -ForegroundColor Green
    Write-Host "📦 Archivo: koha-migration-$fecha.zip" -ForegroundColor Yellow
    Write-Host "📏 Tamaño: $fileSize MB" -ForegroundColor Yellow
    Write-Host "📁 Ubicación: $(Get-Location)\koha-migration-$fecha.zip" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error durante el backup: $_" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $originalLocation
}
