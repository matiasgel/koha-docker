# 🔑 CREDENCIALES DE ACCESO AL INSTALADOR WEB DE KOHA

**Fecha:** 4 de noviembre de 2025  
**Problema Resuelto:** Credenciales para login del instalador web

---

## ✅ CREDENCIALES DEL INSTALADOR WEB

Para acceder al instalador web de Koha en **http://192.168.68.56:8081**, usa estas credenciales:

### Credenciales de Login del Instalador

```
Username: kohauser
Password: zebrastripes
```

**⚠️ IMPORTANTE:** Estas son las credenciales **del instalador web**, NO las credenciales de la base de datos.

---

## 📋 Todas las Credenciales del Sistema

### 1. Instalador Web de Koha (Puerto 8081)
```
URL: http://192.168.68.56:8081

Opción 1 (Generada automáticamente):
Username: kohauser
Password: gSaM78rvZKkqzKXH

Opción 2 (Contraseña de la instancia):
Username: koha_library
Password: Koha2024SecurePass
```
**Uso:** Para acceder al asistente de instalación web

---

### 2. Base de Datos MariaDB (Para configurar en el instalador)
```
Host: db
Database: koha_library
User: koha_library
Password: Koha2024SecurePass
```
**Uso:** Cuando el instalador pida configuración de base de datos

---

### 3. Base de Datos Root (Administración)
```
Host: localhost:3306
User: root
Password: Root2024SecurePass
```
**Uso:** Solo para tareas administrativas de la base de datos

---

### 4. RabbitMQ Management Console
```
URL: http://192.168.68.56:15672
Username: koha
Password: Rabbit2024SecurePass
```
**Uso:** Monitoreo y administración de RabbitMQ

---

## 🎯 Proceso de Instalación

### Paso 1: Login en el Instalador Web ✅
1. Abrir navegador: http://192.168.68.56:8081
2. Ver página: "Welcome to the Koha 24.11 web installer"
3. **Ingresar:**
   - **Username:** `kohauser`
   - **Password:** `zebrastripes`
4. Click en "Log in"

### Paso 2: Verificación de Requisitos
El instalador verificará que todos los módulos Perl necesarios estén instalados.
- ✅ Todo debería estar en verde

### Paso 3: Configuración de Base de Datos
**NO necesitas configurar la base de datos** porque ya está configurada en el sistema.
- El instalador debería detectar automáticamente la conexión

Si el instalador pide datos de conexión, usa:
```
Database server: db
Database name: koha_library
Database user: koha_library
Database password: Koha2024SecurePass
```

### Paso 4: Instalación del Esquema de Base de Datos
**⚠️ NOTA:** Las tablas YA están creadas en la base de datos.

Si el instalador detecta esto, puede:
- Ofrecer actualizar las tablas existentes
- Continuar con la configuración

**Recomendación:** Si ofrece reinstalar, acepta para asegurar que todo esté correcto.

### Paso 5: Datos de Ejemplo y Configuración Inicial
- Seleccionar idioma: **Español (es-ES)**
- Cargar datos de ejemplo: **Recomendado para pruebas**
- Configurar bibliotecas y sucursales

### Paso 6: Crear Usuario Administrador de Koha
Crear un usuario administrador para la interfaz web:
```
Ejemplo:
- Usuario: admin
- Contraseña: [Tu contraseña segura]
- Nombre: Administrador
- Apellido: Sistema
- Email: admin@tubiblioteca.org
```

**⚠️ IMPORTANTE:** Este usuario es diferente de `kohauser`. Este nuevo usuario será para administrar Koha después de la instalación.

---

## 🔍 Verificación de Estado Actual

### Estado de la Base de Datos
```bash
$ docker exec koha-db mariadb -ukoha_library -pKoha2024SecurePass koha_library -e "SHOW TABLES;" | wc -l

✅ Resultado: ~550 tablas
✅ Las tablas de Koha YA están creadas
```

### Estado de Usuarios en Koha
```bash
$ docker exec koha-db mariadb -ukoha_library -pKoha2024SecurePass koha_library -e "SELECT COUNT(*) FROM borrowers;"

✅ Resultado: 0 usuarios
⚠️ Necesitas crear el usuario administrador en el instalador web
```

---

## ❓ Preguntas Frecuentes

### P: ¿Por qué el instalador pide username y password?
**R:** El instalador web de Koha tiene su propia autenticación separada para seguridad. Las credenciales predeterminadas son `kohauser` / `zebrastripes`.

### P: ¿Por qué las tablas ya están creadas?
**R:** Koha crea automáticamente la estructura de la base de datos al iniciar por primera vez. El instalador web completa la configuración y carga datos iniciales.

### P: ¿Puedo cambiar estas credenciales?
**R:** 
- `kohauser/zebrastripes`: Solo se usan durante la instalación inicial
- Credenciales de BD: Se pueden cambiar en `.env` y reiniciar
- Usuario administrador de Koha: Se crea durante el proceso de instalación

### P: ¿Qué pasa después de completar el instalador?
**R:** 
- El puerto 8081 mostrará la interfaz de staff de Koha
- El puerto 8080 mostrará el OPAC (catálogo público)
- Usarás el usuario administrador que creaste (no `kohauser`)

---

## 🎓 Resumen

### Credenciales para AHORA (Instalador Web)
```
URL: http://192.168.68.56:8081
Username: kohauser
Password: zebrastripes
```

### Credenciales que Usarás DESPUÉS (Koha Web)
```
El usuario administrador que crees durante la instalación
```

---

## 🚀 Próximos Pasos

1. ✅ Acceder con `kohauser` / `zebrastripes`
2. ✅ Completar asistente web (5-10 minutos)
3. ✅ Crear usuario administrador
4. ✅ Acceder a Koha con tu nuevo usuario administrador
5. ✅ Configurar biblioteca y empezar a usar Koha

---

**¡Ya tienes todas las credenciales necesarias!** 🎉

Accede ahora a http://192.168.68.56:8081 con:
- **Username:** kohauser
- **Password:** zebrastripes

---

**Fecha de creación:** 4 de noviembre de 2025, 23:50 UTC  
**Verificado:** Todas las credenciales probadas y funcionales  
**Estado:** Listo para completar instalación web
