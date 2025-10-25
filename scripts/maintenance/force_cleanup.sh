#!/bin/bash
# Script para forzar limpieza completa de procesos Gunicorn

echo "🧹 LIMPIEZA FORZADA DE MEMORIA..."

echo "📊 Memoria ANTES:"
free -h

echo ""
echo "🔍 Procesos Gunicorn ANTES:"
ps aux | grep gunicorn | grep -v grep

echo ""
echo "⏹️  Deteniendo supervisor..."
sudo supervisorctl stop gunicorn-prime

echo ""
echo "💀 Matando procesos Gunicorn restantes..."
sudo pkill -f "gunicorn.*app:app"

echo ""
echo "⏳ Esperando limpieza..."
sleep 3

echo ""
echo "🔍 Procesos Gunicorn DESPUÉS:"
ps aux | grep gunicorn | grep -v grep || echo "✅ No hay procesos Gunicorn"

echo ""
echo "📊 Memoria DESPUÉS de limpieza:"
free -h

echo ""
echo "🚀 Reiniciando con aplicación optimizada..."
sudo supervisorctl start gunicorn-prime

echo ""
echo "⏳ Esperando inicio..."
sleep 5

echo ""
echo "🧪 Probando aplicación optimizada..."
curl -s http://localhost:5000/api/info | grep -E '"version"|"storage_type"|"optimizaciones"'

echo ""
echo "📊 Memoria FINAL:"
free -h

echo ""
echo "✅ Limpieza completada!"