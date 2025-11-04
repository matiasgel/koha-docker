# 🔧 FIX: Error al cargar variables .env con espacios

## ⚠️ PROBLEMA

Al ejecutar `setup.sh` o `init.sh`, si el archivo `.env` contiene variables con espacios sin quotes, aparece el error:

```
/dev/fd/63: línea 26: en-GB: orden no encontrada
```

## 🔍 CAUSA

Variables como:
```bash
KOHA_LANGS=es-ES en-GB
```

Necesitan estar entre comillas:
```bash
KOHA_LANGS="es-ES en-GB"
```

Cuando bash intenta ejecutar la línea sin quotes, interpreta `en-GB` como un comando, causando el error.

## ✅ SOLUCIONES

### Solución 1: Usar el script fix-env.sh (Automático)

```bash
bash fix-env.sh
```

✅ Corrige automáticamente el archivo `.env`
✅ Realiza backup en `.env.backup`

### Solución 2: Editar manualmente

Abre el archivo `.env` y asegúrate que:

```bash
# ❌ INCORRECTO (con espacios sin quotes)
KOHA_LANGS=es-ES en-GB
KOHA_LIBRARY_NAME=Biblioteca Principal

# ✅ CORRECTO (con quotes)
KOHA_LANGS="es-ES en-GB"
KOHA_LIBRARY_NAME="Biblioteca Principal"
```

### Solución 3: Crear nuevo .env

```bash
# Desde el directorio del proyecto
cp .env.production .env

# El archivo copiado ya tiene las variables correctamente formateadas
```

## 🚀 DESPUÉS DEL FIX

Vuelve a ejecutar el script:

```bash
# Si estaba en auto-install.sh:
sudo bash auto-install.sh

# O si estaba en install-local.sh:
sudo bash install-local.sh

# O si ejecutaste setup.sh directamente:
sudo ./setup.sh
```

## 📋 VARIABLES QUE NECESITAN QUOTES

Cualquier variable que tenga:
- **Espacios**: `"valor con espacios"`
- **Caracteres especiales**: `"valor-con-caracteres"`
- **Múltiples valores**: `"valor1 valor2"`

Ejemplos:
```bash
# Necesita quotes (con espacios)
KOHA_LANGS="es-ES en-GB"
KOHA_LIBRARY_NAME="Biblioteca Principal"

# Puede ser sin quotes (sin espacios)
KOHA_DB_USER=koha_admin
KOHA_INTRANET_PORT=8081
```

## 🛠️ CAMBIOS REALIZADOS

### Scripts Corregidos:
- ✅ `setup.sh` - Carga segura de variables
- ✅ `init.sh` - Carga segura de variables
- ✅ `fix-env.sh` - Script para arreglar .env automáticamente

### Archivos de Configuración:
- ✅ `.env.production` - Ya tiene quotes correctos
- ✅ `.env.example` - Ya tiene quotes correctos
- ✅ `prod/.env.example` - Corregido con quotes

## ✅ VERIFICACIÓN

Para verificar que el archivo `.env` está correcto:

```bash
# Verificar que KOHA_LANGS tiene quotes
grep KOHA_LANGS .env

# Debe mostrar:
# KOHA_LANGS="es-ES en-GB"
```

## 📝 PRÓXIMA INSTALACIÓN

Cuando instales en otra máquina, estos scripts ya tienen el fix aplicado, así que no deberías ver este error.

Si lo ves de todas formas:
```bash
bash fix-env.sh
```

---

**¡Problema resuelto!** ✅
