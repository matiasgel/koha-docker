# Koha Docker - Configuración de Producción

Esta configuración de producción está diseñada para un entorno de producción robusto y escalable de Koha, utilizando todos los archivos de configuración del directorio `files/` del proyecto principal.

## Características

- **Volúmenes persistentes** para todos los datos importantes
- **Configuraciones personalizadas** basadas en las plantillas de `files/`
- **Backup automático** de la base de datos
- **Monitoreo de salud** para todos los servicios
- **Configuraciones de seguridad** para producción
- **Logging optimizado** para producción

## Estructura de archivos

### Configuraciones utilizadas desde `files/`

El setup utiliza los siguientes archivos del directorio principal `files/`:

- `files/docker/templates/` - Plantillas de configuración de Koha
  - `koha-common.cnf` - Configuración de cliente MySQL
  - `koha-sites.conf` - Configuración de sitios Koha
  - `SIPconfig.xml` - Configuración SIP2
- `files/etc/` - Configuraciones del sistema
  - `koha-envvars/` - Variables de entorno de Koha
  - `cron.d/`, `cron.daily/`, etc. - Tareas programadas
  - `logrotate.d/` - Rotación de logs
  - `s6-overlay/` - Scripts de inicialización y servicios

### Configuraciones personalizadas para producción

- `.env` - Variables de entorno principales
- `.env.prod` - Variables específicas de producción
- `config/koha/koha-sites-prod.conf` - Configuración de sitios personalizada
- `config/koha/koha-common-prod.cnf` - Configuración MySQL personalizada

## Instalación

1. **Configurar variables de entorno**:
   ```bash
   # Editar .env con las contraseñas y configuraciones de tu entorno
   # Las contraseñas deben ser cambiadas antes del despliegue
   ```

2. **Crear estructura de directorios**:
   ```bash
   docker-compose up --no-start
   ```

3. **Inicializar volúmenes**:
   ```bash
   # Los volúmenes se crearán automáticamente en ./volumes/
   ```

4. **Levantar los servicios**:
   ```bash
   docker-compose up -d
   ```

## Servicios incluidos

### Koha (Puerto 8080/8081)
- **OPAC**: http://localhost:8080
- **Staff Interface**: http://localhost:8081
- Utiliza configuraciones de `files/docker/templates/`
- Scripts de inicialización de `files/etc/s6-overlay/`

### MariaDB (Puerto 3306)
- Base de datos optimizada para Koha
- Backups automáticos en `./volumes/mariadb/backups/`
- Configuración personalizada en `./volumes/mariadb/conf/`

### RabbitMQ (Puerto 15672/5672/61613)
- **Management UI**: http://localhost:15672
- Plugin STOMP habilitado para Koha
- Configuración personalizada desde `./config/rabbitmq.conf`

### Memcached
- Cache de sesiones y datos de Koha
- Configurado según `files/docker/templates/koha-sites.conf`

## Volúmenes persistentes

Todos los datos se almacenan en `./volumes/`:

```
volumes/
├── koha/
│   ├── logs/           # Logs de Koha (utiliza logrotate de files/)
│   ├── etc/            # Configuraciones dinámicas
│   ├── uploads/        # Archivos subidos por usuarios
│   ├── covers/         # Portadas de libros
│   └── plugins/        # Plugins de Koha
├── mariadb/
│   ├── data/           # Datos de la base de datos
│   ├── conf/           # Configuraciones MySQL adicionales
│   └── backups/        # Backups automáticos
└── rabbitmq/
    ├── data/           # Datos de RabbitMQ
    └── logs/           # Logs de RabbitMQ
```

## Uso de archivos de `files/`

### Scripts de inicialización
El contenedor utiliza los scripts de `files/etc/s6-overlay/scripts/02-setup-koha.sh` que:
- Configura las variables de entorno
- Crea la instancia de Koha
- Configura Zebra/Elasticsearch
- Instala idiomas configurados
- Configura Plack y Apache

### Configuraciones de sistema
- **Cron jobs**: Se montan desde `files/etc/cron.*/`
- **Logrotate**: Configuración desde `files/etc/logrotate.d/`
- **Variables de entorno**: Desde `files/etc/koha-envvars/`

### Plantillas de configuración
- Las plantillas en `files/docker/templates/` se procesan con `envsubst`
- Variables definidas en `.env` y `.env.prod` se sustituyen automáticamente

## Monitoreo y logs

### Health checks
Todos los servicios tienen health checks configurados:
- Koha: Verificación HTTP en puerto 8080
- MariaDB: Verificación de conexión InnoDB
- RabbitMQ: Ping de diagnóstico
- Memcached: Verificación de stats

### Logs
- **Koha**: `./volumes/koha/logs/` (rotación por logrotate de `files/`)
- **MariaDB**: Docker logs + `./volumes/mariadb/data/`
- **RabbitMQ**: `./volumes/rabbitmq/logs/`

## Backup y restauración

### Backup automático
```bash
# Crear backup manual
docker-compose --profile backup run --rm backup

# Los backups se guardan en ./volumes/mariadb/backups/
```

### Restauración
```bash
# Usar script de restauración
./scripts/restore.sh backup_file.sql
```

## Configuración de producción

### Variables importantes en `.env`

- `MARIADB_ROOT_PASSWORD` - Contraseña root de MariaDB
- `KOHA_DB_PASSWORD` - Contraseña de usuario Koha
- `RABBITMQ_PASSWORD` - Contraseña de RabbitMQ
- `KOHA_LANGS` - Idiomas a instalar (ej: "es-ES en")
- `ZEBRA_MARC_FORMAT` - Formato MARC (marc21, unimarc, etc.)

### Personalización adicional

1. **Configuración de correo**: Editar variables SMTP en `.env.prod`
2. **Límites de recursos**: Ajustar `PLACK_WORKERS` y `PLACK_MAX_REQUESTS`
3. **Configuración de seguridad**: Habilitar HTTPS modificando `FORCE_HTTPS=1`

## Solución de problemas

### Logs importantes
```bash
# Logs de Koha
docker-compose logs koha

# Logs de base de datos
docker-compose logs db

# Logs de inicialización (basados en files/etc/s6-overlay/)
docker exec koha-prod cat /var/log/koha/default/intranet-error.log
```

### Verificar configuración
```bash
# Verificar que las plantillas de files/ se procesaron correctamente
docker exec koha-prod cat /etc/koha/koha-sites.conf
docker exec koha-prod cat /etc/mysql/koha-common.cnf
```

## Mantenimiento

### Actualizaciones
1. Hacer backup antes de actualizar
2. Actualizar imagen de Koha
3. Verificar compatibilidad con archivos de `files/`
4. Probar en entorno de desarrollo primero

### Escalabilidad
- Ajustar `PLACK_WORKERS` según CPU disponible
- Configurar `innodb-buffer-pool-size` según RAM disponible
- Monitorear uso de Memcached y ajustar memoria asignada

Este setup integra completamente los archivos de configuración de `files/` para proporcionar una instalación de producción robusta y mantenible de Koha.
