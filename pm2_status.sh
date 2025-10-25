#!/bin/bash
# 📊 ESTADO DEL GENERADOR DE MAPAS PERSISTENTE

echo "📊 ESTADO DEL GENERADOR DE MAPAS"
echo "================================"

PID_FILE="logs/background_generator.pid"
STATS_FILE="background_generator_stats.json"

# Verificar estado del proceso
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    
    if kill -0 "$PID" 2>/dev/null; then
        echo "🟢 ESTADO: CORRIENDO"
        echo "🆔 PID: $PID"
        
        # Mostrar información del proceso
        echo "💾 MEMORIA: $(ps -p $PID -o rss= | awk '{printf "%.1f MB", $1/1024}')"
        echo "⏰ TIEMPO: $(ps -p $PID -o etime= | xargs)"
        echo "💻 CPU: $(ps -p $PID -o pcpu= | xargs)%"
        
    else
        echo "🔴 ESTADO: DETENIDO (PID inválido)"
        rm -f "$PID_FILE"
    fi
else
    # Buscar por nombre de proceso
    PIDS=$(pgrep -f "background_map_generator.py")
    if [ -n "$PIDS" ]; then
        echo "🟡 ESTADO: CORRIENDO (sin archivo PID)"
        echo "🆔 PIDs encontrados: $PIDS"
    else
        echo "🔴 ESTADO: DETENIDO"
    fi
fi

echo ""
echo "📈 ESTADÍSTICAS:"

# Leer estadísticas si existen
if [ -f "$STATS_FILE" ]; then
    echo "📊 Estadísticas del generador:"
    
    # Extraer datos usando python
    python3 -c "
import json
import sys
from datetime import datetime

try:
    with open('$STATS_FILE', 'r') as f:
        stats = json.load(f)
    
    print(f'   🚀 Iniciado: {stats.get(\"started_at\", \"N/A\")}')
    print(f'   🗺️ Mapas generados: {stats.get(\"maps_generated\", 0):,}')
    print(f'   ❌ Errores: {stats.get(\"errors\", 0)}')
    print(f'   🎯 Tarea actual: {stats.get(\"current_task\", \"N/A\")}')
    print(f'   💾 Tamaño total: {stats.get(\"total_size_mb\", 0):.1f} MB')
    print(f'   ⏰ Última actividad: {stats.get(\"last_activity\", \"N/A\")}')
    
    if 'finished_at' in stats:
        print(f'   🏁 Finalizado: {stats[\"finished_at\"]}')
        
except Exception as e:
    print('   ⚠️ Error leyendo estadísticas:', e)
" 2>/dev/null || echo "   ⚠️ No se pudieron leer las estadísticas"

else
    echo "   ℹ️ No hay estadísticas disponibles"
fi

echo ""
echo "📁 ARCHIVOS:"

# Contar mapas generados
TOTAL_MAPS=$(find static_maps/ -name "data_*.json" 2>/dev/null | wc -l)
MAPS_SIZE=$(du -sh static_maps/ 2>/dev/null | cut -f1 || echo "N/A")

echo "   🗺️ Total mapas: $TOTAL_MAPS"
echo "   💾 Tamaño directorio: $MAPS_SIZE"

# Mostrar logs más recientes
echo ""
echo "📋 LOGS RECIENTES:"
LATEST_LOG=$(ls -t logs/background_generator_*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
    echo "   📄 Archivo: $LATEST_LOG"
    echo "   📝 Últimas 3 líneas:"
    tail -3 "$LATEST_LOG" 2>/dev/null | sed 's/^/      /' || echo "      (no se pudo leer el log)"
else
    echo "   ℹ️ No hay logs disponibles"
fi

echo ""
echo "🎯 COMANDOS DISPONIBLES:"
echo "   ./pm2_start.sh   - Iniciar generador"
echo "   ./pm2_stop.sh    - Detener generador" 
echo "   ./pm2_restart.sh - Reiniciar generador"
echo "   ./pm2_logs.sh    - Ver logs en tiempo real"
echo "   ./pm2_stats.sh   - Estadísticas detalladas"