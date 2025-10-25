#!/bin/bash

# Prime Visualization App Deployment Script - FINAL FIXED VERSION
# Soluciona problemas de compatibilidad con Python 3.13, nginx y dependencias

echo "🚀 Starting FINAL FIXED Prime Visualization App deployment..."

# Configuration variables
APP_NAME="prime-visualization"
APP_DIR="/var/www/$APP_NAME"
PYTHON_VERSION="python3"
VENV_NAME="venv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_status "Updating system packages..."
apt update

print_status "Installing system dependencies..."
apt install -y python3 python3-pip python3-venv nginx git curl

print_status "Removing any existing installation..."
systemctl stop $APP_NAME 2>/dev/null || true
systemctl disable $APP_NAME 2>/dev/null || true
rm -rf $APP_DIR
rm -f /etc/systemd/system/$APP_NAME.service
rm -f /etc/nginx/sites-enabled/$APP_NAME
rm -f /etc/nginx/sites-available/$APP_NAME

print_status "Creating application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

print_status "Setting up Python virtual environment..."
$PYTHON_VERSION -m venv $VENV_NAME
source $VENV_NAME/bin/activate

print_status "Upgrading pip..."
pip install --upgrade pip

print_status "Installing Python dependencies (compatible versions)..."
# Use compatible versions for Python 3.13
pip install Flask==3.1.0 numpy==2.1.0 matplotlib==3.9.0 scipy==1.14.0 \
            gunicorn==23.0.0 Pillow==10.4.0

print_status "Configuring matplotlib for server environment..."
mkdir -p /var/www/.matplotlib
mkdir -p ~/.matplotlib

cat > ~/.matplotlib/matplotlibrc << 'MATPLOT_EOF'
backend: Agg
figure.max_open_warning: 0
font.size: 12
figure.dpi: 100
savefig.dpi: 300
savefig.format: png
savefig.bbox: tight
MATPLOT_EOF

cp ~/.matplotlib/matplotlibrc /var/www/.matplotlib/matplotlibrc

print_status "Creating application files..."

# Create main Flask application with FIXES
cat > app.py << 'PYTHON_EOF'
import os
import sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from flask import Flask, render_template, request, jsonify
import io
import base64
import json
from collections import defaultdict
import math
import traceback
from datetime import datetime
from matplotlib.patches import Wedge
from matplotlib.collections import PatchCollection

# Configure matplotlib
plt.ioff()
matplotlib.rcParams['figure.max_open_warning'] = 0

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False

def criba_de_eratostenes(limite):
    if limite < 2:
        return []
    criba = [True] * (limite + 1)
    criba[0] = criba[1] = False
    for i in range(2, int(math.sqrt(limite)) + 1):
        if criba[i]:
            for j in range(i*i, limite + 1, i):
                criba[j] = False
    return [i for i in range(2, limite + 1) if criba[i]]

def encontrar_patrones_primos(primos):
    patrones = {
        'primos_gemelos': [],
        'primos_primos': [],
        'primos_sexy': [],
        'gaps_primos': defaultdict(int),
        'distribucion_gaps': []
    }
    
    if not primos or len(primos) < 2:
        return patrones
    
    conjunto_primos = set(primos)
    for i, p in enumerate(primos[:-1]):
        gap = primos[i+1] - p
        patrones['distribucion_gaps'].append(gap)
        patrones['gaps_primos'][gap] += 1
        
        if p + 2 in conjunto_primos:
            patrones['primos_gemelos'].append((p, p + 2))
        if p + 4 in conjunto_primos:
            patrones['primos_primos'].append((p, p + 4))
        if p + 6 in conjunto_primos:
            patrones['primos_sexy'].append((p, p + 6))
    
    return patrones

def calcular_metricas(primos, patrones):
    if not primos or len(primos) < 2:
        return {
            'total_primos': 0, 'pares_primos_gemelos': 0, 'pares_primos_primos': 0,
            'pares_primos_sexy': 0, 'gap_promedio': 0.0, 'gap_maximo': 0, 'gap_minimo': 0,
            'densidad_primos_gemelos': 0.0, 'densidad_general': 0.0, 'entropia_gap': 0.0,
            'desviacion_gap': 0.0
        }
    
    gaps = patrones['distribucion_gaps']
    from collections import Counter
    gap_counts = Counter(gaps)
    entropia = 0
    if gaps:
        for count in gap_counts.values():
            p = count / len(gaps)
            if p > 0:
                entropia -= p * math.log2(p)
    
    return {
        'total_primos': int(len(primos)),
        'pares_primos_gemelos': int(len(patrones['primos_gemelos'])),
        'pares_primos_primos': int(len(patrones['primos_primos'])),
        'pares_primos_sexy': int(len(patrones['primos_sexy'])),
        'gap_promedio': float(np.mean(gaps)) if gaps else 0.0,
        'gap_maximo': int(max(gaps)) if gaps else 0,
        'gap_minimo': int(min(gaps)) if gaps else 0,
        'densidad_primos_gemelos': float(len(patrones['primos_gemelos']) / len(primos)) if primos else 0.0,
        'densidad_general': float(len(primos) / primos[-1]) if primos else 0.0,
        'entropia_gap': float(entropia),
        'desviacion_gap': float(np.std(gaps)) if gaps else 0.0
    }

def generar_visualizacion(num_circulos, divisiones_por_circulo, mostrar_primos_gemelos=True,
                         mostrar_primos_primos=True, mostrar_primos_sexy=True, 
                         mostrar_primos_regulares=True, esquema_color='avanzado', alta_calidad=True):
    try:
        plt.clf()
        plt.close('all')
        
        segmentos_totales = num_circulos * divisiones_por_circulo
        primos = criba_de_eratostenes(segmentos_totales)
        conjunto_primos = set(primos)
        patrones = encontrar_patrones_primos(primos)
        metricas = calcular_metricas(primos, patrones)
        
        # Color schemes
        colores = {
            'primo_gemelo': '#FF0000',
            'primo_primo': '#FF8C00', 
            'primo_sexy': '#FF1493',
            'primo_regular': '#0000FF',
            'compuesto': '#D3D3D3',
            'fondo': '#000000'
        }
        
        dpi = 300 if alta_calidad else 200
        fig, ax = plt.subplots(1, figsize=(12, 12), facecolor=colores['fondo'], dpi=dpi)
        ax.set_facecolor(colores['fondo'])
        ax.set_aspect('equal')
        
        limite_grafico = num_circulos + 1
        ax.set_xlim([-limite_grafico, limite_grafico])
        ax.set_ylim([-limite_grafico, limite_grafico])
        ax.axis('off')
        
        # Create prime sets
        conjunto_primos_gemelos = set()
        conjunto_primos_primos = set()
        conjunto_primos_sexy = set()
        
        for par in patrones['primos_gemelos']:
            conjunto_primos_gemelos.update(par)
        for par in patrones['primos_primos']:
            conjunto_primos_primos.update(par)
        for par in patrones['primos_sexy']:
            conjunto_primos_sexy.update(par)
        
        wedges = []
        colores_wedges = []
        
        angulo_segmento = 360 / divisiones_por_circulo
        radio_base = 0.5
        ancho_anillo = 0.9
        
        for n in range(1, segmentos_totales + 1):
            circulo = n // divisiones_por_circulo
            segmento = n % divisiones_por_circulo
            
            if circulo >= num_circulos:
                continue
                
            radio_interno = radio_base + circulo * ancho_anillo
            radio_externo = radio_interno + ancho_anillo
            theta1 = segmento * angulo_segmento
            theta2 = (segmento + 1) * angulo_segmento
            
            # Determine color
            if n in conjunto_primos_gemelos and mostrar_primos_gemelos:
                color = colores['primo_gemelo']
            elif n in conjunto_primos_primos and mostrar_primos_primos:
                color = colores['primo_primo']
            elif n in conjunto_primos_sexy and mostrar_primos_sexy:
                color = colores['primo_sexy']
            elif n in conjunto_primos and mostrar_primos_regulares:
                color = colores['primo_regular']
            else:
                color = colores['compuesto']
            
            wedge = Wedge(center=(0, 0), r=radio_externo, width=ancho_anillo,
                         theta1=theta1, theta2=theta2, alpha=0.8)
            wedges.append(wedge)
            colores_wedges.append(color)
        
        collection = PatchCollection(wedges, facecolors=colores_wedges,
                                   edgecolors='white', linewidths=0.1)
        ax.add_collection(collection)
        
        # Add title
        ax.text(0, limite_grafico - 0.3, 
                f'Visualización de Números Primos\\nCírculos: {num_circulos} | Segmentos: {divisiones_por_circulo}',
                ha='center', va='top', color='white', fontsize=14, fontweight='bold')
        
        # Save to buffer
        buffer_img = io.BytesIO()
        plt.savefig(buffer_img, format='png', dpi=dpi, bbox_inches='tight', 
                   facecolor=colores['fondo'], edgecolor='none', pad_inches=0.1)
        buffer_img.seek(0)
        datos_img = base64.b64encode(buffer_img.read()).decode('utf-8')
        
        plt.close(fig)
        buffer_img.close()
        
        return datos_img, metricas, patrones
        
    except Exception as e:
        plt.close('all')
        print(f"Error in visualization: {str(e)}")
        raise e

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/generar', methods=['POST'])
def generar():
    try:
        datos = request.get_json()
        if not datos:
            return jsonify({'error': 'No JSON data received'}), 400
        
        num_circulos = int(datos.get('num_circulos', 10))
        divisiones_por_circulo = int(datos.get('divisiones_por_circulo', 36))
        mostrar_primos_gemelos = bool(datos.get('mostrar_primos_gemelos', True))
        mostrar_primos_primos = bool(datos.get('mostrar_primos_primos', True))
        mostrar_primos_sexy = bool(datos.get('mostrar_primos_sexy', True))
        mostrar_primos_regulares = bool(datos.get('mostrar_primos_regulares', True))
        esquema_color = str(datos.get('esquema_color', 'avanzado'))
        alta_calidad = bool(datos.get('alta_calidad', True))
        
        # Validate input
        if not (1 <= num_circulos <= 1000):
            return jsonify({'error': 'Number of circles must be between 1 and 1000'}), 400
        if not (4 <= divisiones_por_circulo <= 200):
            return jsonify({'error': 'Divisions per circle must be between 4 and 200'}), 400
        
        datos_img, metricas, patrones = generar_visualizacion(
            num_circulos, divisiones_por_circulo,
            mostrar_primos_gemelos, mostrar_primos_primos,
            mostrar_primos_sexy, mostrar_primos_regulares,
            esquema_color, alta_calidad
        )
        
        # Prepare gap distribution
        dist_gaps = []
        if patrones and 'gaps_primos' in patrones:
            for gap, cuenta in sorted(patrones['gaps_primos'].items()):
                if gap <= 30:
                    dist_gaps.append({'gap': int(gap), 'cuenta': int(cuenta)})
        
        response_data = {
            'imagen': str(datos_img),
            'metricas': dict(metricas),
            'distribucion_gaps': list(dist_gaps),
            'timestamp': datetime.now().isoformat()
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        print(f"Error in /generar: {str(e)}")
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
PYTHON_EOF

print_status "Creating templates directory and HTML file..."
mkdir -p templates

cat > templates/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualización de Números Primos - FIXED</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            margin: 0; padding: 20px; color: white; 
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; margin-bottom: 0.2em; }
        .controls { 
            background: rgba(255,255,255,0.1); 
            padding: 25px; border-radius: 15px; 
            margin-bottom: 20px; 
        }
        .form-group { margin-bottom: 15px; }
        .form-row { display: flex; gap: 20px; flex-wrap: wrap; }
        .form-column { flex: 1; min-width: 300px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input, select, button { 
            padding: 10px; border-radius: 5px; border: none; 
            font-size: 14px;
        }
        input, select { background: white; color: #333; width: 100%; box-sizing: border-box; }
        button { background: #4CAF50; color: white; cursor: pointer; font-weight: bold; }
        button:hover { background: #45a049; }
        .checkbox-group { 
            background: rgba(255,255,255,0.1); 
            padding: 15px; border-radius: 8px; margin-bottom: 15px; 
        }
        .checkbox-item { margin-bottom: 8px; }
        .checkbox-item input { width: auto; margin-right: 8px; }
        .visualization { 
            text-align: center; 
            background: rgba(255,255,255,0.1); 
            padding: 25px; border-radius: 15px; 
        }
        .metrics { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 15px; margin-top: 25px; 
        }
        .metric { 
            background: rgba(255,255,255,0.2); 
            padding: 15px; border-radius: 8px; text-align: center; 
        }
        .metric h3 { margin: 0 0 5px 0; font-size: 1.5em; }
        .metric p { margin: 0; font-size: 0.9em; }
        .loading { display: none; padding: 15px; margin: 15px 0; }
        .error { 
            background: #f44336; padding: 15px; 
            border-radius: 8px; margin: 15px 0; display: none;
        }
        .generate-btn {
            background: #4CAF50; padding: 15px 30px;
            font-size: 16px; border-radius: 8px; margin: 20px 0;
        }
        .result-image { max-width: 100%; border-radius: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔢 Visualización de Números Primos</h1>
            <p>Exploración interactiva de patrones matemáticos</p>
        </div>
        
        <div class="controls">
            <div class="form-row">
                <div class="form-column">
                    <div class="form-group">
                        <label>Número de Círculos:</label>
                        <input type="number" id="num_circulos" value="10" min="1" max="1000">
                    </div>
                    <div class="form-group">
                        <label>Divisiones por Círculo:</label>
                        <input type="number" id="divisiones_por_circulo" value="36" min="4" max="200">
                    </div>
                    <div class="form-group">
                        <label>Esquema de Color:</label>
                        <select id="esquema_color">
                            <option value="avanzado">Avanzado</option>
                        </select>
                    </div>
                </div>
                <div class="form-column">
                    <div class="checkbox-group">
                        <h3>Tipos de Primos a Mostrar</h3>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_gemelos" checked>
                            <label for="mostrar_primos_gemelos">Primos Gemelos (diferencia de 2)</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_primos" checked>
                            <label for="mostrar_primos_primos">Primos Primos (diferencia de 4)</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_sexy" checked>
                            <label for="mostrar_primos_sexy">Primos Sexy (diferencia de 6)</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_regulares" checked>
                            <label for="mostrar_primos_regulares">Primos Regulares</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="alta_calidad" checked>
                            <label for="alta_calidad">Alta Calidad (300 DPI)</label>
                        </div>
                    </div>
                </div>
            </div>
            
            <div style="text-align: center;">
                <button class="generate-btn" onclick="generarVisualizacion()">Generar Visualización</button>
                <div id="loading" class="loading">🔄 Generando visualización...</div>
                <div id="error" class="error"></div>
            </div>
        </div>
        
        <div class="visualization">
            <div id="resultado"></div>
            <div id="metricas" class="metrics"></div>
        </div>
    </div>
    
    <script>
        async function generarVisualizacion() {
            const loading = document.getElementById('loading');
            const error = document.getElementById('error');
            const resultado = document.getElementById('resultado');
            const metricas = document.getElementById('metricas');
            
            loading.style.display = 'block';
            error.style.display = 'none';
            
            try {
                const requestData = {
                    num_circulos: parseInt(document.getElementById('num_circulos').value) || 10,
                    divisiones_por_circulo: parseInt(document.getElementById('divisiones_por_circulo').value) || 36,
                    mostrar_primos_gemelos: document.getElementById('mostrar_primos_gemelos').checked,
                    mostrar_primos_primos: document.getElementById('mostrar_primos_primos').checked,
                    mostrar_primos_sexy: document.getElementById('mostrar_primos_sexy').checked,
                    mostrar_primos_regulares: document.getElementById('mostrar_primos_regulares').checked,
                    esquema_color: document.getElementById('esquema_color').value || 'avanzado',
                    alta_calidad: document.getElementById('alta_calidad').checked
                };
                
                const response = await fetch('/generar', {
                    method: 'POST',
                    headers: { 
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify(requestData)
                });
                
                if (!response.ok) {
                    throw new Error(`Server error: ${response.status}`);
                }
                
                const data = await response.json();
                
                if (data.error) {
                    throw new Error(data.error);
                }
                
                if (data.imagen) {
                    resultado.innerHTML = `<img src="data:image/png;base64,${data.imagen}" class="result-image">`;
                }
                
                if (data.metricas) {
                    const m = data.metricas;
                    metricas.innerHTML = `
                        <div class="metric"><h3>${m.total_primos || 0}</h3><p>Total Primos</p></div>
                        <div class="metric"><h3>${m.pares_primos_gemelos || 0}</h3><p>Pares Gemelos</p></div>
                        <div class="metric"><h3>${m.pares_primos_primos || 0}</h3><p>Pares Primos</p></div>
                        <div class="metric"><h3>${m.pares_primos_sexy || 0}</h3><p>Pares Sexy</p></div>
                        <div class="metric"><h3>${(m.gap_promedio || 0).toFixed(2)}</h3><p>Gap Promedio</p></div>
                        <div class="metric"><h3>${m.gap_maximo || 0}</h3><p>Gap Máximo</p></div>
                    `;
                }
                
            } catch (err) {
                error.textContent = `Error: ${err.message}`;
                error.style.display = 'block';
            } finally {
                loading.style.display = 'none';
            }
        }
        
        // Generate initial visualization
        window.addEventListener('load', function() {
            setTimeout(generarVisualizacion, 500);
        });
    </script>
</body>
</html>
HTML_EOF

print_status "Creating Gunicorn configuration..."
cat > gunicorn.conf.py << 'GUNICORN_EOF'
bind = "0.0.0.0:5000"
workers = 2
worker_class = "sync" 
timeout = 300
max_requests = 1000
preload_app = True
GUNICORN_EOF

print_status "Creating systemd service..."
cat > /etc/systemd/system/$APP_NAME.service << SERVICE_EOF
[Unit]
Description=Prime Visualization App
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/$VENV_NAME/bin
Environment=MPLBACKEND=Agg
ExecStart=$APP_DIR/$VENV_NAME/bin/gunicorn -c gunicorn.conf.py app:app
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF

print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/$APP_NAME << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        client_max_body_size 10M;
    }
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_status "Setting permissions..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

print_status "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

print_status "Starting services..."
systemctl daemon-reload
systemctl enable $APP_NAME
systemctl start $APP_NAME
systemctl enable nginx
systemctl restart nginx

# Wait for services to start
sleep 3

print_status "Checking service status..."
if systemctl is-active --quiet $APP_NAME; then
    print_success "Prime visualization service is running"
else
    print_error "Prime visualization service failed to start"
    print_status "Service logs:"
    journalctl -u $APP_NAME -n 10 --no-pager
fi

if systemctl is-active --quiet nginx; then
    print_success "Nginx is running"
else
    print_error "Nginx failed to start"
    print_status "Nginx logs:"
    journalctl -u nginx -n 10 --no-pager
fi

# Test the application
print_status "Testing application..."
sleep 2
if curl -s -f http://localhost/ > /dev/null; then
    print_success "✅ Application is responding"
else
    print_warning "⚠️  Application may still be starting up"
fi

# Create status script
cat > /usr/local/bin/prime-viz-status << 'STATUS_EOF'
#!/bin/bash
echo "=== Prime Visualization App Status ==="
echo "App Service Status:"
systemctl status prime-visualization --no-pager | head -10
echo ""
echo "Nginx Status:"
systemctl status nginx --no-pager | head -5
echo ""
echo "Recent Logs:"
journalctl -u prime-visualization -n 5 --no-pager
echo ""
echo "Access: http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost')"
STATUS_EOF

chmod +x /usr/local/bin/prime-viz-status

print_success "🎉 FINAL Prime Visualization App deployment completed!"
echo ""
echo "🔗 Access your application:"
echo "   External: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"  
echo "   Local: http://localhost"
echo ""
echo "🔧 Commands:"
echo "   Check status: prime-viz-status"
echo "   View logs: sudo journalctl -u prime-visualization -f"
echo "   Restart: sudo systemctl restart prime-visualization"
echo ""

prime-viz-status
