#!/bin/bash

# Script para configurar certificado SSL con Let's Encrypt
# Requiere un dominio válido apuntando a esta IP: 172.31.7.132

set -e

echo "🔐 Configurando certificado SSL con Let's Encrypt..."

# Verificar si estamos ejecutando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# Solicitar dominio
read -p "📝 Ingrese su dominio (ej: miapp.ejemplo.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Dominio es requerido"
    exit 1
fi

echo "🌐 Configurando SSL para dominio: $DOMAIN"

# 1. Actualizar sistema
echo "📦 Actualizando paquetes..."
apt update
apt install -y nginx certbot python3-certbot-nginx

# 2. Crear configuración nginx básica
echo "⚙️ Configurando nginx..."
cat > /etc/nginx/sites-available/prime-viz << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }

    location /static {
        alias /home/admin/static;
        expires 30d;
    }
}
EOF

# 3. Habilitar sitio
ln -sf /etc/nginx/sites-available/prime-viz /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 4. Verificar configuración nginx
nginx -t

# 5. Reiniciar nginx
systemctl restart nginx
systemctl enable nginx

echo "✅ Nginx configurado correctamente"

# 6. Obtener certificado Let's Encrypt
echo "🔐 Obteniendo certificado SSL..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# 7. Configurar renovación automática
echo "🔄 Configurando renovación automática..."
systemctl enable certbot.timer

# 8. Mostrar estado
echo "📊 Estado de los servicios:"
systemctl status nginx --no-pager -l
systemctl status certbot.timer --no-pager -l

echo ""
echo "✅ ¡SSL configurado exitosamente!"
echo "🌐 Tu aplicación estará disponible en: https://$DOMAIN"
echo "🔒 Certificado válido por 90 días con renovación automática"
echo ""
echo "📝 Para verificar el certificado:"
echo "   certbot certificates"
echo ""
echo "🔄 Para renovar manualmente:"
echo "   certbot renew --dry-run"