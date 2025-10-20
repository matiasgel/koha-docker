# Script de PowerShell para despliegue de Koha en producción
# Este script facilita la configuración e inicio de Koha usando los archivos de files/

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("install", "start", "stop", "restart", "logs", "backup", "status")]
    [string]$Action = "install",
    
    [Parameter(Mandatory=$false)]
    [string]$Service = "all"
)

$ErrorActionPreference = "Stop"

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-DockerCompose {
    try {
        docker-compose --version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Show-Status {
    Write-ColoredOutput "=== Estado de los servicios de Koha ===" "Yellow"
    docker-compose -f docker-compose.prod.yaml ps
    
    Write-ColoredOutput "`n=== Health Checks ===" "Yellow"
    docker-compose -f docker-compose.prod.yaml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
}

function Install-KohaProduction {
    Write-ColoredOutput "Instalando Koha en producción..." "Green"
    
    # Verificar que Docker Compose está disponible
    if (-not (Test-DockerCompose)) {
        Write-ColoredOutput "Error: Docker Compose no está disponible" "Red"
        exit 1
    }
    
    # Verificar que el archivo .env existe
    if (-not (Test-Path ".env")) {
        Write-ColoredOutput "Error: El archivo .env no existe. Cree uno basado en las variables del README." "Red"
        Write-ColoredOutput "Variables importantes a configurar:" "Yellow"
        Write-ColoredOutput "- MARIADB_ROOT_PASSWORD" "Cyan"
        Write-ColoredOutput "- KOHA_DB_PASSWORD" "Cyan"
        Write-ColoredOutput "- RABBITMQ_PASSWORD" "Cyan"
        exit 1
    }
    
    # Verificar que los directorios de files/ existen
    if (-not (Test-Path "../files")) {
        Write-ColoredOutput "Error: El directorio ../files no existe. Este script debe ejecutarse desde el directorio prod/" "Red"
        exit 1
    }
    
    Write-ColoredOutput "Verificando archivos de configuración de files/..." "Cyan"
    $requiredFiles = @(
        "../files/docker/templates/koha-common.cnf",
        "../files/docker/templates/koha-sites.conf",
        "../files/etc/s6-overlay/scripts/02-setup-koha.sh"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-ColoredOutput "Error: Archivo requerido no encontrado: $file" "Red"
            exit 1
        }
    }
    
    Write-ColoredOutput "Creando estructura de directorios de volúmenes..." "Cyan"
    $directories = @(
        "volumes\koha\logs",
        "volumes\koha\etc", 
        "volumes\koha\uploads",
        "volumes\koha\covers",
        "volumes\koha\plugins",
        "volumes\mariadb\data",
        "volumes\mariadb\conf",
        "volumes\mariadb\backups",
        "volumes\rabbitmq\data",
        "volumes\rabbitmq\logs"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColoredOutput "Creado: $dir" "DarkGreen"
        }
    }
    
    Write-ColoredOutput "Descargando imágenes de Docker..." "Cyan"
    docker-compose -f docker-compose.prod.yaml pull
    
    Write-ColoredOutput "Iniciando servicios..." "Cyan"
    docker-compose -f docker-compose.prod.yaml up -d
    
    Write-ColoredOutput "`nEsperando a que los servicios estén listos..." "Cyan"
    Start-Sleep -Seconds 30
    
    Show-Status
    
    Write-ColoredOutput "`n=== INSTALACIÓN COMPLETADA ===" "Green"
    Write-ColoredOutput "URLs de acceso:" "Yellow"
    Write-ColoredOutput "- OPAC (Catálogo): http://localhost:8080" "Cyan"
    Write-ColoredOutput "- Staff Interface: http://localhost:8081" "Cyan"
    Write-ColoredOutput "- RabbitMQ Management: http://localhost:15672" "Cyan"
    Write-ColoredOutput "`nArchivos de configuración utilizados desde files/:" "Yellow"
    Write-ColoredOutput "- Plantillas de configuración: files/docker/templates/" "DarkCyan"
    Write-ColoredOutput "- Scripts de sistema: files/etc/s6-overlay/" "DarkCyan"
    Write-ColoredOutput "- Configuraciones de cron: files/etc/cron.*/" "DarkCyan"
    Write-ColoredOutput "- Configuración de logrotate: files/etc/logrotate.d/" "DarkCyan"
}

function Start-Services {
    Write-ColoredOutput "Iniciando servicios de Koha..." "Green"
    if ($Service -eq "all") {
        docker-compose -f docker-compose.prod.yaml up -d
    } else {
        docker-compose -f docker-compose.prod.yaml up -d $Service
    }
    Show-Status
}

function Stop-Services {
    Write-ColoredOutput "Deteniendo servicios de Koha..." "Yellow"
    if ($Service -eq "all") {
        docker-compose -f docker-compose.prod.yaml down
    } else {
        docker-compose -f docker-compose.prod.yaml stop $Service
    }
}

function Restart-Services {
    Write-ColoredOutput "Reiniciando servicios de Koha..." "Yellow"
    if ($Service -eq "all") {
        docker-compose -f docker-compose.prod.yaml restart
    } else {
        docker-compose -f docker-compose.prod.yaml restart $Service
    }
    Show-Status
}

function Show-Logs {
    Write-ColoredOutput "Mostrando logs..." "Cyan"
    if ($Service -eq "all") {
        docker-compose -f docker-compose.prod.yaml logs -f
    } else {
        docker-compose -f docker-compose.prod.yaml logs -f $Service
    }
}

function Invoke-Backup {
    Write-ColoredOutput "Creando backup de la base de datos..." "Green"
    docker-compose -f docker-compose.prod.yaml --profile backup run --rm backup
    
    Write-ColoredOutput "Listando backups disponibles:" "Cyan"
    Get-ChildItem "volumes\mariadb\backups" | Format-Table Name, Length, LastWriteTime
}

# Script principal
try {
    Write-ColoredOutput "=== Koha Docker Production Manager ===" "Magenta"
    Write-ColoredOutput "Usando configuraciones de files/ del proyecto principal`n" "DarkMagenta"
    
    switch ($Action) {
        "install" { Install-KohaProduction }
        "start" { Start-Services }
        "stop" { Stop-Services }
        "restart" { Restart-Services }
        "logs" { Show-Logs }
        "backup" { Invoke-Backup }
        "status" { Show-Status }
        default { 
            Write-ColoredOutput "Acción no válida: $Action" "Red"
            Write-ColoredOutput "Acciones disponibles: install, start, stop, restart, logs, backup, status" "Yellow"
            exit 1
        }
    }
}
catch {
    Write-ColoredOutput "Error: $($_.Exception.Message)" "Red"
    exit 1
}
