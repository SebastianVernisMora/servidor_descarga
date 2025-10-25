#!/bin/bash
# Script para reiniciar y probar la aplicación

echo "🔄 Reiniciando Gunicorn con optimizaciones..."

# Aplicar configuración optimizada y reiniciar
echo "📝 Aplicando configuración optimizada de Gunicorn..."
sudo supervisorctl restart gunicorn-prime

echo "⏳ Esperando reinicio..."
sleep 5

echo "📊 Memoria después del reinicio:"
free -h

echo ""
echo "🧪 Probando conexión local..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ || echo "Error conexión local"

echo ""
echo "🔍 Procesos Gunicorn activos:"
ps aux | grep gunicorn | grep -v grep

echo ""
echo "📋 Estado del servicio:"
sudo supervisorctl status gunicorn-prime

echo ""
echo "📜 Últimas líneas del log:"
tail -5 /var/log/supervisor/gunicorn.log

echo ""
echo "✅ Verificación completada!"