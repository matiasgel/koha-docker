# 📦 MÉTODOS DE BACKUP Y MIGRACIÓN DE KOHA DOCKER

## 🚀 Método 1: Backup Rápido (Recomendado para la mayoría de casos)

### ✨ Características:
- ⚡ Rápido y simple
- 📦 Solo datos esenciales
- 🎯 Archivo pequeño (~1MB)
- 🔄 Fácil de transferir

### 🎯 Uso:
```powershell
# Hacer backup
.\backup-simple.ps1

# Resultado: koha-simple-YYYYMMDD-HHMM.zip
```

### 📋 Contenido del backup:
- ✅ Base de datos de Koha (koha_teolib)
- ✅ Configuración Docker Compose
- ✅ Configuración RabbitMQ
- ✅ Instrucciones de restauración

---

## 🔧 Método 2: Backup Completo (Para entornos de producción)

### ✨ Características:
- 💾 Backup completo de volúmenes
- 🗄️ Todas las bases de datos
- 📁 Archivos de configuración
- 🐳 Imágenes Docker (opcional)

### 🎯 Uso:
```powershell
# Hacer backup completo
.\backup-koha.ps1

# Backup con directorio personalizado
.\backup-koha.ps1 -BackupPath "C:\MisBackups"

# Resultado: koha-migration-YYYYMMDD-HHMM.zip
```

---

## 🎯 Método 3: Backup Manual (Comando por comando)

### 📋 Para casos específicos:
```powershell
# 1. Solo base de datos
docker exec examples-db-1 mariadb-dump -u root -pexample koha_teolib > backup-db.sql

# 2. Solo configuración
Copy-Item docker-compose.yaml, rabbitmq_plugins backup/

# 3. Volúmenes específicos
docker run --rm -v examples_mariadb-koha:/data -v ${PWD}:/backup alpine tar czf /backup/data.tar.gz -C /data .
```

---

## 🔄 RESTAURACIÓN EN NUEVA MÁQUINA

### 📋 Prerequisitos:
1. ✅ Docker instalado
2. ✅ Docker Compose instalado
3. ✅ Puertos 8080, 8081 disponibles

### 🚀 Proceso de Restauración:

#### ⚡ Restauración Rápida:
```powershell
# 1. Extraer backup
Expand-Archive koha-simple-YYYYMMDD-HHMM.zip -DestinationPath koha-restore

# 2. Ir al directorio
cd koha-restore

# 3. Iniciar base de datos
docker-compose up -d db

# 4. Esperar inicialización
Start-Sleep -Seconds 30

# 5. Restaurar datos
Get-Content koha-database.sql | docker exec -i examples-db-1 mariadb -u root -pexample koha_teolib

# 6. Iniciar todos los servicios
docker-compose up -d
```

#### 🔧 Restauración Completa:
```powershell
# Usar script automatizado
.\restore-koha.ps1 -BackupFile "koha-migration-YYYYMMDD-HHMM.zip"
```

---

## 📊 COMPARACIÓN DE MÉTODOS

| Método | Tamaño | Tiempo | Complejidad | Uso Recomendado |
|--------|--------|--------|-------------|-----------------|
| **Backup Rápido** | ~1MB | 30 seg | Baja | Desarrollo/Testing |
| **Backup Completo** | ~50MB+ | 2-5 min | Media | Producción |
| **Backup Manual** | Variable | Variable | Alta | Casos específicos |

---

## ⚠️ CONSIDERACIONES IMPORTANTES

### 🔒 Seguridad:
- 🔑 **Cambiar contraseñas** en nueva máquina
- 🛡️ **Configurar firewall** apropiadamente
- 🔐 **Verificar permisos** de archivos

### 🌐 Red:
- 🔌 **Verificar puertos** disponibles (8080, 8081)
- 🌍 **Configurar DNS/hosts** si es necesario
- 🔄 **Actualizar variables** de entorno

### 💾 Rendimiento:
- 📏 **Verificar espacio** en disco suficiente
- 🚀 **Comprobar recursos** de sistema
- ⏱️ **Tiempo de transferencia** según tamaño

---

## 🎯 SCRIPTS DISPONIBLES

### 📄 En tu directorio koha-docker:

1. **`backup-simple.ps1`** - Backup rápido de datos esenciales
2. **`backup-koha.ps1`** - Backup completo con volúmenes
3. **`restore-koha.ps1`** - Restauración automatizada
4. **`backup-migration.md`** - Documentación completa

### 🔧 Uso típico:
```powershell
# Desarrollo/Testing
.\backup-simple.ps1

# Producción
.\backup-koha.ps1

# Restaurar en nueva máquina
.\restore-koha.ps1 -BackupFile "backup.zip"
```

---

## ✅ VERIFICACIÓN POST-MIGRACIÓN

### 🔍 Checklist:
- [ ] Servicios corriendo: `docker-compose ps`
- [ ] Web accesible: http://localhost:8081
- [ ] Base de datos funcional: Probar login
- [ ] Idiomas configurados: Verificar español
- [ ] Datos preservados: Verificar configuración

### 🆘 Problemas comunes:
- **Puerto ocupado**: Cambiar puertos en docker-compose.yaml
- **BD no responde**: Esperar más tiempo o reiniciar
- **Permisos**: Ejecutar como administrador si es necesario

---

## 🎉 ¡MIGRACIÓN EXITOSA!

Una vez completada la migración:
- 🌐 **Koha Staff**: http://localhost:8081
- 🌐 **OPAC Público**: http://localhost:8080
- 🔑 **Credenciales**: koha_teolib / example
