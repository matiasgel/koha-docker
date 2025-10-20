# Guía Completa de Instalación de Koha con Docker

## Tabla de Contenidos
1. [Información General](#información-general)
2. [Requisitos del Sistema](#requisitos-del-sistema)
3. [Componentes de la Arquitectura](#componentes-de-la-arquitectura)
4. [Instalación Paso a Paso](#instalación-paso-a-paso)
5. [Configuración del Web Installer](#configuración-del-web-installer)
6. [Configuración del Onboarding Tool](#configuración-del-onboarding-tool)
7. [Acceso a las Interfaces](#acceso-a-las-interfaces)
8. [Solución de Problemas](#solución-de-problemas)
9. [Configuración de Producción](#configuración-de-producción)
10. [Mantenimiento y Backups](#mantenimiento-y-backups)

---

## Información General

### ¿Qué es Koha?
Koha es un sistema integrado de gestión bibliotecaria (ILS) de código abierto desarrollado inicialmente en 1999. Es utilizado por bibliotecas de todo el mundo para gestionar catálogos, circulación, adquisiciones, seriales y más.

### Características principales:
- **OPAC (Online Public Access Catalog)**: Interfaz pública para búsqueda de usuarios
- **Staff Interface**: Interfaz de administración para bibliotecarios
- **Sistema de circulación**: Préstamos, devoluciones, reservas
- **Gestión de adquisiciones**: Compras y proveedores
- **Sistema de reportes**: Reportes estadísticos y administrativos
- **Multidioma**: Soporte para múltiples idiomas
- **Z39.50/SRU**: Importación de registros bibliográficos
- **APIs REST**: Integración con sistemas externos

### Arquitectura Docker de este proyecto:
Este proyecto utiliza la imagen `teogramm/koha:24.11` que incluye:
- **Apache webserver** configurado con Plack
- **Zebra server** para búsqueda (o Elasticsearch como alternativa)
- **Worker de background jobs** para procesos asíncronos
- **Indexador Zebra** para mantener el índice de búsqueda actualizado

---

## Requisitos del Sistema

### Hardware Mínimo:
- **CPU**: 2 cores
- **RAM**: 4GB mínimo, 8GB recomendado
- **Almacenamiento**: 20GB mínimo para desarrollo, 100GB+ para producción
- **Red**: Conexión a internet para descargar imágenes

### Software Requerido:
- **Docker**: Versión 20.10 o superior
- **Docker Compose**: Versión 2.0 o superior
- **Sistema Operativo**: Linux (recomendado), Windows con WSL2, o macOS

### Puertos utilizados:
- **8080**: OPAC (Interfaz pública)
- **8081**: Staff Interface (Interfaz de administración)
- **3306**: MariaDB
- **15672**: RabbitMQ Management UI
- **5672**: RabbitMQ AMQP
- **61613**: RabbitMQ STOMP

---

## Componentes de la Arquitectura

### 1. Contenedor Koha
- **Imagen**: `teogramm/koha:24.11`
- **Función**: Aplicación principal de Koha
- **Servicios incluidos**:
  - Apache HTTP Server con mod_perl
  - Zebra Server para indexación
  - Worker para jobs en background
  - Plack para mejor rendimiento

### 2. Base de Datos MariaDB
- **Imagen**: `mariadb:11`
- **Función**: Almacenamiento de datos
- **Configuración**:
  - Charset: utf8mb4
  - Collation: utf8mb4_unicode_ci
  - InnoDB como motor de almacenamiento

### 3. Cache Memcached
- **Imagen**: `memcached:1.6-alpine`
- **Función**: Cache en memoria para mejorar rendimiento
- **Configuración**: 64MB por defecto

### 4. Message Broker RabbitMQ
- **Imagen**: `rabbitmq:3-management`
- **Función**: Gestión de tareas en background
- **Plugins requeridos**: stomp, management

---

## Instalación Paso a Paso

### Paso 1: Preparación del entorno

1. **Crear directorio de trabajo**:
```bash
mkdir koha-docker && cd koha-docker
```

2. **Clonar o descargar archivos de configuración**:
   - Asegúrate de tener los archivos `docker-compose.yaml` y `rabbitmq_plugins`

3. **Configurar plugins de RabbitMQ**:
```bash
# Crear archivo rabbitmq_plugins
echo "rabbitmq_management." > rabbitmq_plugins
echo "rabbitmq_stomp." >> rabbitmq_plugins
```

### Paso 2: Configuración Básica (Desarrollo/Testing)

1. **Usar la configuración de ejemplos**:
```bash
cd examples
```

2. **Verificar docker-compose.yaml**:
```yaml
version: "3.9"
services:
  koha:
    image: teogramm/koha:24.11
    ports:
      - 8080:8080  # OPAC
      - 8081:8081  # Staff Interface
    environment:
      MYSQL_SERVER: db
      MYSQL_USER: koha_teolib
      MYSQL_PASSWORD: example
      DB_NAME: koha_teolib
      MEMCACHED_SERVERS: memcached:11211
      MB_HOST: rabbitmq
      KOHA_LANGS: "es-ES"  # Configurar idiomas (opcional)
    depends_on:
      - db
      - rabbitmq
      - memcached

  rabbitmq:
    image: rabbitmq:3
    volumes:
      - ./rabbitmq_plugins:/etc/rabbitmq/enabled_plugins

  db:
    image: mariadb:11
    environment:
      MARIADB_ROOT_PASSWORD: example
      MARIADB_DATABASE: koha_teolib
      MARIADB_USER: koha_teolib
      MARIADB_PASSWORD: example

  memcached:
    image: memcached
```

### Configuración de Idiomas
Para instalar idiomas adicionales, usar la variable `KOHA_LANGS`:
- **Un idioma**: `KOHA_LANGS: "es-ES"`
- **Múltiples idiomas**: `KOHA_LANGS: "es-ES en-GB fr-FR"`
- **Idiomas disponibles**: Consultar [lista completa](#idiomas-disponibles)

> **IMPORTANTE**: Si cambias los idiomas después de la primera instalación, debes eliminar el volumen de la base de datos:
> ```bash
> docker-compose down
> docker volume rm examples_mariadb-koha
> docker-compose up -d
> ```

### Paso 3: Iniciar los servicios

1. **Levantar los contenedores**:
```bash
docker-compose up -d
```

2. **Verificar que los servicios estén corriendo**:
```bash
docker-compose ps
```

3. **Verificar logs si hay problemas**:
```bash
docker-compose logs koha
docker-compose logs db
```

### Paso 4: Esperar inicialización
- **Primera vez**: 2-5 minutos para que MariaDB y Koha se inicialicen completamente
- **Verificar estado**: Acceder a http://localhost:8081

---

## Configuración del Web Installer

### Paso 1: Acceso inicial
1. **Abrir navegador** en: http://localhost:8081
2. **Pantalla de login del Web Installer** aparecerá automáticamente

### Paso 2: Credenciales de acceso
**DATOS DE ACCESO CRÍTICOS**:
- **Usuario**: `koha_teolib` (mismo que MYSQL_USER)
- **Contraseña**: `example` (mismo que MYSQL_PASSWORD)

> **NOTA IMPORTANTE**: Las credenciales del web installer son las mismas que las configuradas en la base de datos, NO credenciales personalizadas.

### Paso 3: Proceso del Web Installer

#### 3.1 Selección de idioma
- Seleccionar idioma preferido para la instalación
- Hacer clic en "Continue to the next step"

#### 3.2 Verificación de módulos Perl
- Verificar que todos los módulos requeridos estén instalados
- Hacer clic en "Continue to the next step"

#### 3.3 Configuración de base de datos
- **Verificar configuración**:
  - Database server: `db`
  - Database: `koha_teolib`
  - Database user: `koha_teolib`
  - Password: `example`
- Hacer clic en "Continue to the next step"

#### 3.4 Instalación de tablas
- Confirmar creación de tablas
- **Tiempo estimado**: 2-5 minutos
- Hacer clic en "Continue to the next step"

#### 3.5 Selección de MARC flavour
- **MARC21**: Recomendado para uso general
- **UNIMARC**: Principalmente usado en Europa
- Hacer clic en "Continue to the next step"

#### 3.6 Configuración de datos iniciales
**Datos obligatorios recomendados**:
- ✅ Default MARC21 bibliographic framework
- ✅ Default Koha system authorized values
- ✅ Default classification sources
- ✅ Default message transports
- ✅ Sample notices
- ✅ Enhanced messaging configuration

**Datos opcionales útiles**:
- ✅ Sample patron types and categories
- ✅ Sample item types
- ✅ Sample libraries (para desarrollo/testing)
- ✅ Sample patrons (para desarrollo/testing)
- ✅ Z39.50 servers access

### Paso 4: Finalización del Web Installer
- Hacer clic en "Import" para instalar los datos seleccionados
- Esperar confirmación de instalación exitosa
- Hacer clic en "Set up some of Koha's basic requirements"

---

## Configuración del Onboarding Tool

### Paso 1: Crear biblioteca
- **Library code**: Código de hasta 10 caracteres (ej: "MAIN")
- **Name**: Nombre de la biblioteca (ej: "Biblioteca Principal")

### Paso 2: Crear categoría de usuario
- **Category code**: Código de hasta 10 caracteres (ej: "STAFF")
- **Description**: Descripción (ej: "Personal de la biblioteca")
- **Category type**: Staff
- **Enrollment period**: 12 meses

### Paso 3: Crear usuario administrador
**IMPORTANTE**: Documentar estas credenciales cuidadosamente

- **Surname**: Apellido del administrador
- **First name**: Nombre del administrador
- **Card number**: Número único (ej: "ADMIN001")
- **Library**: Seleccionar biblioteca creada
- **Patron category**: Seleccionar categoría STAFF
- **Username**: Usuario para login (ej: "admin")
- **Password**: Contraseña segura (mínimo 8 caracteres)
- **Permissions**: Superlibrarian (automático)

### Paso 4: Crear tipo de material
- **Item type code**: Código (ej: "BOOK")
- **Description**: Descripción (ej: "Libros")

### Paso 5: Configurar reglas de circulación
- **Current checkouts allowed**: 50
- **Loan period**: 14 días
- **Renewals allowed**: 10
- **Renewals period**: 14 días

---

## Acceso a las Interfaces

### OPAC (Catálogo Público)
- **URL**: http://localhost:8080
- **Usuarios**: Acceso público, usuarios registrados

### Staff Interface (Administración)
- **URL**: http://localhost:8081
- **Usuarios**: Personal con credenciales creadas en onboarding
- **Funciones**: Catalogación, circulación, administración

### RabbitMQ Management (Monitoreo)
- **URL**: http://localhost:15672
- **Usuario**: koha
- **Contraseña**: Configurada en docker-compose

---

## Solución de Problemas

### Problema 1: No se puede acceder al web installer
**Síntomas**:
- Error 500 o página no carga
- Conexión rechazada

**Soluciones**:
1. Verificar que todos los contenedores estén corriendo:
   ```bash
   docker-compose ps
   ```
2. Revisar logs de Koha:
   ```bash
   docker-compose logs koha
   ```
3. Verificar conectividad de base de datos:
   ```bash
   docker-compose exec koha ping db
   ```

### Problema 2: Error de autenticación en web installer
**Síntomas**:
- "Invalid username or password"
- No acepta credenciales

**Soluciones**:
1. **Verificar credenciales correctas**:
   - Usuario: valor de `MYSQL_USER` del docker-compose
   - Contraseña: valor de `MYSQL_PASSWORD` del docker-compose
2. **Verificar variables de entorno**:
   ```bash
   docker-compose exec koha env | grep MYSQL
   ```
3. **Reiniciar contenedores si es necesario**:
   ```bash
   docker-compose restart
   ```

### Problema 3: Base de datos no responde
**Síntomas**:
- Error de conexión a base de datos
- Timeout en conexiones

**Soluciones**:
1. Verificar logs de MariaDB:
   ```bash
   docker-compose logs db
   ```
2. Verificar espacio en disco:
   ```bash
   docker system df
   ```
3. Reiniciar servicio de base de datos:
   ```bash
   docker-compose restart db
   ```

### Problema 4: Rendimiento lento
**Síntomas**:
- Páginas cargan lentamente
- Timeouts frecuentes

**Soluciones**:
1. Verificar recursos del sistema:
   ```bash
   docker stats
   ```
2. Optimizar configuración de MariaDB
3. Aumentar memoria asignada a contenedores

---

## Configuración de Producción

### Diferencias con desarrollo

1. **Archivos separados**:
   - Usar `docker-compose.prod.yaml`
   - Variables de entorno en archivo `.env`

2. **Volúmenes persistentes**:
   ```yaml
   volumes:
     - db_data:/var/lib/mysql
     - koha_etc:/etc/koha
     - koha_logs:/var/log/koha
     - koha_uploads:/var/lib/koha/uploads
   ```

3. **Configuración de seguridad**:
   - Contraseñas fuertes en variables de entorno
   - Firewall configurado
   - Acceso restringido a puertos de gestión

4. **Configuración de red**:
   - Proxy reverso (nginx/Apache)
   - SSL/TLS habilitado
   - Dominios propios

### Ejemplo de configuración de producción

1. **Crear archivo .env**:
```bash
# Database
KOHA_DB_PASSWORD=password_muy_segura_para_bd
MARIADB_ROOT_PASSWORD=password_root_muy_segura

# RabbitMQ
RABBITMQ_PASSWORD=password_rabbitmq_segura

# Koha
KOHA_DOMAIN=biblioteca.midominio.com
TZ=America/Mexico_City
```

2. **Usar docker-compose.prod.yaml**:
```bash
docker-compose -f docker-compose.prod.yaml up -d
```

---

## Mantenimiento y Backups

### Backup de base de datos
```bash
# Backup
docker-compose exec db mysqldump -u root -p koha_production > backup_$(date +%Y%m%d).sql

# Restore
docker-compose exec -i db mysql -u root -p koha_production < backup_20250101.sql
```

### Backup de volúmenes
```bash
# Crear backup de todos los volúmenes
docker run --rm -v koha_etc:/data -v $(pwd):/backup alpine tar czf /backup/koha_etc_backup.tar.gz -C /data .
```

### Monitoreo
1. **Logs de aplicación**:
   ```bash
   docker-compose logs -f koha
   ```

2. **Métricas de contenedores**:
   ```bash
   docker stats
   ```

3. **Estado de servicios**:
   ```bash
   docker-compose ps
   ```

### Actualizaciones
1. **Actualizar imágenes**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

2. **Verificar compatibilidad** antes de actualizar en producción

---

## Referencias y Enlaces Útiles

### Documentación oficial:
- [Manual de Koha 24.11](https://koha-community.org/manual/24.11/en/html/installation.html)
- [Koha Community](https://koha-community.org/)
- [Wiki de Koha](https://wiki.koha-community.org/)

### Recursos Docker:
- [Docker Hub - teogramm/koha](https://hub.docker.com/r/teogramm/koha)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

### Soporte:
- [Bug Tracker de Koha](https://bugs.koha-community.org/)
- [Mailing Lists](https://koha-community.org/support/)
- [IRC Channel: #koha](https://web.libera.chat/#koha)

---

## Notas Importantes de Seguridad

⚠️ **ADVERTENCIAS DE SEGURIDAD**:

1. **Cambiar contraseñas por defecto** antes de usar en producción
2. **No usar credenciales del ejemplo** en entornos públicos
3. **Configurar firewall** para restringir acceso a puertos de gestión
4. **Usar SSL/TLS** para acceso web en producción
5. **Realizar backups regulares** de base de datos y configuración
6. **Monitorear logs** para detectar accesos no autorizados

---

## Idiomas Disponibles

Koha 24.11 incluye soporte para los siguientes idiomas. Para configurarlos, usar la variable `KOHA_LANGS` en docker-compose:

### Idiomas Principales:
- **es-ES**: Español (España)
- **en-GB**: Inglés (Reino Unido)
- **fr-FR**: Francés (Francia)
- **de-DE**: Alemán (Alemania)
- **it-IT**: Italiano (Italia)
- **pt-BR**: Portugués (Brasil)
- **pt-PT**: Portugués (Portugal)
- **ca-ES**: Catalán (España)

### Idiomas Asiáticos:
- **zh-Hans-CN**: Chino Simplificado
- **zh-Hant-TW**: Chino Tradicional (Taiwán)
- **ja-Jpan-JP**: Japonés
- **ko-Kore-KP**: Coreano
- **hi**: Hindi
- **ar-Arab**: Árabe
- **fa-Arab**: Persa
- **th-TH**: Tailandés

### Idiomas Europeos:
- **ru-RU**: Ruso
- **pl-PL**: Polaco
- **nl-NL**: Holandés
- **sv-SE**: Sueco
- **nb-NO**: Noruego Bokmål
- **da-DK**: Danés
- **fi-FI**: Finlandés
- **cs-CZ**: Checo
- **hu-HU**: Húngaro
- **tr-TR**: Turco
- **el-GR**: Griego
- **bg-Cyrl**: Búlgaro
- **hr-HR**: Croata
- **sk-SK**: Eslovaco
- **ro-RO**: Rumano
- **uk-UA**: Ucraniano

### Otros Idiomas:
- **fr-CA**: Francés (Canadá)
- **en-NZ**: Inglés (Nueva Zelanda)
- **ms-MY**: Malayo
- **id-ID**: Indonesio
- **vi-VN**: Vietnamita

### Ejemplo de Configuración Multiidioma:
```yaml
environment:
  KOHA_LANGS: "es-ES en-GB fr-FR"
```

> **Nota**: La instalación de múltiples idiomas aumenta el tiempo de inicio del contenedor y el espacio requerido.

---

## Conclusión

Esta guía proporciona los pasos necesarios para instalar y configurar Koha usando Docker. Para entornos de producción, es crucial seguir las mejores prácticas de seguridad y realizar pruebas exhaustivas antes del despliegue.

Para soporte adicional, consultar la documentación oficial de Koha y la comunidad activa de usuarios y desarrolladores.
