# 🎉 KOHA DOCKER - ACCESO DE RED COMPLETAMENTE FUNCIONAL

## 📋 Estado Actual: ✅ COMPLETAMENTE CONFIGURADO

Tu sistema Koha Docker está listo para ser utilizado desde cualquier máquina de tu red local. **Sin necesidad de configuración manual adicional.**

---

## 🚀 INSTALACIÓN EN NUEVA MÁQUINA

### Línea Única - Completamente Automática

```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

**Eso es todo.** El script hará automáticamente:
- ✅ Instalar Docker
- ✅ Descargar el repositorio
- ✅ Configurar variables de entorno (0.0.0.0 para red)
- ✅ Configurar firewall (permite puertos 8080, 8081)
- ✅ Iniciar todos los servicios
- ✅ Proporcionar credenciales de acceso

---

## 🌐 ACCESO DESPUÉS DE INSTALACIÓN

### Paso 1: Obtener IP del Servidor
```bash
hostname -I
# Salida: 192.168.1.100
```

### Paso 2: Acceder Desde Otra Máquina en la Red

En tu navegador (desde cualquier computadora):

```
📱 Catálogo (OPAC):     http://192.168.1.100:8080
🏢 Staff Interface:     http://192.168.1.100:8081
🐰 RabbitMQ Admin:      http://192.168.1.100:15672
```

### Paso 3: Inicia Sesión

| Campo | Valor |
|-------|-------|
| Usuario | `koha_admin` |
| Contraseña | `KohaAdmin#2024$Web456` |

---

## 📁 ESTRUCTURA DE ARCHIVOS IMPLEMENTADOS

```
koha-docker/
├── auto-install.sh              ← Instalación automatizada (una línea)
├── manage.sh                    ← Gestión de servicios
├── koha-status.sh               ← Ver estado en tiempo real
├── network-setup.sh             ← Configurar firewall
├── verify-network.sh            ← Verificar configuración de red
├── remote-test.sh               ← Test de conectividad remota
│
├── .env.production              ← Variables de entorno (KOHA_DOMAIN=0.0.0.0)
├── .env.example                 ← Template de variables
│
├── prod/docker-compose.prod.yaml ← Configuración Docker actualizada
│
└── Documentación:
    ├── NETWORK_CONFIG.md        ← Guía completa de red
    ├── RESUMEN-ACCESO-RED.md    ← Resumen de implementación
    ├── README.md                ← Actualizado con acceso remoto
    └── TROUBLESHOOTING.md       ← Solución de problemas
```

---

## 🛠️ COMANDOS PRINCIPALES

### Después de instalarse en el servidor:

```bash
# Ver estado actual
./koha-status.sh

# Gestión básica
./manage.sh start       # Iniciar servicios
./manage.sh stop        # Detener servicios
./manage.sh restart     # Reiniciar
./manage.sh status      # Estado detallado
./manage.sh logs        # Ver logs en tiempo real
./manage.sh backup      # Hacer backup

# Verificar configuración de red
./verify-network.sh

# Test de conectividad remota
./remote-test.sh        # Desde otra máquina: ./remote-test.sh 192.168.1.100
```

---

## 🔍 VERIFICACIÓN DE CONFIGURACIÓN

### Los siguientes cambios están implementados:

✅ **Variables de Entorno** (`.env.production`):
```bash
KOHA_DOMAIN=0.0.0.0              # Escucha en todos los interfaces
OPAC_DOMAIN=0.0.0.0              # Accesible desde cualquier IP
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080
```

✅ **Docker Compose** (`prod/docker-compose.prod.yaml`):
```yaml
ports:
  - "0.0.0.0:8080:8080"  # OPAC accesible en todos los interfaces
  - "0.0.0.0:8081:8081"  # Staff accesible en todos los interfaces
```

✅ **Firewall Automático**:
- Puertos 8080 y 8081 permitidos
- Configurado para UFW, firewalld e iptables
- Script automático: `network-setup.sh`

✅ **Scripts de Automatización**:
- Instalación sin interacción
- Configuración automática de firewall
- Gestión simplificada de servicios
- Verificación de estado y conectividad

---

## 🎯 FLUJO DE INSTALACIÓN SIMPLIFICADO

```
1. Clona repositorio / Descargas ISO
   ↓
2. Ejecuta: curl ... | sudo bash
   ↓
3. Espera 3-5 minutos
   ↓
4. Obtén IP: hostname -I
   ↓
5. Accede: http://IP:8080 o http://IP:8081
   ↓
6. ¡Koha funciona en toda la red!
```

---

## 💻 EJEMPLO DE ACCESO DESDE OTRA MÁQUINA

### Servidor (Linux)
```bash
# Instalar
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash

# Obtener IP
hostname -I
# Output: 192.168.1.100
```

### Cliente (Otra máquina en la red)
```bash
# Abrir navegador
http://192.168.1.100:8080   # Ver catálogo
http://192.168.1.100:8081   # Staff interface

# Inicia sesión
Usuario: koha_admin
Contraseña: KohaAdmin#2024$Web456
```

---

## 🔐 CREDENCIALES POR DEFECTO

| Servicio | Usuario | Contraseña |
|----------|---------|-----------|
| **Koha Web** | koha_admin | KohaAdmin#2024$Web456 |
| **Base Datos** | koha_admin | KohaDB#2024$Secure789 |
| **DB Root** | root | RootDB#2024$Strong456 |
| **RabbitMQ** | koha | RabbitMQ#2024$Queue123 |

⚠️ **En producción:** Cambiar estas contraseñas

---

## 🚨 TROUBLESHOOTING RÁPIDO

### "No puedo acceder desde otra máquina"

```bash
# 1. Verificar que Koha está corriendo
./koha-status.sh

# 2. Verificar puertos abiertos
sudo netstat -tlnp | grep -E '8080|8081'

# 3. Configurar firewall
sudo ./network-setup.sh

# 4. Ver logs
docker compose logs -f koha

# 5. Test conectividad
curl http://localhost:8080
```

### "El firewall bloquea el acceso"

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp
sudo ufw enable

# O ejecutar script
sudo ./network-setup.sh
```

---

## 📊 INFORMACIÓN TÉCNICA

**Puertos Expuestos:**
- `0.0.0.0:8080:8080` → OPAC (Catálogo público)
- `0.0.0.0:8081:8081` → Staff Interface (Bibliotecario)
- `0.0.0.0:15672:15672` → RabbitMQ Management

**Redes Configuradas:**
- `koha-prod` → Red interna de producción (172.25.0.0/16)

**Servicios:**
- Koha (Apache + Zebra) → Puerto 8080/8081
- MariaDB → Puerto 3306 (interno)
- RabbitMQ → Puerto 61613/15672
- Memcached → Puerto 11211 (interno)

---

## 📚 DOCUMENTACIÓN DISPONIBLE

1. **NETWORK_CONFIG.md** - Configuración completa de red
2. **RESUMEN-ACCESO-RED.md** - Resumen de implementación
3. **README.md** - Documentación general
4. **TROUBLESHOOTING.md** - Solución de problemas
5. **README-BACKUP.md** - Sistema de backup

---

## ✨ BENEFICIOS

✅ **Una línea de instalación**
✅ **Acceso desde cualquier máquina de la red**
✅ **Firewall configurado automáticamente**
✅ **Contraseñas seguras por defecto**
✅ **Sin configuración manual requerida**
✅ **Scripts de gestión simplificados**
✅ **Completamente Dockerizado**
✅ **Interfaz en español incluida**

---

## 🎉 ¡LISTO PARA USAR!

Tu instalación Koha Docker está completamente funcional y accesible desde toda tu red.

**Para comenzar en una nueva máquina:**

```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

**Espera 3-5 minutos. ¡Eso es todo!**

Luego accede desde cualquier navegador:
- 📱 http://IP-DEL-SERVIDOR:8080
- 🏢 http://IP-DEL-SERVIDOR:8081

