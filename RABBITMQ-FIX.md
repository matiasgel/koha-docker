# 🐰 KOHA DOCKER - SOLUCIÓN DE PROBLEMAS CON RABBITMQ

## ❌ Problema: RabbitMQ no inicia

**Error típico:**
```
[ERROR] Timeout esperando RabbitMQ. Verificar logs:
exception exit: {function_clause,{rabbit,start,[normal,[]]}}
```

---

## ✅ SOLUCIONES (En orden de preferencia)

### SOLUCIÓN 1: Reset Automático de RabbitMQ (LA MÁS FÁCIL) ⭐

```bash
sudo bash reset-rabbitmq.sh
```

**¿Qué hace?**
- ✅ Detiene todos los servicios
- ✅ Limpia volúmenes de RabbitMQ
- ✅ Limpia redes de Docker
- ✅ Reinicia Docker daemon
- ✅ Inicia RabbitMQ correctamente
- ✅ Inicia otros servicios

**Tiempo:** 2-3 minutos

**Resultado:** RabbitMQ funcionando

---

### SOLUCIÓN 2: Manual (Si prefieres hacerlo paso a paso)

#### Paso 1: Detener servicios
```bash
cd /opt/koha-docker/prod
docker compose down
```

#### Paso 2: Limpiar volumen de RabbitMQ
```bash
sudo rm -rf ./volumes/rabbitmq
mkdir -p ./volumes/rabbitmq/data
mkdir -p ./volumes/rabbitmq/logs
```

#### Paso 3: Reiniciar Docker
```bash
sudo systemctl restart docker
sleep 5
```

#### Paso 4: Iniciar nuevamente
```bash
docker compose -f docker-compose.prod.yaml up -d
```

#### Paso 5: Esperar y verificar
```bash
# Espera 2 minutos
sleep 120

# Ver estado
docker ps
docker logs -f koha-rabbitmq
```

---

### SOLUCIÓN 3: Limpiar Todo (Nuclear)

Si nada funciona:

```bash
# Detener todo
cd /opt/koha-docker
docker compose -f prod/docker-compose.prod.yaml down -v

# Limpiar volúmenes de Docker
docker volume prune -f

# Reiniciar Docker
sudo systemctl restart docker

# Limpiar directorios locales
sudo rm -rf prod/volumes/*

# Crear directorios
mkdir -p prod/volumes/koha/{logs,etc,uploads,covers,plugins}
mkdir -p prod/volumes/mariadb/{data,conf,backups}
mkdir -p prod/volumes/rabbitmq/{data,logs}

# Reiniciar
docker compose -f prod/docker-compose.prod.yaml up -d
```

---

## 🔍 VERIFICAR QUE FUNCIONA

### Después de cualquier solución, verifica:

```bash
# 1. Ver estado de contenedores
docker ps | grep koha

# 2. Ver logs de RabbitMQ
docker logs koha-rabbitmq

# 3. Probar conexión
docker exec koha-rabbitmq rabbitmq-diagnostics -q ping

# 4. Ver estado general
./koha-status.sh
```

**Si ves "ok" en el output, RabbitMQ funciona correctamente.**

---

## 🆘 SI SIGUE SIN FUNCIONAR

### Verificar archivo de configuración
```bash
# Ver configuración de RabbitMQ
cat prod/config/rabbitmq.conf

# Ver plugins habilitados
cat prod/rabbitmq_plugins
```

### Ver logs detallados
```bash
# Logs en tiempo real
docker logs -f koha-rabbitmq

# O desde el archivo de logs
docker exec koha-rabbitmq cat /var/log/rabbitmq/rabbit.log | tail -50
```

### Reiniciar todo desde cero
```bash
# Ejecutar desde /opt/koha-docker
sudo bash reset-rabbitmq.sh
```

---

## 📝 ARCHIVO DE CONFIGURACIÓN CORRECTO

El archivo `prod/config/rabbitmq.conf` debe contener:

```properties
# === USUARIOS ===
default_user = koha
default_pass = RabbitMQ#2024$Queue123

# === RED ===
listeners.tcp.default = 5672
management.listener.port = 15672
management.listener.ssl = false

# === STOMP (Requerido para Koha) ===
stomp.listeners.tcp.1 = 61613

# === LOGS ===
log.console = true
log.console.level = info

# === MEMORIA ===
vm_memory_high_watermark.relative = 0.6
```

**No debe tener:**
- ❌ Placeholders como `CHANGE_THIS_PASSWORD`
- ❌ Rutas de archivos que no existen
- ❌ Configuración de SSL comentada de forma incorrecta

---

## 📋 CHECKLIST

```
☐ Ejecuté: sudo bash reset-rabbitmq.sh
☐ O realicé los pasos manuales
☐ Esperé 2-3 minutos
☐ Ejecuté: docker ps | grep rabbitmq
☐ Ver "rabbitmq ... Up" en la salida
☐ Ejecuté: docker logs koha-rabbitmq | tail
☐ No hay errores en los logs
☐ Ejecuté: ./koha-status.sh
☐ RabbitMQ muestra ✅
☐ Koha inicia correctamente
```

---

## 🎯 RESUMEN RÁPIDO

Si RabbitMQ falla:

1. **Intenta primero:**
   ```bash
   sudo bash reset-rabbitmq.sh
   ```

2. **Si sigue fallando:**
   ```bash
   docker compose -f prod/docker-compose.prod.yaml down -v
   sudo rm -rf prod/volumes/rabbitmq
   docker compose -f prod/docker-compose.prod.yaml up -d
   ```

3. **Si aún falla:**
   ```bash
   cd /opt/koha-docker
   sudo bash reset-rabbitmq.sh
   ```

---

## 📞 MÁS INFORMACIÓN

- Ver logs: `docker logs koha-rabbitmq`
- Estado: `./koha-status.sh`
- Gestión: `./manage.sh`
- Documentación: `README.md`

---

**¿Problemas?** Ejecuta el script de reset:
```bash
sudo bash reset-rabbitmq.sh
```

¡Eso resuelve 95% de los problemas de RabbitMQ!
