#!/bin/bash
# =============================================================================
# FIX VARIABLES .ENV - Corrige problemas con variables con espacios
# =============================================================================

echo "🔧 Corrigiendo archivo .env..."

# Hacer backup
cp .env .env.backup

# Arreglar KOHA_LANGS para que tenga quotes
sed -i 's/KOHA_LANGS=es-ES en-GB/KOHA_LANGS="es-ES en-GB"/g' .env

# Arreglar cualquier variable sin quotes que tenga espacios
sed -i 's/^KOHA_LIBRARY_NAME=\([^"]*\)$/KOHA_LIBRARY_NAME="\1"/g' .env

echo "✅ Archivo .env corregido"
echo "💾 Backup guardado en .env.backup"