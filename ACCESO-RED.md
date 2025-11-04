# 🌐 Configurar Koha para Acceso desde Toda la Red

Por defecto, Koha Docker puede estar limitado a `localhost`. Esta guía te muestra cómo hacerlo accesible desde cualquier computadora de tu red.

## 📋 Verificación de Accesibilidad Actual

```bash
# Comprueba si Koha es accesible
curl http://localhost:8080        # ✅ Funciona localmente
curl http://TU-IP-DOCKER:8080    # ❓ Desde otra máquina
```

Si la segunda línea falla, sigue las instrucciones abajo.

---

## ✅ Solución 1: Verificar Puertos (La más rápida)

### 1.1 Verificar que Docker escucha en todos los interfaces

El archivo `docker-compose.prod.yaml` debe tener:

```yaml
ports:
  - "8080:8080"    # Cualquier interface:8080 → Contenedor:8080
  - "8081:8081"    # Cualquier interface:8081 → Contenedor:8081
```

✅ **Este es el formato correcto** (escucha en 0.0.0.0 automáticamente)

❌ **Formato incorrecto** (solo localhost):
```yaml
ports:
  - "127.0.0.1:8080:8080"
  - "127.0.0.1:8081:8081"
```

### 1.2 Verificar que Apache está vinculado correctamente

El archivo `.env` debe tener:

```bash
# CORRECTO - Escucha en todos los interfaces
KOHA_DOMAIN=0.0.0.0          # o tu IP/dominio
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080
```

---

## ✅ Solución 2: Actualizar .env para Acceso de Red

Edita `.env` (o `.env.production` en producción):

```bash
# CAMBIAR ESTO:
KOHA_DOMAIN=localhost
# POR ESTO:
KOHA_DOMAIN=0.0.0.0

# O si tienes un dominio:
KOHA_DOMAIN=biblioteca.ejemplo.com

# O si tienes una IP fija:
KOHA_DOMAIN=192.168.1.100
```

---

## ✅ Solución 3: Configuración de Apache (Avanzado)

Si Apache sigue limitado a localhost, edita la configuración:

```bash
# Entrar al contenedor
docker compose exec koha bash

# Editar configuración de Apache
vi /etc/apache2/ports.conf
```

Debe mostrar:
```apache
Listen 8080
Listen 8081
```

❌ NO debe mostrar:
```apache
Listen 127.0.0.1:8080
Listen 127.0.0.1:8081
```

Si está limitado a localhost, corrígelo:
```bash
# Dentro del contenedor
sed -i 's/Listen 127.0.0.1:8080/Listen 8080/g' /etc/apache2/ports.conf
sed -i 's/Listen 127.0.0.1:8081/Listen 8081/g' /etc/apache2/ports.conf
systemctl restart apache2
```

---

## ✅ Solución 4: Firewall (Si sigue sin funcionar)

### Linux/macOS
```bash
# Verificar que los puertos están abiertos
sudo netstat -tlnp | grep 808

# Si no aparecen, comprueba Docker:
docker port nombre_contenedor_koha
```

### Windows (Firewall de Windows)
```powershell
# Permitir puertos en Firewall
netsh advfirewall firewall add rule name="Koha OPAC" dir=in action=allow protocol=tcp localport=8080
netsh advfirewall firewall add rule name="Koha Staff" dir=in action=allow protocol=tcp localport=8081
```

### Todas las plataformas
```bash
# Comprobar que Docker Daemon escucha
docker ps | grep koha

# Comprobar que los puertos están en escucha
# Linux:
sudo netstat -tlnp | grep -E '8080|8081'
# macOS:
netstat -an | grep -E '8080|8081'
# Windows PowerShell:
netstat -ano | findstr "8080"
```

---

## ✅ Solución 5: Docker Desktop (Windows/macOS)

Si usas **Docker Desktop** en Windows o macOS:

1. Abre **Docker Desktop Settings**
2. Ve a **Resources** → **Network**
3. Asegúrate de que los puertos 8080 y 8081 no están bloqueados

### Windows específicamente
- El firewall de Windows puede bloquear los puertos
- Abre **Windows Defender Firewall**
- Busca reglas para los puertos 8080 y 8081

---

## 🧪 Pruebas de Accesibilidad

### 1. Desde la máquina del Docker
```bash
# Debe funcionar
curl http://localhost:8080
curl http://127.0.0.1:8080
curl http://0.0.0.0:8080

# También debe funcionar con tu IP
curl http://$(hostname -I | awk '{print $1}'):8080
```

### 2. Desde otra máquina de la red
```bash
# Reemplaza con la IP de la máquina con Docker
curl http://192.168.1.100:8080

# Si tienes un dominio, también debe funcionar
curl http://biblioteca.ejemplo.com:8080
```

### 3. Verificar DNS (si usas dominio)
```bash
# Verifica que el dominio resuelve la IP correcta
nslookup biblioteca.ejemplo.com
# O en Linux:
dig biblioteca.ejemplo.com
```

---

## 🔧 Reiniciar Servicios

Después de hacer cambios, reinicia todo:

```bash
# Opción 1: Usando manage.sh
./manage.sh restart

# Opción 2: Manualmente
docker compose down
docker compose up -d
```

Espera 30-60 segundos para que Apache inicie completamente.

---

## 📝 Configuración Completa del .env para Red

Aquí está la configuración correcta completa:

```bash
# === RED ===
KOHA_DOMAIN=0.0.0.0              # Escuchar en todos los interfaces
KOHA_INTRANET_PORT=8081
KOHA_OPAC_PORT=8080
KOHA_INTRANET_PREFIX=
KOHA_INTRANET_SUFFIX=
KOHA_OPAC_PREFIX=
KOHA_OPAC_SUFFIX=

# === SERVICIOS ===
MEMCACHED_SERVERS=memcached:11211
MB_HOST=rabbitmq
MB_PORT=61613
MB_USER=koha
MB_PASS=RabbitMQ#2024$Queue123

# === ACCESO ===
MYSQL_SERVER=db
MYSQL_USER=koha_admin
MYSQL_PASSWORD=KohaDB#2024$Secure789
MYSQL_ROOT_PASSWORD=RootDB#2024$Strong456
```

---

## 🆘 Solucionar Problemas

### "Conexión rechazada" desde otra máquina
1. ✅ Verifica que el contenedor está en ejecución: `docker ps`
2. ✅ Verifica la IP del host: `hostname -I` (Linux) o `ipconfig` (Windows)
3. ✅ Comprueba que el firewall no bloquea los puertos
4. ✅ Verifica la configuración de Apache en el contenedor

### "El dominio no se resuelve"
1. ✅ Configura un dominio en tu router o en `/etc/hosts`
2. ✅ Usa la IP directamente mientras pruebas
3. ✅ Comprueba los registros DNS

### "Funciona localmente pero no desde la red"
1. ✅ Casi siempre es un problema de firewall
2. ✅ Verifica que los puertos 8080 y 8081 no están bloqueados
3. ✅ En Windows, desactiva momentáneamente el firewall para probar

---

## 🎯 Acceso Final

Una vez todo configurado, accede desde cualquier máquina de la red:

```
📱 OPAC:  http://IP-O-DOMINIO:8080
🏢 Staff: http://IP-O-DOMINIO:8081
👤 Usuario: koha_admin
🔑 Contraseña: KohaAdmin#2024$Web456
```

Reemplaza:
- `IP-O-DOMINIO` con la IP o dominio de tu servidor Docker
- Los puertos si los has cambiado en `.env`

---

## 🔒 Seguridad en Red

### Para Producción:
1. ✅ Configura SSL/HTTPS (certificados Let's Encrypt)
2. ✅ Usa contraseñas fuertes (no las por defecto)
3. ✅ Limita el acceso por IP en el firewall
4. ✅ Usa un WAF (Web Application Firewall)
5. ✅ Configura autenticación LDAP/AD si es posible

### Configuración SSL Rápida:
```bash
# Generar certificado autofirmado
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365

# O usar Let's Encrypt (recomendado)
certbot certonly --standalone -d biblioteca.ejemplo.com
```

---

**¿Sigue sin funcionar?** Revisa los logs:
```bash
docker compose logs -f koha
```