# 🚀 INSTALACIÓN DE KOHA DOCKER - GUÍA COMPLETA

## 📋 Dos Formas de Instalar

### Opción 1: Instalación Remota (Una línea)
Se descarga y configura automáticamente desde GitHub

### Opción 2: Instalación Local (Desde Git Descargado)
Se usa el directorio donde se clonó el repositorio

---

## ✅ OPCIÓN 1: INSTALACIÓN REMOTA (La más fácil)

### Paso 1: Ejecutar comando único
```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

**¿Qué hace?**
- ✅ Descarga el repositorio de GitHub
- ✅ Instala Docker si no lo tiene
- ✅ Configura automáticamente para acceso de red
- ✅ Inicia todos los servicios

**Tiempo:** 5-10 minutos

**Resultado:** Koha accesible desde toda la red

---

## ✅ OPCIÓN 2: INSTALACIÓN LOCAL (Desde Git Descargado)

### Paso 1: Descargar repositorio
```bash
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker
```

### Paso 2: Ejecutar instalación local
```bash
sudo bash install-local.sh
```

**¿Qué hace?**
- ✅ Valida que se ejecuta desde el directorio correcto
- ✅ Instala Docker si no lo tiene
- ✅ Configura automáticamente para acceso de red
- ✅ Inicia todos los servicios en el directorio local

**Tiempo:** 5-10 minutos

**Resultado:** Koha accesible desde toda la red

---

## 🎯 COMPARACIÓN DE MÉTODOS

| Aspecto | Remota (1 línea) | Local (Git) |
|---------|---|---|
| **Complejidad** | Mínima ⭐ | Fácil ⭐⭐ |
| **Descarga** | Automática | Manual (git clone) |
| **Control** | Menos | Más |
| **Ideal para** | Producción rápida | Desarrollo/Customización |

---

## 🆘 SI TIENES PROBLEMAS

### Con instalación remota
```bash
# Si falla, descarga localmente e instala
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker
sudo bash install-local.sh
```

### Con instalación local
```bash
# Verifica que estás en el directorio correcto
pwd  # Debe mostrar la ruta con koha-docker

# Verifica que tienes permisos
sudo ls setup.sh init.sh

# Ejecuta la instalación
sudo bash install-local.sh
```

---

## ✅ VERIFICAR QUE FUNCIONA

Después de instalar (espera 2-3 minutos):

```bash
# Ver estado del sistema
./koha-status.sh

# Verificar acceso de red
./network-check.sh

# Ver logs
./manage.sh logs
```

---

## 🌐 ACCEDER DESPUÉS DE LA INSTALACIÓN

### Desde la misma máquina
```
http://localhost:8080    # OPAC
http://localhost:8081    # Staff
```

### Desde otra máquina de la red
```
http://IP-DEL-SERVIDOR:8080    # OPAC
http://IP-DEL-SERVIDOR:8081    # Staff
```

### Obtener tu IP
```bash
hostname -I | awk '{print $1}'
```

---

## 🔑 CREDENCIALES DE ACCESO

```
Usuario: koha_admin
Contraseña: KohaAdmin#2024$Web456
```

---

## 📊 PUERTOS CONFIGURADOS

| Puerto | Servicio | Acceso |
|--------|----------|--------|
| **8080** | OPAC (Catálogo público) | http://IP:8080 |
| **8081** | Staff Interface | http://IP:8081 |
| **15672** | RabbitMQ Management | http://IP:15672 |
| **5432** | PostgreSQL (interno) | Solo contenedor |
| **11211** | Memcached (interno) | Solo contenedor |

---

## 🛠️ COMANDOS DESPUÉS DE INSTALAR

```bash
# Estado del sistema
./koha-status.sh

# Gestión de servicios
./manage.sh start       # Iniciar
./manage.sh stop        # Detener
./manage.sh restart     # Reiniciar
./manage.sh status      # Ver estado
./manage.sh logs        # Ver logs
./manage.sh backup      # Hacer backup

# Verificación de red
./network-check.sh      # Verificar configuración
./firewall-setup.sh     # Configurar firewall
./remote-test.sh IP     # Probar desde otra máquina
```

---

## 🔒 IMPORTANTE PARA PRODUCCIÓN

1. **Cambiar contraseñas por defecto**
   ```bash
   # Accede a Staff Interface
   # Cambiar contraseña de koha_admin
   # Cambiar credenciales de base de datos
   ```

2. **Configurar SSL/HTTPS**
   ```bash
   # Generar certificado
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
   ```

3. **Configurar firewall**
   ```bash
   sudo ./firewall-setup.sh
   ```

4. **Hacer backups regulares**
   ```bash
   ./manage.sh backup
   ```

---

## 📋 CHECKLIST DE VERIFICACIÓN

```
☐ Instalación completada sin errores
☐ Docker Desktop/Engine está ejecutándose
☐ Ejecuté ./koha-status.sh - muestra todos los servicios verdes
☐ Ejecuté ./network-check.sh - muestra acceso de red
☐ Probé acceso local: http://localhost:8080
☐ Probé acceso remoto: http://IP:8080 desde otra máquina
☐ Ingresé con koha_admin / KohaAdmin#2024$Web456
☐ Staff Interface es accesible desde otra máquina
☐ OPAC es accesible desde otra máquina
```

---

## 🆘 TROUBLESHOOTING RÁPIDO

### "No puedo conectar desde otra máquina"
```bash
./network-check.sh          # Diagnóstico
sudo ./firewall-setup.sh    # Abrir puertos
./manage.sh restart         # Reiniciar servicios
```

### "Los servicios no inician"
```bash
./manage.sh logs            # Ver qué falla
docker compose ps           # Ver estado de contenedores
docker compose logs -f      # Ver logs en tiempo real
```

### "¿Olvidé la contraseña?"
```
Por defecto: KohaAdmin#2024$Web456
Para cambiarla: Accede a Staff Interface y cambia en Parámetros
```

---

## 📞 SOPORTE

- **Documentación completa**: Ver [README.md](README.md)
- **Acceso de red**: Ver [ACCESO-RED.md](ACCESO-RED.md)
- **Solución de problemas**: Ver [GUIA-RAPIDA.md](GUIA-RAPIDA.md)
- **Cambios realizados**: Ver [CAMBIOS-RED.md](CAMBIOS-RED.md)

---

## 🎉 ¡LISTO!

Tu Koha Docker está ahora:
- ✅ Completamente instalado
- ✅ Accesible desde toda tu red
- ✅ Configurado automáticamente
- ✅ Listo para usar

**Accede en:** `http://IP-DEL-SERVIDOR:8080`
