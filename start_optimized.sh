#!/bin/bash
# 🔥 SERVIDOR OPTIMIZADO - MÁXIMO RENDIMIENTO 

echo "🔥 INICIANDO SERVIDOR OPTIMIZADO..."

# Matar procesos existentes
echo "🛑 Deteniendo procesos existentes..."
pkill -f "python.*app" 2>/dev/null || true
pkill -f "python.*deploy" 2>/dev/null || true
pkill -f "flask" 2>/dev/null || true
pkill -f "gunicorn" 2>/dev/null || true

# Limpiar cache
echo "🗑️ Limpiando cache del sistema..."
sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# Optimizaciones de memoria
export PYTHONOPTIMIZE=1
export PYTHONDONTWRITEBYTECODE=1
export MALLOC_TRIM_THRESHOLD=100000

# Verificar mapas estáticos
echo "📊 Verificando mapas estáticos..."
MAPS_COUNT=$(find static_maps/ -name "data_*.json" | wc -l)
echo "✅ $MAPS_COUNT mapas estáticos disponibles"

# Verificar memoria disponible
FREE_MEM=$(free -m | awk 'NR==2{print $7}')
echo "💾 Memoria disponible: ${FREE_MEM}MB"

# Obtener IP pública y configuración de red
LOCAL_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname -f)

# Iniciar aplicación estática optimizada
echo "🚀 Iniciando aplicación estática en puerto 3000..."
cd /home/admin/servidor_descarga

# Usar python3 del sistema con optimizaciones - SIEMPRE PUERTO 3000 PÚBLICO
nohup python3 -O static_app.py \
    --port=3000 \
    --host=0.0.0.0 \
    > optimized.log 2>&1 &

PYTHON_PID=$!
echo "✅ Servidor iniciado con PID: $PYTHON_PID"

# Esperar que el servidor inicie
sleep 5

# Verificar que está funcionando
if python3 -c "import requests; requests.get('http://localhost:3000/api/info', timeout=5)" 2>/dev/null; then
    echo "✅ Servidor funcionando correctamente en puerto 3000"
    echo ""
    echo "🌐 ACCESOS PÚBLICOS DISPONIBLES:"
    echo "   📍 IP Local:  http://${LOCAL_IP}:3000/"
    echo "   🌍 Hostname:  http://${HOSTNAME}:3000/"
    echo "   🔗 Localhost: http://localhost:3000/"
    echo ""
    echo "📈 Mapas disponibles: $MAPS_COUNT"
    echo "⚡ Modo: ESTÁTICO (máximo rendimiento)"
    echo "🔥 Puerto 3000 PÚBLICO configurado"
else
    echo "❌ Error: Servidor no responde"
    tail -10 optimized.log
    exit 1
fi

echo "🔥 SERVIDOR OPTIMIZADO INICIADO CON ÉXITO"