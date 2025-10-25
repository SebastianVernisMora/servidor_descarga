#!/bin/bash
# Script para monitorear el uso de memoria

echo "🔍 MONITOREO DE MEMORIA - $(date)"
echo "=================================="

echo "📊 MEMORIA SISTEMA:"
free -h

echo ""
echo "🐍 PROCESOS PYTHON (por memoria):"
ps aux --sort=-%mem | grep python | head -10

echo ""
echo "🌐 PROCESOS GUNICORN:"
ps aux | grep gunicorn | grep -v grep

echo ""
echo "💾 CACHE EN DISCO:"
if [ -d "/var/www/prime-visualization/cache_primes" ]; then
    echo "Archivos en cache: $(ls -1 /var/www/prime-visualization/cache_primes/*.cache 2>/dev/null | wc -l)"
    echo "Tamaño cache: $(du -sh /var/www/prime-visualization/cache_primes 2>/dev/null | cut -f1)"
else
    echo "Cache no encontrado"
fi

echo ""
echo "🏠 CACHE LOCAL:"
if [ -d "/home/admin/cache_primes" ]; then
    echo "Archivos en cache: $(ls -1 /home/admin/cache_primes/*.cache 2>/dev/null | wc -l)"
    echo "Tamaño cache: $(du -sh /home/admin/cache_primes 2>/dev/null | cut -f1)"
else
    echo "Cache no encontrado"
fi

echo ""
echo "🎯 APLICACIONES ACTIVAS:"
echo "Puerto 5000 (Gunicorn): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/info 2>/dev/null || echo "No responde")"
echo "Puerto 5001 (Optimizada): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/api/info 2>/dev/null || echo "No responde")"