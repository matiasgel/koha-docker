# 🚀 KOHA DOCKER - GUÍA DE INICIO RÁPIDO (ACCESO DE RED)

## ⚡ En 3 Pasos - Acceso Completo Desde Toda tu Red

### 1️⃣ VERIFICAR CONFIGURACIÓN (30 segundos)
```bash
./network-check.sh
```
✅ Si dice "✅ Escuchando en todos los interfaces" → ¡Listo!
❌ Si hay advertencias → Continúa con el paso 2

---

### 2️⃣ ABRIR PUERTOS EN FIREWALL (1 minuto)
```bash
sudo ./firewall-setup.sh
```
✅ Permite acceso desde la red
❌ Si prefieres hacerlo manualmente:
```bash
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp
```

---

### 3️⃣ REINICIAR SERVICIOS (30 segundos)
```bash
./manage.sh restart
```
✅ Espera 30 segundos a que inicie completamente
❌ Si hay problemas: `./manage.sh logs`

---

## 🎯 ¡LISTO! ACCEDE AHORA

### Obtén tu IP del servidor:
```bash
hostname -I | awk '{print $1}'
```
Resultado: `192.168.1.100` (por ejemplo)

### Abre en el navegador desde CUALQUIER computadora:
```
📱 OPAC (Catálogo):     http://192.168.1.100:8080
🏢 Staff Interface:     http://192.168.1.100:8081
```

### Ingresa con:
```
👤 Usuario: koha_admin
🔑 Contraseña: KohaAdmin#2024$Web456
```

---

## 🧪 VERIFICAR QUE FUNCIONA

### Desde la máquina del Docker:
```bash
curl http://localhost:8080
```

### Desde otra máquina de la red:
```bash
curl http://192.168.1.100:8080
```

### O simplemente:
```bash
./remote-test.sh 192.168.1.100
```

---

## 📚 DOCUMENTACIÓN

- 📖 Guía completa: [ACCESO-RED.md](ACCESO-RED.md)
- 🎯 Guía rápida: [RED-ACCESO-COMPLETADO.md](RED-ACCESO-COMPLETADO.md)
- 📝 Cambios realizados: [CAMBIOS-RED.md](CAMBIOS-RED.md)
- 📊 Resumen: [RESUMEN-IMPLEMENTACION.md](RESUMEN-IMPLEMENTACION.md)

---

## 🛠️ COMANDOS ÚTILES

```bash
./koha-status.sh          # Ver estado del sistema
./manage.sh status        # Ver estado de servicios
./manage.sh logs          # Ver logs en tiempo real
./manage.sh restart       # Reiniciar servicios
./network-check.sh        # Verificar acceso de red
./remote-test.sh IP       # Probar acceso remoto
```

---

## 🆘 PROBLEMAS COMUNES

### "No puedo conectar desde otra PC"
```bash
# 1. Verifica la IP correcta
hostname -I

# 2. Verifica puertos abiertos
./network-check.sh

# 3. Abre puertos si es necesario
sudo ./firewall-setup.sh

# 4. Reinicia servicios
./manage.sh restart

# 5. Prueba acceso remoto
./remote-test.sh IP-CORRECTA
```

### "Olvide la contraseña"
```
Por defecto: KohaAdmin#2024$Web456
```

### "¿Qué es esa IP?"
```bash
# Obtén la IP de tu servidor
hostname -I | awk '{print $1}'
```

---

## ✅ CHECKLIST RÁPIDO

```
☐ Ejecuté ./network-check.sh
☐ Ejecuté sudo ./firewall-setup.sh
☐ Ejecuté ./manage.sh restart
☐ Probé en otra máquina: http://IP:8080
☐ Ingresé con koha_admin / KohaAdmin#2024$Web456
☐ ¡FUNCIONANDO!
```

---

## 🎉 ¡YA ESTÁ!

Tu Koha Docker es ahora accesible desde **cualquier computadora de tu red**.

**Acceso en cualquier máquina:**
```
http://IP-DEL-SERVIDOR:8080
```

¡Disfruta! 📚
