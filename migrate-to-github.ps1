# migrate-to-github.ps1
# Script para migrar el repositorio koha-docker a tu GitHub personal

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "koha-docker"
)

Write-Host "Migrando repositorio a tu GitHub personal..." -ForegroundColor Green
Write-Host "Usuario: $GitHubUsername" -ForegroundColor Yellow
Write-Host "Repositorio: $RepoName" -ForegroundColor Yellow

try {
    # Verificar que estamos en un repositorio git
    $gitStatus = git status 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Este directorio no es un repositorio git válido"
    }

    # Agregar tu repositorio como origin
    Write-Host "Configurando remote origin..." -ForegroundColor Blue
    git remote add origin "https://github.com/$GitHubUsername/$RepoName.git"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error al agregar el remote origin"
    }

    # Verificar configuración de usuario git
    $gitUser = git config user.name
    $gitEmail = git config user.email
    
    if (-not $gitUser -or -not $gitEmail) {
        Write-Host "Configurando usuario de Git..." -ForegroundColor Yellow
        Write-Host "Ingresa tu nombre completo:" -ForegroundColor Cyan
        $userName = Read-Host
        Write-Host "Ingresa tu email de GitHub:" -ForegroundColor Cyan
        $userEmail = Read-Host
        
        git config user.name "$userName"
        git config user.email "$userEmail"
        
        # Actualizar variables
        $gitUser = git config user.name
        $gitEmail = git config user.email
    }

    Write-Host "Usuario Git configurado: $gitUser <$gitEmail>" -ForegroundColor Green

    # Agregar todos los archivos al staging area
    Write-Host "Preparando archivos para commit..." -ForegroundColor Blue
    git add .

    # Verificar si hay cambios para commit
    $statusOutput = git status --porcelain
    if ($statusOutput) {
        Write-Host "Haciendo commit de cambios..." -ForegroundColor Blue
        git commit -m "feat: Add Spanish localization, backup scripts, and production configuration

- Added comprehensive installation guide in Spanish (GUIA_INSTALACION_KOHA.md)
- Created automated backup scripts (backup-koha.ps1, backup-simple.ps1)
- Added restore script (restore-koha.ps1)
- Configured Spanish language support (es-ES)
- Added production environment setup
- Created backup and migration documentation
- Enhanced docker-compose configuration with language support"
    }

    # Push al repositorio
    Write-Host "Subiendo archivos a GitHub..." -ForegroundColor Blue
    git push -u origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nMigracion completada exitosamente!" -ForegroundColor Green
        Write-Host "Tu repositorio esta disponible en:" -ForegroundColor Cyan
        Write-Host "   https://github.com/$GitHubUsername/$RepoName" -ForegroundColor White
        
        Write-Host "`nProximos pasos recomendados:" -ForegroundColor Yellow
        Write-Host "1. Visita tu repositorio en GitHub" -ForegroundColor White
        Write-Host "2. Actualiza la descripcion del repositorio" -ForegroundColor White
        Write-Host "3. Agrega tags/topics como: koha, docker, library, ils" -ForegroundColor White
        Write-Host "4. Considera hacer el repositorio publico para ayudar a otros" -ForegroundColor White
        
    } else {
        throw "Error al hacer push al repositorio"
    }

} catch {
    Write-Host "Error durante la migracion: $_" -ForegroundColor Red
    Write-Host "Verificaciones:" -ForegroundColor Yellow
    Write-Host "   - Creaste el repositorio en GitHub?" -ForegroundColor White
    Write-Host "   - Tu usuario de GitHub es correcto?" -ForegroundColor White
    Write-Host "   - Tienes permisos de escritura?" -ForegroundColor White
    Write-Host "   - Tu conexion a internet funciona?" -ForegroundColor White
    exit 1
}