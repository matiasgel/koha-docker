# Scripts de Administración para Koha

## Backup Script (backup.sh)
Script automatizado para crear backups de la base de datos de Koha.

**Uso:**
```bash
# Ejecutar backup manual
docker-compose -f docker-compose.prod.yaml run --rm backup

# O usando el perfil de backup
docker-compose -f docker-compose.prod.yaml --profile backup up backup
```

**Características:**
- Backup comprimido con gzip
- Verificación de integridad con SHA256
- Retención automática de backups antiguos
- Enlace simbólico al backup más reciente

## Restore Script (restore.sh)
Script para restaurar la base de datos desde un archivo de backup.

**Uso:**
```bash
# Detener Koha primero
docker-compose -f docker-compose.prod.yaml stop koha

# Ejecutar restauración
docker-compose -f docker-compose.prod.yaml run --rm -v $(pwd)/scripts:/scripts backup /scripts/restore.sh koha_20241226_140000.sql.gz

# Reiniciar Koha
docker-compose -f docker-compose.prod.yaml start koha
```

**Características:**
- Verificación de integridad del backup
- Confirmación antes de sobrescribir datos
- Validación de archivos de backup

## Monitor Script (monitor.sh)
Script de monitoreo para verificar el estado de todos los servicios.

**Uso:**
```bash
./scripts/monitor.sh
```

**Información mostrada:**
- Estado de cada contenedor
- Health checks de servicios
- Uso de disco de volúmenes
- URLs de acceso
- Comandos útiles para logs

## Configuración de Backups Automáticos

Para configurar backups automáticos, puede usar cron en el host:

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 2:00 AM
0 2 * * * cd /path/to/koha-docker/prod && docker-compose -f docker-compose.prod.yaml --profile backup up backup >> /var/log/koha-backup.log 2>&1
```

## Permisos

En sistemas Unix/Linux, asegúrese de que los scripts tengan permisos de ejecución:

```bash
chmod +x scripts/*.sh
```
