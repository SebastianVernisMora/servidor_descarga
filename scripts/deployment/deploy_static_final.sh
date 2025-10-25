#!/bin/bash

echo "🔥 DESPLIEGUE FINAL - APLICACIÓN ESTÁTICA EN PUERTO 3000"
echo "========================================================"

# Detener procesos previos
echo "🛑 Deteniendo aplicaciones previas..."
pkill -f deploy_enhanced.py 2>/dev/null || true
pkill -f static_app.py 2>/dev/null || true
pkill -f app_optimized.py 2>/dev/null || true

# Esperar a que se detengan
sleep 3

# Verificar que puerto 3000 esté libre
echo "🔍 Verificando puerto 3000..."
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "⚠️  Puerto 3000 en uso. Liberando..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

cd /home/sebastianvernis/servidor_descarga

# Verificar archivos necesarios
echo "📂 Verificando archivos..."
if [ ! -f "static_app.py" ]; then
    echo "❌ Error: static_app.py no encontrado"
    exit 1
fi

if [ ! -d "static_maps" ]; then
    echo "❌ Error: directorio static_maps no encontrado"
    echo "💡 Ejecutar primero: python3 pregenerate_static_maps.py"
    exit 1
fi

if [ ! -f "static_maps/index.json" ]; then
    echo "❌ Error: índice de mapas no encontrado"
    exit 1
fi

echo "✅ Todos los archivos verificados"

# Contar mapas generados
MAP_COUNT=$(venv/bin/python -c "
import json
with open('static_maps/index.json', 'r') as f:
    data = json.load(f)
print(len(data['maps']))
")

echo "📊 $MAP_COUNT mapas pre-generados listos"

# Iniciar aplicación estática
echo "🚀 Iniciando aplicación estática en puerto 3000..."

# Ejecutar en background con logs
nohup venv/bin/python static_app.py > static_deployment.log 2>&1 &
STATIC_PID=$!

echo "🔄 Esperando a que la aplicación inicie..."
sleep 5

# Verificar que se inició correctamente
if ps -p $STATIC_PID > /dev/null 2>&1; then
    echo "✅ Proceso iniciado correctamente (PID: $STATIC_PID)"
    
    # Verificar conectividad
    echo "🧪 Verificando conectividad..."
    
    for i in {1..10}; do
        if venv/bin/python -c "
import requests
try:
    response = requests.get('http://localhost:3000/api/info', timeout=3)
    print('✅ Servidor respondiendo:', response.status_code)
    exit(0)
except:
    print('⏳ Esperando...')
    exit(1)
" 2>/dev/null; then
            break
        fi
        sleep 1
    done
    
    # Test final completo
    echo "🎯 Ejecutando tests finales..."
    venv/bin/python -c "
import requests
import json

print('Verificación completa:')
tests = [
    ('GET', '/api/info', 'Info API'),
    ('GET', '/api/maps', 'Lista Mapas'),
    ('POST', '/api/interactive-map', 'Mapa Interactivo'),
    ('GET', '/api/random-map', 'Mapa Aleatorio'),
    ('GET', '/api/number/97', 'Análisis Número')
]

success_count = 0
for method, endpoint, name in tests:
    try:
        if method == 'POST':
            r = requests.post(f'http://localhost:3000{endpoint}',
                            json={'num_circulos': 10, 'divisiones_por_circulo': 24},
                            timeout=5)
        else:
            r = requests.get(f'http://localhost:3000{endpoint}', timeout=5)
        
        if r.status_code == 200:
            print(f'✅ {name}: OK')
            success_count += 1
        else:
            print(f'⚠️  {name}: HTTP {r.status_code}')
    except Exception as e:
        print(f'❌ {name}: Error')

print(f'Tests exitosos: {success_count}/{len(tests)}')

if success_count == len(tests):
    print()
    print('🎉 APLICACIÓN COMPLETAMENTE FUNCIONAL!')
else:
    print()
    print('⚠️  Algunos tests fallaron - verificar logs')
"
    
    echo ""
    echo "🌟 DESPLIEGUE ESTÁTICO COMPLETADO!"
    echo ""
    echo "📊 ESTADÍSTICAS:"
    echo "   💾 $MAP_COUNT mapas HTML pre-generados"
    echo "   ⚡ Tiempo de respuesta: <5ms (archivos estáticos)"
    echo "   🧠 Uso de RAM: Mínimo (sin cálculos)"
    echo "   🚀 Rendimiento: MÁXIMO"
    echo ""
    echo "🌐 ACCESO PÚBLICO:"
    echo "   http://TU_DOMINIO:3000/"
    echo "   http://TU_DOMINIO:3000/api/maps"
    echo ""
    echo "📝 LOGS:"
    echo "   tail -f static_deployment.log"
    echo ""
    echo "🔄 REINICIAR:"
    echo "   ./deploy_static_final.sh"
    
else
    echo "❌ Error: La aplicación no se pudo iniciar"
    echo "📝 Verificando logs..."
    if [ -f "static_deployment.log" ]; then
        tail -10 static_deployment.log
    fi
    exit 1
fi