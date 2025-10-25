#!/bin/bash

# Prime Visualization App - COMPLETE VERSION Deployment Script
# Full featured application with advanced mathematical mappings and high-quality rendering

echo "🚀 Desplegando Aplicación Completa de Visualización de Números Primos..."

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
    print_error "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

print_status "Actualizando paquetes del sistema..."
apt update && apt upgrade -y

print_status "Instalando dependencias del sistema..."
apt install -y python3 python3-pip python3-venv python3-dev python3-tk \
    nginx supervisor git build-essential pkg-config \
    libfreetype6-dev libpng-dev libjpeg-dev

print_status "Creando directorio de aplicación..."
mkdir -p $APP_DIR
cd $APP_DIR

print_status "Configurando entorno virtual de Python..."
$PYTHON_VERSION -m venv $VENV_NAME
source $VENV_NAME/bin/activate

print_status "Instalando dependencias de Python..."
pip install --upgrade pip setuptools wheel

# Install all required packages
pip install Flask==3.1.2 \
    numpy==2.3.3 \
    matplotlib==3.10.6 \
    scipy==1.16.2 \
    gunicorn==21.2.0

print_status "Configurando matplotlib para entorno sin cabeza..."
mkdir -p ~/.matplotlib
echo "backend: Agg" > ~/.matplotlib/matplotlibrc

print_status "Creando aplicación completa (versión española)..."

# Create COMPLETE main application file
cat > app.py << 'EOF'
import numpy as np
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from flask import Flask, render_template, request, jsonify, send_from_directory
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

# ===== FUNCIONES MATEMÁTICAS MEJORADAS =====

def criba_de_eratostenes(limite):
    """Generación optimizada de primos usando la Criba de Eratóstenes."""
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
    """Análisis avanzado de patrones para números primos."""
    patrones = {
        'primos_gemelos': [],  # gap = 2
        'primos_primos': [],  # gap = 4
        'primos_sexy': [],  # gap = 6
        'gaps_primos': defaultdict(int),
        'distribucion_gaps': [],
        'densidad_por_rango': []
    }
    
    conjunto_primos = set(primos)
    
    # Analizar gaps y pares especiales de primos
    for i, p in enumerate(primos[:-1]):
        gap = primos[i+1] - p
        patrones['distribucion_gaps'].append(gap)
        patrones['gaps_primos'][gap] += 1
        
        # Verificar pares especiales de primos
        if p + 2 in conjunto_primos:
            patrones['primos_gemelos'].append((p, p + 2))
        if p + 4 in conjunto_primos:
            patrones['primos_primos'].append((p, p + 4))
        if p + 6 in conjunto_primos:
            patrones['primos_sexy'].append((p, p + 6))
    
    # Calcular densidad por rangos
    range_size = max(primos) // 10 if primos else 1
    for i in range(0, max(primos) if primos else 1, range_size):
        count = sum(1 for p in primos if i <= p < i + range_size)
        density = count / range_size if range_size > 0 else 0
        patrones['densidad_por_rango'].append({
            'inicio_rango': i,
            'fin_rango': i + range_size,
            'cuenta': count,
            'densidad': density
        })
    
    return patrones

def calcular_metricas_avanzadas(primos, patrones):
    """Calcular métricas estadísticas avanzadas."""
    if not primos or len(primos) < 2:
        return {}
    
    gaps = patrones['distribucion_gaps']
    
    metricas = {
        'total_primos': len(primos),
        'pares_primos_gemelos': len(patrones['primos_gemelos']),
        'pares_primos_primos': len(patrones['primos_primos']),
        'pares_primos_sexy': len(patrones['primos_sexy']),
        'gap_promedio': np.mean(gaps) if gaps else 0,
        'varianza_gap': np.var(gaps) if gaps else 0,
        'desviacion_gap': np.std(gaps) if gaps else 0,
        'gap_maximo': max(gaps) if gaps else 0,
        'densidad_primos_gemelos': len(patrones['primos_gemelos']) / len(primos) if primos else 0,
        'entropia_gap': calcular_entropia(patrones['gaps_primos']),
        'violaciones_postulado_bertrand': contar_violaciones_bertrand(primos)
    }
    
    return metricas

def calcular_entropia(cuentas_gap):
    """Calcular entropía de Shannon de la distribución de gaps."""
    if not cuentas_gap:
        return 0
    
    total = sum(cuentas_gap.values())
    if total == 0:
        return 0
    
    entropia = 0
    for cuenta in cuentas_gap.values():
        if cuenta > 0:
            p = cuenta / total
            entropia -= p * math.log2(p)
    
    return entropia

def contar_violaciones_bertrand(primos):
    """Contar violaciones del postulado de Bertrand (con fines educativos)."""
    violaciones = 0
    for i, p in enumerate(primos[:-1]):
        siguiente_primo = primos[i+1]
        if siguiente_primo > 2 * p:
            violaciones += 1
    return violaciones

# ===== FUNCIONES DE MAPEO =====

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

# ===== FUNCIONES DE VISUALIZACIÓN =====

def generar_visualizacion_mejorada(num_circulos, divisiones_por_circulo, tipo_mapeo='lineal', 
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
    plt.rcParams['axes.linewidth'] = 0.8
    plt.rcParams['patch.linewidth'] = 0.5
    
    fig, ax = plt.subplots(1, figsize=tamano_figura, facecolor=colores['fondo'])
    ax.set_facecolor(colores['fondo'])
    ax.set_aspect('equal')
    
    limite_grafico = num_circulos + 0.8
    ax.set_xlim([-limite_grafico, limite_grafico])
    ax.set_ylim([-limite_grafico, limite_grafico])
    ax.axis('off')
    
    # Antialiasing y renderizado suave
    fig.patch.set_antialiased(True)
    ax.patch.set_antialiased(True)
    
    # Calcular posiciones y colores para cada número
    angulo_segmento = 360 / divisiones_por_circulo
    radio_base_interno = 0.6
    ancho_anillo = 0.95  # Ligeramente menor para mejor separación
    
    conjunto_primos_gemelos = set()
    conjunto_primos_primos = set()
    conjunto_primos_sexy = set()
    
    for par in patrones['primos_gemelos']:
        conjunto_primos_gemelos.update(par)
    for par in patrones['primos_primos']:
        conjunto_primos_primos.update(par)
    for par in patrones['primos_sexy']:
        conjunto_primos_sexy.update(par)
    
    # Renderizado por lotes para mejor rendimiento
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
        
        # Determinar color basado en propiedades del número con prioridad
        if n in conjunto_primos_gemelos:
            color = colores['primo_gemelo']
            alpha = 0.95
        elif n in conjunto_primos_primos:
            color = colores['primo_primo']
            alpha = 0.9
        elif n in conjunto_primos_sexy:
            color = colores['primo_sexy']
            alpha = 0.85
        elif n in conjunto_primos:
            color = colores['primo_regular']
            alpha = 0.8
        else:
            color = colores['compuesto']
            alpha = 0.6
        
        wedge = Wedge(
            center=(0, 0),
            r=radio_externo,
            width=ancho_anillo,
            theta1=theta1,
            theta2=theta2,
            alpha=alpha
        )
        wedges.append(wedge)
        colores_wedges.append(color)
    
    # Crear colección para renderizado por lotes
    coleccion_wedges = PatchCollection(wedges, 
                                     facecolors=colores_wedges,
                                     edgecolors='white',
                                     linewidths=0.05 if alta_calidad else 0.1,
                                     antialiased=True)
    ax.add_collection(coleccion_wedges)
    
    # Añadir título mejorado con efectos de sombra
    partes_titulo = [
        f"Visualización Avanzada de Números Primos ({tipo_mapeo.title()})",
        f"Círculos: {num_circulos} | Segmentos: {divisiones_por_circulo} | Total: {segmentos_totales:,}"
    ]
    if incluir_metricas:
        partes_titulo.append(f"Primos: {metricas.get('total_primos', 0):,} | Pares Gemelos: {metricas.get('pares_primos_gemelos', 0)}")
    
    titulo_texto = ax.text(0, limite_grafico - 0.3, '\n'.join(partes_titulo), 
                        ha='center', va='top', color='white', 
                        fontsize=16 if alta_calidad else 14, 
                        fontweight='bold',
                        bbox=dict(boxstyle='round,pad=0.5', facecolor='black', alpha=0.7))
    
    # Añadir efecto de sombra sutil
    titulo_texto.set_path_effects([path_effects.withStroke(linewidth=3, foreground='black')])
    
    # Crear leyenda mejorada con mejor posicionamiento
    elementos_leyenda = [
        plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=colores['primo_gemelo'], 
                  markersize=12, label='Primos Gemelos (gap=2)', markeredgecolor='white', markeredgewidth=1),
        plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=colores['primo_primo'], 
                  markersize=12, label='Primos Primos (gap=4)', markeredgecolor='white', markeredgewidth=1),
        plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=colores['primo_sexy'], 
                  markersize=12, label='Primos Sexy (gap=6)', markeredgecolor='white', markeredgewidth=1),
        plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=colores['primo_regular'], 
                  markersize=12, label='Primos Regulares', markeredgecolor='white', markeredgewidth=1),
        plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=colores['compuesto'], 
                  markersize=12, label='Números Compuestos', markeredgecolor='white', markeredgewidth=1)
    ]
    
    leyenda = ax.legend(handles=elementos_leyenda, loc='upper left', bbox_to_anchor=(-0.05, 0.95), 
                      frameon=True, labelcolor='white', fontsize=11 if alta_calidad else 9,
                      facecolor='black', edgecolor='white', framealpha=0.8)
    leyenda.get_frame().set_linewidth(1.5)
    
    # Añadir guías de círculos concéntricos para mejor legibilidad
    if alta_calidad:
        for i in range(0, num_circulos, max(1, num_circulos // 5)):
            radio_guia = radio_base_interno + i * ancho_anillo + ancho_anillo/2
            guia_circulo = Circle((0, 0), radio_guia, fill=False, 
                                edgecolor='white', alpha=0.2, linewidth=0.5, linestyle='--')
            ax.add_patch(guia_circulo)
    
    # Guardar gráfico a string base64 con configuraciones de alta calidad
    buffer_img = io.BytesIO()
    dpi_guardado = dpi
    plt.savefig(buffer_img, format='png', dpi=dpi_guardado, bbox_inches='tight', 
                facecolor=colores['fondo'], edgecolor='none',
                pad_inches=0.2, transparent=False,
                metadata={'Title': 'Visualización Avanzada de Números Primos',
                         'Author': 'Explorador de Patrones Primos',
                         'Software': 'Python/Matplotlib'})
    buffer_img.seek(0)
    datos_img = base64.b64encode(buffer_img.read()).decode()
    plt.close()
    
    # Resetear configuraciones de matplotlib
    plt.rcdefaults()
    
    return datos_img, metricas, patrones

# ===== RUTAS FLASK =====

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/generar', methods=['POST'])
def generar():
    try:
        datos = request.json
        num_circulos = int(datos.get('num_circulos', 10))
        divisiones_por_circulo = int(datos.get('divisiones_por_circulo', 36))
        tipo_mapeo = datos.get('tipo_mapeo', 'lineal')
        esquema_color = datos.get('esquema_color', 'avanzado')
        incluir_metricas = datos.get('incluir_metricas', True)
        calidad_renderizado = datos.get('calidad_renderizado', 'alta')
        
        # Convertir configuración de calidad a booleano
        alta_calidad = calidad_renderizado == 'alta'
        
        # Validar entradas
        if num_circulos < 1 or num_circulos > 50:
            return jsonify({'error': 'El número de círculos debe estar entre 1 y 50'}), 400
        if divisiones_por_circulo < 4 or divisiones_por_circulo > 360:
            return jsonify({'error': 'Las divisiones por círculo deben estar entre 4 y 360'}), 400
        
        datos_img, metricas, patrones = generar_visualizacion_mejorada(
            num_circulos, divisiones_por_circulo, tipo_mapeo, esquema_color, incluir_metricas, alta_calidad
        )
        
        # Preparar distribución de gaps para frontend
        dist_gaps = []
        if patrones and 'gaps_primos' in patrones:
            for gap, cuenta in sorted(patrones['gaps_primos'].items()):
                if gap <= 30:  # Limitar a los primeros 30 gaps para mostrar
                    dist_gaps.append({'gap': gap, 'cuenta': cuenta})
        
        datos_respuesta = {
            'imagen': datos_img,
            'metricas': metricas,
            'distribucion_gaps': dist_gaps,
            'datos_densidad': patrones.get('densidad_por_rango', []) if patrones else []
        }
        
        return jsonify(datos_respuesta)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

print_status "Creando directorio de templates y archivo HTML completo..."
mkdir -p templates
mkdir -p static

# Create COMPLETE HTML template
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualización Avanzada de Números Primos</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }

        .container {
            max-width: 1600px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
            color: white;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }

        .header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }

        .main-content {
            display: grid;
            grid-template-columns: 1fr 2fr 1fr;
            gap: 20px;
            align-items: start;
        }

        .controls-panel, .metrics-panel {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .visualization-panel {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            text-align: center;
        }

        h3 {
            color: #4a5568;
            margin-bottom: 20px;
            font-size: 1.3rem;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 10px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2d3748;
        }

        input[type="number"], select {
            width: 100%;
            padding: 12px;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            font-size: 16px;
            transition: all 0.3s ease;
            background: white;
        }

        input[type="number"]:focus, select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .checkbox-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        input[type="checkbox"] {
            transform: scale(1.2);
        }

        .generate-btn {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .generate-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
        }

        .generate-btn:active {
            transform: translateY(0);
        }

        .generate-btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }

        .loading {
            display: none;
            text-align: center;
            color: #667eea;
            font-weight: 600;
            margin: 20px 0;
        }

        .loading.show {
            display: block;
        }

        .spinner {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-right: 10px;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .visualization-container {
            margin: 20px 0;
            min-height: 600px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .visualization-container img {
            max-width: 100%;
            height: auto;
            border-radius: 15px;
            box-shadow: 0 8px 40px rgba(0,0,0,0.3);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            image-rendering: -webkit-optimize-contrast;
            image-rendering: crisp-edges;
        }
        
        .visualization-container img:hover {
            transform: scale(1.02);
            box-shadow: 0 12px 60px rgba(0,0,0,0.4);
        }

        .metrics-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 20px;
        }

        .metric-item {
            background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
            padding: 15px;
            border-radius: 10px;
            text-align: center;
            border-left: 4px solid #667eea;
        }

        .metric-value {
            font-size: 1.5rem;
            font-weight: bold;
            color: #2d3748;
            margin-bottom: 5px;
        }

        .metric-label {
            font-size: 0.9rem;
            color: #718096;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .chart-container {
            margin-top: 20px;
            height: 300px;
            position: relative;
        }

        .error-message {
            background: #fed7d7;
            color: #c53030;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #e53e3e;
        }

        .info-panel {
            background: rgba(255, 255, 255, 0.9);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }

        .mapping-info {
            font-size: 0.9rem;
            color: #4a5568;
            background: #f7fafc;
            padding: 15px;
            border-radius: 8px;
            margin-top: 10px;
        }

        .color-legend {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 10px;
            margin-top: 20px;
        }

        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px;
            background: #f7fafc;
            border-radius: 6px;
        }

        .legend-color {
            width: 16px;
            height: 16px;
            border-radius: 3px;
            border: 1px solid #e2e8f0;
        }

        .legend-text {
            font-size: 0.85rem;
            color: #4a5568;
        }

        @media (max-width: 1200px) {
            .main-content {
                grid-template-columns: 1fr;
                grid-template-rows: auto auto auto;
            }
            
            .controls-panel {
                order: 1;
            }
            
            .visualization-panel {
                order: 2;
            }
            
            .metrics-panel {
                order: 3;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔢 Visualización Avanzada de Números Primos</h1>
            <p>Exploración interactiva de patrones primos usando mapeos matemáticos avanzados y análisis estadístico</p>
        </div>

        <div class="main-content">
            <!-- Panel de Controles -->
            <div class="controls-panel">
                <h3>🎛️ Configuración</h3>
                
                <div class="form-group">
                    <label for="num_circulos">Número de Círculos Concéntricos:</label>
                    <input type="number" id="num_circulos" min="1" max="50" value="15" />
                    <small>Rango: 1-50</small>
                </div>

                <div class="form-group">
                    <label for="divisiones_por_circulo">Divisiones por Círculo:</label>
                    <input type="number" id="divisiones_por_circulo" min="4" max="360" value="36" />
                    <small>Rango: 4-360</small>
                </div>

                <div class="form-group">
                    <label for="tipo_mapeo">Función de Mapeo:</label>
                    <select id="tipo_mapeo">
                        <option value="lineal">Lineal (Estándar)</option>
                        <option value="logaritmico">Espiral Logarítmica</option>
                        <option value="arquimedes">Espiral de Arquímedes</option>
                    </select>
                    <div id="info_mapeo" class="mapping-info">
                        El mapeo lineal coloca los números secuencialmente en círculos concéntricos.
                    </div>
                </div>

                <div class="form-group">
                    <label for="esquema_color">Esquema de Colores:</label>
                    <select id="esquema_color">
                        <option value="avanzado">Avanzado (Clásico)</option>
                        <option value="plasma">Plasma (Vibrante)</option>
                        <option value="naturaleza">Naturaleza (Orgánico)</option>
                    </select>
                </div>

                <div class="form-group">
                    <div class="checkbox-group">
                        <input type="checkbox" id="incluir_metricas" checked />
                        <label for="incluir_metricas">Incluir Métricas Estadísticas</label>
                    </div>
                </div>

                <div class="form-group">
                    <label for="calidad_renderizado">Calidad de Renderizado:</label>
                    <select id="calidad_renderizado">
                        <option value="alta" selected>Alta Calidad (300 DPI)</option>
                        <option value="estandar">Estándar (200 DPI)</option>
                        <option value="rapida">Vista Previa Rápida (100 DPI)</option>
                    </select>
                    <div class="mapping-info">
                        La alta calidad proporciona imágenes nítidas listas para publicación pero tarda más en renderizar.
                    </div>
                </div>

                <button id="generar" class="generate-btn">
                    Generar Visualización
                </button>

                <div id="cargando" class="loading">
                    <div class="spinner"></div>
                    Generando visualización...
                </div>

                <div class="info-panel">
                    <h4>🎨 Tipos de Primos</h4>
                    <div id="leyenda_colores" class="color-legend">
                        <!-- La leyenda dinámica se insertará aquí -->
                    </div>
                </div>
            </div>

            <!-- Panel de Visualización -->
            <div class="visualization-panel">
                <h3>📊 Visualización de Patrones Primos</h3>
                <div id="contenedor_visualizacion" class="visualization-container">
                    <p style="color: #718096; font-size: 1.1rem;">
                        Configure los parámetros y haga clic en "Generar Visualización" para explorar patrones primos
                    </p>
                </div>
                <div id="mensaje_error" class="error-message" style="display: none;"></div>
            </div>

            <!-- Panel de Métricas -->
            <div class="metrics-panel">
                <h3>📈 Análisis Estadístico</h3>
                
                <div id="contenedor_metricas">
                    <p style="color: #718096; text-align: center; margin: 40px 0;">
                        Las métricas aparecerán después de generar la visualización
                    </p>
                </div>

                <div class="chart-container">
                    <canvas id="graficoGaps"></canvas>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Configuración y estado
        const configuracion = {
            urlApi: '/generar',
            maxReintentos: 3,
            retrasoReintento: 1000
        };

        let graficoGaps = null;

        // Descripciones de funciones de mapeo
        const descripcionesMapeo = {
            lineal: "El mapeo lineal coloca números secuencialmente en círculos concéntricos, manteniendo el orden natural.",
            logaritmico: "El mapeo de espiral logarítmica usa escalado logarítmico para distribuir mejor los primos y revelar patrones.",
            arquimedes: "El mapeo de espiral de Arquímedes sigue r = aθ, creando una distribución espiral uniforme."
        };

        // Definiciones de esquemas de color
        const esquemasColor = {
            avanzado: {
                primo_gemelo: '#FF0000',
                primo_primo: '#FF8C00',
                primo_sexy: '#FF1493',
                primo_regular: '#0000FF',
                compuesto: '#D3D3D3'
            },
            plasma: {
                primo_gemelo: '#F0F921',
                primo_primo: '#FD9467',
                primo_sexy: '#E16462',
                primo_regular: '#B12A90',
                compuesto: '#6A00A8'
            },
            naturaleza: {
                primo_gemelo: '#FF6B6B',
                primo_primo: '#4ECDC4',
                primo_sexy: '#45B7D1',
                primo_regular: '#96CEB4',
                compuesto: '#FFEAA7'
            }
        };

        // Elementos del DOM
        const elementos = {
            botonGenerar: document.getElementById('generar'),
            cargando: document.getElementById('cargando'),
            contenedorVisualizacion: document.getElementById('contenedor_visualizacion'),
            mensajeError: document.getElementById('mensaje_error'),
            contenedorMetricas: document.getElementById('contenedor_metricas'),
            infoMapeo: document.getElementById('info_mapeo'),
            leyendaColores: document.getElementById('leyenda_colores'),
            selectMapeo: document.getElementById('tipo_mapeo'),
            selectEsquemaColor: document.getElementById('esquema_color')
        };

        // Event listeners
        elementos.botonGenerar.addEventListener('click', generarVisualizacion);
        elementos.selectMapeo.addEventListener('change', actualizarInfoMapeo);
        elementos.selectEsquemaColor.addEventListener('change', actualizarLeyendaColor);

        // Inicializar
        actualizarInfoMapeo();
        actualizarLeyendaColor();

        function actualizarInfoMapeo() {
            const tipoMapeo = elementos.selectMapeo.value;
            elementos.infoMapeo.textContent = descripcionesMapeo[tipoMapeo];
        }

        function actualizarLeyendaColor() {
            const esquema = elementos.selectEsquemaColor.value;
            const colores = esquemasColor[esquema];
            
            const itemsLeyenda = [
                { color: colores.primo_gemelo, texto: 'Primos Gemelos' },
                { color: colores.primo_primo, texto: 'Primos Primos' },
                { color: colores.primo_sexy, texto: 'Primos Sexy' },
                { color: colores.primo_regular, texto: 'Primos Regulares' },
                { color: colores.compuesto, texto: 'Números Compuestos' }
            ];

            elementos.leyendaColores.innerHTML = itemsLeyenda.map(item => `
                <div class="legend-item">
                    <div class="legend-color" style="background-color: ${item.color}"></div>
                    <div class="legend-text">${item.texto}</div>
                </div>
            `).join('');
        }

        async function generarVisualizacion() {
            const datosSolicitud = {
                num_circulos: parseInt(document.getElementById('num_circulos').value),
                divisiones_por_circulo: parseInt(document.getElementById('divisiones_por_circulo').value),
                tipo_mapeo: document.getElementById('tipo_mapeo').value,
                esquema_color: document.getElementById('esquema_color').value,
                incluir_metricas: document.getElementById('incluir_metricas').checked,
                calidad_renderizado: document.getElementById('calidad_renderizado').value
            };

            // Validar entradas
            if (datosSolicitud.num_circulos < 1 || datosSolicitud.num_circulos > 50) {
                mostrarError('El número de círculos debe estar entre 1 y 50');
                return;
            }

            if (datosSolicitud.divisiones_por_circulo < 4 || datosSolicitud.divisiones_por_circulo > 360) {
                mostrarError('Las divisiones por círculo deben estar entre 4 y 360');
                return;
            }

            // Mostrar estado de carga
            mostrarCarga(true);
            ocultarError();

            try {
                const respuesta = await fetch(configuracion.urlApi, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(datosSolicitud)
                });

                if (!respuesta.ok) {
                    const datosError = await respuesta.json();
                    throw new Error(datosError.error || `Error HTTP! estado: ${respuesta.status}`);
                }

                const datos = await respuesta.json();
                mostrarResultados(datos);

            } catch (error) {
                console.error('Error generando visualización:', error);
                mostrarError(`Error al generar visualización: ${error.message}`);
            } finally {
                mostrarCarga(false);
            }
        }

        function mostrarResultados(datos) {
            // Mostrar visualización principal con opción de descarga
            if (datos.imagen) {
                elementos.contenedorVisualizacion.innerHTML = `
                    <div style="position: relative;">
                        <img src="data:image/png;base64,${datos.imagen}" alt="Visualización de Números Primos" 
                             style="cursor: zoom-in;" onclick="abrirModalImagen(this.src)" />
                        <button onclick="descargarImagen('${datos.imagen}')" 
                                style="position: absolute; top: 10px; right: 10px; 
                                       background: rgba(255,255,255,0.9); border: none; 
                                       border-radius: 6px; padding: 8px 12px; cursor: pointer;
                                       font-size: 12px; font-weight: bold; color: #333;
                                       box-shadow: 0 2px 10px rgba(0,0,0,0.2);">
                            📥 Descargar HD
                        </button>
                    </div>
                `;
            }

            // Mostrar métricas
            if (datos.metricas) {
                mostrarMetricas(datos.metricas);
            }

            // Mostrar gráfico de distribución de gaps
            if (datos.distribucion_gaps) {
                mostrarGraficoGaps(datos.distribucion_gaps);
            }
        }

        function mostrarMetricas(metricas) {
            const htmlMetricas = `
                <div class="metrics-grid">
                    <div class="metric-item">
                        <div class="metric-value">${metricas.total_primos || 0}</div>
                        <div class="metric-label">Total Primos</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${metricas.pares_primos_gemelos || 0}</div>
                        <div class="metric-label">Pares Primos Gemelos</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${metricas.pares_primos_primos || 0}</div>
                        <div class="metric-label">Pares Primos Primos</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${metricas.pares_primos_sexy || 0}</div>
                        <div class="metric-label">Pares Primos Sexy</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${(metricas.gap_promedio || 0).toFixed(2)}</div>
                        <div class="metric-label">Gap Promedio</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${metricas.gap_maximo || 0}</div>
                        <div class="metric-label">Gap Máximo</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${((metricas.densidad_primos_gemelos || 0) * 100).toFixed(1)}%</div>
                        <div class="metric-label">Densidad Primos Gemelos</div>
                    </div>
                    <div class="metric-item">
                        <div class="metric-value">${(metricas.entropia_gap || 0).toFixed(2)}</div>
                        <div class="metric-label">Entropía de Gaps</div>
                    </div>
                </div>
            `;

            elementos.contenedorMetricas.innerHTML = htmlMetricas;
        }

        function mostrarGraficoGaps(datosGaps) {
            const ctx = document.getElementById('graficoGaps').getContext('2d');
            
            if (graficoGaps) {
                graficoGaps.destroy();
            }

            const etiquetas = datosGaps.map(item => `Gap ${item.gap}`);
            const datos = datosGaps.map(item => item.cuenta);

            graficoGaps = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: etiquetas,
                    datasets: [{
                        label: 'Frecuencia de Gaps',
                        data: datos,
                        backgroundColor: 'rgba(102, 126, 234, 0.8)',
                        borderColor: 'rgba(102, 126, 234, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Distribución de Gaps entre Primos',
                            font: {
                                size: 14,
                                weight: 'bold'
                            }
                        },
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Frecuencia'
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Tamaño del Gap'
                            }
                        }
                    }
                }
            });
        }

        function mostrarCarga(mostrar) {
            elementos.cargando.classList.toggle('show', mostrar);
            elementos.botonGenerar.disabled = mostrar;
        }

        function mostrarError(mensaje) {
            elementos.mensajeError.textContent = mensaje;
            elementos.mensajeError.style.display = 'block';
        }

        function ocultarError() {
            elementos.mensajeError.style.display = 'none';
        }

        // Funciones de modal de imagen y descarga
        function abrirModalImagen(src) {
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed; top: 0; left: 0; width: 100%; height: 100%;
                background: rgba(0,0,0,0.9); display: flex; align-items: center;
                justify-content: center; z-index: 10000; cursor: zoom-out;
            `;
            
            const img = document.createElement('img');
            img.src = src;
            img.style.cssText = `
                max-width: 95%; max-height: 95%; border-radius: 10px;
                box-shadow: 0 20px 80px rgba(0,0,0,0.5);
            `;
            
            modal.appendChild(img);
            modal.onclick = () => document.body.removeChild(modal);
            document.body.appendChild(modal);
        }

        function descargarImagen(datosBase64) {
            const enlace = document.createElement('a');
            enlace.href = 'data:image/png;base64,' + datosBase64;
            enlace.download = `visualizacion_primos_${Date.now()}.png`;
            document.body.appendChild(enlace);
            enlace.click();
            document.body.removeChild(enlace);
        }

        // Manejar redimensionamiento de ventana para el gráfico
        window.addEventListener('resize', () => {
            if (graficoGaps) {
                graficoGaps.resize();
            }
        });
    </script>
</body>
</html>
EOF

print_status "Creando configuración optimizada de Gunicorn..."
cat > gunicorn.conf.py << 'EOF'
bind = "0.0.0.0:5000"
workers = 3
worker_class = "sync"
worker_connections = 1000
timeout = 600
keepalive = 5
max_requests = 2000
max_requests_jitter = 200
preload_app = True
worker_tmp_dir = "/dev/shm"
EOF

print_status "Creando archivo de servicio systemd..."
cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=Prime Visualization Advanced App
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/$VENV_NAME/bin"
Environment="MPLCONFIGDIR=/tmp"
ExecStart=$APP_DIR/$VENV_NAME/bin/gunicorn -c gunicorn.conf.py app:app
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=10
KillMode=mixed
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

print_status "Configurando Nginx con optimizaciones..."
cat > /etc/nginx/sites-available/$APP_NAME << 'EOF'
upstream prime_app {
    server 127.0.0.1:5000 fail_timeout=5s max_fails=3;
}

server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    location / {
        proxy_pass http://prime_app;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 600s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 600s;
        proxy_buffering off;
    }
    
    location /static {
        alias /var/www/prime-visualization/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
        gzip_static on;
    }
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_status "Configurando permisos y propietarios..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR
chmod +x $APP_DIR/app.py

print_status "Iniciando servicios..."
systemctl daemon-reload
systemctl enable $APP_NAME
systemctl start $APP_NAME
systemctl enable nginx
systemctl restart nginx

# Crear script de estado mejorado
cat > /usr/local/bin/prime-viz-status << 'EOF'
#!/bin/bash
echo "=== Prime Visualization Advanced App Status ==="
echo ""
echo "🔍 Application Status:"
systemctl status prime-visualization --no-pager -l | head -10
echo ""
echo "🌐 Web Server Status:"
systemctl status nginx --no-pager -l | head -10
echo ""
echo "📊 Resource Usage:"
echo "Memory Usage:"
ps aux --sort=-%mem | grep -E "(gunicorn|nginx)" | head -5
echo ""
echo "🔗 Network Connections:"
netstat -tuln | grep -E ":80|:5000" || ss -tuln | grep -E ":80|:5000"
echo ""
echo "📋 Recent App Logs (last 5 lines):"
journalctl -u prime-visualization -n 5 --no-pager
echo ""
echo "🎯 Quick Tests:"
curl -I http://localhost >/dev/null 2>&1 && echo "✅ HTTP Response: OK" || echo "❌ HTTP Response: FAILED"
echo "✅ Deployment Complete!"
EOF

chmod +x /usr/local/bin/prime-viz-status

print_success "¡Despliegue de aplicación completa finalizado exitosamente!"
print_status "Aplicación corriendo en: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"
print_status "Acceso local: http://localhost"
print_status "Usa 'prime-viz-status' para verificar el estado de la aplicación"
print_status "Logs disponibles con: journalctl -u prime-visualization -f"

echo ""
echo "🎉 ¡Aplicación Avanzada de Visualización de Primos está funcionando!"
echo "🎨 Características disponibles:"
echo "   • Renderizado de alta calidad hasta 300 DPI"
echo "   • 3 funciones de mapeo matemático (Lineal, Logarítmico, Arquímedes)"
echo "   • 3 esquemas de color profesionales"
echo "   • Análisis estadístico completo (Entropía, Densidad, Gaps)"
echo "   • Interface interactiva completa en español"
echo "   • Descarga de imágenes HD"
echo "   • Modal de zoom para inspección detallada"
echo "   • Gráficos dinámicos con Chart.js"
echo ""
echo "📊 ¡Accede a tu aplicación y explora patrones matemáticos avanzados!"
echo "🔧 Comandos de gestión:"
echo "  - Estado: prime-viz-status"
echo "  - Reiniciar: systemctl restart prime-visualization"
echo "  - Logs: journalctl -u prime-visualization -f"
EOF

print_status "Configurando script como ejecutable..."
chmod +x deploy_full.sh

print_success "Script de despliegue completo creado exitosamente!"
echo ""
echo "📦 Archivo: deploy_full.sh"
echo "🎯 Incluye todas las funcionalidades avanzadas:"
echo "   • Criba de Eratóstenes optimizada"
echo "   • 3 funciones de mapeo matemático"
echo "   • Análisis estadístico completo"
echo "   • Renderizado de alta calidad (300 DPI)"
echo "   • Interface HTML5 completa"
echo "   • Configuración de producción optimizada"
echo ""
echo "🚀 Para desplegar: sudo ./deploy_full.sh"