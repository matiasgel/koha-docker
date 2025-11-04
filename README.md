# Koha Docker con Soporte en Español 🇪🇸

![Koha](https://img.shields.io/badge/Koha-24.11-blue)
![Docker](https://img.shields.io/badge/Docker-Ready-green)
![Spanish](https://img.shields.io/badge/Idioma-Español-red)

Un setup completo de Koha con Docker que incluye:
* ✅ **Soporte completo en español** (es-ES)
* 🚀 **Scripts de backup automatizados**
* 📚 **Guía de instalación en español**
* 🐳 **Configuración Docker lista para producción**
* 🔧 **Herramientas de migración y restauración**

## 🎯 Características Principales

### 🐳 Contenedor Koha
- **Apache webserver** sirviendo OPAC (Puerto 8080) y Staff Interface (Puerto 8081)
- **Zebra server** e indexador para búsquedas
- **Background jobs worker** para procesos asíncronos
- **Plack** configurado para mejor rendimiento

### 🌐 Idiomas Soportados
- **Español (es-ES)** - Completamente traducido
- **Inglés (en-GB)** - Idioma por defecto
- **Múltiples idiomas** disponibles (ver documentación)

### 📦 Servicios Adicionales Requeridos
- **MySQL/MariaDB** server
- **Memcached** server  
- **RabbitMQ** server con plugin stomp habilitado

*Nota: Elasticsearch también es soportado como alternativa a Zebra.*

## 🚀 Inicio Rápido

### 📋 Requisitos Previos
- Docker y Docker Compose instalados
- Puertos 8080 y 8081 disponibles

### ⚡ Instalación Express (Desarrollo/Testing)
```bash
# Clonar repositorio
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker/examples

# Iniciar servicios
docker-compose up -d

# Esperar inicialización (2-3 minutos)
# Acceder a: http://localhost:8081
```

### 🏭 Instalación en Producción (Debian 13)
```bash
# Descargar instalador para Debian 13
curl -O https://raw.githubusercontent.com/matiasgel/koha-docker/main/prod/linux/install-debian13.sh

# Ejecutar instalación automática
chmod +x install-debian13.sh
sudo ./install-debian13.sh

# Configurar y iniciar
cd /opt/koha-docker
sudo nano .env  # Personalizar configuración
sudo systemctl start koha-docker
```

### 🔑 Credenciales de Acceso

#### Desarrollo (examples/)
- **Usuario**: `koha_teolib`
- **Contraseña**: `example`

#### Producción (Debian 13)
- **Usuario**: `pjnadmin_koha`
- **Contraseña**: `pjnadmin_db_2024!`

## 📚 Documentación

### 📖 Guías Disponibles
- **[📋 Guía de Instalación Completa](GUIA_INSTALACION_KOHA.md)** - Instalación paso a paso en español
- **[� Instalación en Linux](INSTALACION_LINUX.md)** - Guía específica para sistemas Linux
- **[�💾 Guía de Backup y Migración](backup-migration.md)** - Backup automático y migración
- **[📄 Documentación de Backup](README-BACKUP.md)** - Resumen visual de métodos de backup

### 🛠️ Scripts Incluidos
- **`backup-simple.ps1`** - Backup rápido para Windows (PowerShell)
- **`backup-simple-linux.sh`** - Backup rápido para Linux (Bash)
- **`backup-koha.ps1`** - Backup completo con volúmenes
- **`restore-koha.ps1`** - Restauración automatizada (Windows)
- **`restore-simple-linux.sh`** - Restauración para Linux
- **`monitor-koha.sh`** - Script de monitoreo para Linux
- **`migrate-to-github.ps1`** - Migración de repositorio

## 🏗️ Configuración

### 🔧 Variables de Entorno
Las principales variables están documentadas en [config-main.env](config-main.env).

**Variables importantes:**
- `KOHA_LANGS="es-ES"` - Configura idioma español
- `MYSQL_USER` y `MYSQL_PASSWORD` - Credenciales de base de datos
- `MEMCACHED_SERVERS` - Servidor de cache
- `MB_HOST` - Servidor RabbitMQ

### 📁 Logs
Los logs se almacenan en `/var/log/koha` dentro del contenedor.

## 🏭 Entorno de Producción

### 🐧 Linux (Recomendado para Producción)

Configuración completa y optimizada para servidores Linux:

```bash
# Instalación automatizada
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/prod/linux/install-prod.sh | sudo bash
```

**Características:**
- ✅ Nginx como proxy reverso con SSL
- ✅ Configuración optimizada de MariaDB
- ✅ Firewall y seguridad automática
- ✅ Backups programados
- ✅ Monitoreo del sistema
- ✅ Servicios systemd

📖 **[Ver documentación completa de Linux](prod/linux/README.md)**

### 🪟 Windows

Para producción, se recomienda usar la configuración en el directorio `prod/` que incluye:
- Volúmenes persistentes
- Configuración de seguridad mejorada
- Scripts de monitoreo
- Configuración optimizada de base de datos

```bash
cd prod/
docker-compose -f docker-compose.prod.yaml up -d
```

## 🔄 Backup y Migración

### Backup Rápido
```bash
# Linux
./backup-simple-linux.sh

# Windows
.\backup-simple.ps1
```

### Migración a Nueva Máquina
```bash
# Linux
./restore-simple-linux.sh backup.tar.gz

# Windows
.\restore-koha.ps1 -BackupFile "backup.zip"
```

## 🆘 Soporte

### 📞 Recursos de Ayuda
- [Manual Oficial de Koha](https://koha-community.org/manual/24.11/en/html/)
- [Comunidad Koha](https://koha-community.org/)
- [Wiki de Koha](https://wiki.koha-community.org/)

### 🐛 Problemas Comunes
- **Puerto ocupado**: Cambiar puertos en docker-compose.yaml
- **BD no responde**: Esperar más tiempo para inicialización
- **Error de idioma**: Verificar variable `KOHA_LANGS`

## 📄 Licencia

Este proyecto incluye configuraciones y mejoras sobre el trabajo original. Consulta [LICENSE](LICENSE) para más detalles.

## 🙏 Créditos

- **Imagen base**: [teogramm/koha](https://hub.docker.com/r/teogramm/koha) en Docker Hub
- **Scripts originales**: Basados en [koha-community/docker](https://gitlab.com/koha-community/docker/koha-docker)
- **Mejoras**: Soporte en español, scripts de backup, documentación completa

---

## ⭐ ¿Te resultó útil?

Si este proyecto te ayudó, considera:
- ⭐ Dar una estrella al repositorio
- 🐛 Reportar issues o sugerir mejoras
- 🤝 Contribuir con mejoras
- 📢 Compartir con otros bibliotecarios

