# 🚀 QUICK START - KOHA DOCKER EN RED

## ⚡ Instalación (2 Opciones)

### OPCIÓN 1: Una Línea (La más fácil)
```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

### OPCIÓN 2: Desde Git Descargado
```bash
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker
sudo bash install-local.sh
```

**Espera 5-10 minutos para que inicie completamente...**

## 🌐 Acceso Inmediato

```bash
# Obtén la IP de tu servidor
hostname -I | awk '{print $1}'

# En tu navegador (desde otra máquina):
http://192.168.1.100:8080   # Catálogo (OPAC)
http://192.168.1.100:8081   # Staff Interface
```

## 🔑 Inicia Sesión

```
Usuario: koha_admin
Contraseña: KohaAdmin#2024$Web456
```

## 📱 URLs

| Servicio | URL |
|----------|-----|
| **Catálogo (OPAC)** | http://IP:8080 |
| **Staff Interface** | http://IP:8081 |
| **RabbitMQ** | http://IP:15672 |

## 🛠️ Comandos Diarios

```bash
./koha-status.sh      # Ver estado
./manage.sh start     # Iniciar
./manage.sh stop      # Detener
./manage.sh restart   # Reiniciar
./manage.sh logs      # Ver logs
./manage.sh backup    # Backup
```

## 🔐 Credenciales Base de Datos

- Usuario: `koha_admin`
- Contraseña: `KohaDB#2024$Secure789`
- Host: `db`

## ⚙️ Si Hay Problemas

```bash
# Verificar configuración de red
./network-check.sh

# Configurar firewall
sudo ./firewall-setup.sh

# Test de conectividad
./remote-test.sh 192.168.1.100
```

## 📊 Puertos

- **8080** → OPAC (Catálogo público)
- **8081** → Staff Interface (Bibliotecario)
- **15672** → RabbitMQ Management

## 💡 Notas

- ✅ Ya está configurado para red
- ✅ Accesible desde cualquier máquina
- ✅ Contraseñas seguras por defecto
- ⚠️ Cambiar en producción

## 📞 Documentación

- [INSTALACION.md](INSTALACION.md) - Guía completa de instalación
- [ACCESO-RED.md](ACCESO-RED.md) - Configuración de red
- [GUIA-RAPIDA.md](GUIA-RAPIDA.md) - Guía rápida
- [README.md](README.md) - Documentación completa
