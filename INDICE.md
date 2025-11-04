# 📑 ÍNDICE DE ARCHIVOS Y SCRIPTS - KOHA DOCKER

## 🚀 INSTALACIÓN

### Instaladores
- **`auto-install.sh`** - Instalación remota (una línea desde GitHub)
- **`install-local.sh`** - Instalación local (desde git descargado)

### Documentación de Instalación
- **`INSTALACION.md`** ⭐ - Guía completa: ambos métodos de instalación
- **`QUICK-START.md`** ⭐ - Inicio rápido (2-3 minutos)

---

## 🌐 ACCESO DE RED

### Scripts de Verificación y Configuración
- **`network-check.sh`** - Verifica acceso de red (diagnóstico completo)
- **`firewall-setup.sh`** - Configura automáticamente el firewall
- **`remote-test.sh`** - Prueba acceso desde otra máquina

### Documentación de Red
- **`ACCESO-RED.md`** ⭐ - Guía detallada de configuración de red
- **`RED-ACCESO-COMPLETADO.md`** - Resumen de cambios realizados
- **`CAMBIOS-RED.md`** - Registro técnico de cambios

---

## 🛠️ GESTIÓN DIARIA

### Scripts de Gestión
- **`manage.sh`** ⭐ - Gestión principal (start/stop/restart/logs/backup)
- **`koha-status.sh`** ⭐ - Estado del sistema en tiempo real

### Configuración del Sistema
- **`setup.sh`** - Preparación del sistema (ejecutado durante instalación)
- **`init.sh`** - Inicialización de servicios (ejecutado durante instalación)

---

## 📚 DOCUMENTACIÓN PRINCIPAL

### Empezar Aquí
1. **`README.md`** - Inicio: descripción general del proyecto
2. **`QUICK-START.md`** - Instalación rápida (2-3 minutos)
3. **`GUIA-RAPIDA.md`** - Guía de inicio rápido

### Configuración
- **`INSTALACION.md`** - Instalación detallada
- **`ACCESO-RED.md`** - Configuración de acceso de red
- **`.github/copilot-instructions.md`** - Instrucciones para AI

### Referencia
- **`config-main.env`** - Plantilla de configuración (con comentarios)
- **`.env.production`** - Archivo de configuración por defecto (producción)
- **`.env.example`** - Ejemplo de configuración

---

## 🗂️ ESTRUCTURA DE DIRECTORIOS

```
koha-docker/
├── 🚀 INSTALADORES
│   ├── auto-install.sh                    # Instalación remota
│   └── install-local.sh                   # Instalación local
│
├── 🌐 SCRIPTS DE RED
│   ├── network-check.sh                   # Verificación de red
│   ├── firewall-setup.sh                  # Configuración de firewall
│   └── remote-test.sh                     # Test de acceso remoto
│
├── 🛠️ SCRIPTS DE GESTIÓN
│   ├── manage.sh                          # Gestión principal
│   ├── koha-status.sh                     # Estado del sistema
│   ├── setup.sh                           # Setup del sistema
│   └── init.sh                            # Inicialización de servicios
│
├── 📚 DOCUMENTACIÓN PRINCIPAL
│   ├── README.md                          # Descripción general
│   ├── QUICK-START.md                     # Inicio rápido
│   ├── GUIA-RAPIDA.md                     # Guía rápida
│   ├── INSTALACION.md                     # Guía de instalación
│   ├── ACCESO-RED.md                      # Configuración de red
│   └── INDICE.md                          # Este archivo
│
├── ⚙️ CONFIGURACIÓN
│   ├── .env.production                    # Config. por defecto
│   ├── .env.example                       # Ejemplo de config
│   ├── config-main.env                    # Plantilla comentada
│   └── config-sip.env                     # Config. SIP
│
├── 🐳 DOCKER
│   ├── docker-compose.yaml                # Para examples/
│   ├── Dockerfile                         # Definición de imagen
│   ├── files/                             # Configuraciones internas
│   └── prod/                              # Configuración producción
│
├── 📦 RESPALDO Y RESTAURACIÓN
│   ├── backup-koha.ps1                    # Backup completo (PowerShell)
│   ├── backup-simple.ps1                  # Backup simple (PowerShell)
│   ├── backup-simple-linux.sh             # Backup simple (Linux)
│   ├── restore-koha.ps1                   # Restauración (PowerShell)
│   ├── restore-koha.sh                    # Restauración (Bash)
│   └── restore-simple-linux.sh            # Restauración simple (Linux)
│
├── 📚 EJEMPLOS
│   ├── examples/                          # Configuración de desarrollo
│   └── prod/                              # Configuración de producción
│
└── 📋 INFORMACIÓN
    ├── README-BACKUP.md                   # Información de backup
    ├── GUIA_INSTALACION_KOHA.md          # Guía en español
    ├── LICENSE                            # Licencia
    └── koha-docker.code-workspace         # Workspace de VS Code
```

---

## 🎯 GUÍA RÁPIDA POR CASO DE USO

### "Quiero instalar Koha Docker rápidamente"
1. Leer: `QUICK-START.md`
2. Ejecutar: `auto-install.sh` o `install-local.sh`
3. Acceder: `http://IP:8080`

### "Tengo problemas de acceso desde otra máquina"
1. Ejecutar: `./network-check.sh`
2. Si falla: `sudo ./firewall-setup.sh`
3. Reiniciar: `./manage.sh restart`
4. Probar: `./remote-test.sh IP`

### "Quiero entender cómo funciona todo"
1. Leer: `README.md`
2. Leer: `ACCESO-RED.md`
3. Revisar: `CAMBIOS-RED.md`

### "Quiero gestionar Koha día a día"
```bash
./koha-status.sh              # Ver estado
./manage.sh logs              # Ver logs
./manage.sh backup            # Hacer backup
./manage.sh restart           # Reiniciar
```

### "Necesito hacer respaldo/restauración"
- Leer: `README-BACKUP.md`
- Scripts disponibles:
  - `backup-koha.ps1` (Windows - completo)
  - `backup-simple.ps1` (Windows - simple)
  - `backup-simple-linux.sh` (Linux - simple)

---

## 🚀 PASOS INICIALES

### 1. Elegir método de instalación
- **Opción A (Remota)**: `curl -fsSL ... | sudo bash`
- **Opción B (Local)**: `git clone` → `sudo bash install-local.sh`

### 2. Esperar a que inicie (5-10 minutos)
- Los servicios necesitan tiempo para iniciar
- Especialmente MariaDB y Koha

### 3. Verificar que funciona
```bash
./koha-status.sh
./network-check.sh
```

### 4. Acceder
- **Localmente**: `http://localhost:8080`
- **Desde red**: `http://IP:8080`

### 5. Ingresar
- Usuario: `koha_admin`
- Contraseña: `KohaAdmin#2024$Web456`

---

## 🔑 CREDENCIALES POR DEFECTO

```
Koha Admin:
  Usuario: koha_admin
  Contraseña: KohaAdmin#2024$Web456

Base de Datos:
  Usuario: koha_admin
  Contraseña: KohaDB#2024$Secure789
  Root: RootDB#2024$Strong456

RabbitMQ:
  Usuario: koha
  Contraseña: RabbitMQ#2024$Queue123
```

---

## 📊 PUERTOS

| Puerto | Servicio | URL |
|--------|----------|-----|
| 8080 | OPAC (Catálogo) | http://IP:8080 |
| 8081 | Staff Interface | http://IP:8081 |
| 15672 | RabbitMQ Management | http://IP:15672 |
| 3306 | MySQL/MariaDB | db:3306 (interno) |
| 11211 | Memcached | memcached:11211 (interno) |
| 61613 | RabbitMQ STOMP | rabbitmq:61613 (interno) |

---

## 🛠️ COMANDOS FRECUENTES

```bash
# ESTADO
./koha-status.sh
./network-check.sh

# GESTIÓN
./manage.sh start
./manage.sh stop
./manage.sh restart
./manage.sh status
./manage.sh logs

# MANTENIMIENTO
./manage.sh backup
./manage.sh update

# VERIFICACIÓN DE RED
./network-check.sh
sudo ./firewall-setup.sh
./remote-test.sh IP
```

---

## 📖 LECTURA RECOMENDADA

### Para todos
- `QUICK-START.md` - Instalación (5 min)
- `GUIA-RAPIDA.md` - Inicio (3 min)

### Para desarrolladores
- `README.md` - Visión general (10 min)
- `ACCESO-RED.md` - Red en detalle (15 min)

### Para administradores
- `INSTALACION.md` - Instalación completa (20 min)
- `README-BACKUP.md` - Backup y restauración (15 min)
- `.github/copilot-instructions.md` - Arquitectura técnica (20 min)

---

## ✅ CHECKLIST

```
☐ Instalación completada
☐ Servicios en ejecución (./koha-status.sh)
☐ Red verificada (./network-check.sh)
☐ Acceso local funciona (http://localhost:8080)
☐ Acceso remoto funciona (http://IP:8080)
☐ Primer backup hecho (./manage.sh backup)
☐ Credenciales cambiadas (producción)
☐ SSL configurado (producción)
```

---

## 🎓 APRENDE MÁS

### Coha
- [Sitio oficial de Koha](https://koha-community.org/)
- [Documentación de Koha](https://koha-community.org/documentation/)

### Docker
- [Documentación de Docker](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

### Este Proyecto
- Todas las respuestas en los `.md` del proyecto
- Scripts comentados con explicaciones

---

## 📞 AYUDA RÁPIDA

**"¿No sé por dónde empezar?"**
→ Lee `QUICK-START.md`

**"La instalación falla"**
→ Ejecuta `./network-check.sh`

**"No puedo conectar desde otra PC"**
→ Ejecuta `./firewall-setup.sh`

**"¿Cuál es la contraseña?"**
→ Ver sección "Credenciales por defecto" arriba

**"¿Cómo hago backup?"**
→ `./manage.sh backup`

---

## 🎉 LISTO

Tienes todo lo que necesitas para:
- ✅ Instalar Koha Docker
- ✅ Acceder desde toda la red
- ✅ Gestionar el sistema
- ✅ Hacer respaldos

¡Comienza con `QUICK-START.md`!
