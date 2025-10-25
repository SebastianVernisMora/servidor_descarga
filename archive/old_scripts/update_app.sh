#!/bin/bash

# Script para actualizar solo la aplicación sin reinstalar todo el sistema
# Para usar después de modificar deploy.sh

echo "🔄 Actualizando Prime Visualization App..."

# Configuration variables
APP_NAME="prime-visualization"
APP_DIR="/var/www/$APP_NAME"
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
    print_error "El directorio de la aplicación no existe: $APP_DIR"
    print_error "Ejecuta deploy.sh primero para instalar la aplicación"
    exit 1
fi

print_status "Deteniendo la aplicación..."
systemctl stop $APP_NAME

print_status "Navegando al directorio de la aplicación..."
cd $APP_DIR

print_status "Activando entorno virtual..."
source $VENV_NAME/bin/activate

print_status "Actualizando el archivo de la aplicación..."
# Create updated application file (Spanish version)
cat > app.py << 'EOF'
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from flask import Flask, render_template, request, jsonify
import io
import base64
import json
from collections import defaultdict
import math
from scipy import stats
import os
from matplotlib.patches import Wedge, Circle
from matplotlib.collections import PatchCollection
import matplotlib.patheffects as path_effects

app = Flask(__name__)

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

def encontrar_patrones_primos(primos, gap_maximo=30):
    patrones = {
        'primos_gemelos': [],
        'primos_primos': [],
        'primos_sexy': [],
        'gaps_primos': defaultdict(int),
        'distribucion_gaps': [],
        'densidad_por_rango': []
    }
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

def calcular_metricas_avanzadas(primos, patrones):
    if not primos or len(primos) < 2:
        return {}
    gaps = patrones['distribucion_gaps']
    
    # Calcular entropía de Shannon de los gaps
    from collections import Counter
    gap_counts = Counter(gaps)
    total_gaps = len(gaps)
    entropia = 0
    if total_gaps > 0:
        for count in gap_counts.values():
            p = count / total_gaps
            if p > 0:
                entropia -= p * math.log2(p)
    
    return {
        'total_primos': len(primos),
        'pares_primos_gemelos': len(patrones['primos_gemelos']),
        'pares_primos_primos': len(patrones['primos_primos']),
        'pares_primos_sexy': len(patrones['primos_sexy']),
        'gap_promedio': np.mean(gaps) if gaps else 0,
        'gap_maximo': max(gaps) if gaps else 0,
        'gap_minimo': min(gaps) if gaps else 0,
        'densidad_primos_gemelos': len(patrones['primos_gemelos']) / len(primos) if primos else 0,
        'densidad_general': len(primos) / primos[-1] if primos else 0,
        'entropia_gap': entropia,
        'desviacion_gap': np.std(gaps) if gaps else 0
    }

def mapeo_lineal(n, segmentos_totales, num_circulos, divisiones_por_circulo):
    """Mapeo lineal estándar."""
    circulo = n // divisiones_por_circulo
    segmento = n % divisiones_por_circulo
    return circulo, segmento

def mapeo_logaritmico(n, segmentos_totales, num_circulos, divisiones_por_circulo):
    """Mapeo de espiral logarítmica para mejor distribución de primos."""
    if n <= 0:
        return 0, 0
    
    log_n = math.log(n + 1)
    log_maximo = math.log(segmentos_totales + 1)
    
    # Mapear a coordenadas espirales
    pos_normalizada = log_n / log_maximo if log_maximo > 0 else 0
    posiciones_totales = num_circulos * divisiones_por_circulo
    pos_espiral = int(pos_normalizada * posiciones_totales)
    
    circulo = min(pos_espiral // divisiones_por_circulo, num_circulos - 1)
    segmento = pos_espiral % divisiones_por_circulo
    
    return circulo, segmento

def mapeo_espiral_arquimedes(n, segmentos_totales, num_circulos, divisiones_por_circulo):
    """Mapeo de espiral de Arquímedes."""
    if n <= 0:
        return 0, 0
    
    # Convertir a coordenadas polares con espiral de Arquímedes
    theta = 2 * math.pi * math.sqrt(n)
    r = math.sqrt(n) / math.sqrt(segmentos_totales) * num_circulos
    
    circulo = min(int(r), num_circulos - 1)
    segmento = int((theta % (2 * math.pi)) / (2 * math.pi) * divisiones_por_circulo)
    
    return circulo, segmento

def generar_visualizacion_mejorada(num_circulos, divisiones_por_circulo, mostrar_primos_gemelos=True,
                                  mostrar_primos_primos=True, mostrar_primos_sexy=True, 
                                  mostrar_primos_regulares=True, tipo_mapeo='lineal', 
                                  esquema_color='avanzado', incluir_metricas=True, alta_calidad=True):
    """Generar visualización mejorada de primos con renderizado de alta calidad."""
    segmentos_totales = num_circulos * divisiones_por_circulo
    primos = criba_de_eratostenes(segmentos_totales)
    conjunto_primos = set(primos)
    patrones = encontrar_patrones_primos(primos)
    metricas = calcular_metricas_avanzadas(primos, patrones) if incluir_metricas else {}
    
    # Elegir función de mapeo
    funciones_mapeo = {
        'lineal': mapeo_lineal,
        'logaritmico': mapeo_logaritmico,
        'arquimedes': mapeo_espiral_arquimedes
    }
    func_mapeo = funciones_mapeo.get(tipo_mapeo, mapeo_lineal)
    
    # Esquemas de color
    esquemas_color = {
        'avanzado': {
            'primo_gemelo': '#FF0000',      # Rojo
            'primo_primo': '#FF8C00',       # Naranja Oscuro
            'primo_sexy': '#FF1493',        # Rosa Profundo
            'primo_regular': '#0000FF',     # Azul
            'compuesto': '#D3D3D3',         # Gris Claro
            'fondo': '#000000'              # Negro
        },
        'plasma': {
            'primo_gemelo': '#F0F921',      # Amarillo Brillante
            'primo_primo': '#FD9467',       # Naranja
            'primo_sexy': '#E16462',        # Rojo
            'primo_regular': '#B12A90',     # Púrpura
            'compuesto': '#6A00A8',         # Púrpura Oscuro
            'fondo': '#0D0887'              # Azul Oscuro
        },
        'naturaleza': {
            'primo_gemelo': '#FF6B6B',      # Coral
            'primo_primo': '#4ECDC4',       # Verde Azulado
            'primo_sexy': '#45B7D1',        # Azul Cielo
            'primo_regular': '#96CEB4',     # Menta
            'compuesto': '#FFEAA7',         # Amarillo Claro
            'fondo': '#2D3436'              # Gris Oscuro
        }
    }
    
    colores = esquemas_color.get(esquema_color, esquemas_color['avanzado'])
    
    # Crear figura de alta calidad
    dpi = 300 if alta_calidad else 200
    tamano_figura = (16, 16) if alta_calidad else (12, 12)
    
    # Usar configuraciones de alta calidad
    plt.rcParams['figure.dpi'] = dpi
    plt.rcParams['savefig.dpi'] = dpi
    plt.rcParams['font.size'] = 12 if alta_calidad else 10
    plt.rcParams['lines.linewidth'] = 0.8 if alta_calidad else 0.5
    plt.rcParams['patch.linewidth'] = 0.1 if alta_calidad else 0.05
    
    fig, ax = plt.subplots(1, figsize=tamano_figura, facecolor=colores['fondo'])
    ax.set_facecolor(colores['fondo'])
    ax.set_aspect('equal')
    
    limite_grafico = num_circulos + 0.8
    ax.set_xlim([-limite_grafico, limite_grafico])
    ax.set_ylim([-limite_grafico, limite_grafico])
    ax.axis('off')
    
    angulo_segmento = 360 / divisiones_por_circulo
    radio_base_interno = 0.6
    ancho_anillo = 0.95
    
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
    
    for n in range(1, segmentos_totales + 1):
        circulo, segmento = func_mapeo(n, segmentos_totales, num_circulos, divisiones_por_circulo)
        if circulo >= num_circulos:
            continue
            
        radio_interno = radio_base_interno + circulo * ancho_anillo
        radio_externo = radio_interno + ancho_anillo
        theta1 = segmento * angulo_segmento
        theta2 = (segmento + 1) * angulo_segmento
        
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
    
    coleccion_wedges = PatchCollection(wedges, facecolors=colores_wedges,
                                     edgecolors='white', linewidths=0.1, antialiased=True)
    ax.add_collection(coleccion_wedges)
    
    ax.text(0, limite_grafico - 0.3, f'Visualización de Números Primos\nCírculos: {num_circulos} | Segmentos: {divisiones_por_circulo}',
            ha='center', va='top', color='white', fontsize=14, fontweight='bold')
    
    buffer_img = io.BytesIO()
    plt.savefig(buffer_img, format='png', dpi=dpi, bbox_inches='tight', 
                facecolor=colores['fondo'], edgecolor='none', 
                pad_inches=0.1, transparent=False, 
                metadata={'Software': 'Prime Visualization App'})
    buffer_img.seek(0)
    datos_img = base64.b64encode(buffer_img.read()).decode()
    plt.close()
    
    return datos_img, metricas, patrones

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/generar', methods=['POST'])
def generar():
    try:
        datos = request.json
        num_circulos = int(datos.get('num_circulos', 10))
        divisiones_por_circulo = int(datos.get('divisiones_por_circulo', 36))
        mostrar_primos_gemelos = datos.get('mostrar_primos_gemelos', True)
        mostrar_primos_primos = datos.get('mostrar_primos_primos', True)
        mostrar_primos_sexy = datos.get('mostrar_primos_sexy', True)
        mostrar_primos_regulares = datos.get('mostrar_primos_regulares', True)
        tipo_mapeo = datos.get('tipo_mapeo', 'lineal')
        esquema_color = datos.get('esquema_color', 'avanzado')
        alta_calidad = datos.get('alta_calidad', True)
        
        if num_circulos < 1 or num_circulos > 10000:
            return jsonify({'error': 'El número de círculos debe estar entre 1 y 10,000'}), 400
        if divisiones_por_circulo < 4 or divisiones_por_circulo > 500:
            return jsonify({'error': 'Las divisiones por círculo deben estar entre 4 y 500'}), 400
        
        datos_img, metricas, patrones = generar_visualizacion_mejorada(num_circulos, divisiones_por_circulo,
                                                                       mostrar_primos_gemelos, mostrar_primos_primos,
                                                                       mostrar_primos_sexy, mostrar_primos_regulares,
                                                                       tipo_mapeo, esquema_color, True, alta_calidad)
        
        dist_gaps = []
        if patrones and 'gaps_primos' in patrones:
            for gap, cuenta in sorted(patrones['gaps_primos'].items()):
                if gap <= 30:
                    dist_gaps.append({'gap': gap, 'cuenta': cuenta})
        
        return jsonify({
            'imagen': datos_img,
            'metricas': metricas,
            'distribucion_gaps': dist_gaps
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

print_status "Actualizando template HTML..."
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualización de Números Primos</title>
    <style>
        body { font-family: Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin: 0; padding: 20px; color: white; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 30px; }
        .controls { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-row { display: flex; gap: 20px; align-items: flex-start; flex-wrap: wrap; }
        .form-column { flex: 1; min-width: 300px; }
        label { display: block; margin-bottom: 5px; cursor: pointer; }
        input, select, button { padding: 10px; border-radius: 5px; border: none; margin-right: 10px; }
        button { background: #4CAF50; color: white; cursor: pointer; }
        button:hover { background: #45a049; }
        button.toggle-btn { background: #2196F3; padding: 8px 16px; font-size: 12px; }
        .checkbox-group { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; margin-bottom: 15px; }
        .checkbox-group h3 { margin-top: 0; margin-bottom: 10px; font-size: 16px; }
        .checkbox-item { margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
        .checkbox-item input[type="checkbox"] { width: 18px; height: 18px; }
        .help-icon { display: inline-block; width: 20px; height: 20px; background: #2196F3; color: white; border-radius: 50%; text-align: center; line-height: 20px; font-size: 12px; cursor: pointer; margin-left: 5px; }
        .tooltip { position: relative; }
        .tooltip .tooltiptext { visibility: hidden; width: 300px; background-color: rgba(0,0,0,0.9); color: #fff; text-align: left; border-radius: 6px; padding: 10px; position: absolute; z-index: 1; bottom: 125%; left: 50%; margin-left: -150px; opacity: 0; transition: opacity 0.3s; font-size: 12px; line-height: 1.4; }
        .tooltip:hover .tooltiptext { visibility: visible; opacity: 1; }
        .visualization { text-align: center; background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 20px; }
        .metric { background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; text-align: center; }
        .loading { display: none; }
        .error { background: #f44336; padding: 10px; border-radius: 5px; margin: 10px 0; }
        .color-legend { display: flex; justify-content: center; gap: 20px; margin-top: 15px; flex-wrap: wrap; }
        .legend-item { display: flex; align-items: center; gap: 8px; font-size: 14px; }
        .color-box { width: 20px; height: 20px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔢 Visualización Avanzada de Números Primos</h1>
            <p>Exploración interactiva de patrones matemáticos</p>
        </div>
        
        <div class="controls">
            <div class="form-row">
                <div class="form-column">
                    <div class="form-group">
                        <label>Número de Círculos:
                            <span class="tooltip help-icon">?
                                <span class="tooltiptext">
                                    <strong>Número de Círculos:</strong><br>
                                    Define cuántos anillos concéntricos se dibujarán en la visualización. Cada círculo representa un rango de números. Más círculos = más números analizados.<br>
                                    <em>Rango: 1 - 10,000</em>
                                </span>
                            </span>
                        </label>
                        <input type="number" id="num_circulos" value="10" min="1" max="10000">
                    </div>
                    <div class="form-group">
                        <label>Divisiones por Círculo:
                            <span class="tooltip help-icon">?
                                <span class="tooltiptext">
                                    <strong>Divisiones por Círculo:</strong><br>
                                    Determina cuántos segmentos tiene cada círculo. Más divisiones = mayor resolución y precisión en la visualización de patrones.<br>
                                    <em>Rango: 4 - 500</em>
                                </span>
                            </span>
                        </label>
                        <input type="number" id="divisiones_por_circulo" value="36" min="4" max="500">
                    </div>
                    <div class="form-group">
                        <label>Tipo de Mapeo:
                            <span class="tooltip help-icon">?
                                <span class="tooltiptext">
                                    <strong>Tipo de Mapeo:</strong><br>
                                    Define cómo se distribuyen los números en la visualización:<br>
                                    • <strong>Lineal:</strong> Distribución secuencial estándar<br>
                                    • <strong>Logarítmico:</strong> Enfatiza números pequeños<br>
                                    • <strong>Arquímedes:</strong> Espiral matemática clásica
                                </span>
                            </span>
                        </label>
                        <select id="tipo_mapeo">
                            <option value="lineal">Lineal</option>
                            <option value="logaritmico">Logarítmico</option>
                            <option value="arquimedes">Espiral de Arquímedes</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Esquema de Color:
                            <span class="tooltip help-icon">?
                                <span class="tooltiptext">
                                    <strong>Esquemas de Color:</strong><br>
                                    • <strong>Avanzado:</strong> Colores clásicos sobre fondo negro<br>
                                    • <strong>Plasma:</strong> Gradiente cálido amarillo-púrpura<br>
                                    • <strong>Naturaleza:</strong> Colores suaves inspirados en la naturaleza
                                </span>
                            </span>
                        </label>
                        <select id="esquema_color">
                            <option value="avanzado">Avanzado</option>
                            <option value="plasma">Plasma</option>
                            <option value="naturaleza">Naturaleza</option>
                        </select>
                    </div>
                </div>
                <div class="form-column">
                    <div class="checkbox-group">
                        <h3>Tipos de Primos a Mostrar
                            <button class="toggle-btn" onclick="toggleTodos()">Alternar Todos</button>
                        </h3>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_gemelos" checked>
                            <label for="mostrar_primos_gemelos">Primos Gemelos
                                <span class="tooltip help-icon">?
                                    <span class="tooltiptext">
                                        <strong>Primos Gemelos:</strong><br>
                                        Pares de números primos que difieren en 2 unidades (ej: 3,5 o 11,13). Son especialmente raros en números grandes y muestran patrones fascinantes.<br>
                                        <em>Color: Rojo (#FF0000)</em>
                                    </span>
                                </span>
                            </label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_primos" checked>
                            <label for="mostrar_primos_primos">Primos Primos
                                <span class="tooltip help-icon">?
                                    <span class="tooltiptext">
                                        <strong>Primos Primos:</strong><br>
                                        Pares de números primos que difieren en 4 unidades (ej: 3,7 o 13,17). Menos frecuentes que los gemelos, forman patrones únicos en la visualización.<br>
                                        <em>Color: Naranja (#FF8C00)</em>
                                    </span>
                                </span>
                            </label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_sexy" checked>
                            <label for="mostrar_primos_sexy">Primos Sexy
                                <span class="tooltip help-icon">?
                                    <span class="tooltiptext">
                                        <strong>Primos Sexy:</strong><br>
                                        Pares de números primos que difieren en 6 unidades (ej: 5,11 o 13,19). Su nombre viene del latín 'sex' (seis). Crean patrones hexagonales interesantes.<br>
                                        <em>Color: Rosa (#FF1493)</em>
                                    </span>
                                </span>
                            </label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_regulares" checked>
                            <label for="mostrar_primos_regulares">Primos Regulares
                                <span class="tooltip help-icon">?
                                    <span class="tooltiptext">
                                        <strong>Primos Regulares:</strong><br>
                                        Todos los demás números primos que no pertenecen a ninguna de las categorías especiales anteriores. Forman la base de la visualización.<br>
                                        <em>Color: Azul (#0000FF)</em>
                                    </span>
                                </span>
                            </label>
                        </div>
                    </div>
                    <div class="checkbox-group">
                        <h3>Opciones de Renderizado</h3>
                        <div class="checkbox-item">
                            <input type="checkbox" id="alta_calidad" checked>
                            <label for="alta_calidad">Alta Calidad (300 DPI)
                                <span class="tooltip help-icon">?
                                    <span class="tooltiptext">
                                        <strong>Alta Calidad:</strong><br>
                                        Renderiza la imagen a 300 DPI con mayor tamaño y detalle. Recomendado para visualizaciones complejas, pero toma más tiempo generar.
                                    </span>
                                </span>
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            <div style="text-align: center; margin-top: 20px;">
                <button onclick="generarVisualizacion()">Generar Visualización</button>
                <div id="loading" class="loading">Generando visualización...</div>
                <div id="error" class="error" style="display: none;"></div>
            </div>
            <div class="color-legend">
                <div class="legend-item">
                    <div class="color-box" style="background-color: #FF0000;"></div>
                    <span>Primos Gemelos</span>
                </div>
                <div class="legend-item">
                    <div class="color-box" style="background-color: #FF8C00;"></div>
                    <span>Primos Primos</span>
                </div>
                <div class="legend-item">
                    <div class="color-box" style="background-color: #FF1493;"></div>
                    <span>Primos Sexy</span>
                </div>
                <div class="legend-item">
                    <div class="color-box" style="background-color: #0000FF;"></div>
                    <span>Primos Regulares</span>
                </div>
                <div class="legend-item">
                    <div class="color-box" style="background-color: #D3D3D3;"></div>
                    <span>Números Compuestos</span>
                </div>
            </div>
        </div>
        
        <div class="visualization">
            <div id="resultado"></div>
            <div id="metricas" class="metrics"></div>
        </div>
    </div>
    
    <script>
        function toggleTodos() {
            const checkboxes = ['mostrar_primos_gemelos', 'mostrar_primos_primos', 'mostrar_primos_sexy', 'mostrar_primos_regulares'];
            const primerCheckbox = document.getElementById(checkboxes[0]);
            const nuevoEstado = !primerCheckbox.checked;
            
            checkboxes.forEach(id => {
                document.getElementById(id).checked = nuevoEstado;
            });
        }
        
        async function generarVisualizacion() {
            const loading = document.getElementById('loading');
            const error = document.getElementById('error');
            const resultado = document.getElementById('resultado');
            const metricas = document.getElementById('metricas');
            
            loading.style.display = 'block';
            error.style.display = 'none';
            
            try {
                const response = await fetch('/generar', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        num_circulos: parseInt(document.getElementById('num_circulos').value),
                        divisiones_por_circulo: parseInt(document.getElementById('divisiones_por_circulo').value),
                        mostrar_primos_gemelos: document.getElementById('mostrar_primos_gemelos').checked,
                        mostrar_primos_primos: document.getElementById('mostrar_primos_primos').checked,
                        mostrar_primos_sexy: document.getElementById('mostrar_primos_sexy').checked,
                        mostrar_primos_regulares: document.getElementById('mostrar_primos_regulares').checked,
                        tipo_mapeo: document.getElementById('tipo_mapeo').value,
                        esquema_color: document.getElementById('esquema_color').value,
                        alta_calidad: document.getElementById('alta_calidad').checked
                    })
                });
                
                const data = await response.json();
                
                if (!response.ok) throw new Error(data.error);
                
                resultado.innerHTML = `<img src="data:image/png;base64,${data.imagen}" style="max-width: 100%; border-radius: 10px;">`;
                
                if (data.metricas) {
                    metricas.innerHTML = `
                        <div class="metric"><h3>${data.metricas.total_primos}</h3><p>Total Primos</p></div>
                        <div class="metric"><h3>${data.metricas.pares_primos_gemelos}</h3><p>Pares Gemelos</p></div>
                        <div class="metric"><h3>${data.metricas.pares_primos_primos}</h3><p>Pares Primos</p></div>
                        <div class="metric"><h3>${data.metricas.pares_primos_sexy}</h3><p>Pares Sexy</p></div>
                        <div class="metric"><h3>${data.metricas.gap_promedio.toFixed(2)}</h3><p>Gap Promedio</p></div>
                        <div class="metric"><h3>${data.metricas.gap_maximo}</h3><p>Gap Máximo</p></div>
                        <div class="metric"><h3>${data.metricas.gap_minimo}</h3><p>Gap Mínimo</p></div>
                        <div class="metric"><h3>${((data.metricas.densidad_primos_gemelos || 0) * 100).toFixed(2)}%</h3><p>Densidad Gemelos</p></div>
                        <div class="metric"><h3>${((data.metricas.densidad_general || 0) * 100).toFixed(2)}%</h3><p>Densidad General</p></div>
                        <div class="metric"><h3>${data.metricas.entropia_gap.toFixed(2)}</h3><p>Entropía Gaps</p></div>
                        <div class="metric"><h3>${data.metricas.desviacion_gap.toFixed(2)}</h3><p>Desviación Gaps</p></div>
                    `;
                }
                
            } catch (err) {
                error.textContent = err.message;
                error.style.display = 'block';
            } finally {
                loading.style.display = 'none';
            }
        }
        
        // Generar visualización inicial al cargar la página
        window.addEventListener('load', function() {
            generarVisualizacion();
        });
    </script>
</body>
</html>
EOF

print_status "Estableciendo permisos..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

print_status "Reiniciando la aplicación..."
systemctl start $APP_NAME
systemctl restart nginx

print_success "¡Actualización completada!"
print_status "La aplicación actualizada está corriendo en: http://$(curl -s ifconfig.me):80"
print_status "Acceso local: http://localhost"

echo ""
echo "🎉 ¡Aplicación actualizada exitosamente!"
echo "🔧 Los nuevos cambios incluyen:"
echo "  - Rango ampliado: hasta 10,000 círculos y 500 divisiones"
echo "  - Checkboxes para tipos de primos"
echo "  - Tooltips explicativos"
echo "  - Botón 'Alternar Todos'"
echo "  - Leyenda de colores"