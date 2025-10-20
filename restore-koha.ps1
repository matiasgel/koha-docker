# restore-koha.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

Write-Host "🔄 Iniciando restauración de Koha..." -ForegroundColor Green

# Verificar que el archivo existe
if (-not (Test-Path $BackupFile)) {
    Write-Host "❌ Error: El archivo de backup no existe: $BackupFile" -ForegroundColor Red
    exit 1
}

$originalLocation = Get-Location

try {
    # Extraer backup
    $extractPath = "koha-restore-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    Write-Host "📁 Extrayendo backup en: $extractPath" -ForegroundColor Yellow
    
    Expand-Archive -Path $BackupFile -DestinationPath $extractPath -Force
    Set-Location $extractPath

    # Buscar el directorio del backup
    $backupContent = Get-ChildItem -Directory | Select-Object -First 1
    if ($backupContent) {
        Set-Location $backupContent.Name
        Write-Host "📂 Contenido encontrado en: $($backupContent.Name)" -ForegroundColor Yellow
    }

    # Verificar archivos necesarios
    $requiredFiles = @("docker-compose-backup.yaml", "rabbitmq_plugins-backup", "koha-database-backup.sql")
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            throw "Archivo requerido no encontrado: $file"
        }
    }

    # Restaurar configuración
    Write-Host "📄 Restaurando configuración..." -ForegroundColor Blue
    Copy-Item "docker-compose-backup.yaml" -Destination "docker-compose.yaml"
    Copy-Item "rabbitmq_plugins-backup" -Destination "rabbitmq_plugins"

    # Verificar que Docker esté funcionando
    Write-Host "🐳 Verificando Docker..." -ForegroundColor Blue
    docker --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker no está disponible o no está funcionando"
    }

    # Limpiar contenedores existentes (si los hay)
    Write-Host "🧹 Limpiando contenedores existentes..." -ForegroundColor Yellow
    docker-compose down 2>$null

    # Iniciar base de datos
    Write-Host "🗄️ Iniciando base de datos..." -ForegroundColor Blue
    docker-compose up -d db
    
    # Esperar que la base de datos se inicialice
    Write-Host "⏳ Esperando inicialización de base de datos (30 segundos)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # Verificar que la BD esté funcionando
    docker exec examples-db-1 mariadb -u root -pexample -e "SELECT 1;" 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⏳ BD aún no lista, esperando 15 segundos más..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }

    # Restaurar base de datos
    Write-Host "📥 Restaurando base de datos..." -ForegroundColor Blue
    Get-Content "koha-database-backup.sql" | docker exec -i examples-db-1 mariadb -u root -pexample
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error al restaurar la base de datos"
    }

    # Iniciar todos los servicios
    Write-Host "🚀 Iniciando todos los servicios..." -ForegroundColor Blue
    docker-compose up -d

    # Esperar que los servicios se inicialicen
    Write-Host "⏳ Esperando inicialización de servicios..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15

    # Verificar estado
    Write-Host "✅ Verificando estado de los servicios..." -ForegroundColor Green
    docker-compose ps

    # Verificar acceso web
    Write-Host "🌐 Verificando acceso web..." -ForegroundColor Blue
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Koha responde correctamente en puerto 8081" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Koha aún no responde en puerto 8081, puede necesitar más tiempo" -ForegroundColor Yellow
    }

    Write-Host "`n🎉 Restauración completada exitosamente!" -ForegroundColor Green
    Write-Host "🌐 Accede a Koha en: http://localhost:8081" -ForegroundColor Cyan
    Write-Host "🌐 OPAC disponible en: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "📁 Archivos restaurados en: $(Get-Location)" -ForegroundColor Yellow
    
    Write-Host "`n📋 Credenciales de acceso:" -ForegroundColor Yellow
    Write-Host "   Usuario: koha_teolib" -ForegroundColor White
    Write-Host "   Contraseña: example" -ForegroundColor White
    
} catch {
    Write-Host "❌ Error durante la restauración: $_" -ForegroundColor Red
    Write-Host "💡 Verifica que Docker esté funcionando y que tengas los permisos necesarios" -ForegroundColor Yellow
    exit 1
} finally {
    Set-Location $originalLocation
}
