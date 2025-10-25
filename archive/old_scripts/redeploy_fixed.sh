#!/bin/bash

# Script de redespliegue corregido - maneja SSL paso a paso

set -e

echo "🚀 REDESPLIEGUE AUTOMÁTICO CON CONFIGURACIÓN BLACKBOX"
echo "===================================================="

# Cargar configuración
source_config() {
    if [ -f ".blackbox" ]; then
        echo "📋 Cargando configuración desde .blackbox..."
        export $(grep -v '^#' .blackbox | grep '=' | xargs)
        echo "✅ Configuración cargada"
    else
        echo "⚠️  Archivo .blackbox no encontrado, usando valores por defecto"
        export APP_PORT=5001
        export ENABLE_SSL=true
        export HOST=127.0.0.1
    fi
}

# Detener aplicaciones existentes (solo las que podemos)
stop_services() {
    echo "🛑 Deteniendo servicios que podemos controlar..."
    
    # Detener nuestras aplicaciones Python
    pkill -f "app_configurable.py" || true
    pkill -f "app_optimized.py" || true
    
    sleep 2
    echo "✅ Servicios detenidos"
}

# Configurar nginx básico (sin SSL primero)
setup_nginx_basic() {
    echo "🔧 Configurando nginx básico (HTTP)..."
    
    # Verificar si nginx está instalado
    if ! command -v nginx &> /dev/null; then
        echo "📦 Instalando nginx..."
        sudo apt update
        sudo apt install -y nginx
    fi
    
    # Crear configuración básica HTTP
    sudo tee /etc/nginx/sites-available/prime-viz > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

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

    # Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
EOF
    
    # Habilitar sitio
    sudo ln -sf /etc/nginx/sites-available/prime-viz /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Verificar configuración
    sudo nginx -t
    
    echo "✅ Nginx básico configurado"
}

# Iniciar aplicación
start_app() {
    echo "🚀 Iniciando aplicación..."
    
    cd /home/admin
    
    # Crear directorio para logs si no existe
    mkdir -p logs
    
    # Iniciar aplicación
    nohup python3 app_configurable.py > logs/app.log 2>&1 &
    
    # Esperar y verificar
    sleep 3
    
    if pgrep -f "app_configurable.py" > /dev/null; then
        echo "✅ Aplicación iniciada correctamente"
    else
        echo "❌ Error al iniciar aplicación"
        echo "📋 Últimas líneas del log:"
        tail -n 10 logs/app.log 2>/dev/null || echo "No hay logs disponibles"
        exit 1
    fi
}

# Reiniciar nginx
restart_nginx() {
    echo "🔄 Reiniciando nginx..."
    sudo systemctl restart nginx
    
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx reiniciado correctamente"
    else
        echo "❌ Error en nginx"
        sudo systemctl status nginx --no-pager
        exit 1
    fi
}

# Configurar SSL después
setup_ssl_after() {
    if [ "$ENABLE_SSL" = "true" ]; then
        echo "🔐 Configurando SSL..."
        
        # Instalar certbot si no existe
        if ! command -v certbot &> /dev/null; then
            echo "📦 Instalando certbot..."
            sudo apt install -y certbot python3-certbot-nginx
        fi
        
        # Obtener certificado
        echo "🔐 Obteniendo certificado SSL..."
        sudo certbot --nginx \
            -d ${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com} \
            --non-interactive \
            --agree-tos \
            --email ${SSL_EMAIL:-admin@amazonaws.com} \
            --redirect || {
                echo "⚠️  Error obteniendo certificado SSL, continuando sin SSL"
                echo "📋 La aplicación estará disponible solo por HTTP"
                return 0
            }
        
        # Habilitar renovación automática
        sudo systemctl enable certbot.timer || true
        
        echo "✅ SSL configurado"
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
    echo "  • Aplicación Flask: $(pgrep -f 'app_configurable.py' > /dev/null && echo '✅ Corriendo' || echo '❌ Detenida')"
    echo "  • Nginx: $(sudo systemctl is-active nginx 2>/dev/null || echo '❌ Detenido')"
    
    # Verificar SSL
    SSL_STATUS="❌ No configurado"
    if [ "$ENABLE_SSL" = "true" ] && sudo certbot certificates 2>/dev/null | grep -q "${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"; then
        SSL_STATUS="✅ Configurado"
    fi
    echo "  • SSL: $SSL_STATUS"
    
    # Mostrar URLs de acceso
    echo ""
    echo "🌐 URLs de acceso:"
    if [ "$SSL_STATUS" = "✅ Configurado" ]; then
        echo "  • HTTPS: https://${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"
        echo "  • HTTP: http://${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com} (redirige a HTTPS)"
    else
        echo "  • HTTP: http://${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"
    fi
    echo "  • Local: http://127.0.0.1:${APP_PORT:-5001}"
    
    # Mostrar información de configuración actual
    echo ""
    echo "📋 Configuración actual (.blackbox):"
    echo "  • Puerto: ${APP_PORT:-5001}"
    echo "  • SSL habilitado: ${ENABLE_SSL:-true}"
    echo "  • Dominio: ${DOMAIN:-ec2-44-195-68-60.compute-1.amazonaws.com}"
    echo "  • Método: ${DEPLOY_METHOD:-flask}"
    
    echo ""
    echo "📋 Para ver logs:"
    echo "  • App: tail -f /home/admin/logs/app.log"
    echo "  • Nginx: sudo tail -f /var/log/nginx/error.log"
}

# Ejecución principal
main() {
    echo "Iniciando redespliegue..."
    
    source_config
    stop_services
    setup_nginx_basic
    start_app
    restart_nginx
    setup_ssl_after
    verify_deployment
    
    echo ""
    echo "✅ ¡REDESPLIEGUE COMPLETADO!"
    echo "🔧 Para cambiar puerto u otras opciones, edita .blackbox y ejecuta:"
    echo "   bash redeploy_fixed.sh"
}

# Ejecutar función principal
main