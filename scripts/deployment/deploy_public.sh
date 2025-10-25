#!/bin/bash

echo "🌐 DESPLEGANDO EN PUERTO PÚBLICO 3000"
echo "======================================"
echo "⚠️  ATENCIÓN: Esto reemplazará la aplicación actual en puerto 3000"
echo ""

# Verificar confirmación
read -p "¿Continuar con el despliegue público? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Despliegue cancelado"
    exit 1
fi

echo "🔄 Preparando despliegue..."

# Detener aplicaciones en puerto 3000 y 8000
echo "🛑 Deteniendo aplicaciones existentes..."
pkill -f "deploy_enhanced.py"
pkill -f "app_optimized.py"
pkill -f "app.py.*3000"

# Esperar a que se detengan completamente
sleep 3

# Verificar si hay procesos usando puerto 3000
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "⚠️  Hay procesos usando el puerto 3000. Intentando terminarlos..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Cambiar al directorio correcto
cd /home/admin

# Verificar archivos necesarios
if [ ! -f "deploy_enhanced.py" ]; then
    echo "❌ Error: deploy_enhanced.py no encontrado"
    exit 1
fi

if [ ! -f "index_interactive_enhanced.html" ]; then
    echo "❌ Error: index_interactive_enhanced.html no encontrado"
    exit 1
fi

echo "✅ Archivos verificados"

# Crear log específico para puerto público
LOG_FILE="public_app.log"

# Ejecutar aplicación mejorada en puerto 3000
echo "🚀 Iniciando aplicación mejorada en PUERTO PÚBLICO 3000..."
nohup python3 deploy_enhanced.py > $LOG_FILE 2>&1 &

# Esperar a que inicie
sleep 5

# Verificar que está corriendo
if pgrep -f "deploy_enhanced.py" > /dev/null; then
    echo "✅ Aplicación desplegada exitosamente en puerto público!"
    echo ""
    echo "🌐 URLs PÚBLICAS disponibles:"
    echo "   🎨 Interfaz Principal: http://localhost:3000/enhanced"
    echo "   🏠 Página de Inicio:   http://localhost:3000/"
    echo "   🔧 API Interactiva:    http://localhost:3000/api/interactive-map"
    echo "   📊 API Análisis:       http://localhost:3000/api/number/97"
    echo "   📈 Información:        http://localhost:3000/api/info"
    echo ""
    echo "🧪 Probando la aplicación pública..."
    
    # Esperar un poco más para asegurar que está lista
    sleep 2
    
    # Test básico de la API
    if timeout 10 python3 -c "
import requests
try:
    response = requests.post('http://localhost:3000/api/interactive-map', 
                           json={'num_circulos': 3, 'divisiones_por_circulo': 12}, 
                           timeout=5)
    if response.status_code == 200 and 'elementos' in response.json():
        print('✅ API funcionando correctamente')
    else:
        print('⚠️  API respondió pero podría tener problemas')
except:
    print('⚠️  API no responde - verificar logs')
    "; then
        :
    fi
    
    # Test de la interfaz
    if timeout 5 python3 -c "
import requests
try:
    response = requests.get('http://localhost:3000/enhanced', timeout=3)
    if response.status_code == 200 and 'Mapa Interactivo Mejorado' in response.text:
        print('✅ Interfaz pública accesible')
    else:
        print('⚠️  Interfaz respondió pero podría tener problemas')
except:
    print('⚠️  Interfaz no responde - verificar logs')
    "; then
        :
    fi
    
    echo ""
    echo "🎉 DESPLIEGUE PÚBLICO COMPLETADO!"
    echo ""
    echo "🌍 Tu aplicación está ahora disponible públicamente en:"
    echo "   http://TU_DOMINIO:3000/enhanced"
    echo "   http://TU_DOMINIO:3000/"
    echo ""
    echo "📊 Características desplegadas:"
    echo "   ✅ Mapa interactivo HTML (sin imágenes)"
    echo "   ✅ Tooltips matemáticos avanzados"
    echo "   ✅ API responsiva para mapas dinámicos"
    echo "   ✅ Responsive design para móviles"
    echo "   ✅ Múltiples mapeos matemáticos"
    echo "   ✅ Tipos de primos clasificados"
    echo ""
    echo "📝 Para ver logs en tiempo real:"
    echo "   tail -f $LOG_FILE"
    echo ""
    echo "🔄 Para reiniciar:"
    echo "   ./deploy_public.sh"
    echo ""
    echo "🛑 Para detener:"
    echo "   pkill -f deploy_enhanced.py"
    
else
    echo "❌ Error: La aplicación no se pudo iniciar en puerto 3000"
    echo "Revisando logs..."
    if [ -f "$LOG_FILE" ]; then
        echo "Últimas líneas del log:"
        tail -15 $LOG_FILE
    fi
    
    # Verificar si hay algo usando el puerto
    echo ""
    echo "Verificando puerto 3000..."
    if lsof -i:3000 2>/dev/null; then
        echo "Hay algo usando el puerto 3000"
    else
        echo "Puerto 3000 libre"
    fi
    
    exit 1
fi