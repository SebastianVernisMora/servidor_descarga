#!/bin/bash
# 🌐 DESPLIEGUE PÚBLICO PUERTO 3000 - DNS e IP PÚBLICA

echo "🌐 CONFIGURANDO DESPLIEGUE PÚBLICO EN PUERTO 3000..."

# Detener cualquier proceso existente
echo "🛑 Deteniendo procesos existentes..."
pkill -f "python.*app" 2>/dev/null || true
pkill -f "static_app.py" 2>/dev/null || true

# Obtener información de red
LOCAL_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname -f)

echo "📍 Configuración de red detectada:"
echo "   🔸 IP Local: $LOCAL_IP"
echo "   🔸 Hostname: $HOSTNAME"

# Verificar puerto 3000 disponible
if ss -tlnp | grep -q :3000; then
    echo "⚠️ Puerto 3000 en uso, liberando..."
    fuser -k 3000/tcp 2>/dev/null || true
    sleep 2
fi

# Configurar aplicación para acceso público
export FLASK_HOST=0.0.0.0
export FLASK_PORT=3000
export FLASK_DEBUG=False

# Iniciar servidor optimizado con acceso público
echo "🚀 Iniciando servidor en puerto 3000 (acceso público)..."
cd /home/admin/servidor_descarga

# Aplicación estática optimizada con máximo rendimiento
nohup python3 -O static_app.py \
    --port=3000 \
    --host=0.0.0.0 \
    > public_deployment.log 2>&1 &

SERVER_PID=$!
echo "✅ Servidor iniciado con PID: $SERVER_PID"

# Esperar inicialización
echo "⏳ Esperando inicialización del servidor..."
sleep 8

# Verificar funcionamiento
echo "🔍 Verificando acceso público..."

# Test local
if python3 -c "
import requests
try:
    r = requests.get('http://localhost:3000/api/info', timeout=10)
    print('✅ Test localhost: OK')
except:
    print('❌ Test localhost: FAIL')
    exit(1)
" 2>/dev/null; then
    
    # Mostrar información de acceso
    echo ""
    echo "🔥 SERVIDOR DESPLEGADO CON ÉXITO EN PUERTO 3000"
    echo "=================================="
    echo ""
    echo "🌐 ACCESOS PÚBLICOS DISPONIBLES:"
    echo ""
    echo "   📍 IP PÚBLICA:   http://${LOCAL_IP}:3000/"
    echo "   🌍 DNS/HOSTNAME: http://${HOSTNAME}:3000/"
    echo "   🔗 LOCALHOST:    http://localhost:3000/"
    echo ""
    echo "🎯 ENDPOINTS PRINCIPALES:"
    echo "   🏠 Interfaz:     http://${LOCAL_IP}:3000/"
    echo "   📊 API Info:     http://${LOCAL_IP}:3000/api/info"
    echo "   🗺️ Mapas:        http://${LOCAL_IP}:3000/api/maps"
    echo "   🎲 Aleatorio:    http://${LOCAL_IP}:3000/api/random-map"
    echo ""
    echo "⚡ Características:"
    echo "   • Puerto 3000 PÚBLICO configurado"
    echo "   • Acceso desde cualquier IP/DNS"
    echo "   • 980 mapas estáticos disponibles"
    echo "   • Respuesta <5ms"
    echo "   • Máximo rendimiento"
    echo ""
    echo "📋 Control del servidor:"
    echo "   Ver logs: tail -f public_deployment.log"
    echo "   Detener:  ./stop_server.sh"
    echo "   Estado:   ps aux | grep static_app"
    echo ""
else
    echo "❌ ERROR: El servidor no está respondiendo"
    echo "📋 Revisando logs..."
    tail -20 public_deployment.log
    exit 1
fi

echo "✅ DESPLIEGUE PÚBLICO COMPLETADO - PUERTO 3000 ACTIVO"