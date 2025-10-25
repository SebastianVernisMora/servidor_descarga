#!/bin/bash
# Script para comprimir archivos archivados

echo "🗜️  COMPRIMIENDO ARCHIVOS ARCHIVADOS..."

# Crear backup comprimido
tar -czf archive_backup_$(date +%Y%m%d_%H%M).tar.gz archive/

# Mostrar estadísticas
original_size=$(du -sh archive/ | cut -f1)
compressed_size=$(ls -lh archive_backup_*.tar.gz | tail -1 | awk '{print $5}')

echo "📊 ESTADÍSTICAS:"
echo "Original: $original_size"
echo "Comprimido: $compressed_size"

# Verificar integridad
echo "🧪 Verificando integridad..."
tar -tzf archive_backup_*.tar.gz > /dev/null && echo "✅ Archivo comprimido OK"

echo "📋 Archivos disponibles para eliminar:"
echo "- archive/ (directorio completo)"
echo "- $(ls archive_backup_*.tar.gz | tail -1) (mantener como backup)"

echo ""
echo "⚠️  Para eliminar el directorio original:"
echo "rm -rf archive/"

echo "✅ Compresión completada!"