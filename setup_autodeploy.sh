#!/bin/bash

echo "🚀 CONFIGURANDO SISTEMA DE DESPLIEGUE AUTOMÁTICO"

# 1. Crear directorio de logs
mkdir -p logs

# 2. Hacer ejecutable el script de auto-deploy
chmod +x auto_deploy.py

# 3. Instalar dependencias necesarias
pip3 install flask requests

# 4. Configurar variables de entorno
echo "📝 Configurando variables de entorno..."

# Crear archivo de configuración
cat > .env << 'EOF'
# GitHub Webhook Secret (cambiar por el real)
WEBHOOK_SECRET=your-github-webhook-secret-change-this

# Puerto para el servidor de auto-deploy
AUTODEPLOY_PORT=9000

# Configuración del repositorio
REPO_PATH=/home/admin/servidor_descarga
EOF

echo "⚙️ Variables de entorno creadas en .env"

# 5. Crear servicio systemd para auto-deploy
sudo tee /etc/systemd/system/autodeploy.service > /dev/null << EOF
[Unit]
Description=Auto Deploy Service for GitHub Webhooks
After=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin/servidor_descarga
Environment=PATH=/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/home/admin/servidor_descarga/.env
ExecStart=/usr/bin/python3 /home/admin/servidor_descarga/auto_deploy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. Habilitar y iniciar el servicio
echo "🔧 Habilitando servicio systemd..."
sudo systemctl daemon-reload
sudo systemctl enable autodeploy.service
sudo systemctl start autodeploy.service

echo "✅ CONFIGURACIÓN COMPLETADA"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Cambiar WEBHOOK_SECRET en .env por un secreto seguro"
echo "2. Configurar webhook en GitHub:"
echo "   - URL: http://TU_SERVIDOR:9000/webhook"
echo "   - Content-Type: application/json"
echo "   - Secret: el valor de WEBHOOK_SECRET"
echo "   - Eventos: Just the push event"
echo ""
echo "🔍 COMANDOS ÚTILES:"
echo "# Ver estado del servicio"
echo "sudo systemctl status autodeploy"
echo ""
echo "# Ver logs en tiempo real"
echo "tail -f logs/auto_deploy.log"
echo ""
echo "# Probar despliegue manual"
echo "curl -X POST http://localhost:9000/manual-deploy"
echo ""
echo "# Ver estado del auto-deploy"
echo "curl http://localhost:9000/status"