#!/bin/bash
# Script de mantenimiento general

echo "🧹 MANTENIMIENTO DEL SISTEMA"
echo "============================"

echo ""
echo "📊 ESTADO DE MEMORIA:"
free -h

echo ""
echo "💾 CACHE EN DISCO:"
if [ -d "cache_primes" ]; then
    echo "Archivos cache: $(ls cache_primes/*.cache 2>/dev/null | wc -l)"
    echo "Tamaño cache: $(du -sh cache_primes 2>/dev/null | cut -f1)"
else
    echo "No hay cache local"
fi

echo ""
echo "🔄 PROCESOS APLICACIÓN:"
ps aux | grep -E "(gunicorn|python.*app)" | grep -v grep | wc -l | xargs echo "Procesos activos:"

echo ""
echo "🌐 CONECTIVIDAD:"
echo -n "App local: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null || echo "No responde"

echo ""
echo "📁 ESPACIO EN DISCO:"
df -h / | tail -1 | awk '{print "Usado: " $3 " / " $2 " (" $5 ")"}'

echo ""
echo "🗄️ ARCHIVOS TEMPORALES:"
find /tmp -name "*prime*" -o -name "*cache*" 2>/dev/null | wc -l | xargs echo "Archivos temp encontrados:"

echo ""
echo "⚡ ACCIONES RECOMENDADAS:"
if [ -d "archive" ] && [ -f "archive_backup_*.tar.gz" ]; then
    echo "- rm -rf archive/ (liberar 484K, backup disponible)"
fi

cache_count=$(ls cache_primes/*.cache 2>/dev/null | wc -l)
if [ "$cache_count" -gt 20 ]; then
    echo "- Limpiar cache antiguo (>20 archivos)"
fi

echo ""
echo "✅ Mantenimiento completado - $(date)"