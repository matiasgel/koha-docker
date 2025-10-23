# Configuración de Producción Linux para Koha Docker

Este directorio contiene la configuración completa para ejecutar Koha Docker en un entorno de producción en Linux.

## 📁 Estructura de Archivos

```
prod/linux/
├── docker-compose.prod-linux.yaml    # Configuración principal de Docker Compose
├── .env.production                   # Template de variables de entorno
├── install-prod.sh                   # Script de instalación automatizada
├── config/                          # Configuraciones de servicios
│   ├── mariadb/my.cnf              # Configuración optimizada de MariaDB
│   ├── rabbitmq/                   # Configuración de RabbitMQ
│   └── nginx/                      # Configuración de Nginx como proxy
└── scripts/                        # Scripts de gestión
    ├── backup-full.sh              # Script de backup completo
    └── monitor.sh                  # Script de monitoreo del sistema
```

## 🚀 Instalación Rápida

### Método 1: Script Automatizado (Recomendado)

```bash
# Descargar e instalar
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/prod/linux/install-prod.sh | sudo bash
```

### Método 2: Instalación Manual

```bash
# 1. Crear directorio de instalación
sudo mkdir -p /opt/koha-docker
cd /opt/koha-docker

# 2. Descargar configuración
git clone https://github.com/matiasgel/koha-docker.git temp
sudo cp -r temp/prod/linux/* .
sudo rm -rf temp

# 3. Configurar permisos
sudo chown -R $(whoami):$(whoami) .
chmod +x scripts/*.sh

# 4. Configurar variables de entorno
cp .env.production .env
# Editar .env con tus configuraciones

# 5. Instalar Docker (si no está instalado)
curl -fsSL https://get.docker.com | sh

# 6. Iniciar servicios
docker compose -f docker-compose.prod-linux.yaml up -d
```

## ⚙️ Configuración

### Variables de Entorno Importantes

Edita el archivo `.env` y personaliza:

```bash
# Base de datos
KOHA_DB_NAME=koha_production
KOHA_DB_USER=koha_admin
KOHA_DB_PASSWORD=TU_PASSWORD_SEGURA

# Dominio
KOHA_DOMAIN=biblioteca.tudominio.com
OPAC_DOMAIN=catalogo.tudominio.com

# Rutas
DATA_PATH=/opt/koha-docker/data

# Zona horaria
TIMEZONE=America/Argentina/Buenos_Aires
```

### Certificados SSL

Por defecto se genera un certificado auto-firmado. Para producción:

```bash
# Copiar certificados válidos
sudo cp tu-certificado.crt ssl/cert.pem
sudo cp tu-clave-privada.key ssl/key.pem
sudo chmod 644 ssl/cert.pem
sudo chmod 600 ssl/key.pem
```

## 🛠️ Gestión del Sistema

### Scripts Disponibles

```bash
# Iniciar servicios
./scripts/start.sh

# Parar servicios
./scripts/stop.sh

# Ver estado
./scripts/status.sh

# Ejecutar backup
./scripts/backup.sh

# Monitoreo completo
./scripts/monitor.sh

# Monitoreo específico
./scripts/monitor.sh services    # Solo servicios
./scripts/monitor.sh database    # Solo base de datos
./scripts/monitor.sh health      # Solo puntuación de salud
```

### Servicio Systemd

```bash
# Habilitar inicio automático
sudo systemctl enable koha-docker

# Controlar servicio
sudo systemctl start koha-docker
sudo systemctl stop koha-docker
sudo systemctl status koha-docker
```

## 🔧 Arquitectura de Producción

### Servicios Incluidos

1. **Koha Container**
   - Imagen: `teogramm/koha:24.11`
   - Puertos: 8080 (OPAC), 8081 (Staff)
   - Volúmenes persistentes para configuración y datos

2. **MariaDB**
   - Imagen: `mariadb:11`
   - Configuración optimizada para Koha
   - Backup automático nocturno

3. **Nginx**
   - Proxy reverso con SSL
   - Rate limiting y seguridad
   - Compresión gzip

4. **RabbitMQ**
   - Gestión de trabajos en background
   - Management UI en puerto 15672

5. **Memcached**
   - Cache en memoria para mejor rendimiento

6. **Monitoring**
   - cAdvisor para métricas de contenedores
   - Scripts de monitoreo personalizados

### Red y Seguridad

- **Red interna**: Comunicación entre contenedores aislada
- **Firewall**: UFW configurado automáticamente
- **Fail2ban**: Protección contra ataques de fuerza bruta
- **SSL/TLS**: Terminación SSL en Nginx
- **Rate Limiting**: Protección contra DoS

## 📊 Monitoreo

### Acceso a Interfaces

- **Koha OPAC**: https://catalogo.tudominio.com
- **Koha Staff**: https://biblioteca.tudominio.com
- **RabbitMQ Management**: http://localhost:15672
- **cAdvisor**: http://localhost:8090

### Logs

```bash
# Ver logs en tiempo real
docker compose -f docker-compose.prod-linux.yaml logs -f

# Logs específicos
docker logs koha-prod
docker logs koha-db-prod
docker logs koha-nginx-prod
```

### Métricas

```bash
# Estado de recursos
docker stats

# Monitoreo completo
./scripts/monitor.sh

# Salud del sistema
./scripts/monitor.sh health
```

## 💾 Backup y Restauración

### Backup Automático

- **Programado**: Diariamente a las 2:00 AM
- **Retención**: 30 días por defecto
- **Incluye**: Base de datos, configuración, uploads, logs

### Backup Manual

```bash
# Backup completo
./scripts/backup.sh

# Backup solo de BD
docker exec koha-db-prod mariadb-dump -u root -p$MARIADB_ROOT_PASSWORD koha_production > backup.sql
```

### Restauración

```bash
# Restaurar base de datos
cat backup.sql | docker exec -i koha-db-prod mariadb -u root -p$MARIADB_ROOT_PASSWORD koha_production

# Restaurar volúmenes
docker run --rm -v koha-etc:/data -v /path/to/backup:/backup alpine tar xzf /backup/koha_etc_backup.tar.gz -C /data
```

## 🔧 Optimización

### Rendimiento de Base de Datos

El archivo `config/mariadb/my.cnf` incluye:
- Buffer pool de 2GB (ajustable)
- Configuración optimizada para Koha
- Logs de consultas lentas habilitados

### Rendimiento de Nginx

- Compresión gzip activada
- Cache de contenido estático
- Keep-alive optimizado
- Rate limiting configurado

### Monitoreo de Recursos

```bash
# Ver uso de recursos
./scripts/monitor.sh resources

# Métricas detalladas
docker exec koha-db-prod mariadb -u root -p$MARIADB_ROOT_PASSWORD -e "SHOW GLOBAL STATUS"
```

## 🆘 Solución de Problemas

### Problemas Comunes

#### Servicios no inician
```bash
# Verificar logs
docker compose -f docker-compose.prod-linux.yaml logs

# Verificar espacio en disco
df -h

# Verificar permisos
ls -la /opt/koha-docker/data/
```

#### Base de datos no responde
```bash
# Reiniciar solo la BD
docker compose -f docker-compose.prod-linux.yaml restart db

# Verificar conexión
docker exec koha-db-prod mariadb -u root -p$MARIADB_ROOT_PASSWORD -e "SELECT 1"
```

#### Problemas de SSL
```bash
# Verificar certificados
openssl x509 -in ssl/cert.pem -text -noout

# Regenerar certificado auto-firmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/key.pem -out ssl/cert.pem
```

### Contacto y Soporte

- **Documentación**: [README principal](../../README.md)
- **Issues**: [GitHub Issues](https://github.com/matiasgel/koha-docker/issues)
- **Comunidad Koha**: [koha-community.org](https://koha-community.org/)

## 📋 Checklist de Producción

Antes de poner en producción:

- [ ] Cambiar todas las contraseñas por defecto
- [ ] Configurar certificados SSL válidos
- [ ] Actualizar dominios en configuración de Nginx
- [ ] Configurar backup automático
- [ ] Probar restauración de backup
- [ ] Configurar monitoreo y alertas
- [ ] Documentar procedimientos específicos de tu organización
- [ ] Configurar notificaciones por email
- [ ] Verificar que el firewall esté activo
- [ ] Probar acceso desde red externa