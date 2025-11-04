# Configuración de Red - Koha Docker

## 🌐 Acceso desde toda la red local

Koha Docker está configurado para ser accesible desde cualquier computadora en tu red local. No está limitado a `localhost`.

## ⚡ Instalación Automática (Recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

El script de instalación automática:
- ✅ Instala Docker
- ✅ Clona el repositorio
- ✅ Configura variables de entorno
- ✅ **Configura automáticamente el firewall para permitir puertos 8080 y 8081**
- ✅ Inicia todos los servicios

## 🔑 Configuración de Red Manual

Si instalas manualmente, asegúrate de configurar estos elementos:

### 1. Variables de Entorno (`.env`)

```bash
# DEBE estar en 0.0.0.0 para escuchar en todos los interfaces
KOHA_DOMAIN=0.0.0.0
OPAC_DOMAIN=0.0.0.0

# Puertos (por defecto)
KOHA_INTRANET_PORT=8081  # Staff Interface
KOHA_OPAC_PORT=8080       # OPAC (Catálogo)
```

### 2. Docker Compose Ports

En `docker-compose.yml`, los puertos deben estar expuestos en `0.0.0.0`:

```yaml
services:
  koha:
    ports:
      - "0.0.0.0:8080:8080"  # OPAC
      - "0.0.0.0:8081:8081"  # Staff Interface
```

### 3. Firewall - Permitir Puertos

Ejecuta después de la instalación:

```bash
sudo /opt/koha-docker/network-setup.sh
```

O manualmente:

**UFW (Ubuntu/Debian):**
```bash
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp
sudo ufw enable
```

**firewalld (CentOS/RHEL):**
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload
```

**iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
```

## 📍 Acceso desde Otras Máquinas

### 1. Encuentra la IP del servidor Koha

En la máquina servidor:
```bash
hostname -I
# Salida: 192.168.1.100
```

### 2. Accede desde otra máquina en la red

Desde cualquier navegador en tu red:

```
📱 Catálogo (OPAC):       http://192.168.1.100:8080
🏢 Staff Interface:        http://192.168.1.100:8081
🐰 RabbitMQ Management:    http://192.168.1.100:15672
```

### 3. Credenciales por defecto

```
Usuario: koha_admin
Contraseña: KohaAdmin#2024$Web456
```

## 🔍 Verificar Conectividad

### Desde la máquina servidor:

```bash
# Ver qué interfaces están escuchando en los puertos
sudo netstat -tlnp | grep 8080
sudo netstat -tlnp | grep 8081

# Salida esperada:
# tcp        0      0 0.0.0.0:8080             0.0.0.0:*               LISTEN
# tcp        0      0 0.0.0.0:8081             0.0.0.0:*               LISTEN
```

### Desde otra máquina:

```bash
# Verificar que los puertos estén abiertos
nc -zv 192.168.1.100 8080
nc -zv 192.168.1.100 8081

# O con curl
curl -I http://192.168.1.100:8080
curl -I http://192.168.1.100:8081
```

## 🔧 Troubleshooting

### Problema: No puedo acceder desde otra máquina

**Solución 1: Verificar que Koha está corriendo**
```bash
./koha-status.sh
./manage.sh status
```

**Solución 2: Verificar firewall**
```bash
# UFW
sudo ufw status
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp

# O ejecutar script de red
sudo ./network-setup.sh
```

**Solución 3: Verificar Docker**
```bash
# Ver contenedores
docker ps

# Ver puertos expuestos
docker port container_name

# Ver logs
docker compose logs koha
```

**Solución 4: Verificar conectividad de red**
```bash
# Desde máquina remota
ping 192.168.1.100

# Verificar si Puerto está abierto
nc -zv 192.168.1.100 8080

# Ver ruta de red
tracert 192.168.1.100  # Windows
traceroute 192.168.1.100  # Linux/Mac
```

### Problema: Firewall bloquea los puertos

**Para UFW:**
```bash
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp
sudo ufw reload
```

**Para firewalld:**
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload
```

**Deshabilitar firewall temporalmente (SOLO PARA TESTING):**
```bash
sudo ufw disable  # UFW
# o
sudo systemctl stop firewalld  # firewalld
```

## 🌍 Acceso Remoto (Fuera de la Red Local)

Si necesitas acceder desde fuera de tu red local, tienes varias opciones:

### Opción 1: Proxy Inverso con Nginx

```bash
# Instalar Nginx
sudo apt-get install nginx

# Crear configuración
sudo nano /etc/nginx/sites-available/koha
```

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 8081;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Opción 2: VPN

- Usa OpenVPN o WireGuard para conectarte a tu red
- Luego accede como si fueras local

### Opción 3: SSH Tunnel

```bash
# Desde máquina remota
ssh -L 8080:localhost:8080 -L 8081:localhost:8081 usuario@servidor-ip

# Entonces accede a http://localhost:8080
```

## 📋 Verificación Completa

```bash
# 1. Verificar Docker
docker ps

# 2. Verificar Koha
./koha-status.sh

# 3. Verificar puertos
sudo netstat -tlnp | grep -E '8080|8081'

# 4. Verificar firewall
sudo ufw status

# 5. Verificar conectividad local
curl http://localhost:8080

# 6. Verificar desde otra máquina en la red
curl http://192.168.1.100:8080
```

## 🔐 Producción - Recomendaciones

En producción, considera:

1. **Usar HTTPS**: Instala certificados SSL
2. **Nginx Proxy**: Usa Nginx como proxy inverso
3. **Cambiar puertos**: No usar 8080/8081, usar 80/443
4. **Cambiar contraseñas**: No usar las contraseñas por defecto
5. **Whitelist de IPs**: Permitir solo IPs específicas en firewall
6. **VPN**: Usar VPN para acceso remoto seguro

## 📞 Soporte

Para más ayuda:
- Revisar logs: `docker compose logs -f`
- Verificar documentación oficial de Koha
- Contactar soporte Docker
