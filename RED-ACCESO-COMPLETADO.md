# 🌐 KOHA DOCKER - ACCESO DESDE TODA LA RED

## 📋 Resumen Rápido

Tu Koha Docker **AHORA está configurado para ser accesible desde cualquier computadora de tu red**.

### ✅ Configuración completada:

- ✅ `.env.production` → `KOHA_DOMAIN=0.0.0.0` (escucha en todos los interfaces)
- ✅ `.env.example` → Actualizado con comentarios claros
- ✅ `docker-compose.prod.yaml` → Puertos correctamente expuestos
- ✅ Scripts de verificación y firewall creados

---

## 🚀 Pasos para Activar Acceso de Red

### 1. Verificar la configuración está correcta
```bash
./network-check.sh
```

Este script verifica:
- ✅ Docker funcionando
- ✅ Contenedor Koha activo
- ✅ Puertos 8080 y 8081 abiertos
- ✅ Conectividad local y de red
- ✅ Estado del firewall

### 2. Abrir puertos en el firewall (si es necesario)
```bash
sudo ./firewall-setup.sh
```

Esto automáticamente:
- ✅ Detecta tu tipo de firewall (UFW, firewalld, iptables)
- ✅ Permite puerto 8080 (OPAC)
- ✅ Permite puerto 8081 (Staff Interface)
- ✅ Opcionalmente permite puerto 15672 (RabbitMQ)

### 3. Reiniciar servicios
```bash
./manage.sh restart
```

---

## 🌐 Acceso desde cualquier computadora

Después de completar los pasos anteriores:

### Desde la máquina del Docker:
```bash
# Localmente (siempre funciona)
http://localhost:8080        # OPAC
http://localhost:8081        # Staff Interface
```

### Desde otra máquina de la red:
```bash
# Usando la IP del servidor Docker
http://192.168.1.100:8080    # OPAC (reemplaza con tu IP)
http://192.168.1.100:8081    # Staff Interface
```

### O si tienes un dominio configurado:
```bash
# Usando un dominio
http://biblioteca.ejemplo.com:8080
http://biblioteca.ejemplo.com:8081
```

---

## 🔍 Verificar que funciona

### 1. Encontrar la IP del servidor Docker
```bash
# En Linux/macOS
hostname -I | awk '{print $1}'

# En Windows (si Docker está en WSL)
ip addr show | grep "inet " | grep -v "127.0.0.1"
```

### 2. Probar acceso local
```bash
curl http://localhost:8080
curl http://localhost:8081
```

### 3. Probar acceso desde la red
Desde otra computadora, abre en el navegador:
```
http://IP-DEL-SERVIDOR:8080
```

---

## 🎯 Credenciales de Acceso

```
👤 Usuario: koha_admin
🔑 Contraseña: KohaAdmin#2024$Web456
```

### Interfaz de Staff:
```
http://IP-DEL-SERVIDOR:8081
```

### Catálogo Público (OPAC):
```
http://IP-DEL-SERVIDOR:8080
```

---

## 🔧 Configuración Manual (si lo necesitas)

### En `.env`:
```bash
# DEBE SER UNO DE ESTOS:
KOHA_DOMAIN=0.0.0.0              # ✅ Escucha en todos los interfaces
KOHA_DOMAIN=192.168.1.100        # ✅ IP específica
KOHA_DOMAIN=biblioteca.local      # ✅ Dominio específico

# ❌ NO uses esto (solo local):
KOHA_DOMAIN=localhost
KOHA_DOMAIN=127.0.0.1
```

### En `docker-compose.yaml`:
```yaml
# ✅ CORRECTO (todos los interfaces):
ports:
  - "8080:8080"
  - "8081:8081"

# ❌ INCORRECTO (solo localhost):
ports:
  - "127.0.0.1:8080:8080"
  - "127.0.0.1:8081:8081"
```

---

## 🆘 Solucionar Problemas

### "Desde otra máquina no puedo conectar"

1. **Verifica que el contenedor está corriendo:**
   ```bash
   docker ps | grep koha
   ```

2. **Verifica la IP correcta:**
   ```bash
   hostname -I  # Linux
   ipconfig     # Windows
   ```

3. **Prueba conectividad de red:**
   ```bash
   # Desde otra máquina
   ping IP-DEL-SERVIDOR
   ```

4. **Verifica el firewall:**
   ```bash
   sudo ufw status
   # Debe mostrar 8080 y 8081 permitidos
   ```

5. **Revisa logs:**
   ```bash
   ./manage.sh logs
   ```

---

## 📚 Scripts Útiles Creados

### `network-check.sh`
Verifica que todo está configurado correctamente para acceso de red.

### `firewall-setup.sh`
Configura automáticamente el firewall para permitir los puertos.

### `manage.sh restart`
Reinicia todos los servicios.

### `koha-status.sh`
Muestra el estado actual de Koha.

---

## 🔒 Seguridad

### Recomendaciones para Producción:

1. **Cambiar contraseñas por defecto**
   - No uses KohaAdmin#2024$Web456 en producción
   - Crea contraseñas fuertes y únicas

2. **Configurar SSL/HTTPS**
   ```bash
   # Generar certificado autofirmado
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
   ```

3. **Usar un proxy inverso**
   - Nginx o Apache como reverso proxy
   - SSL en el proxy
   - Ocultar puertos internos

4. **Limitar acceso por IP**
   - En el firewall: permitir solo IPs específicas
   - En Koha: usar restricciones de acceso

5. **Mantener actualizado**
   ```bash
   ./manage.sh update
   ```

---

## ✅ Validar Instalación

Ejecuta esto para verificar que todo funciona:

```bash
# 1. Verificar configuración de red
./network-check.sh

# 2. Ver estado de servicios
./koha-status.sh

# 3. Ver logs en tiempo real
./manage.sh logs

# 4. Hacer backup
./manage.sh backup
```

---

## 📞 Acceso Desde Diferentes Ubicaciones

### Desde un navegador en la misma máquina
```
http://localhost:8080
```

### Desde otra computadora en la red
```
http://192.168.1.100:8080
```

### Desde el mismo servidor (diferente puerto)
```
# Si tienes otro puerto abierto
http://server.local:8080
```

### A través de dominio (si está configurado)
```
http://biblioteca.ejemplo.com:8080
```

---

**¿Todo listo?** 🎉

Accede desde cualquier computadora de tu red usando:
```
http://IP-DEL-SERVIDOR:8080
```

¡Disfruta tu Koha Docker accesible desde toda la red!
