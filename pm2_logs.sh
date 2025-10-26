#!/bin/bash
# 📋 VER LOGS DEL GENERADOR EN TIEMPO REAL

echo "📋 LOGS DEL GENERADOR DE MAPAS EN TIEMPO REAL"
echo "============================================="

# Buscar el log más reciente
LATEST_LOG=$(ls -t logs/background_generator_*.log 2>/dev/null | head -1)

if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
    echo "📄 Siguiendo: $LATEST_LOG"
    echo "💡 Presiona Ctrl+C para salir"
    echo ""
    
    # Seguir el log en tiempo real
    tail -f "$LATEST_LOG"
else
    echo "❌ No se encontraron logs del generador"
    echo ""
    echo "📁 Logs disponibles:"
    ls -la logs/ 2>/dev/null || echo "   (directorio logs no existe)"
    echo ""
    echo "💡 Ejecuta './pm2_start.sh' para iniciar el generador"
fi