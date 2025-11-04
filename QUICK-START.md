# 🚀 QUICK START - KOHA DOCKER EN RED

## ⚡ Instalación (1 minuto)

```bash
curl -fsSL https://raw.githubusercontent.com/matiasgel/koha-docker/main/auto-install.sh | sudo bash
```

**Espera 3-5 minutos...**

## 🌐 Acceso Inmediato

```bash
# Desde otra máquina:
hostname -I  # En el servidor → 192.168.1.100

# En tu navegador:
http://192.168.1.100:8080   # Catálogo
http://192.168.1.100:8081   # Staff
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
# Verificar configuración
./verify-network.sh

# Configurar firewall
sudo ./network-setup.sh

# Test de conectividad
./remote-test.sh 192.168.1.100
```

## 📊 Puertos

- **8080** → OPAC (Catálogo público)
- **8081** → Staff Interface (Bibliotecario)
- **15672** → RabbitMQ Management

## 💡 Notas

- ✅ Ya está configurado para red
- ✅ Firewall configurado automáticamente
- ✅ Accesible desde cualquier máquina
- ✅ Contraseñas seguras por defecto
- ⚠️ Cambiar en producción

## 📞 Soporte

Ver documentación:
- `NETWORK_CONFIG.md` - Configuración de red
- `TROUBLESHOOTING.md` - Solución de problemas
- `README.md` - Documentación completa
