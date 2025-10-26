#!/bin/bash
# 🚀 INICIO PERSISTENTE DEL GENERADOR DE MAPAS (Estilo PM2)

echo "🚀 INICIANDO GENERADOR DE MAPAS PERSISTENTE..."

# Verificar si ya está corriendo
if pgrep -f "background_map_generator.py" > /dev/null; then
    echo "⚠️ El generador ya está corriendo"
    echo "📊 PIDs activos:"
    pgrep -f "background_map_generator.py" -l
    exit 1
fi

# Crear directorio de logs
mkdir -p logs

# Timestamp para logs únicos
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/background_generator_${TIMESTAMP}.log"
PID_FILE="logs/background_generator.pid"

echo "📁 Logs: $LOG_FILE"
echo "🆔 PID file: $PID_FILE"

# Iniciar en segundo plano con nohup
nohup python3 background_map_generator.py > "$LOG_FILE" 2>&1 &

# Capturar PID
GENERATOR_PID=$!
echo "$GENERATOR_PID" > "$PID_FILE"

# Esperar un momento para verificar que inició correctamente
sleep 3

if kill -0 "$GENERATOR_PID" 2>/dev/null; then
    echo "✅ Generador iniciado exitosamente"
    echo "🆔 PID: $GENERATOR_PID"
    echo "📊 Estado: CORRIENDO"
    echo ""
    echo "🎯 COMANDOS DE CONTROL:"
    echo "   Ver logs:     tail -f $LOG_FILE"
    echo "   Ver estado:   ./pm2_status.sh"
    echo "   Detener:      ./pm2_stop.sh"
    echo "   Reiniciar:    ./pm2_restart.sh"
    echo "   Ver stats:    ./pm2_stats.sh"
    echo ""
    echo "🔥 GENERADOR PERSISTENTE ACTIVO - Creando mapas continuamente..."
else
    echo "❌ Error: El generador no pudo iniciarse"
    if [ -f "$LOG_FILE" ]; then
        echo "📋 Últimas líneas del log:"
        tail -10 "$LOG_FILE"
    fi
    exit 1
fi