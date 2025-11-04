# 🚀 Koha Docker - Quick Deploy

## ⚡ Instalación en 1 Minuto

```bash
# 1. Clonar repositorio
git clone https://github.com/matiasgel/koha-docker.git
cd koha-docker

# 2. Ejecutar instalación automática
./quick-install.sh

# 3. Abrir navegador
# http://TU_IP_SERVIDOR:8081
```

**¡Listo!** Koha funcionando en ~2 minutos ⏱️

---

## 📋 Requisitos

- Docker Engine v24.0+
- Docker Compose v2.0+
- Puertos libres: 8080, 8081, 3306, 15672

```bash
# Verificar requisitos
docker --version
docker compose version
```

---

## 🔧 Comandos Rápidos

### Instalar desde cero
```bash
./quick-install.sh
```

### Iniciar servicios existentes
```bash
./quick-start.sh
```

### Detener servicios
```bash
docker compose down
```

### Ver logs
```bash
docker logs koha-prod -f
```

### Ver estado
```bash
docker ps
```

---

## 🌐 URLs de Acceso

Reemplaza `TU_IP` con la IP de tu servidor:

- **Staff Interface**: http://TU_IP:8081
- **OPAC (Catálogo)**: http://TU_IP:8080
- **RabbitMQ Admin**: http://TU_IP:15672

---

## 🔑 Credenciales por Defecto

### Base de Datos (para instalador web)
```
Host: db
Database: koha_library
User: koha_library
Password: Koha2024SecurePass
```

### RabbitMQ Management
```
User: koha
Password: Rabbit2024SecurePass
```

**⚠️ Cambiar en producción** editando `.env`

---

## 📖 Documentación Completa

- **Guía de Instalación**: [GUIA-INSTALACION-NUEVA.md](GUIA-INSTALACION-NUEVA.md)
- **Prueba de Reinstalación**: [PRUEBA-REINSTALACION-EXITOSA.md](PRUEBA-REINSTALACION-EXITOSA.md)
- **Scripts**: [README-SCRIPTS.md](README-SCRIPTS.md)
- **Instalación Exitosa**: [INSTALLATION-SUCCESS.md](INSTALLATION-SUCCESS.md)

---

## ✅ Verificación Rápida

```bash
# ¿Servicios corriendo?
docker ps

# ¿Web funcionando?
curl -I http://localhost:8081

# ¿Base de datos OK?
docker exec koha-db mariadb -ukoha_library -pKoha2024SecurePass -e "SELECT 1"
```

---

## 🐛 Problemas Comunes

### Puerto 3306 ocupado
```bash
sudo systemctl stop mariadb
```

### Apache muestra página por defecto
```bash
docker exec koha-prod apache2ctl restart
```

### Ver más soluciones
Consulta [GUIA-INSTALACION-NUEVA.md](GUIA-INSTALACION-NUEVA.md#-troubleshooting)

---

## 📊 Arquitectura

```
┌─────────────────────────────────────┐
│       Red Docker (172.26.0.0/16)    │
│                                      │
│  ┌──────────┐  ┌─────────────┐     │
│  │ koha-    │  │ koha-       │     │
│  │ prod     │  │ memcached   │     │
│  │ :8080    │  └─────────────┘     │
│  │ :8081    │                       │
│  └──────────┘  ┌─────────────┐     │
│       │        │ koha-db     │     │
│       │────────│ :3306       │     │
│       │        └─────────────┘     │
│       │                             │
│       │        ┌─────────────┐     │
│       └────────│koha-rabbitmq│     │
│                │ :15672      │     │
│                └─────────────┘     │
└─────────────────────────────────────┘
```

---

## 🎯 Características

✅ Instalación automatizada en 1 comando  
✅ Koha 24.11 (última versión estable)  
✅ MariaDB 11 con persistencia  
✅ RabbitMQ con STOMP  
✅ Apache + Zebra + Plack  
✅ Memcached para cache  
✅ Acceso desde red local  
✅ Volúmenes persistentes  
✅ Scripts de gestión  
✅ Documentación completa  

---

## 📝 Siguiente Paso

Después de ejecutar `./quick-install.sh`:

1. Abre http://TU_IP:8081 en tu navegador
2. Verás el instalador web de Koha
3. Sigue el asistente usando las credenciales de arriba
4. ¡Disfruta de Koha!

---

## 🆘 Soporte

- **Documentación**: Ver archivos `*.md` en el repositorio
- **Issues**: https://github.com/matiasgel/koha-docker/issues
- **Koha Community**: https://koha-community.org/support/

---

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver archivo [LICENSE](LICENSE).

---

**Última actualización:** 4 de noviembre de 2025  
**Versión Koha:** 24.11  
**Estado:** ✅ Producción Ready
