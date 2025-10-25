#!/bin/bash

echo "🌐 VERIFICACIÓN DE DESPLIEGUE PÚBLICO"
echo "======================================"

echo "🔍 Verificando estado de servicios..."

# Verificar aplicación estática
if ps aux | grep -q "static_app.py" && ! ps aux | grep "static_app.py" | grep -q grep; then
    echo "✅ Aplicación estática ejecutándose en puerto 3000"
else
    echo "❌ Aplicación estática NO ejecutándose"
    echo "💡 Ejecutar: cd /home/admin && ./deploy_static_final.sh"
    exit 1
fi

# Verificar nginx
if ps aux | grep -q "nginx: master" && ! ps aux | grep "nginx: master" | grep -q grep; then
    echo "✅ Nginx ejecutándose"
else
    echo "❌ Nginx no está ejecutándose"
    exit 1
fi

echo ""
echo "🧪 Probando conectividad..."

# Test puerto 3000 (directo)
if python3 -c "
import requests
try:
    r = requests.get('http://localhost:3000/api/info', timeout=5)
    if r.status_code == 200:
        data = r.json()
        print(f'✅ Puerto 3000: {data[\"statistics\"][\"total_maps\"]} mapas disponibles')
    else:
        print(f'⚠️  Puerto 3000: HTTP {r.status_code}')
        exit(1)
except Exception as e:
    print(f'❌ Puerto 3000: {e}')
    exit(1)
"; then
    :
else
    echo "❌ Aplicación estática no responde en puerto 3000"
    exit 1
fi

# Test puerto 80 (nginx)
echo "🌐 Verificando acceso público..."

python3 -c "
import requests

try:
    # Test página principal
    r = requests.get('http://localhost/', timeout=5)
    print(f'Puerto 80 status: {r.status_code}')
    
    if r.status_code == 200:
        content = r.text
        if 'Pre-generados' in content or 'static' in content.lower():
            print('✅ NGINX SIRVIENDO APLICACIÓN ESTÁTICA')
            print('🎉 DESPLIEGUE PÚBLICO EXITOSO!')
        elif 'Visualización' in content or 'Mapa Interactivo' in content:
            print('⚠️  NGINX SIRVIENDO APLICACIÓN ANTERIOR')
            print('💡 Necesitas configurar la redirección de nginx')
            print('📝 Ejecuta los comandos en: ./setup_nginx_redirect.sh')
        else:
            print('❓ Contenido no identificado en nginx')
    else:
        print(f'⚠️  Nginx respondió con HTTP {r.status_code}')
    
    # Test API a través de nginx
    try:
        r = requests.get('http://localhost/api/info', timeout=5)
        if r.status_code == 200:
            data = r.json()
            if 'static' in data.get('version', ''):
                print('✅ API estática accesible públicamente')
                print(f'📊 {data[\"statistics\"][\"total_maps\"]} mapas públicos')
            else:
                print('⚠️  API antigua todavía activa')
        else:
            print(f'⚠️  API: HTTP {r.status_code}')
    except:
        print('❌ API no accesible a través de nginx')

except Exception as e:
    print(f'❌ Error verificando nginx: {e}')
"

echo ""
echo "📊 ESTADO DE ARCHIVOS ESTÁTICOS:"
echo "Mapas generados: $(ls static_maps/*.html 2>/dev/null | wc -l)"
echo "Datos JSON: $(ls static_maps/*.json 2>/dev/null | wc -l)"
echo "Tamaño total: $(du -sh static_maps/ 2>/dev/null | cut -f1)"

echo ""
echo "📝 LOGS DISPONIBLES:"
echo "   tail -f static_deployment.log"

echo ""
echo "🔧 SI NECESITAS RECONFIGURAR:"
echo "   ./setup_nginx_redirect.sh  # Ver comandos de nginx"
echo "   ./deploy_static_final.sh   # Reiniciar aplicación estática"