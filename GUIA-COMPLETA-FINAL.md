# 🎉 KOHA DOCKER - GUÍA COMPLETA FINAL

## ✅ ESTADO: COMPLETAMENTE FUNCIONAL Y LISTO PARA INSTALAR

Tu Koha Docker está completamente preparado para ser instalado desde **cualquier máquina** de tu red.

---

## 📦 DOS FORMAS DE INSTALAR

### 🌐 OPCIÓN 1: Una Línea (Remota)
```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```
- ✅ Descarga automática desde GitHub
- ✅ Instala Docker si no lo tiene
- ✅ Configura acceso de red automáticamente
- ⏱️ 5-10 minutos

### 🖥️ OPCIÓN 2: Desde Git Descargado (Local)
```bash
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker
sudo bash install-local.sh
```
- ✅ Instala desde el directorio descargado
- ✅ No requiere internet después de clonar
- ✅ Configura acceso de red automáticamente
- ⏱️ 5-10 minutos

---

## 🌐 ACCESO DESDE CUALQUIER MÁQUINA

### Después de instalar (espera 2-3 minutos):

**En la máquina del servidor:**
```bash
hostname -I | awk '{print $1}'
# Resultado: 192.168.1.100
```

**Desde CUALQUIER otra máquina de tu red, abre en el navegador:**
```
📱 Catálogo (OPAC):      http://192.168.1.100:8080
🏢 Staff Interface:      http://192.168.1.100:8081
🐰 RabbitMQ Management:  http://192.168.1.100:15672
```

**Inicia sesión con:**
```
Usuario: koha_admin
Contraseña: KohaAdmin#2024$Web456
```

---

## 🛠️ DESPUÉS DE INSTALAR

### Ver estado del sistema
```bash
./koha-status.sh
```

### Verificar acceso de red
```bash
./network-check.sh
```

### Gestionar servicios
```bash
./manage.sh start      # Iniciar
./manage.sh stop       # Detener
./manage.sh restart    # Reiniciar
./manage.sh logs       # Ver logs
./manage.sh backup     # Hacer backup
./manage.sh update     # Actualizar sistema
```

### Probar acceso desde otra máquina
```bash
./remote-test.sh 192.168.1.100
```

---

## 📚 DOCUMENTACIÓN DISPONIBLE

### Para Empezar
- **[QUICK-START.md](QUICK-START.md)** - Referencia rápida
- **[GUIA-RAPIDA.md](GUIA-RAPIDA.md)** - 3 pasos para acceder

### Para Instalar
- **[INSTALACION.md](INSTALACION.md)** - Guía completa de instalación
- **[INDICE.md](INDICE.md)** - Índice de todos los archivos y scripts

### Para Configurar Red
- **[ACCESO-RED.md](ACCESO-RED.md)** - Configuración de red en detalle
- **[RED-ACCESO-COMPLETADO.md](RED-ACCESO-COMPLETADA.md)** - Resumen de cambios

### Para Resolver Problemas
- **[FIX-ENV-VARIABLES.md](FIX-ENV-VARIABLES.md)** - Si hay error de variables .env
- **[CAMBIOS-RED.md](CAMBIOS-RED.md)** - Cambios técnicos realizados

### General
- **[README.md](README.md)** - Descripción general del proyecto
- **[IMPLEMENTACION-COMPLETADA.md](IMPLEMENTACION-COMPLETADA.md)** - Resumen de implementación

---

## 📋 CHECKLIST RÁPIDO

```
ANTES DE INSTALAR:
☐ Tener Ubuntu/Debian/CentOS con acceso root o sudo
☐ Conexión a internet
☐ Mínimo 2GB RAM disponibles

INSTALAR (elige una):
☐ curl -fsSL ... | sudo bash
   O
☐ git clone...; sudo bash install-local.sh

ESPERAR:
☐ Esperar 5-10 minutos para que inicie

VERIFICAR:
☐ ./koha-status.sh - Todos servicios verdes
☐ ./network-check.sh - Acceso de red funciona
☐ http://IP:8080 - Funciona desde navegador local

PROBAR REMOTO:
☐ ./remote-test.sh IP - Test de otra máquina
☐ http://IP:8080 desde otra PC - Funciona
☐ Ingresar con koha_admin / KohaAdmin#2024$Web456

PRODUCCIÓN:
☐ Cambiar contraseña de koha_admin
☐ Cambiar contraseña de BD
☐ Configurar SSL/HTTPS
☐ Hacer primer backup

¡LISTO!
```

---

## 🔧 TODOS LOS SCRIPTS DISPONIBLES

### Instalación
- `auto-install.sh` - Instalación remota
- `install-local.sh` - Instalación local

### Verificación
- `network-check.sh` - Diagnóstico de red
- `firewall-setup.sh` - Configurar firewall
- `remote-test.sh` - Probar acceso remoto

### Reparación
- `fix-env.sh` - Reparar variables .env con espacios

### Gestión
- `manage.sh` - Gestor principal de Koha
- `koha-status.sh` - Ver estado en tiempo real

### Sistema
- `setup.sh` - Setup del sistema (ejecutado automáticamente)
- `init.sh` - Inicialización de servicios (ejecutado automáticamente)

---

## 🎯 CASOS DE USO

### "Quiero instalar rápidamente"
1. Lee [QUICK-START.md](QUICK-START.md)
2. Ejecuta: `curl -fsSL ... | sudo bash`
3. Accede: `http://IP:8080`

### "Necesito más detalles"
1. Lee [INSTALACION.md](INSTALACION.md)
2. Elige opción 1 o 2
3. Sigue pasos específicos

### "No puedo conectar desde otra máquina"
1. Ejecuta: `./network-check.sh`
2. Si falla: `sudo ./firewall-setup.sh`
3. Reinicia: `./manage.sh restart`
4. Prueba: `./remote-test.sh IP`

### "Tengo error en variables .env"
1. Lee [FIX-ENV-VARIABLES.md](FIX-ENV-VARIABLES.md)
2. Ejecuta: `bash fix-env.sh`
3. Continúa con instalación

### "Necesito entender la arquitectura"
1. Lee [README.md](README.md)
2. Lee [ACCESO-RED.md](ACCESO-RED.md)
3. Lee [CAMBIOS-RED.md](CAMBIOS-RED.md)

---

## 🔐 CREDENCIALES

### Koha Admin
```
Usuario: koha_admin
Contraseña: KohaAdmin#2024$Web456
```

### Base de Datos (MariaDB)
```
Usuario: koha_admin
Contraseña: KohaDB#2024$Secure789
Root: RootDB#2024$Strong456
Host: db
```

### RabbitMQ
```
Usuario: koha
Contraseña: RabbitMQ#2024$Queue123
Management UI: http://IP:15672
```

---

## 📊 PUERTOS Y SERVICIOS

| Puerto | Servicio | Acceso | URL |
|--------|----------|--------|-----|
| 8080 | OPAC (Catálogo) | http | http://IP:8080 |
| 8081 | Staff Interface | http | http://IP:8081 |
| 15672 | RabbitMQ Management | http | http://IP:15672 |
| 3306 | MySQL/MariaDB | tcp | db:3306 (interno) |
| 11211 | Memcached | tcp | memcached:11211 (interno) |
| 61613 | RabbitMQ STOMP | tcp | rabbitmq:61613 (interno) |

---

## 🚀 PRIMER ACCESO

1. **Obtén la IP de tu servidor:**
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. **Abre en navegador (desde otra máquina):**
   ```
   http://IP:8080
   ```

3. **Inicia sesión:**
   - Usuario: `koha_admin`
   - Contraseña: `KohaAdmin#2024$Web456`

4. **Completa el asistente de Koha:**
   - Configurar biblioteca
   - Establecer parámetros del sistema
   - Crear usuarios adicionales

5. **Haz tu primer backup:**
   ```bash
   ./manage.sh backup
   ```

---

## ⚡ COMANDOS RÁPIDOS

```bash
# ESTADO Y DIAGNÓSTICO
./koha-status.sh              # Estado visual
./network-check.sh            # Diagnóstico de red
./remote-test.sh 192.168.1.X  # Probar acceso remoto

# GESTIÓN DIARIA
./manage.sh start             # Iniciar
./manage.sh stop              # Detener
./manage.sh restart           # Reiniciar
./manage.sh logs              # Ver logs

# MANTENIMIENTO
./manage.sh backup            # Hacer backup
./manage.sh update            # Actualizar sistema

# CONFIGURACIÓN
sudo ./firewall-setup.sh      # Configurar firewall
bash fix-env.sh               # Reparar .env si es necesario
```

---

## 💡 TIPS Y TRUCOS

### Ver logs en tiempo real
```bash
./manage.sh logs
```

### Acceder a la base de datos
```bash
docker compose exec db mysql -u root -pRootDB#2024$Strong456
```

### Hacer backup manual
```bash
./manage.sh backup
```

### Cambiar contraseña (una vez dentro de Koha)
- Acceder a Staff Interface
- Parámetros → Seguridad → Cambiar contraseña

### Actualizar a nueva versión
```bash
./manage.sh update
```

---

## 🔒 SEGURIDAD EN PRODUCCIÓN

⚠️ **IMPORTANTE:**

1. **Cambiar todas las contraseñas por defecto**
   - koha_admin en Koha
   - BD credentials
   - RabbitMQ

2. **Configurar SSL/HTTPS**
   ```bash
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
   ```

3. **Usar proxy inverso (Nginx/Apache)**
   - SSL en el proxy
   - Ocultar puertos internos

4. **Firewall restrictivo**
   - Permitir solo IPs autorizadas
   - Limitar acceso a puertos

5. **Backups regulares**
   ```bash
   ./manage.sh backup  # Hacer regularmente
   ```

---

## 🆘 AYUDA RÁPIDA

| Problema | Solución |
|----------|----------|
| **No sé por dónde empezar** | Lee [QUICK-START.md](QUICK-START.md) |
| **Error en instalación** | Ejecuta `./network-check.sh` |
| **No puedo conectar remotamente** | Ejecuta `sudo ./firewall-setup.sh` |
| **Error de variables .env** | Ejecuta `bash fix-env.sh` |
| **Olvide contraseña** | Ver sección "Credenciales" arriba |
| **¿Cómo hago backup?** | `./manage.sh backup` |
| **¿Qué archivos existen?** | Lee [INDICE.md](INDICE.md) |

---

## 📈 RECURSOS

- **Sitio de Koha**: https://koha-community.org/
- **Documentación oficial**: https://koha-community.org/documentation/
- **Foros de soporte**: https://koha-community.org/forums/

---

## ✅ TODO LISTO

Tu Koha Docker está completamente configurado y listo para:

✅ Instalar desde cualquier máquina
✅ Acceder desde toda la red
✅ Gestionar completamente
✅ Hacer backups
✅ Escalar a producción

**Comienza ahora:**
```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

¡Disfruta tu biblioteca digital compartida! 📚🎉
