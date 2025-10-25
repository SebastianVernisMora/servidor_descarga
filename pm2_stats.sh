#!/bin/bash
# 📈 ESTADÍSTICAS DETALLADAS DEL GENERADOR DE MAPAS

echo "📈 ESTADÍSTICAS DETALLADAS DEL GENERADOR"
echo "========================================"

STATS_FILE="background_generator_stats.json"
MAPS_DIR="static_maps"

# Información del proceso
echo "🔧 PROCESO:"
if pgrep -f "background_map_generator.py" > /dev/null; then
    PID=$(pgrep -f "background_map_generator.py")
    echo "   🟢 Estado: CORRIENDO"
    echo "   🆔 PID: $PID"
    echo "   💾 RAM: $(ps -p $PID -o rss= | awk '{printf "%.1f MB", $1/1024}')"
    echo "   💻 CPU: $(ps -p $PID -o pcpu=)%"
    echo "   ⏰ Tiempo activo: $(ps -p $PID -o etime=)"
else
    echo "   🔴 Estado: DETENIDO"
fi

echo ""

# Estadísticas del generador
echo "📊 ESTADÍSTICAS DE GENERACIÓN:"
if [ -f "$STATS_FILE" ]; then
    python3 -c "
import json
import sys
from datetime import datetime, timedelta

try:
    with open('$STATS_FILE', 'r') as f:
        stats = json.load(f)
    
    # Información básica
    print(f'   🚀 Iniciado: {stats.get(\"started_at\", \"N/A\")}')
    print(f'   🗺️ Mapas generados: {stats.get(\"maps_generated\", 0):,}')
    print(f'   ❌ Errores: {stats.get(\"errors\", 0)}')
    print(f'   💾 Tamaño generado: {stats.get(\"total_size_mb\", 0):.1f} MB')
    print(f'   ⏰ Última actividad: {stats.get(\"last_activity\", \"N/A\")}')
    print(f'   🎯 Tarea actual: {stats.get(\"current_task\", \"N/A\")}')
    
    # Calcular velocidad si hay datos suficientes
    if stats.get('maps_generated', 0) > 0 and 'started_at' in stats:
        try:
            start_time = datetime.fromisoformat(stats['started_at'].replace('Z', '+00:00'))
            now = datetime.now()
            if 'last_activity' in stats:
                now = datetime.fromisoformat(stats['last_activity'].replace('Z', '+00:00'))
            
            elapsed = (now - start_time).total_seconds() / 3600  # horas
            if elapsed > 0:
                rate = stats['maps_generated'] / elapsed
                print(f'   ⚡ Velocidad: {rate:.1f} mapas/hora')
        except:
            pass
            
    if 'finished_at' in stats:
        print(f'   🏁 Finalizado: {stats[\"finished_at\"]}')
        
except Exception as e:
    print('   ⚠️ Error leyendo estadísticas:', e)
"
else
    echo "   ℹ️ No hay estadísticas disponibles"
fi

echo ""

# Estadísticas del directorio de mapas
echo "🗺️ MAPAS ESTÁTICOS:"
if [ -d "$MAPS_DIR" ]; then
    TOTAL_FILES=$(find "$MAPS_DIR" -name "data_*.json" | wc -l)
    TOTAL_SIZE=$(du -sh "$MAPS_DIR" | cut -f1)
    LATEST_FILE=$(find "$MAPS_DIR" -name "data_*.json" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    echo "   📁 Directorio: $MAPS_DIR"
    echo "   🗂️ Total archivos: $TOTAL_FILES"
    echo "   💾 Tamaño total: $TOTAL_SIZE"
    
    if [ -n "$LATEST_FILE" ]; then
        LATEST_NAME=$(basename "$LATEST_FILE")
        LATEST_TIME=$(stat -c %y "$LATEST_FILE" 2>/dev/null | cut -d. -f1)
        echo "   🆕 Último generado: $LATEST_NAME"
        echo "   ⏰ Fecha: $LATEST_TIME"
    fi
    
    # Top 5 archivos más grandes
    echo ""
    echo "   📊 Top 5 mapas más grandes:"
    find "$MAPS_DIR" -name "data_*.json" -type f -exec ls -lh {} \; | \
    sort -k5 -hr | head -5 | \
    awk '{print "      " $9 " (" $5 ")"}' | \
    sed 's|static_maps/||g' || echo "      (no se pudo obtener información)"
    
else
    echo "   ❌ Directorio de mapas no encontrado"
fi

echo ""

# Logs disponibles
echo "📋 LOGS:"
LOGS_DIR="logs"
if [ -d "$LOGS_DIR" ]; then
    LOG_COUNT=$(find "$LOGS_DIR" -name "background_generator_*.log" | wc -l)
    LOGS_SIZE=$(du -sh "$LOGS_DIR" 2>/dev/null | cut -f1 || echo "N/A")
    
    echo "   📁 Directorio: $LOGS_DIR"
    echo "   📄 Archivos de log: $LOG_COUNT"
    echo "   💾 Tamaño logs: $LOGS_SIZE"
    
    # Último log
    LATEST_LOG=$(ls -t "$LOGS_DIR"/background_generator_*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        LOG_SIZE=$(ls -lh "$LATEST_LOG" | awk '{print $5}')
        echo "   🆕 Log actual: $(basename "$LATEST_LOG") ($LOG_SIZE)"
    fi
else
    echo "   ❌ No hay directorio de logs"
fi

echo ""

# Recursos del sistema
echo "💻 SISTEMA:"
echo "   💾 RAM libre: $(free -h | awk 'NR==2{print $7}')"
echo "   💽 Disco libre: $(df -h . | awk 'NR==2{print $4}')"
echo "   🌡️ Load average: $(uptime | awk -F'load average:' '{print $2}')"

echo ""

# Estimaciones
echo "📊 ESTIMACIONES:"
if [ -f "$STATS_FILE" ] && [ -d "$MAPS_DIR" ]; then
    python3 -c "
import json
import os
from datetime import datetime

try:
    # Leer stats
    with open('$STATS_FILE', 'r') as f:
        stats = json.load(f)
    
    maps_generated = stats.get('maps_generated', 0)
    
    if maps_generated > 0 and 'started_at' in stats:
        start_time = datetime.fromisoformat(stats['started_at'].replace('Z', '+00:00'))
        now = datetime.now()
        if 'last_activity' in stats:
            now = datetime.fromisoformat(stats['last_activity'].replace('Z', '+00:00'))
        
        elapsed_hours = (now - start_time).total_seconds() / 3600
        
        if elapsed_hours > 0:
            rate_per_hour = maps_generated / elapsed_hours
            
            # Estimar configuraciones totales posibles (aproximado)
            estimated_total = 50000  # Estimación conservadora
            remaining = max(0, estimated_total - maps_generated)
            
            if rate_per_hour > 0:
                hours_remaining = remaining / rate_per_hour
                
                print(f'   ⚡ Velocidad actual: {rate_per_hour:.1f} mapas/hora')
                print(f'   📊 Progreso estimado: {(maps_generated/estimated_total)*100:.1f}%')
                
                if hours_remaining < 24:
                    print(f'   ⏳ Tiempo restante estimado: {hours_remaining:.1f} horas')
                else:
                    print(f'   ⏳ Tiempo restante estimado: {hours_remaining/24:.1f} días')

except Exception as e:
    print('   ⚠️ Error calculando estimaciones:', e)
"
else
    echo "   ℹ️ No hay suficientes datos para estimaciones"
fi

echo ""
echo "🎯 COMANDOS DE CONTROL:"
echo "   ./pm2_start.sh   - Iniciar generador"
echo "   ./pm2_stop.sh    - Detener generador"
echo "   ./pm2_restart.sh - Reiniciar generador"
echo "   ./pm2_logs.sh    - Ver logs en tiempo real"
echo "   ./pm2_status.sh  - Estado rápido"