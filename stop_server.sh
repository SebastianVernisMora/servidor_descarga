#!/bin/bash
# 🛑 DETENER TODOS LOS PROCESOS DEL SERVIDOR

echo "🛑 Deteniendo todos los procesos del servidor..."

# Matar todos los procesos relacionados
pkill -f "python.*app" 2>/dev/null && echo "✅ Procesos python app detenidos"
pkill -f "python.*deploy" 2>/dev/null && echo "✅ Procesos deploy detenidos"
pkill -f "flask" 2>/dev/null && echo "✅ Procesos flask detenidos"
pkill -f "gunicorn" 2>/dev/null && echo "✅ Procesos gunicorn detenidos"
pkill -f "static_app.py" 2>/dev/null && echo "✅ Aplicación estática detenida"

# Verificar que no hay procesos corriendo
REMAINING=$(ps aux | grep -E "(python.*app|python.*deploy|flask|gunicorn)" | grep -v grep | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ Todos los procesos del servidor han sido detenidos"
else
    echo "⚠️ $REMAINING procesos aún corriendo:"
    ps aux | grep -E "(python.*app|python.*deploy|flask|gunicorn)" | grep -v grep
fi

# Limpiar archivos de log temporales
rm -f optimized.log enhanced_app.log public_app.log static_deployment.log 2>/dev/null

echo "🔥 SERVIDOR COMPLETAMENTE DETENIDO"