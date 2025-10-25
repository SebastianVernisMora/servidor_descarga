#!/bin/bash

echo "🚀 Desplegando Mapa Interactivo Mejorado de Números Primos..."
echo "=================================================="

# Verificar si ya está ejecutándose
if pgrep -f "deploy_enhanced.py" > /dev/null; then
    echo "⚠️  Aplicación ya está ejecutándose. Reiniciando..."
    pkill -f deploy_enhanced.py
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

# Ejecutar aplicación en background
echo "🚀 Iniciando aplicación mejorada en puerto 8000..."
nohup python3 deploy_enhanced.py > enhanced_app.log 2>&1 &

# Esperar a que inicie
sleep 3

# Verificar que está corriendo
if pgrep -f "deploy_enhanced.py" > /dev/null; then
    echo "✅ Aplicación iniciada exitosamente!"
    echo ""
    echo "📊 URLs disponibles:"
    echo "   🎨 Interfaz Principal: http://localhost:8000/enhanced"
    echo "   🔧 API Interactiva:    http://localhost:8000/api/interactive-map"
    echo "   📈 Información:        http://localhost:8000/api/info"
    echo ""
    echo "🧪 Probando la aplicación..."
    
    # Test básico de la API
    if curl -s -X POST "http://localhost:8000/api/interactive-map" \
        -H "Content-Type: application/json" \
        -d '{"num_circulos": 3, "divisiones_por_circulo": 12}' | grep -q "elementos"; then
        echo "✅ API funcionando correctamente"
    else
        echo "⚠️  API podría tener problemas"
    fi
    
    # Test de la interfaz
    if curl -s "http://localhost:8000/enhanced" | grep -q "Mapa Interactivo Mejorado"; then
        echo "✅ Interfaz accesible"
    else
        echo "⚠️  Interfaz podría tener problemas"
    fi
    
    echo ""
    echo "🎉 DESPLIEGUE COMPLETADO EXITOSAMENTE!"
    echo ""
    echo "📝 Para ver logs en tiempo real:"
    echo "   tail -f enhanced_app.log"
    echo ""
    echo "🔄 Para reiniciar:"
    echo "   ./deploy_to_domain.sh"
    echo ""
    echo "🛑 Para detener:"
    echo "   pkill -f deploy_enhanced.py"
    echo ""
    echo "🌐 Accede a tu aplicación desde el navegador:"
    echo "   http://TU_DOMINIO:8000/enhanced"
    
else
    echo "❌ Error: La aplicación no se pudo iniciar"
    echo "Revisando logs..."
    if [ -f "enhanced_app.log" ]; then
        tail -10 enhanced_app.log
    fi
    exit 1
fi