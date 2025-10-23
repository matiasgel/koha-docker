# 🐧 Koha Docker para Debian 13 - Guía de Instalación en Producción

Esta guía está optimizada para **Debian 13** con las claves de acceso usando el patrón **"pjnadmin_"**.

## 📋 Requisitos Previos

### Sistema Operativo
- ✅ **Debian 13** (tux)
- ✅ **Docker** ya instalado
- ✅ **Acceso root** o sudo

### Hardware Mínimo para Producción
- 🖥️ **CPU**: 4 cores
- 💾 **RAM**: 8GB
- 💿 **Almacenamiento**: 100GB+ (SSD recomendado)
- 🌐 **Red**: Conexión estable a internet

## 🚀 Instalación Rápida

### Paso 1: Descargar e Instalar

```bash
# Descargar el instalador
curl -O https://raw.githubusercontent.com/matiasgel/koha-docker/main/prod/linux/install-debian13.sh

# Hacer ejecutable
chmod +x install-debian13.sh

# Ejecutar instalación
sudo ./install-debian13.sh
```

El script automáticamente:
- ✅ Instala herramientas básicas faltantes en Debian 13
- ✅ Configura usuarios y permisos del sistema
- ✅ Crea estructura de directorios
- ✅ Descarga configuraciones optimizadas
- ✅ Configura servicios systemd
- ✅ Establece firewall básico
- ✅ Configura backup automático

### Paso 2: Configuración Personalizada

```bash
cd /opt/koha-docker

# Editar variables de entorno
sudo nano .env

# Variables principales a personalizar:
# KOHA_DOMAIN=tu-biblioteca.local
# TIMEZONE=America/Argentina/Buenos_Aires
# BACKUP_PATH=/ruta/a/tus/backups
```

### Paso 3: Iniciar Servicios

```bash
# Iniciar servicios
sudo systemctl start koha-docker

# Habilitar inicio automático
sudo systemctl enable koha-docker

# Verificar estado
sudo ./prod/linux/koha-manage.sh status
```

## 🔑 Credenciales por Defecto

### Base de Datos
- **Usuario**: `pjnadmin_koha`
- **Contraseña**: `pjnadmin_db_2024!`
- **Root**: `pjnadmin_root_2024!`

### RabbitMQ
- **Usuario**: `pjnadmin_rabbit`
- **Contraseña**: `pjnadmin_rabbit_2024!`

### Web Installer
- **Usuario**: `pjnadmin_koha`
- **Contraseña**: `pjnadmin_db_2024!`

> ⚠️ **IMPORTANTE**: Cambia estas contraseñas en producción

## 🌐 Acceso a las Interfaces

Una vez iniciado el sistema:

| Servicio | URL | Puerto |
|----------|-----|---------|
| **Staff Interface** | http://localhost:8081 | 8081 |
| **OPAC** | http://localhost:8080 | 8080 |
| **RabbitMQ Management** | http://localhost:15672 | 15672 |

## 🛠️ Gestión del Sistema

### Script de Gestión

El sistema incluye un script de gestión completo:

```bash
# Ver estado
sudo /opt/koha-docker/prod/linux/koha-manage.sh status

# Iniciar servicios
sudo /opt/koha-docker/prod/linux/koha-manage.sh start

# Detener servicios
sudo /opt/koha-docker/prod/linux/koha-manage.sh stop

# Reiniciar servicios
sudo /opt/koha-docker/prod/linux/koha-manage.sh restart

# Ver logs
sudo /opt/koha-docker/prod/linux/koha-manage.sh logs

# Ver logs de un servicio específico
sudo /opt/koha-docker/prod/linux/koha-manage.sh logs koha

# Hacer backup manual
sudo /opt/koha-docker/prod/linux/koha-manage.sh backup

# Limpiar sistema
sudo /opt/koha-docker/prod/linux/koha-manage.sh cleanup

# Generar reporte del sistema
sudo /opt/koha-docker/prod/linux/koha-manage.sh report
```

### Servicios Systemd

```bash
# Estado del servicio
sudo systemctl status koha-docker

# Logs del servicio
sudo journalctl -u koha-docker -f

# Reiniciar servicio
sudo systemctl restart koha-docker
```

## 📦 Estructura de Directorios

```
/opt/koha-docker/                 # Directorio principal
├── docker-compose.yml           # Configuración Docker Compose
├── .env                         # Variables de entorno
├── config/                      # Configuraciones
│   ├── nginx/                   # Configuración Nginx
│   ├── mariadb/                 # Configuración MariaDB
│   ├── rabbitmq/                # Configuración RabbitMQ
│   └── koha/                    # Configuración Koha
├── scripts/                     # Scripts de utilidad
│   ├── backup.sh               # Script de backup
│   └── init-db.sql             # Inicialización de BD
└── data/                       # Datos persistentes
    ├── mariadb/                # Datos MariaDB
    ├── koha/                   # Datos Koha
    └── rabbitmq/               # Datos RabbitMQ

/var/log/koha-docker/            # Logs del sistema
├── koha/                       # Logs de Koha
├── mariadb/                    # Logs de MariaDB
└── nginx/                      # Logs de Nginx

/opt/koha-docker/backups/        # Backups automáticos
```

## 💾 Sistema de Backup

### Backup Automático
- ⏰ **Programado**: Diariamente a las 2:00 AM
- 📁 **Ubicación**: `/opt/koha-docker/backups/`
- 🗂️ **Retención**: 30 días por defecto
- 📊 **Incluye**: Base de datos completa + configuraciones

### Backup Manual

```bash
# Backup inmediato
sudo /opt/koha-docker/prod/linux/koha-manage.sh backup

# Los backups se guardan en:
ls -la /opt/koha-docker/backups/
```

### Restaurar Backup

```bash
# Restaurar desde backup
sudo /opt/koha-docker/prod/linux/koha-manage.sh restore /ruta/al/backup.sql
```

## 🔧 Configuración Avanzada

### Variables de Entorno Principales

```bash
# Base de datos
KOHA_DB_NAME=koha_production
KOHA_DB_USER=pjnadmin_koha
KOHA_DB_PASSWORD=pjnadmin_db_2024!

# Koha
KOHA_LANGS=es-ES
KOHA_INSTANCE=biblioteca
TIMEZONE=America/Argentina/Buenos_Aires

# Rendimiento
MYSQL_INNODB_BUFFER_POOL_SIZE=1G
MYSQL_MAX_CONNECTIONS=200
MEMCACHED_MEMORY=256m

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"
```

### Configuración de Dominio

Para usar dominios propios, edita `.env`:

```bash
KOHA_DOMAIN=biblioteca.tu-dominio.com
OPAC_DOMAIN=catalogo.tu-dominio.com
```

Y configura tu DNS para apuntar a la IP del servidor.

### SSL/HTTPS

Para habilitar SSL:

1. Obtén certificados SSL
2. Copia los certificados a `/opt/koha-docker/ssl/`
3. Edita `.env`:
   ```bash
   SSL_ENABLED=true
   SSL_CERT_PATH=/opt/koha-docker/ssl/cert.pem
   SSL_KEY_PATH=/opt/koha-docker/ssl/key.pem
   ```
4. Reinicia los servicios

## 🔍 Monitoreo y Logs

### Ver Logs en Tiempo Real

```bash
# Todos los servicios
sudo docker compose logs -f

# Servicio específico
sudo docker compose logs -f koha
sudo docker compose logs -f mariadb
```

### Ubicación de Logs

```bash
# Logs de aplicación
tail -f /var/log/koha-docker/koha/koha.log

# Logs de base de datos
tail -f /var/log/koha-docker/mariadb/error.log

# Logs de acceso web
tail -f /var/log/koha-docker/nginx/access.log
```

### Métricas del Sistema

```bash
# Estado de contenedores
sudo docker stats

# Uso de volúmenes
sudo docker system df

# Información del sistema
sudo /opt/koha-docker/prod/linux/koha-manage.sh report
```

## 🆘 Solución de Problemas

### Problemas Comunes

#### 1. Servicios no inician
```bash
# Verificar logs
sudo journalctl -u koha-docker -f

# Verificar Docker
sudo systemctl status docker

# Verificar configuración
sudo docker compose config
```

#### 2. Error de conexión a base de datos
```bash
# Verificar estado de MariaDB
sudo docker compose logs mariadb

# Verificar conectividad
sudo docker exec koha-mariadb mariadb -u root -p
```

#### 3. Problemas de permisos
```bash
# Restaurar permisos
sudo chown -R koha:koha-docker /opt/koha-docker
sudo chown -R koha:koha-docker /var/log/koha-docker
```

#### 4. Puerto ocupado
```bash
# Verificar puertos en uso
sudo netstat -tulpn | grep :8080
sudo netstat -tulpn | grep :8081

# Cambiar puertos en .env si es necesario
```

### Comandos de Diagnóstico

```bash
# Estado completo del sistema
sudo /opt/koha-docker/prod/linux/koha-manage.sh status

# Logs de systemd
sudo journalctl -u koha-docker --since "1 hour ago"

# Verificar recursos
free -h
df -h
sudo docker stats --no-stream
```

## 🔄 Actualización del Sistema

### Actualizar Koha Docker

```bash
# Actualización automática (incluye backup)
sudo /opt/koha-docker/prod/linux/koha-manage.sh update

# O manualmente:
cd /opt/koha-docker
sudo docker compose pull
sudo docker compose up -d
```

### Actualizar Configuraciones

```bash
# Descargar nuevas configuraciones
cd /opt/koha-docker
sudo git pull

# Reiniciar servicios
sudo systemctl restart koha-docker
```

## 🔒 Seguridad

### Configuración de Firewall

El script de instalación configura ufw automáticamente, pero puedes ajustarlo:

```bash
# Ver reglas actuales
sudo ufw status

# Permitir acceso desde red específica
sudo ufw allow from 192.168.1.0/24 to any port 8080
sudo ufw allow from 192.168.1.0/24 to any port 8081

# Bloquear acceso público a RabbitMQ Management
sudo ufw deny 15672
```

### Cambiar Contraseñas por Defecto

```bash
# Editar archivo de configuración
sudo nano /opt/koha-docker/.env

# Cambiar todas las variables que contienen "pjnadmin_"
# Reiniciar servicios después del cambio
sudo systemctl restart koha-docker
```

### Backup de Seguridad

```bash
# Backup completo del sistema
sudo tar -czf /tmp/koha-full-backup.tar.gz \
    /opt/koha-docker \
    /var/log/koha-docker \
    /etc/systemd/system/koha-docker.service
```

## 📞 Soporte

### Documentación Adicional
- [Manual Oficial de Koha](https://koha-community.org/manual/24.11/en/html/)
- [Repositorio GitHub](https://github.com/matiasgel/koha-docker)
- [Wiki de Koha](https://wiki.koha-community.org/)

### Logs para Soporte

Si necesitas ayuda, incluye:

```bash
# Generar reporte completo
sudo /opt/koha-docker/prod/linux/koha-manage.sh report

# Información del sistema
uname -a
docker version
docker compose version
```

---

## ✅ Checklist Post-Instalación

- [ ] Servicios iniciados correctamente
- [ ] Acceso web funcionando (8080, 8081)
- [ ] Contraseñas cambiadas por defecto
- [ ] Backup automático configurado
- [ ] Firewall configurado
- [ ] Dominio configurado (si aplica)
- [ ] SSL configurado (si aplica)
- [ ] Monitoreo configurado
- [ ] Documentación leída

¡Tu instalación de Koha Docker en Debian 13 está lista para producción! 🎉