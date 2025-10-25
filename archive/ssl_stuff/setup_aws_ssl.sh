#!/bin/bash

# Configuración SSL para dominio AWS EC2
# Dominio: ec2-44-195-68-60.compute-1.amazonaws.com

set -e

DOMAIN="ec2-44-195-68-60.compute-1.amazonaws.com"

echo "🔐 Configurando SSL para dominio AWS: $DOMAIN"

# Verificar privilegios root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ejecutar con: sudo $0"
    exit 1
fi

# 1. Actualizar sistema
echo "📦 Actualizando sistema..."
apt update && apt upgrade -y

# 2. Instalar nginx y certbot
echo "🔧 Instalando nginx y certbot..."
apt install -y nginx certbot python3-certbot-nginx

# 3. Verificar que la app Flask esté corriendo
echo "🚀 Verificando aplicación Flask..."
if ! pgrep -f "python.*app_optimized.py"; then
    echo "⚠️  Iniciando aplicación Flask..."
    sudo -u admin nohup python3 /home/admin/app_optimized.py > /home/admin/app.log 2>&1 &
    sleep 3
fi

# 4. Crear configuración nginx para AWS
echo "⚙️ Configurando nginx..."
cat > /etc/nginx/sites-available/prime-viz-aws << 'EOF'
server {
    listen 80;
    server_name ec2-44-195-68-60.compute-1.amazonaws.com;

    # Seguridad básica
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Proxy a Flask
    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Archivos estáticos (si existen)
    location /static/ {
        alias /home/admin/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Favicon
    location /favicon.ico {
        access_log off;
        log_not_found off;
    }
}
EOF

# 5. Habilitar sitio y deshabilitar default
ln -sf /etc/nginx/sites-available/prime-viz-aws /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 6. Testear configuración nginx
echo "🧪 Verificando configuración nginx..."
nginx -t

# 7. Iniciar/reiniciar nginx
echo "🔄 Reiniciando nginx..."
systemctl stop nginx || true
systemctl start nginx
systemctl enable nginx

# 8. Verificar que nginx está corriendo
if ! systemctl is-active --quiet nginx; then
    echo "❌ Error: nginx no está corriendo"
    systemctl status nginx
    exit 1
fi

echo "✅ Nginx configurado y corriendo"

# 9. Obtener certificado Let's Encrypt
echo "🔐 Obteniendo certificado SSL..."
echo "📧 Usando email: admin@amazonaws.com"

certbot --nginx \
    -d $DOMAIN \
    --non-interactive \
    --agree-tos \
    --email admin@amazonaws.com \
    --redirect \
    --expand

# 10. Verificar certificado
echo "🔍 Verificando certificado..."
certbot certificates

# 11. Configurar renovación automática
echo "🔄 Configurando renovación automática..."
systemctl enable certbot.timer
systemctl start certbot.timer

# 12. Probar renovación
echo "🧪 Probando renovación automática..."
certbot renew --dry-run

# 13. Estado final
echo ""
echo "✅ ¡SSL configurado exitosamente!"
echo "🌐 Dominio: https://$DOMAIN"
echo "🔒 Certificado válido por 90 días"
echo "🔄 Renovación automática habilitada"
echo ""
echo "📊 Servicios:"
systemctl status nginx --no-pager -l | head -5
systemctl status certbot.timer --no-pager -l | head -5
echo ""
echo "🔗 Accede a tu aplicación en:"
echo "   https://$DOMAIN"
echo ""
echo "📝 Para verificar certificado:"
echo "   sudo certbot certificates"
echo ""
echo "🔧 Para ver logs de nginx:"
echo "   sudo tail -f /var/log/nginx/access.log"