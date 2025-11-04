# 🐧 Despliegue de Koha Linux desde Windows

Scripts para preparar y desplegar Koha Docker en un servidor Linux desde un sistema Windows.

## 📋 Descripción

Este conjunto de scripts permite:
- ✅ **Generar configuración completa** desde Windows
- ✅ **Crear volúmenes persistentes** automáticamente  
- ✅ **Configurar SSL** con certificados auto-firmados
- ✅ **Desplegar en producción** con un solo comando
- ✅ **Monitoreo básico** integrado

## 🚀 Uso Rápido

### Paso 1: Preparación desde Windows

```powershell
# Ejecutar desde el directorio raíz del proyecto koha-docker
.\prepare-linux-deployment.ps1 -DomainName "biblioteca.miorganizacion.com" -OpacDomain "catalogo.miorganizacion.com"
```

**Parámetros disponibles:**
- `-DomainName`: Dominio para la interfaz administrativa (default: biblioteca.local)
- `-OpacDomain`: Dominio para el catálogo público (default: catalogo.local)  
- `-InstallPath`: Ruta de instalación en Linux (default: /opt/koha-docker)
- `-OutputDir`: Directorio local de salida (default: koha-linux-deployment)

### Paso 2: Transferir al servidor Linux

```bash
# Comprimir y transferir archivos
zip -r koha-deployment.zip koha-linux-deployment/
scp koha-deployment.zip usuario@servidor-linux:/tmp/

# En el servidor Linux
cd /tmp
unzip koha-deployment.zip
cd koha-linux-deployment
```

### Paso 3: Ejecutar setup en Linux

```bash
# Hacer ejecutables los scripts
chmod +x *.sh

# Ejecutar setup inicial (como root)
sudo ./setup.sh

# Inicializar Koha  
sudo ./init.sh
```

## 📁 Archivos Generados

El script genera la siguiente estructura:

```
koha-linux-deployment/
├── .env                    # Variables de entorno con passwords seguros
├── docker-compose.yml      # Configuración Docker optimizada para Linux
├── setup.sh               # Script de setup inicial del sistema
├── init.sh                # Script de inicialización de Koha
├── manage.sh              # Script de gestión diaria
├── config/                # Configuraciones de servicios
├── files/                 # Archivos base de Koha
└── ssl/                   # Directorio para certificados SSL
```

## 🔐 Credenciales Generadas

El script genera automáticamente passwords seguros para:

- **Base de datos Koha**: Usuario `koha_admin`
- **MySQL Root**: Usuario `root`  
- **RabbitMQ**: Usuario `koha`
- **Admin Koha**: Usuario `koha_admin` (interfaz web)

**⚠️ Importante**: Guarda las credenciales mostradas al final de la ejecución.

## 🛠️ Scripts de Gestión

Una vez instalado, puedes usar:

```bash
# Gestión básica
sudo ./manage.sh start      # Iniciar servicios
sudo ./manage.sh stop       # Detener servicios  
sudo ./manage.sh restart    # Reiniciar servicios
sudo ./manage.sh status     # Ver estado

# Diagnóstico
sudo ./manage.sh logs       # Ver todos los logs
sudo ./manage.sh logs koha  # Ver logs de Koha específicamente

# Mantenimiento
sudo ./manage.sh backup     # Crear backup
sudo ./manage.sh update     # Actualizar imágenes

# Monitoreo
koha-status.sh             # Ver estado completo del sistema
```

## 🌐 Acceso Web

Después de la inicialización exitosa:

- **OPAC (Catálogo)**: `http://tu-dominio:8080`
- **Staff Interface**: `http://tu-dominio:8081`

## 📊 Características del Despliegue

### Volúmenes Persistentes
- ✅ `koha-etc`: Configuraciones de Koha
- ✅ `koha-var`: Datos de la aplicación  
- ✅ `koha-logs`: Logs del sistema
- ✅ `koha-uploads`: Archivos subidos por usuarios
- ✅ `koha-plugins`: Plugins instalados
- ✅ `mariadb-data`: Base de datos
- ✅ `rabbitmq-data`: Datos de RabbitMQ

### Servicios Configurados
- 🗄️ **MariaDB 11**: Base de datos optimizada
- 🐰 **RabbitMQ 3**: Cola de mensajes con management UI
- 🗃️ **Memcached**: Cache en memoria
- 📚 **Koha 24.11**: Sistema bibliotecario con soporte español

### Seguridad
- 🔒 Passwords generados automáticamente
- 🌐 Servicios expuestos solo en localhost
- 🔐 SSL configurado (certificados auto-firmados)
- 👤 Usuario de sistema dedicado (`koha`)

## 🐛 Resolución de Problemas

### Koha no responde
```bash
# Ver logs
sudo ./manage.sh logs koha

# Reiniciar servicio específico
docker compose restart koha
```

### Base de datos no conecta
```bash
# Verificar estado de MariaDB
docker compose ps db
docker compose logs db

# Reiniciar base de datos
docker compose restart db
```

### Puertos ocupados
```bash
# Verificar qué usa los puertos
sudo netstat -tulpn | grep :808
sudo lsof -i :8080
sudo lsof -i :8081
```

### Volúmenes corruptos
```bash
# Ver volúmenes
docker volume ls | grep koha

# Recrear volumen específico (⚠️ PIERDE DATOS)
docker volume rm koha-logs
docker volume create koha-logs
```

## 📋 Requisitos del Sistema Linux

- **OS**: Debian 12+, Ubuntu 20.04+, RHEL 8+
- **RAM**: Mínimo 4GB, recomendado 8GB+
- **Almacenamiento**: Mínimo 20GB libres
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

## 🔄 Backup y Restauración

### Backup Manual
```bash
# Backup completo
sudo ./manage.sh backup

# Backup solo base de datos
docker compose exec db mariadb-dump -u root -p koha_production > backup-db.sql
```

### Migración a Nuevo Servidor
1. Crear backup en servidor origen
2. Ejecutar `prepare-linux-deployment.ps1` en Windows
3. Transferir backup + archivos generados al nuevo servidor  
4. Ejecutar `setup.sh` e `init.sh`
5. Restaurar backup de datos

## 📞 Soporte

Para problemas específicos:
1. Revisar logs: `sudo ./manage.sh logs`
2. Verificar estado: `koha-status.sh`
3. Consultar documentación oficial: https://koha-community.org/
4. Issues del proyecto: https://github.com/matiasgel/koha-docker