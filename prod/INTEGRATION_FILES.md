# Integración con archivos de files/

Este documento explica cómo la configuración de producción utiliza e integra los archivos del directorio `files/` del proyecto principal.

## Archivos de files/ utilizados

### 1. Templates de configuración (`files/docker/templates/`)

#### koha-common.cnf
- **Ubicación**: `files/docker/templates/koha-common.cnf`
- **Uso**: Configuración de cliente MySQL para Koha
- **Variables procesadas**:
  - `${MYSQL_SERVER}` → `db` (nombre del servicio de base de datos)
  - `${MYSQL_PASSWORD}` → `${MARIADB_ROOT_PASSWORD}` (de .env)
- **Montaje**: Se copia procesado a `/etc/mysql/koha-common.cnf` en el contenedor

#### koha-sites.conf
- **Ubicación**: `files/docker/templates/koha-sites.conf`
- **Uso**: Configuración principal de sitios Koha
- **Variables procesadas**:
  - `${KOHA_DOMAIN}` → `localhost`
  - `${KOHA_INTRANET_PORT}` → `8081`
  - `${KOHA_OPAC_PORT}` → `8080`
  - `${ZEBRA_MARC_FORMAT}` → `marc21`
  - `${ZEBRA_LANGUAGE}` → `en`
  - `${USE_MEMCACHED}` → `yes`
  - `${MEMCACHED_SERVERS}` → `memcached:11211`
- **Procesamiento**: El script `02-setup-koha.sh` usa `envsubst` para procesar las variables

#### SIPconfig.xml
- **Ubicación**: `files/docker/templates/SIPconfig.xml`
- **Uso**: Configuración del protocolo SIP2 (cuando esté habilitado)
- **Variables**: `${SIP_CONF_ACCOUNTS}`, `${SIP_CONF_LIBS}`

### 2. Scripts de sistema (`files/etc/s6-overlay/`)

#### 02-setup-koha.sh
- **Ubicación**: `files/etc/s6-overlay/scripts/02-setup-koha.sh`
- **Función**: Script principal de inicialización de Koha
- **Tareas que realiza**:
  - Configura variables de entorno por defecto
  - Procesa templates con `envsubst`
  - Crea la instancia de Koha con `koha-create`
  - Configura Elasticsearch (si está habilitado)
  - Instala/configura idiomas
  - Habilita Plack y configura Apache
  - Gestiona servicios (Zebra, workers, etc.)

#### Servicios s6-overlay
Los archivos en `files/etc/s6-overlay/s6-rc.d/` definen los servicios:
- `apache2/` - Servidor web Apache
- `cron/` - Tareas programadas
- `plack/` - Servidor de aplicaciones Plack
- `worker/` y `worker-long-tasks/` - Workers de background jobs
- `zebra-indexer/` y `zebra-server/` - Servicios de indexación

### 3. Configuraciones de sistema (`files/etc/`)

#### Variables de entorno
- **Ubicación**: `files/etc/koha-envvars/`
- **Archivos**: `INSTANCE_NAME`, `KOHA_CONF`, `KOHA_HOME`, `PERL5LIB`
- **Uso**: Variables de entorno específicas de Koha

#### Tareas programadas (Cron)
- **files/etc/cron.d/koha** - Tareas diarias de Koha
- **files/etc/cron.daily/koha** - Tareas diarias de mantenimiento
- **files/etc/cron.hourly/koha** - Tareas por hora
- **files/etc/cron.monthly/koha** - Tareas mensuales

#### Rotación de logs
- **files/etc/logrotate.d/koha-core** - Configuración de logrotate para logs de Koha

## Cómo se integran en la configuración de producción

### 1. Montaje de volúmenes en docker-compose.prod.yaml

```yaml
volumes:
  # Archivos de configuración base desde files/
  - ../files/docker/templates:/docker/templates:ro
  - ../files/etc/koha-envvars:/etc/koha-envvars:ro
  - ../files/etc/cron.d:/etc/cron.d:ro
  - ../files/etc/cron.daily:/etc/cron.daily:ro
  - ../files/etc/cron.hourly:/etc/cron.hourly:ro
  - ../files/etc/cron.monthly:/etc/cron.monthly:ro
  - ../files/etc/logrotate.d:/etc/logrotate.d:ro
  - ../files/etc/s6-overlay:/etc/s6-overlay:ro
```

### 2. Variables de entorno definidas

Las variables definidas en `.env` y `.env.prod` son utilizadas por:
- Los templates para generar configuraciones finales
- El script `02-setup-koha.sh` para la inicialización
- Los servicios s6-overlay para la gestión de procesos

### 3. Proceso de inicialización

1. **Container startup**: s6-overlay inicia usando los archivos de `files/etc/s6-overlay/`
2. **Setup script**: `02-setup-koha.sh` se ejecuta y:
   - Lee variables de entorno de `.env` y `.env.prod`
   - Procesa templates de `files/docker/templates/` con `envsubst`
   - Genera configuraciones finales en `/etc/koha/` y `/etc/mysql/`
   - Crea la instancia de Koha
3. **Service management**: Los servicios definidos en `s6-rc.d/` se inician

### 4. Configuraciones personalizadas adicionales

Además de usar los archivos de `files/`, se añaden configuraciones específicas de producción:
- `config/koha/koha-sites-prod.conf` - Configuración personalizada que extiende la base
- `config/koha/koha-common-prod.cnf` - Configuración MySQL personalizada

## Ventajas de esta integración

### 1. Consistencia
- Usa las mismas configuraciones base que el proyecto principal
- Mantiene compatibilidad con actualizaciones upstream

### 2. Flexibilidad
- Permite personalizar configuraciones específicas de producción
- Variables de entorno centralizadas en archivos `.env`

### 3. Mantenibilidad
- Los cambios en `files/` se propagan automáticamente
- Configuraciones de producción separadas y versionables

### 4. Escalabilidad
- Fácil modificación de variables para diferentes entornos
- Soporte para múltiples configuraciones (dev, staging, prod)

## Verificación de la integración

### Verificar que los archivos se montaron correctamente:
```powershell
# Verificar templates
docker exec koha-prod ls -la /docker/templates/

# Verificar scripts s6-overlay
docker exec koha-prod ls -la /etc/s6-overlay/scripts/

# Verificar configuraciones generadas
docker exec koha-prod cat /etc/koha/koha-sites.conf
docker exec koha-prod cat /etc/mysql/koha-common.cnf
```

### Verificar que las variables se procesaron:
```powershell
# Ver variables de entorno en el contenedor
docker exec koha-prod env | grep -E "(KOHA|MYSQL|MB_)"

# Verificar que los servicios s6 están corriendo
docker exec koha-prod s6-rc -l
```

## Solución de problemas

### Si los templates no se procesan correctamente:
1. Verificar que las variables están definidas en `.env` y `.env.prod`
2. Comprobar que el script `02-setup-koha.sh` tiene permisos de ejecución
3. Revisar logs del contenedor durante la inicialización

### Si los servicios no inician:
1. Verificar que los archivos de `files/etc/s6-overlay/` se montaron correctamente
2. Comprobar dependencias entre servicios en los archivos `dependencies.d/`
3. Revisar logs específicos de cada servicio

Esta integración asegura que la configuración de producción sea robusta, mantenible y consistente con el proyecto principal de koha-docker.
