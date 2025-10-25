#!/bin/bash

# Script de redespliegue automático con configuración .blackbox

set -e

echo "🚀 REDESPLIEGUE AUTOMÁTICO CON CONFIGURACIÓN BLACKBOX"
echo "===================================================="

# Cargar configuración
source_config() {
    if [ -f ".blackbox" ]; then
        echo "📋 Cargando configuración desde .blackbox..."
        # Exportar variables desde .blackbox
        export $(grep -v '^#' .blackbox | grep '=' | xargs)
        echo "✅ Configuración cargada"
    else
        echo "⚠️  Archivo .blackbox no encontrado, usando valores por defecto"
        export APP_PORT=5001
        export ENABLE_SSL=true
        export HOST=127.0.0.1
    fi
}

# Detener aplicaciones existentes
stop_services() {
    echo "🛑 Deteniendo servicios existentes..."
    
    # Detener aplicaciones Python
    pkill -f "python.*app" || true
    pkill -f gunicorn || true
    
    # Esperar a que terminen
    sleep 2
    
    echo "✅ Servicios detenidos"
}

# Configurar nginx si está habilitado
setup_nginx() {
    if [ "$USE_NGINX_PROXY" = "true" ] && [ "$ENABLE_SSL" = "true" ]; then
        echo "🔧 Configurando nginx con SSL..."
        
        # Verificar si nginx está instalado
        if ! command -v nginx &> /dev/null; then
            echo "📦 Instalando nginx..."
            sudo apt update
            sudo apt install -y nginx
        fi
        
        # Crear configuración nginx
        sudo tee /etc/nginx/sites-available/prime-viz > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com};

    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com};

    # SSL Configuration (will be managed by certbot)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Proxy to Flask app
    location / {
        proxy_pass http://127.0.0.1:${APP_PORT:-5001};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files
    location /static/ {
        alias /home/admin/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
        
        # Habilitar sitio
        sudo ln -sf /etc/nginx/sites-available/prime-viz /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
        
        # Verificar configuración
        sudo nginx -t
        
        echo "✅ Nginx configurado"
    fi
}

# Obtener certificado SSL
setup_ssl() {
    if [ "$ENABLE_SSL" = "true" ]; then
        echo "🔐 Configurando SSL..."
        
        # Instalar certbot si no existe
        if ! command -v certbot &> /dev/null; then
            echo "📦 Instalando certbot..."
            sudo apt install -y certbot python3-certbot-nginx
        fi
        
        # Verificar si ya existe el certificado
        if sudo certbot certificates 2>/dev/null | grep -q "${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"; then
            echo "📋 Certificado SSL ya existe"
        else
            echo "🔐 Obteniendo nuevo certificado SSL..."
            sudo certbot --nginx \
                -d ${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com} \
                --non-interactive \
                --agree-tos \
                --email ${SSL_EMAIL:-admin@amazonaws.com} \
                --redirect
        fi
        
        # Habilitar renovación automática
        sudo systemctl enable certbot.timer || true
        
        echo "✅ SSL configurado"
    fi
}

# Iniciar aplicación
start_app() {
    echo "🚀 Iniciando aplicación..."
    
    # Cambiar al directorio correcto
    cd /home/admin
    
    # Iniciar aplicación en background
    case "${DEPLOY_METHOD:-flask}" in
        "gunicorn")
            echo "🔧 Usando Gunicorn..."
            nohup gunicorn -w ${WORKERS:-4} -b ${HOST:-127.0.0.1}:${APP_PORT:-5001} app_configurable:app > app.log 2>&1 &
            ;;
        "flask"|*)
            echo "🔧 Usando Flask..."
            nohup python3 app_configurable.py > app.log 2>&1 &
            ;;
    esac
    
    # Esperar y verificar
    sleep 3
    
    if pgrep -f "python.*app" > /dev/null; then
        echo "✅ Aplicación iniciada correctamente"
    else
        echo "❌ Error al iniciar aplicación"
        echo "📋 Últimas líneas del log:"
        tail -n 10 app.log
        exit 1
    fi
}

# Reiniciar nginx si está habilitado
restart_nginx() {
    if [ "$USE_NGINX_PROXY" = "true" ]; then
        echo "🔄 Reiniciando nginx..."
        sudo systemctl restart nginx
        
        if sudo systemctl is-active --quiet nginx; then
            echo "✅ Nginx reiniciado correctamente"
        else
            echo "❌ Error en nginx"
            sudo systemctl status nginx --no-pager
            exit 1
        fi
    fi
}

# Verificar despliegue
verify_deployment() {
    echo "🔍 Verificando despliegue..."
    
    # Verificar aplicación local
    sleep 2
    if curl -s http://127.0.0.1:${APP_PORT:-5001}/api/info > /dev/null; then
        echo "✅ Aplicación Flask respondiendo localmente"
    else
        echo "⚠️  Aplicación Flask no responde localmente"
    fi
    
    # Mostrar estado
    echo ""
    echo "📊 Estado de servicios:"
    echo "  • Aplicación Flask: $(pgrep -f 'python.*app' > /dev/null && echo '✅ Corriendo' || echo '❌ Detenida')"
    if command -v nginx &> /dev/null; then
        echo "  • Nginx: $(sudo systemctl is-active nginx 2>/dev/null || echo 'No instalado')"
    fi
    
    # Mostrar URLs de acceso
    echo ""
    echo "🌐 URLs de acceso:"
    if [ "$ENABLE_SSL" = "true" ]; then
        echo "  • HTTPS: https://${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"
        echo "  • HTTP: http://${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com} (redirige a HTTPS)"
    else
        echo "  • HTTP: http://${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"
    fi
    echo "  • Local: http://127.0.0.1:${APP_PORT:-5001}"
    
    echo ""
    echo "📋 Para ver logs en tiempo real:"
    echo "  tail -f /home/admin/app.log"
}

# Ejecución principal
main() {
    echo "Iniciando redespliegue..."
    
    source_config
    stop_services
    
    if [ "$USE_NGINX_PROXY" = "true" ]; then
        setup_nginx
        if [ "$ENABLE_SSL" = "true" ]; then
            setup_ssl
        fi
    fi
    
    start_app
    
    if [ "$USE_NGINX_PROXY" = "true" ]; then
        restart_nginx
    fi
    
    verify_deployment
    
    echo ""
    echo "✅ ¡REDESPLIEGUE COMPLETADO!"
    echo "🔧 Para cambiar configuración, edita el archivo .blackbox y ejecuta ./redeploy.sh"
}

# Ejecutar función principal
main