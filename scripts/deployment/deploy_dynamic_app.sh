#!/bin/bash

echo "🎨 DESPLEGANDO APLICACIÓN DINÁMICA CON GENERACIÓN EN TIEMPO REAL"
echo "================================================================"

# Detener aplicaciones previas
echo "🛑 Deteniendo aplicaciones previas..."
pkill -f static_app.py 2>/dev/null || true
pkill -f app_optimized.py 2>/dev/null || true
sleep 2

# Verificar puerto 3000
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "⚠️  Puerto 3000 en uso. Liberando..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

cd /home/sebastianvernis/servidor_descarga

# Iniciar aplicación dinámica
echo "🚀 Iniciando aplicación dinámica en puerto 3000..."
nohup venv/bin/python app_optimized.py > dynamic_app.log 2>&1 &
APP_PID=$!

echo "🔄 Esperando a que la aplicación inicie..."
sleep 5

# Verificar que se inició
if ps -p $APP_PID > /dev/null 2>&1; then
    echo "✅ Proceso iniciado (PID: $APP_PID)"
    
    # Verificar conectividad
    for i in {1..10}; do
        if venv/bin/python -c "
import requests
try:
    r = requests.get('http://localhost:3000/api/info', timeout=3)
    if r.status_code == 200:
        print('✅ Servidor respondiendo')
        exit(0)
except:
    pass
exit(1)
" 2>/dev/null; then
            break
        fi
        echo "⏳ Esperando..."
        sleep 1
    done
    
    echo ""
    echo "🎨 APLICACIÓN DINÁMICA DESPLEGADA!"
    echo ""
    echo "🔧 CARACTERÍSTICAS:"
    echo "   ✅ Generación de mapas en tiempo real"
    echo "   ✅ Selector completo de parámetros"
    echo "   ✅ Cache en disco para optimización"
    echo "   ✅ Análisis matemático avanzado"
    echo ""
    echo "🌐 ACCESO:"
    echo "   http://localhost:3000/"
    echo ""
    echo "📝 LOGS:"
    echo "   tail -f dynamic_app.log"
else
    echo "❌ Error al iniciar la aplicación"
    if [ -f dynamic_app.log ]; then
        tail -10 dynamic_app.log
    fi
    exit 1
fi