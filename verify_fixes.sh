#!/bin/bash
# Script de verificación (sin sudo) para monitorear el progreso

echo "🔍 VERIFICACIÓN DEL ESTADO DE LA APLICACIÓN"
echo "==========================================="

echo ""
echo "📊 MEMORIA ACTUAL:"
free -h

echo ""
echo "🐍 PROCESOS GUNICORN:"
ps aux | grep gunicorn | grep -v grep | wc -l | xargs echo "Número de procesos:"
ps aux | grep gunicorn | grep -v grep | head -3

echo ""
echo "🌐 CONEXIÓN LOCAL:"
echo -n "Puerto 5000: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null || echo "No responde"

echo -n "API endpoint: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/info 2>/dev/null || echo "No responde"

echo ""
echo "⚙️  CONFIGURACIÓN GUNICORN:"
if [ -f "/var/www/prime-visualization/gunicorn.conf.py" ]; then
    echo -n "Workers configurados: "
    grep "workers =" /var/www/prime-visualization/gunicorn.conf.py 2>/dev/null || echo "No se puede leer"
else
    echo "Archivo de configuración no accesible"
fi

echo ""
echo "📁 TEMPLATES DISPONIBLES:"
if [ -d "/var/www/prime-visualization/templates" ]; then
    ls -la /var/www/prime-visualization/templates/ 2>/dev/null || echo "No se puede leer directorio"
else
    echo "Directorio templates no accesible"
fi

echo ""
echo "🧪 TEST DIRECTO DE RUTAS:"
cd /home/admin && python3 test_flask_route.py 2>/dev/null || echo "Test no disponible"

echo ""
echo "✅ Verificación completada - $(date)"