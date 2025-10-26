#!/bin/bash
# 🔄 REINICIAR GENERADOR DE MAPAS PERSISTENTE

echo "🔄 REINICIANDO GENERADOR DE MAPAS..."
echo "===================================="

# Detener primero
echo "🛑 Paso 1: Deteniendo generador actual..."
./pm2_stop.sh

# Esperar un momento
echo "⏳ Esperando 3 segundos..."
sleep 3

# Iniciar de nuevo
echo "🚀 Paso 2: Iniciando generador..."
./pm2_start.sh

echo ""
echo "✅ REINICIO COMPLETADO"