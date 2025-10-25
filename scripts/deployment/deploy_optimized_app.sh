#!/bin/bash
# Script para desplegar aplicación optimizada para memoria

echo "🚀 Desplegando aplicación optimizada para memoria..."

# Crear backup del app actual
echo "📦 Creando backup..."
sudo cp /var/www/prime-visualization/app.py /var/www/prime-visualization/app_original_backup.py

# Copiar aplicación optimizada
echo "📋 Copiando aplicación optimizada..."
sudo cp /home/admin/app_optimized.py /var/www/prime-visualization/app.py

# Cambiar permisos
sudo chown www-data:www-data /var/www/prime-visualization/app.py
sudo chmod 755 /var/www/prime-visualization/app.py

# Crear directorio de cache
echo "📁 Configurando cache en disco..."
sudo mkdir -p /var/www/prime-visualization/cache_primes
sudo chown www-data:www-data /var/www/prime-visualization/cache_primes
sudo chmod 755 /var/www/prime-visualization/cache_primes

# Verificar memoria antes
echo "📊 Memoria ANTES:"
free -h

# Reiniciar servicios
echo "🔄 Reiniciando servicios..."
sudo supervisorctl restart gunicorn-prime

# Esperar un momento
sleep 5

# Verificar memoria después
echo "📊 Memoria DESPUÉS:"
free -h

# Probar aplicación
echo "🧪 Probando aplicación..."
curl -s http://localhost:5000/api/info | jq '.version, .optimizaciones'

echo "✅ Despliegue completado!"