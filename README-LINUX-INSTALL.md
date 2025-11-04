# 🐧 Instalación de Koha Docker en Linux desde Repositorio

## 📋 Descripción

Scripts para instalar Koha Docker en Linux de forma completamente automatizada usando volúmenes persistentes. El proceso incluye limpieza completa, creación de estructura de datos y inicialización de servicios.

## 🚀 Proceso de Instalación

### Paso 1: Clonar Repositorio en Linux

```bash
# En el servidor Linux de destino
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker
```

### Paso 2: Configurar Variables de Entorno

```bash
# Copiar plantilla de configuración
cp .env.production .env

# Editar configuración (IMPORTANTE: cambiar passwords)
nano .env
```

**Variables críticas a configurar:**
```bash
# Cambiar TODAS las contraseñas
KOHA_DB_PASSWORD=TU_PASSWORD_SEGURO_DB
MYSQL_ROOT_PASSWORD=TU_PASSWORD_ROOT_SEGURO  
RABBITMQ_PASSWORD=TU_PASSWORD_RABBITMQ
KOHA_ADMIN_PASSWORD=TU_PASSWORD_ADMIN

# Configurar dominios
KOHA_DOMAIN=biblioteca.tudominio.com
OPAC_DOMAIN=catalogo.tudominio.com

# Configurar biblioteca
KOHA_LIBRARY_NAME=Tu Biblioteca
```

### Paso 3: Ejecutar Setup (Limpieza y Preparación)

```bash
# Hacer ejecutables los scripts
chmod +x setup.sh init.sh

# Ejecutar setup como root (limpia todo y prepara)
sudo ./setup.sh
```

**El setup.sh realiza:**
- ✅ Limpia contenedores e imágenes Koha existentes
- ✅ Elimina volúmenes anteriores (con confirmación)
- ✅ Crea estructura de directorios para volúmenes persistentes
- ✅ Configura usuarios y permisos del sistema
- ✅ Genera certificados SSL auto-firmados
- ✅ Configura servicios systemd
- ✅ Crea scripts de monitoreo

### Paso 4: Inicializar Servicios

```bash
# Inicializar Koha (como root)
sudo ./init.sh
```

**El init.sh realiza:**
- ✅ Descarga imágenes Docker
- ✅ Inicializa base de datos MariaDB
- ✅ Configura RabbitMQ con usuario Koha
- ✅ Inicia Memcached
- ✅ Levanta servicio principal de Koha
- ✅ Verifica conectividad y estado de servicios

### Paso 5: Completar Instalación Web

1. Acceder al Staff Interface: `http://tu-servidor:8081`
2. Usar credenciales configuradas en `.env`
3. Seguir asistente web de instalación de Koha
4. Configurar biblioteca y parámetros del sistema

## 📁 Estructura de Archivos Creada

```
/opt/koha-docker/                    # Directorio principal
├── .env                            # Variables de entorno
├── docker-compose.production.yml   # Configuración Docker
├── setup.sh                       # Script de limpieza y setup
├── init.sh                        # Script de inicialización
├── manage.sh                      # Script de gestión diaria
├── ssl/                           # Certificados SSL
└── data/                          # Datos persistentes
    ├── koha/                      # Datos de Koha
    │   ├── etc/                   # Configuraciones
    │   ├── var/                   # Datos de aplicación
    │   ├── logs/                  # Logs de Koha
    │   ├── uploads/               # Archivos subidos
    │   └── plugins/               # Plugins instalados
    ├── mariadb/                   # Base de datos
    │   ├── data/                  # Datos MySQL
    │   └── conf/                  # Configuración MySQL
    └── rabbitmq/                  # Cola de mensajes
        ├── data/                  # Datos RabbitMQ
        └── conf/                  # Configuración RabbitMQ
```

## 🔧 Gestión Post-Instalación

### Scripts de Gestión

```bash
# Script principal de gestión
sudo /opt/koha-docker/manage.sh start     # Iniciar servicios
sudo /opt/koha-docker/manage.sh stop      # Detener servicios
sudo /opt/koha-docker/manage.sh restart   # Reiniciar servicios
sudo /opt/koha-docker/manage.sh status    # Ver estado
sudo /opt/koha-docker/manage.sh logs      # Ver logs
sudo /opt/koha-docker/manage.sh logs koha # Ver logs específicos

# Monitoreo del sistema
koha-status.sh                            # Estado completo del sistema
```

### Docker Compose Directo

```bash
cd /opt/koha-docker

# Usar el archivo de producción
sudo docker compose -f docker-compose.production.yml ps
sudo docker compose -f docker-compose.production.yml logs koha
sudo docker compose -f docker-compose.production.yml restart db
```

### Servicio Systemd

```bash
sudo systemctl start koha-docker     # Iniciar
sudo systemctl stop koha-docker      # Detener  
sudo systemctl status koha-docker    # Ver estado
sudo systemctl enable koha-docker    # Habilitar auto-inicio
```

## 🌐 Acceso a Servicios

### Interfaces Web

- **OPAC (Catálogo)**: http://tu-servidor:8080
- **Staff Interface**: http://tu-servidor:8081
- **RabbitMQ Management**: http://tu-servidor:15672

### Bases de Datos

```bash
# Acceso directo a MariaDB
sudo docker compose -f docker-compose.production.yml exec db mariadb -u root -p

# Backup manual de base de datos
sudo docker compose -f docker-compose.production.yml exec db mariadb-dump -u root -p koha_production > backup.sql
```

## 🔄 Backup y Restauración

### Backup Completo

```bash
# Backup automático (si está configurado)
sudo /opt/koha-docker/manage.sh backup

# Backup manual de volúmenes
sudo tar -czf koha-backup-$(date +%Y%m%d).tar.gz -C /opt/koha-docker data/

# Backup solo base de datos
sudo docker compose -f docker-compose.production.yml exec db mariadb-dump \
  -u root -p koha_production > koha-db-$(date +%Y%m%d).sql
```

### Restauración

```bash
# Detener servicios
sudo ./manage.sh stop

# Restaurar volúmenes (cuidado: sobrescribe datos)
sudo tar -xzf koha-backup-YYYYMMDD.tar.gz -C /opt/koha-docker

# Restaurar solo base de datos
cat koha-db-YYYYMMDD.sql | sudo docker compose -f docker-compose.production.yml exec -T db mariadb -u root -p koha_production

# Reiniciar servicios
sudo ./init.sh
```

## 📊 Monitoreo y Logs

### Verificación de Estado

```bash
# Estado completo
koha-status.sh

# Estado Docker
sudo docker compose -f docker-compose.production.yml ps

# Uso de recursos
sudo docker stats

# Volúmenes persistentes
sudo docker volume ls | grep koha
```

### Logs

```bash
# Logs en tiempo real
sudo docker compose -f docker-compose.production.yml logs -f

# Logs específicos por servicio
sudo docker compose -f docker-compose.production.yml logs koha
sudo docker compose -f docker-compose.production.yml logs db
sudo docker compose -f docker-compose.production.yml logs rabbitmq

# Logs del sistema en archivos
sudo tail -f /opt/koha-docker/data/koha/logs/*
sudo tail -f /var/log/koha-docker/*
```

## 🔧 Configuración Avanzada

### SSL con Certificados Válidos

```bash
# Reemplazar certificados auto-firmados
sudo cp tu-certificado.crt /opt/koha-docker/ssl/cert.pem
sudo cp tu-clave-privada.key /opt/koha-docker/ssl/key.pem
sudo chmod 644 /opt/koha-docker/ssl/cert.pem
sudo chmod 600 /opt/koha-docker/ssl/key.pem

# Reiniciar servicios
sudo ./manage.sh restart
```

### Configuración de Email

```bash
# Editar .env
nano /opt/koha-docker/.env

# Añadir configuración SMTP
SMTP_HOST=smtp.tudominio.com
SMTP_PORT=587
SMTP_USER=biblioteca@tudominio.com
SMTP_PASSWORD=tu_password_email
SMTP_TLS=true

# Reiniciar Koha
sudo docker compose -f docker-compose.production.yml restart koha
```

### Ajuste de Rendimiento

```bash
# Editar configuración en .env
KOHA_PLACK_WORKERS=4                    # Más workers para más concurrencia
KOHA_BACKGROUND_WORKERS=6               # Más workers para tareas background

# Para servidores con más RAM, ajustar límites
DB_MEMORY_LIMIT=4g                      # Límite de memoria para MariaDB
KOHA_MEMORY_LIMIT=2g                    # Límite de memoria para Koha
```

## 🐛 Resolución de Problemas

### Koha no Responde

```bash
# Verificar estado
sudo docker compose -f docker-compose.production.yml ps

# Ver logs detallados
sudo docker compose -f docker-compose.production.yml logs koha | tail -50

# Reiniciar solo Koha
sudo docker compose -f docker-compose.production.yml restart koha
```

### Base de Datos no Conecta

```bash
# Verificar MariaDB
sudo docker compose -f docker-compose.production.yml logs db

# Probar conexión manual
sudo docker compose -f docker-compose.production.yml exec db mariadb -u root -p

# Reiniciar base de datos
sudo docker compose -f docker-compose.production.yml restart db
```

### Volúmenes Corruptos

```bash
# Verificar volúmenes
sudo docker volume ls | grep koha
sudo docker volume inspect koha-data

# Recrear volumen específico (⚠️ PIERDE DATOS)
sudo docker volume rm koha-logs
sudo docker volume create koha-logs
```

### Limpiar Instalación Completa

```bash
# Detener todo
sudo ./manage.sh stop

# Ejecutar setup nuevamente (limpia todo)
sudo ./setup.sh

# Reinicializar
sudo ./init.sh
```

## 📋 Requisitos del Sistema

- **OS**: Debian 11+, Ubuntu 20.04+, CentOS 8+, RHEL 8+
- **RAM**: Mínimo 4GB, recomendado 8GB+
- **Almacenamiento**: Mínimo 50GB libres para datos
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Puertos**: 8080, 8081, 3306, 15672 disponibles

## 📞 Soporte

- **Documentación oficial**: https://koha-community.org/
- **Issues del proyecto**: https://github.com/matiasgel/koha-docker/issues
- **Estado del sistema**: `koha-status.sh`
- **Logs detallados**: `/opt/koha-docker/data/koha/logs/`