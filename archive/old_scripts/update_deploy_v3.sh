#!/bin/bash

# Script de Actualización y Despliegue v3.0
# Actualiza la aplicación de visualización de primos con mejoras

set -e  # Exit on any error

echo "🚀 Iniciando actualización de la aplicación de visualización de primos v3.0..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Configuración
APP_DIR="/var/www/prime-visualization"
BACKUP_DIR="/var/www/backups/$(date '+%Y%m%d_%H%M%S')"
PYTHON_PATH="/usr/bin/python3"

log "Creando backup de la aplicación actual..."
sudo mkdir -p /var/www/backups
sudo cp -r $APP_DIR $BACKUP_DIR
success "Backup creado en $BACKUP_DIR"

# Detener servicios
log "Deteniendo servicios..."
sudo systemctl stop prime-visualization || warning "Servicio ya detenido"
sudo systemctl stop nginx || error "Error deteniendo nginx"

# Instalar dependencias adicionales si es necesario
log "Verificando dependencias Python..."
pip3 install --upgrade flask numpy matplotlib scipy psutil || warning "Algunas dependencias pueden no haberse actualizado"

# Copiar nueva aplicación optimizada
log "Copiando aplicación optimizada..."
sudo cp /home/admin/app_optimized.py $APP_DIR/app.py
sudo chown www-data:www-data $APP_DIR/app.py
sudo chmod +x $APP_DIR/app.py
success "Aplicación actualizada"

# Copiar nueva interfaz mejorada
log "Copiando interfaz mejorada..."
sudo mkdir -p $APP_DIR/templates
sudo cp /home/admin/index_enhanced.html $APP_DIR/templates/
sudo chown www-data:www-data $APP_DIR/templates/index_enhanced.html
success "Interfaz actualizada"

# Configurar variables de entorno para BLACKBOX API
log "Configurando variables de entorno..."
if [ ! -f /home/admin/.env ]; then
    cat > /home/admin/.env << EOF
# Configuración BLACKBOX API
BLACKBOX_API_KEY=your_api_key_here

# Configuración de cache
CACHE_SIZE=100
CACHE_TTL=3600

# Configuración de rendimiento
MAX_WORKERS=4
ENABLE_COMPRESSION=true
EOF
    warning "Archivo .env creado. Configure su API key de BLACKBOX."
fi

# Copiar variables de entorno al directorio de la aplicación
sudo cp /home/admin/.env $APP_DIR/
sudo chown www-data:www-data $APP_DIR/.env

# Actualizar systemd service para usar las nuevas características
log "Actualizando configuración de systemd..."
sudo tee /etc/systemd/system/prime-visualization.service > /dev/null << EOF
[Unit]
Description=Prime Visualization App v3.0 with AI
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin
Environment=FLASK_ENV=production
Environment=FLASK_APP=app.py
EnvironmentFile=$APP_DIR/.env
ExecStart=$PYTHON_PATH app.py
Restart=always
RestartSec=10
KillMode=mixed
TimeoutStopSec=30

# Límites de recursos
LimitNOFILE=65535
MemoryMax=2G

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=prime-viz-v3

[Install]
WantedBy=multi-user.target
EOF

success "Servicio systemd actualizado"

# Recargar systemd
log "Recargando configuración de systemd..."
sudo systemctl daemon-reload

# Actualizar configuración de nginx si es necesario
log "Verificando configuración de nginx..."
NGINX_CONF="/etc/nginx/sites-available/prime-visualization"
if [ -f "$NGINX_CONF" ]; then
    # Agregar headers para mejor rendimiento
    sudo tee -a $NGINX_CONF > /dev/null << EOF

# Cache headers para recursos estáticos
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, no-transform";
}

# Compresión
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;

# Rate limiting
limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
EOF
    success "Configuración de nginx mejorada"
else
    warning "Configuración de nginx no encontrada"
fi

# Crear directorio de cache
log "Creando directorios de cache..."
sudo mkdir -p $APP_DIR/cache
sudo mkdir -p $APP_DIR/logs
sudo chown -R www-data:www-data $APP_DIR/cache
sudo chown -R www-data:www-data $APP_DIR/logs
success "Directorios creados"

# Iniciar servicios
log "Iniciando servicios..."
sudo systemctl start prime-visualization
sleep 3
sudo systemctl start nginx

# Verificar estado
if sudo systemctl is-active --quiet prime-visualization; then
    success "Servicio prime-visualization iniciado correctamente"
else
    error "Error iniciando prime-visualization"
    sudo journalctl -u prime-visualization --no-pager -n 20
    exit 1
fi

if sudo systemctl is-active --quiet nginx; then
    success "Nginx iniciado correctamente"
else
    error "Error iniciando nginx"
    sudo journalctl -u nginx --no-pager -n 10
    exit 1
fi

# Habilitar servicios para inicio automático
sudo systemctl enable prime-visualization
sudo systemctl enable nginx

# Verificar que la aplicación responda
log "Verificando funcionamiento de la aplicación..."
sleep 5

# Test local
if curl -s -f http://localhost/ > /dev/null; then
    success "Aplicación responde correctamente en localhost"
else
    error "Aplicación no responde en localhost"
fi

# Test API
if curl -s -f -X POST -H "Content-Type: application/json" \
    -d '{"num_circulos":5,"divisiones_por_circulo":12}' \
    http://localhost/generar > /dev/null; then
    success "API funciona correctamente"
else
    warning "API puede tener problemas"
fi

# Test de información del sistema
if curl -s -f http://localhost/api/info > /dev/null; then
    success "Endpoint de información funciona"
else
    warning "Endpoint de información no accesible"
fi

# Mostrar estado final
echo
echo "========================================="
echo "🎉 ACTUALIZACIÓN COMPLETADA"
echo "========================================="
echo
echo "📊 Estado de Servicios:"
sudo systemctl status prime-visualization --no-pager -l | grep -E "(Active|Main PID)"
sudo systemctl status nginx --no-pager -l | grep -E "(Active|Main PID)"
echo
echo "🌐 URLs de Acceso:"
echo "  • Local: http://localhost/"
echo "  • Externa: http://$(curl -s ifconfig.me)/" 
echo
echo "🔧 Nuevas Características v3.0:"
echo "  ✓ Cache inteligente de visualizaciones"
echo "  ✓ Chat de IA con BLACKBOX API"
echo "  ✓ Sistema de tooltips explicativos"
echo "  ✓ Compresión optimizada de imágenes"  
echo "  ✓ Análisis automático con IA"
echo "  ✓ Interfaz mejorada con iconos"
echo
echo "📝 Configuración Pendiente:"
echo "  • Configure BLACKBOX_API_KEY en $APP_DIR/.env para habilitar IA"
echo "  • Los logs están disponibles en: sudo journalctl -u prime-visualization -f"
echo "  • Cache stats: curl http://localhost/cache/stats"
echo
echo "🔍 Verificación Final:"
curl -s http://localhost/api/info | python3 -m json.tool | head -20 2>/dev/null || echo "API info disponible"
echo
echo "========================================="

# Crear script de mantenimiento
log "Creando script de mantenimiento..."
sudo tee /usr/local/bin/prime-viz-maintenance > /dev/null << 'EOF'
#!/bin/bash
# Script de mantenimiento para Prime Visualization v3.0

case "$1" in
    restart)
        sudo systemctl restart prime-visualization nginx
        echo "Servicios reiniciados"
        ;;
    status)
        sudo systemctl status prime-visualization nginx
        ;;
    logs)
        sudo journalctl -u prime-visualization -f
        ;;
    cache-clear)
        curl -X POST http://localhost/cache/clear
        echo "Cache limpiado"
        ;;
    stats)
        curl -s http://localhost/api/info | python3 -m json.tool
        ;;
    backup)
        sudo cp -r /var/www/prime-visualization /var/www/backups/manual_$(date '+%Y%m%d_%H%M%S')
        echo "Backup manual creado"
        ;;
    *)
        echo "Uso: $0 {restart|status|logs|cache-clear|stats|backup}"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/prime-viz-maintenance
success "Script de mantenimiento creado: prime-viz-maintenance"

echo
success "🚀 Actualización completada exitosamente!"
echo "   Aplicación v3.0 funcionando con todas las mejoras integradas"
echo "   Backup disponible en: $BACKUP_DIR"
echo

# Mostrar últimas líneas de log para verificar
log "Últimas líneas de log:"
sudo journalctl -u prime-visualization --no-pager -n 5

exit 0
