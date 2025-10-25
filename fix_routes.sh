#!/bin/bash
echo "🔧 Corrigiendo rutas Flask..."

# Backup actual
sudo cp /var/www/prime-visualization/app.py /var/www/prime-visualization/app_before_route_fix.py

# Corregir rutas
sudo sed -i '982,984c\
    """Página principal."""\
    return render_template('"'"'index.html'"'"')' /var/www/prime-visualization/app.py

sudo sed -i '987,989c\
    """Página de login - redirige a main."""\
    return render_template('"'"'index.html'"'"')' /var/www/prime-visualization/app.py

sudo sed -i '992,994c\
    """Aplicación principal."""\
    return render_template('"'"'index.html'"'"')' /var/www/prime-visualization/app.py

# Verificar cambios
echo "📋 Verificando cambios:"
sudo sed -n '980,995p' /var/www/prime-visualization/app.py

echo ""
echo "🔄 Reiniciando Gunicorn..."
sudo supervisorctl restart gunicorn-prime

echo "⏳ Esperando reinicio..."
sleep 3

echo "🧪 Probando ruta corregida..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/

echo ""
echo "✅ Corrección aplicada!"