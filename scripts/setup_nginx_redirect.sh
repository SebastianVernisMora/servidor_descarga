#!/bin/bash

echo "🌐 CONFIGURANDO REDIRECCIÓN DE NGINX A APLICACIÓN ESTÁTICA"
echo "=========================================================="

echo "⚠️  IMPORTANTE: Este script requiere permisos de administrador"
echo "Si no tienes sudo, copia y ejecuta los comandos manualmente como root"
echo ""

# Mostrar configuración necesaria
echo "📝 CONFIGURACIÓN NGINX NECESARIA:"
echo ""

cat > /tmp/nginx_static_config << 'EOF'
# Archivo: /etc/nginx/sites-available/static-primes
server {
    listen 80;
    server_name _;
    
    # Redirigir todo el tráfico a la aplicación estática en puerto 3000
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }
    
    # Headers para mejor performance de archivos estáticos
    location ~* \.(html|json)$ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_cache_valid 200 1h;
        add_header X-Static-Cache "HIT";
    }
}
EOF

echo "1️⃣ CREAR CONFIGURACIÓN DE NGINX:"
echo "sudo tee /etc/nginx/sites-available/static-primes << 'NGINX_CONFIG'"
cat /tmp/nginx_static_config
echo "NGINX_CONFIG"
echo ""

echo "2️⃣ ACTIVAR CONFIGURACIÓN:"
echo "sudo ln -sf /etc/nginx/sites-available/static-primes /etc/nginx/sites-enabled/"
echo "sudo nginx -t"
echo "sudo systemctl reload nginx"
echo ""

echo "3️⃣ VERIFICAR APLICACIÓN ESTÁTICA:"
echo "ps aux | grep static_app"
echo "curl http://localhost:3000/api/info"
echo ""

echo "4️⃣ COMANDOS COMPLETOS PARA COPY-PASTE:"
echo "----------------------------------------"

cat << 'COMMANDS'
# Crear configuración nginx
sudo tee /etc/nginx/sites-available/static-primes > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
    }
}
EOF

# Activar y aplicar
sudo ln -sf /etc/nginx/sites-available/static-primes /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Verificar
curl http://localhost/api/info
COMMANDS

echo ""
echo "🔍 DIAGNÓSTICO ACTUAL:"
echo "----------------------------------------"

# Verificar estado actual
echo "Puerto 80 (nginx):"
python3 -c "
import requests
try:
    r = requests.get('http://localhost', timeout=3)
    print(f'  Status: {r.status_code}')
    if 'Pre-generados' in r.text:
        print('  ✅ Ya sirviendo aplicación estática')
    elif 'Visualización' in r.text:
        print('  ⚠️  Sirviendo aplicación anterior')
    else:
        print('  ❓ Contenido no identificado')
except Exception as e:
    print(f'  ❌ Error: {e}')
"

echo ""
echo "Puerto 3000 (aplicación estática):"
python3 -c "
import requests
try:
    r = requests.get('http://localhost:3000/api/info', timeout=3)
    if r.status_code == 200:
        data = r.json()
        print(f'  ✅ Aplicación estática funcionando')
        print(f'  📊 {data[\"statistics\"][\"total_maps\"]} mapas disponibles')
        print(f'  🚀 Versión: {data[\"version\"]}')
    else:
        print(f'  ⚠️  Status: {r.status_code}')
except Exception as e:
    print(f'  ❌ Error: {e}')
"

echo ""
echo "🎯 PRÓXIMOS PASOS:"
echo "1. Ejecutar los comandos sudo de arriba para configurar nginx"
echo "2. La aplicación estática ya está funcionando en puerto 3000"
echo "3. Nginx redirigirá el tráfico público a la aplicación estática"
echo ""
echo "🌐 Después de la configuración, accede a:"
echo "   http://TU_DOMINIO/ (redirigirá a aplicación estática)"