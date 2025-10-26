#!/bin/bash
# 🛑 DETENER GENERADOR DE MAPAS PERSISTENTE

echo "🛑 DETENIENDO GENERADOR DE MAPAS..."

PID_FILE="logs/background_generator.pid"

# Verificar si existe el archivo PID
if [ ! -f "$PID_FILE" ]; then
    echo "⚠️ No se encontró archivo PID, buscando procesos manualmente..."
    
    # Buscar por nombre de proceso
    PIDS=$(pgrep -f "background_map_generator.py")
    if [ -n "$PIDS" ]; then
        echo "📍 Procesos encontrados: $PIDS"
        for pid in $PIDS; do
            echo "🛑 Deteniendo PID $pid..."
            kill -TERM "$pid"
            sleep 2
            
            # Verificar si el proceso aún existe
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️ Proceso $pid no respondió a TERM, usando KILL..."
                kill -KILL "$pid"
            fi
        done
        echo "✅ Todos los procesos del generador detenidos"
    else
        echo "ℹ️ No hay procesos del generador corriendo"
    fi
else
    # Leer PID del archivo
    PID=$(cat "$PID_FILE")
    
    if kill -0 "$PID" 2>/dev/null; then
        echo "🛑 Deteniendo generador con PID $PID..."
        
        # Enviar señal TERM para terminación elegante
        kill -TERM "$PID"
        
        # Esperar hasta 10 segundos para terminación elegante
        for i in {1..10}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                echo "✅ Generador detenido exitosamente"
                break
            fi
            echo "⏳ Esperando terminación elegante... ($i/10)"
            sleep 1
        done
        
        # Si aún está corriendo, forzar terminación
        if kill -0 "$PID" 2>/dev/null; then
            echo "⚠️ Forzando terminación..."
            kill -KILL "$PID"
            sleep 1
            
            if ! kill -0 "$PID" 2>/dev/null; then
                echo "✅ Generador terminado forzadamente"
            else
                echo "❌ Error: No se pudo detener el proceso"
                exit 1
            fi
        fi
        
        # Limpiar archivo PID
        rm -f "$PID_FILE"
        
    else
        echo "ℹ️ El proceso con PID $PID ya no existe"
        rm -f "$PID_FILE"
    fi
fi

echo "🔚 Generador de mapas detenido"