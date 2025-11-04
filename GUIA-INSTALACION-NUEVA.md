# Guía de Instalación de Koha Docker en Nuevo Servidor

## ✅ Verificación Exitosa

Este proceso ha sido **probado y verificado** el 4 de noviembre de 2025.

La instalación completa desde cero funciona correctamente y tarda aproximadamente **2-3 minutos**.

---

## 📋 Requisitos Previos

### Software Necesario
- **Docker Engine** v24.0+ 
- **Docker Compose** v2.0+
- **Git** (para clonar el repositorio)
- **bash** (shell por defecto)

### Sistema Operativo
- Linux (probado en Debian/Ubuntu)
- CPU: 2 cores mínimo
- RAM: 4GB mínimo, 8GB recomendado
- Disco: 10GB mínimo para volúmenes persistentes

### Red
- Puerto **8080** libre (OPAC - catálogo público)
- Puerto **8081** libre (Staff Interface - interfaz administrativa)
- Puerto **3306** libre (MariaDB)
- Puerto **15672** libre (RabbitMQ Management)

### Verificación de Docker

```bash
# Verificar versiones
docker --version
docker compose version

# Verificar que Docker esté corriendo
docker ps
```

---

## 🚀 Instalación Paso a Paso

### 1. Clonar el Repositorio

```bash
# Clonar desde GitHub
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker

# Verificar que el script de instalación existe
ls -lh quick-install.sh
```

### 2. Ejecutar Instalación Automática

```bash
# Dar permisos de ejecución (si es necesario)
chmod +x quick-install.sh

# Ejecutar instalación completa
./quick-install.sh
```

**El script realizará automáticamente:**
1. ✅ Limpieza de contenedores anteriores (si existen)
2. ✅ Limpieza de volúmenes y redes
3. ✅ Creación de estructura de directorios
4. ✅ Configuración de RabbitMQ con plugin STOMP
5. ✅ Creación de red Docker (172.26.0.0/16)
6. ✅ Creación de volúmenes persistentes
7. ✅ Inicio de servicios en orden correcto
8. ✅ Verificación de salud de servicios
9. ✅ Pruebas de conectividad HTTP

**Tiempo estimado:** 2-3 minutos

### 3. Verificar Instalación

Una vez completado, el script mostrará:

```
✓ INSTALACIÓN COMPLETADA EXITOSAMENTE

Accede a Koha en:
  - Staff Interface: http://TU_IP:8081
  - OPAC (catálogo): http://TU_IP:8080
  - RabbitMQ Admin: http://TU_IP:15672

Credenciales de base de datos:
  - Base de datos: koha_library
  - Usuario: koha_library
  - Contraseña: Koha2024SecurePass
```

### 4. Verificar Servicios Manualmente

```bash
# Ver estado de contenedores
docker ps

# Verificar conectividad HTTP
curl -I http://localhost:8081

# Ver logs de Koha
docker logs koha-prod -f
```

---

## 🔧 Configuración Inicial de Koha

### 1. Acceder al Instalador Web

Abre en tu navegador:
```
http://TU_IP_DEL_SERVIDOR:8081
```

Deberías ver: **"Log in to the Koha web installer › Koha"**

### 2. Completar Asistente de Instalación

El instalador te guiará paso a paso. Usa estas credenciales para la base de datos:

| Campo | Valor |
|-------|-------|
| **Servidor de base de datos** | `db` |
| **Nombre de base de datos** | `koha_library` |
| **Usuario de base de datos** | `koha_library` |
| **Contraseña de base de datos** | `Koha2024SecurePass` |

### 3. Seguir Pasos del Instalador

1. **Verificación de requisitos** - Todo debe estar en verde ✅
2. **Configuración de base de datos** - Usar credenciales de arriba
3. **Instalación de esquema** - Click en "Continue to next step"
4. **Instalación de datos de ejemplo** - Seleccionar idioma español
5. **Configuración inicial** - Crear usuario administrador
6. **Completar instalación** - Seguir pasos finales

---

## 📁 Estructura de Archivos Creados

```
koha-docker/
├── .env                          # Variables de entorno
├── docker-compose.yml            # Configuración de servicios
├── quick-install.sh              # Script de instalación (USAR ESTE)
├── quick-start.sh                # Script de inicio rápido
├── data/                         # Datos persistentes
│   ├── rabbitmq/
│   │   └── conf/
│   │       └── enabled_plugins   # [rabbitmq_stomp].
│   ├── backups/                  # Backups automáticos
│   └── logs/                     # Logs de aplicación
└── volumes/                      # Volúmenes Docker (NO TOCAR)
```

---

## 🔒 Credenciales por Defecto

### Base de Datos MariaDB
- **Root Password**: `Root2024SecurePass`
- **Database**: `koha_library`
- **User**: `koha_library`
- **Password**: `Koha2024SecurePass`

### RabbitMQ
- **User**: `koha`
- **Password**: `Rabbit2024SecurePass`
- **Management URL**: http://TU_IP:15672

### Koha Web
- Las credenciales se crean durante el asistente de instalación
- Usuario administrador que tú definas
- Contraseña segura recomendada

**⚠️ IMPORTANTE**: Cambiar estas contraseñas en producción editando el archivo `.env`

---

## 🎯 Scripts de Gestión

### Iniciar Servicios (servidor ya instalado)

```bash
./quick-start.sh
```

### Detener Servicios

```bash
docker compose down
```

### Ver Logs

```bash
# Logs de Koha en tiempo real
docker logs koha-prod -f

# Logs de base de datos
docker logs koha-db -f

# Logs de RabbitMQ
docker logs koha-rabbitmq -f
```

### Reiniciar Servicios

```bash
docker compose restart
```

### Ver Estado

```bash
docker ps
docker compose ps
```

---

## 🔍 Verificación Post-Instalación

### 1. Verificar Contenedores

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Resultado esperado:**
```
NAMES            STATUS                    PORTS
koha-prod        Up X minutes (healthy)    0.0.0.0:8080-8081->8080-8081/tcp
koha-memcached   Up X minutes              11211/tcp
koha-rabbitmq    Up X minutes (healthy)    0.0.0.0:15672->15672/tcp
koha-db          Up X minutes (healthy)    0.0.0.0:3306->3306/tcp
```

### 2. Verificar Base de Datos

```bash
docker exec koha-db mariadb -ukoha_library -pKoha2024SecurePass -e "SHOW DATABASES;"
```

### 3. Verificar Conectividad HTTP

```bash
# Staff Interface
curl -I http://localhost:8081

# OPAC
curl -I http://localhost:8080
```

### 4. Verificar desde Otro Equipo en la Red

```bash
# Reemplazar TU_IP con la IP del servidor
curl -I http://TU_IP:8081
curl -I http://TU_IP:8080
```

---

## 🐛 Troubleshooting

### Problema: Puerto 3306 ocupado

**Error**: `bind: address already in use`

**Solución**:
```bash
# Detener MariaDB local
sudo systemctl stop mariadb

# O cambiar puerto en docker-compose.yml
# "0.0.0.0:3307:3306"  # Usar puerto 3307 en host
```

### Problema: Apache muestra página por defecto

**Solución**:
```bash
# Reiniciar Apache dentro del contenedor
docker exec koha-prod apache2ctl restart

# Verificar VirtualHosts
docker exec koha-prod apache2ctl -S
```

### Problema: RabbitMQ no inicia

**Solución**:
```bash
# Verificar plugin STOMP
cat data/rabbitmq/conf/enabled_plugins

# Debe contener: [rabbitmq_stomp].

# Si está mal, corregir:
echo '[rabbitmq_stomp].' > data/rabbitmq/conf/enabled_plugins
docker compose restart rabbitmq
```

### Problema: Network conflict

**Error**: `subnet overlap`

**Solución**: El script usa `172.26.0.0/16` para evitar conflictos. Si persiste:
```bash
# Editar docker-compose.yml y cambiar subnet
subnet: 172.27.0.0/16  # Usar otro rango
```

### Problema: Contenedores no inician

**Solución**:
```bash
# Ver logs detallados
docker compose logs

# Reiniciar todo desde cero
./quick-install.sh
```

---

## 📊 Arquitectura del Sistema

```
┌─────────────────────────────────────────────────┐
│           Red Docker (172.26.0.0/16)            │
│                                                  │
│  ┌──────────────┐  ┌──────────────┐            │
│  │  koha-prod   │  │ koha-memcached│            │
│  │  (Apache +   │  │  (Cache)      │            │
│  │   Koha +     │  └──────────────┘            │
│  │   Zebra +    │                               │
│  │   Plack)     │  ┌──────────────┐            │
│  │              │  │  koha-db     │            │
│  │ :8080, :8081 │──│  (MariaDB)   │            │
│  └──────────────┘  │  :3306       │            │
│         │          └──────────────┘            │
│         │                                       │
│         │          ┌──────────────┐            │
│         └──────────│koha-rabbitmq │            │
│                    │ (Message     │            │
│                    │  Broker)     │            │
│                    │ :15672       │            │
│                    └──────────────┘            │
└─────────────────────────────────────────────────┘
         │
         │ Puertos expuestos a host
         ▼
  8080 (OPAC), 8081 (Staff), 3306 (DB), 15672 (RabbitMQ)
```

---

## 💾 Datos Persistentes

Los siguientes volúmenes Docker mantienen los datos entre reinicios:

- **koha-etc**: Configuración de Koha
- **koha-var**: Archivos variables de Koha
- **koha-logs**: Logs de aplicación
- **koha-uploads**: Archivos subidos
- **koha-plugins**: Plugins instalados
- **koha-covers**: Portadas de libros
- **mariadb-data**: Base de datos (CRÍTICO)
- **mariadb-conf**: Configuración de MariaDB
- **rabbitmq-data**: Datos de RabbitMQ
- **rabbitmq-conf**: Configuración de RabbitMQ

**⚠️ IMPORTANTE**: 
- Hacer backups regulares de `mariadb-data`
- No borrar volúmenes a menos que quieras perder todos los datos

---

## 🔄 Reinstalación Completa

Si necesitas empezar de cero (BORRA TODOS LOS DATOS):

```bash
# Opción 1: Usar script de instalación (RECOMENDADO)
./quick-install.sh

# Opción 2: Manual
docker compose down -v  # -v borra volúmenes
docker network rm koha-network 2>/dev/null || true
rm -rf data/ volumes/
./quick-install.sh
```

---

## 📝 Cambiar Configuración

### Cambiar Contraseñas

Edita el archivo `.env`:

```bash
nano .env
```

Cambia los valores:
```env
KOHA_DB_PASSWORD=TU_NUEVA_CONTRASEÑA
MYSQL_ROOT_PASSWORD=TU_CONTRASEÑA_ROOT
RABBITMQ_PASSWORD=TU_CONTRASEÑA_RABBITMQ
```

Luego reinicia:
```bash
docker compose down
./quick-install.sh
```

### Cambiar Puertos

Edita `docker-compose.yml`:

```yaml
ports:
  - "0.0.0.0:9080:8080"  # OPAC en puerto 9080
  - "0.0.0.0:9081:8081"  # Staff en puerto 9081
```

Reinicia:
```bash
docker compose down
docker compose up -d
```

---

## 🎓 Recursos Adicionales

### Documentación Oficial
- **Koha**: https://koha-community.org/
- **Manual Koha**: https://koha-community.org/manual/

### Documentación del Proyecto
- `README.md` - Documentación principal
- `INSTALLATION-SUCCESS.md` - Guía de éxito de instalación
- `README-SCRIPTS.md` - Documentación de scripts

### Soporte
- **Koha Community**: https://koha-community.org/support/
- **IRC**: #koha en irc.oftc.net
- **Lista de correo**: https://koha-community.org/support/koha-mailing-lists/

---

## ✅ Checklist de Instalación

Usa este checklist para verificar cada paso:

- [ ] Docker y Docker Compose instalados
- [ ] Puertos 8080, 8081, 3306, 15672 libres
- [ ] Repositorio clonado
- [ ] Script `quick-install.sh` ejecutado
- [ ] 4 contenedores corriendo (koha-prod, koha-db, koha-rabbitmq, koha-memcached)
- [ ] HTTP 302 en `curl -I http://localhost:8081`
- [ ] Página de instalador visible en navegador
- [ ] Base de datos `koha_library` accesible
- [ ] Asistente web de Koha completado
- [ ] Usuario administrador creado
- [ ] Acceso desde red local verificado

---

## 🎉 ¡Instalación Completa!

Si todos los pasos anteriores funcionaron correctamente, ahora tienes:

✅ **Koha 24.11** completamente funcional  
✅ **Base de datos** MariaDB con persistencia  
✅ **RabbitMQ** configurado con STOMP  
✅ **Apache** con VirtualHosts correctos  
✅ **Acceso desde red local** en todos los puertos  
✅ **Volúmenes persistentes** para datos  

**Próximos pasos:**
1. Completar configuración inicial en el instalador web
2. Configurar bibliotecas y sucursales
3. Importar datos bibliográficos
4. Configurar usuarios y permisos
5. Personalizar interfaz OPAC

---

**Fecha de última actualización:** 4 de noviembre de 2025  
**Versión de Koha:** 24.11  
**Autor:** Matías (matiasgel)  
**Repositorio:** https://github.com/matiasgel/koha-docker
