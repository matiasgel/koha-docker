# backup-simple.ps1 - Backup rápido solo de datos esenciales
param(
    [string]$BackupName = "koha-simple-$(Get-Date -Format 'yyyyMMdd-HHmm')"
)

Write-Host "Iniciando backup simple de Koha..." -ForegroundColor Green

try {
    # Crear directorio de backup
    New-Item -ItemType Directory -Path $BackupName -Force | Out-Null
    
    Write-Host "Creando backup en: $BackupName" -ForegroundColor Yellow

    # Backup de base de datos (solo koha_teolib)
    Write-Host "Backup de base de datos..." -ForegroundColor Blue
    docker exec examples-db-1 mariadb-dump -u root -pexample koha_teolib > "$BackupName\koha-database.sql"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error en backup de base de datos"
    }

    # Copiar configuración
    Write-Host "Copiando configuración..." -ForegroundColor Blue
    Copy-Item "examples\docker-compose.yaml" -Destination "$BackupName\docker-compose.yaml"
    Copy-Item "examples\rabbitmq_plugins" -Destination "$BackupName\rabbitmq_plugins"

    # Crear archivo README
    $readme = @"
Backup Simple de Koha
=====================
Fecha: $(Get-Date)
Host: $env:COMPUTERNAME

Contenido:
- koha-database.sql: Base de datos de Koha
- docker-compose.yaml: Configuración de Docker
- rabbitmq_plugins: Configuración de RabbitMQ

Restauración en nueva máquina:
1. Instalar Docker y Docker Compose
2. Copiar archivos a directorio de trabajo
3. Ejecutar comandos:

docker-compose up -d db
Start-Sleep -Seconds 30
Get-Content koha-database.sql | docker exec -i examples-db-1 mariadb -u root -pexample koha_teolib
docker-compose up -d

Credenciales:
- Usuario web installer: koha_teolib
- Contraseña: example
"@

    $readme | Out-File -FilePath "$BackupName\README.txt" -Encoding UTF8

    # Comprimir
    Write-Host "Comprimiendo..." -ForegroundColor Blue
    Compress-Archive -Path $BackupName -DestinationPath "$BackupName.zip" -Force

    $fileSize = [math]::Round((Get-Item "$BackupName.zip").Length / 1MB, 2)
    
    Write-Host "Backup simple completado!" -ForegroundColor Green
    Write-Host "Archivo: $BackupName.zip" -ForegroundColor Yellow
    Write-Host "Tamaño: $fileSize MB" -ForegroundColor Yellow
    
    # Limpiar directorio temporal
    Remove-Item -Recurse -Force $BackupName
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
