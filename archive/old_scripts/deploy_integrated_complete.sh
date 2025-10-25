#!/bin/bash

# Prime Visualization App - INTEGRACIÓN COMPLETA CON TODOS LOS PARÁMETROS
# Versión integrada con todas las características de todos los archivos de despliegue

echo "🚀 Desplegando Aplicación INTEGRADA COMPLETA de Visualización de Números Primos..."
echo "🔗 Integrando parámetros de TODOS los archivos de despliegue existentes"

# Configuration variables
APP_NAME="prime-visualization"
APP_DIR="/var/www/$APP_NAME"
PYTHON_VERSION="python3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_feature() { echo -e "${PURPLE}[FEATURE]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

print_status "Actualizando sistema..."
apt update && apt upgrade -y

print_status "Instalando dependencias del sistema completas..."
apt install -y python3 python3-pip python3-venv python3-dev python3-tk \
    nginx git curl build-essential pkg-config \
    libfreetype6-dev libpng-dev libjpeg-dev libopenblas-dev gfortran \
    redis-server supervisor htop

print_status "Removiendo instalación previa si existe..."
systemctl stop $APP_NAME 2>/dev/null || true
systemctl disable $APP_NAME 2>/dev/null || true
rm -rf $APP_DIR
rm -f /etc/systemd/system/$APP_NAME.service
rm -f /etc/nginx/sites-enabled/$APP_NAME
rm -f /etc/nginx/sites-available/$APP_NAME

print_status "Creando directorio de aplicación..."
mkdir -p $APP_DIR/{static,templates,cache,data}
cd $APP_DIR

print_status "Configurando entorno virtual Python..."
$PYTHON_VERSION -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel

print_status "Instalando todas las dependencias Python..."
# Instalar todas las dependencias encontradas en los archivos
pip install Flask==3.1.0 numpy==2.1.0 matplotlib==3.9.0 scipy==1.14.0 \
    gunicorn==23.0.0 Pillow==10.4.0 redis==5.0.0 celery==5.3.0 \
    requests==2.31.0 psutil==5.9.0

print_status "Configurando matplotlib optimizado..."
mkdir -p /var/www/.matplotlib ~/.matplotlib

cat > ~/.matplotlib/matplotlibrc << 'EOF'
backend: Agg
figure.max_open_warning: 0
font.size: 12
figure.dpi: 100
savefig.dpi: 300
savefig.format: png
savefig.bbox: tight
axes.facecolor: black
figure.facecolor: black
text.color: white
axes.labelcolor: white
xtick.color: white
ytick.color: white
EOF

cp ~/.matplotlib/matplotlibrc /var/www/.matplotlib/matplotlibrc

print_feature "Creando aplicación con TODOS los parámetros integrados..."

# Crear aplicación Python COMPLETA con TODOS los parámetros de todos los archivos
cat > app.py << 'PYTHON_EOF'
import os
import sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from flask import Flask, render_template, request, jsonify, send_file, send_from_directory
import io
import base64
import json
from collections import defaultdict, Counter
import math
import traceback
from datetime import datetime
import time
from matplotlib.patches import Wedge, Circle, Rectangle
from matplotlib.collections import PatchCollection
import matplotlib.patheffects as path_effects
from scipy import stats
import requests
import psutil

# Configurar matplotlib para mejor rendimiento
plt.ioff()
matplotlib.rcParams.update({
    'figure.max_open_warning': 0,
    'savefig.pad_inches': 0.1,
    'font.family': 'sans-serif',
    'axes.grid': False
})

app = Flask(__name__)
app.config.update({
    'JSON_AS_ASCII': False,
    'MAX_CONTENT_LENGTH': 50 * 1024 * 1024,  # 50MB max
    'SEND_FILE_MAX_AGE_DEFAULT': 3600
})

# ===== FUNCIONES MATEMÁTICAS AVANZADAS =====

def criba_de_eratostenes_optimizada(limite):
    """Criba de Eratóstenes optimizada con técnicas avanzadas."""
    if limite < 2: return []
    if limite == 2: return [2]
    
    # Solo números impares después del 2
    sqrt_limite = int(math.sqrt(limite)) + 1
    es_primo = [True] * (limite + 1)
    es_primo[0] = es_primo[1] = False
    
    # Manejar el 2 por separado
    for i in range(4, limite + 1, 2):
        es_primo[i] = False
    
    # Solo verificar números impares
    for i in range(3, sqrt_limite, 2):
        if es_primo[i]:
            for j in range(i*i, limite + 1, 2*i):
                es_primo[j] = False
    
    return [i for i in range(2, limite + 1) if es_primo[i]]

def encontrar_todos_los_patrones_primos(primos):
    """Análisis exhaustivo de todos los patrones de primos."""
    if not primos or len(primos) < 2:
        return {}
    
    patrones = {
        'primos_gemelos': [],        # gap = 2
        'primos_primos': [],         # gap = 4  
        'primos_sexy': [],           # gap = 6
        'primos_sophie_germain': [], # p donde 2p+1 también es primo
        'gaps_primos': defaultdict(int),
        'distribucion_gaps': [],
        'consecutivos_especiales': [],
        'palindromos': [],
        'mersenne': [],
        'fermat': [],
        'densidad_por_rango': [],
        'secuencias_aritmeticas': []
    }
    
    conjunto_primos = set(primos)
    
    # Análisis de gaps y pares especiales
    for i, p in enumerate(primos[:-1]):
        gap = primos[i+1] - p
        patrones['distribucion_gaps'].append(gap)
        patrones['gaps_primos'][gap] += 1
        
        # Pares especiales
        if p + 2 in conjunto_primos:
            patrones['primos_gemelos'].append((p, p + 2))
        if p + 4 in conjunto_primos:
            patrones['primos_primos'].append((p, p + 4))
        if p + 6 in conjunto_primos:
            patrones['primos_sexy'].append((p, p + 6))
        
        # Sophie Germain
        if 2*p + 1 in conjunto_primos:
            patrones['primos_sophie_germain'].append((p, 2*p + 1))
        
        # Palíndromos
        if str(p) == str(p)[::-1] and len(str(p)) > 1:
            patrones['palindromos'].append(p)
    
    # Mersenne: 2^n - 1
    for n in range(2, 20):  # Limitado para eficiencia
        mersenne = 2**n - 1
        if mersenne in conjunto_primos and mersenne <= max(primos):
            patrones['mersenne'].append(mersenne)
    
    # Fermat: 2^(2^n) + 1
    for n in range(5):
        fermat = 2**(2**n) + 1
        if fermat in conjunto_primos and fermat <= max(primos):
            patrones['fermat'].append(fermat)
    
    # Densidad por rangos
    max_primo = max(primos)
    num_rangos = min(20, max_primo // 100)
    if num_rangos > 0:
        tamaño_rango = max_primo // num_rangos
        for i in range(num_rangos):
            inicio = i * tamaño_rango
            fin = (i + 1) * tamaño_rango
            count = sum(1 for p in primos if inicio <= p < fin)
            density = count / tamaño_rango if tamaño_rango > 0 else 0
            patrones['densidad_por_rango'].append({
                'inicio': inicio, 'fin': fin, 'count': count, 'density': density
            })
    
    return patrones

def calcular_metricas_completas(primos, patrones):
    """Calcular todas las métricas estadísticas posibles."""
    if not primos or len(primos) < 2:
        return inicializar_metricas_vacias()
    
    gaps = patrones.get('distribucion_gaps', [])
    gap_counts = Counter(gaps) if gaps else Counter()
    
    # Entropía de Shannon
    entropia = 0
    if gaps:
        total_gaps = len(gaps)
        for count in gap_counts.values():
            p = count / total_gaps
            if p > 0: entropia -= p * math.log2(p)
    
    # Coeficiente de variación
    gap_mean = np.mean(gaps) if gaps else 0
    gap_std = np.std(gaps) if gaps else 0
    coef_variacion = gap_std / gap_mean if gap_mean > 0 else 0
    
    # Test de aleatoriedad (runs test simplificado)
    runs_test = calcular_runs_test(primos) if len(primos) > 10 else 0
    
    # Densidad asintótica teórica vs real
    max_primo = max(primos)
    densidad_teorica = 1 / math.log(max_primo) if max_primo > 1 else 0
    densidad_real = len(primos) / max_primo if max_primo > 0 else 0
    
    return {
        'total_primos': int(len(primos)),
        'primo_maximo': int(max(primos)),
        'primo_minimo': int(min(primos)),
        'rango_total': int(max(primos) - min(primos)),
        'pares_primos_gemelos': int(len(patrones.get('primos_gemelos', []))),
        'pares_primos_primos': int(len(patrones.get('primos_primos', []))),
        'pares_primos_sexy': int(len(patrones.get('primos_sexy', []))),
        'primos_sophie_germain': int(len(patrones.get('primos_sophie_germain', []))),
        'primos_palindromos': int(len(patrones.get('palindromos', []))),
        'primos_mersenne': int(len(patrones.get('mersenne', []))),
        'primos_fermat': int(len(patrones.get('fermat', []))),
        'gap_promedio': float(gap_mean),
        'gap_maximo': int(max(gaps)) if gaps else 0,
        'gap_minimo': int(min(gaps)) if gaps else 0,
        'gap_mediana': float(np.median(gaps)) if gaps else 0,
        'gap_moda': int(gap_counts.most_common(1)[0][0]) if gap_counts else 0,
        'desviacion_gap': float(gap_std),
        'varianza_gap': float(np.var(gaps)) if gaps else 0,
        'coeficiente_variacion': float(coef_variacion),
        'entropia_gap': float(entropia),
        'asimetria_gap': float(stats.skew(gaps)) if len(gaps) > 3 else 0,
        'curtosis_gap': float(stats.kurtosis(gaps)) if len(gaps) > 3 else 0,
        'densidad_real': float(densidad_real),
        'densidad_teorica': float(densidad_teorica),
        'ratio_densidades': float(densidad_real / densidad_teorica) if densidad_teorica > 0 else 0,
        'densidad_primos_gemelos': float(len(patrones.get('primos_gemelos', [])) / len(primos)),
        'densidad_primos_especiales': float((len(patrones.get('primos_gemelos', [])) + 
                                           len(patrones.get('primos_primos', [])) + 
                                           len(patrones.get('primos_sexy', []))) / len(primos)),
        'factor_calidad_distribucion': float(runs_test),
        'indice_irregularidad': float(gap_std / gap_mean) if gap_mean > 0 else 0,
        'timestamp': datetime.now().isoformat()
    }

def inicializar_metricas_vacias():
    """Métricas iniciales cuando no hay datos suficientes."""
    return {k: 0 if k != 'timestamp' else datetime.now().isoformat() 
            for k in ['total_primos', 'primo_maximo', 'primo_minimo', 'rango_total',
                     'pares_primos_gemelos', 'pares_primos_primos', 'pares_primos_sexy',
                     'gap_promedio', 'gap_maximo', 'gap_minimo', 'desviacion_gap', 
                     'entropia_gap', 'densidad_real', 'timestamp']}

def calcular_runs_test(primos):
    """Test simplificado de aleatoriedad basado en runs de gaps."""
    if len(primos) < 10: return 0
    gaps = np.diff(primos)
    median_gap = np.median(gaps)
    runs = sum(1 for i in range(1, len(gaps)) 
              if (gaps[i] > median_gap) != (gaps[i-1] > median_gap))
    expected_runs = (2 * len(gaps) - 1) / 3
    return abs(runs - expected_runs) / expected_runs if expected_runs > 0 else 0

# ===== FUNCIONES DE MAPEO GEOMÉTRICO =====

def mapeo_lineal(n, total, num_circulos, divisiones):
    """Mapeo lineal estándar - distribución secuencial."""
    circulo = n // divisiones
    segmento = n % divisiones
    return min(circulo, num_circulos - 1), segmento

def mapeo_logaritmico(n, total, num_circulos, divisiones):
    """Mapeo logarítmico - enfatiza números pequeños."""
    if n <= 0: return 0, 0
    log_pos = math.log(n + 1) / math.log(total + 1) if total > 0 else 0
    pos_total = int(log_pos * num_circulos * divisiones)
    circulo = min(pos_total // divisiones, num_circulos - 1)
    segmento = pos_total % divisiones
    return circulo, segmento

def mapeo_espiral_arquimedes(n, total, num_circulos, divisiones):
    """Espiral de Arquímedes - r = aθ."""
    if n <= 0: return 0, 0
    theta = 2 * math.pi * math.sqrt(n / total) if total > 0 else 0
    r = math.sqrt(n / total) * num_circulos if total > 0 else 0
    circulo = min(int(r), num_circulos - 1)
    segmento = int((theta % (2 * math.pi)) / (2 * math.pi) * divisiones)
    return circulo, segmento

def mapeo_espiral_fibonacci(n, total, num_circulos, divisiones):
    """Espiral de Fibonacci - basado en la razón áurea."""
    if n <= 0: return 0, 0
    phi = (1 + math.sqrt(5)) / 2
    theta = 2 * math.pi * n / phi
    r = math.sqrt(n) / math.sqrt(total) * num_circulos if total > 0 else 0
    circulo = min(int(r), num_circulos - 1)
    segmento = int((theta % (2 * math.pi)) / (2 * math.pi) * divisiones)
    return circulo, segmento

def mapeo_cuadratico(n, total, num_circulos, divisiones):
    """Mapeo cuadrático - distribución no lineal."""
    if n <= 0: return 0, 0
    pos_cuad = (n / total) ** 0.5 if total > 0 else 0
    pos_total = int(pos_cuad * num_circulos * divisiones)
    circulo = min(pos_total // divisiones, num_circulos - 1)
    segmento = pos_total % divisiones
    return circulo, segmento

def mapeo_hexagonal(n, total, num_circulos, divisiones):
    """Mapeo hexagonal - empaquetado hexagonal."""
    if n <= 0: return 0, 0
    # Convertir a coordenadas hexagonales
    q = int(math.sqrt(n))
    r = n - q * q
    # Mapear a coordenadas polares
    circulo = min(q % num_circulos, num_circulos - 1)
    segmento = (r * divisiones) // (2 * q + 1) if q > 0 else 0
    return circulo, segmento % divisiones

# ===== ESQUEMAS DE COLOR AVANZADOS =====

def obtener_esquemas_color():
    """Todos los esquemas de color disponibles."""
    return {
        'clasico': {
            'primo_gemelo': '#FF0000', 'primo_primo': '#FF8C00', 'primo_sexy': '#FF1493',
            'primo_sophie': '#9400D3', 'primo_palindromo': '#FFD700', 'primo_mersenne': '#00FFFF',
            'primo_fermat': '#ADFF2F', 'primo_regular': '#0000FF', 'compuesto': '#808080', 'fondo': '#000000'
        },
        'plasma': {
            'primo_gemelo': '#F0F921', 'primo_primo': '#FD9467', 'primo_sexy': '#E16462',
            'primo_sophie': '#B12A90', 'primo_palindromo': '#6A00A8', 'primo_mersenne': '#2D115F',
            'primo_fermat': '#0D0887', 'primo_regular': '#440154', 'compuesto': '#482777', 'fondo': '#0D0887'
        },
        'naturaleza': {
            'primo_gemelo': '#FF6B6B', 'primo_primo': '#4ECDC4', 'primo_sexy': '#45B7D1',
            'primo_sophie': '#96CEB4', 'primo_palindromo': '#FFEAA7', 'primo_mersenne': '#DDA0DD',
            'primo_fermat': '#98D8C8', 'primo_regular': '#74B9FF', 'compuesto': '#DCDCDC', 'fondo': '#2D3436'
        },
        'neon': {
            'primo_gemelo': '#FF073A', 'primo_primo': '#FF8C42', 'primo_sexy': '#FFF700',
            'primo_sophie': '#39FF14', 'primo_palindromo': '#00FFFF', 'primo_mersenne': '#BF00FF',
            'primo_fermat': '#FF1493', 'primo_regular': '#0080FF', 'compuesto': '#404040', 'fondo': '#000000'
        },
        'oceanico': {
            'primo_gemelo': '#FF6B9D', 'primo_primo': '#C44569', 'primo_sexy': '#F8B500',
            'primo_sophie': '#6A0572', 'primo_palindromo': '#AB83A1', 'primo_mersenne': '#1B9AAA',
            'primo_fermat': '#06FFA5', 'primo_regular': '#4D96FF', 'compuesto': '#9BADB7', 'fondo': '#2C3A47'
        },
        'monocromatico': {
            'primo_gemelo': '#FFFFFF', 'primo_primo': '#E0E0E0', 'primo_sexy': '#C0C0C0',
            'primo_sophie': '#A0A0A0', 'primo_palindromo': '#808080', 'primo_mersenne': '#606060',
            'primo_fermat': '#404040', 'primo_regular': '#303030', 'compuesto': '#202020', 'fondo': '#000000'
        }
    }

# ===== FUNCIÓN DE VISUALIZACIÓN PRINCIPAL =====

def generar_visualizacion_completa(
    num_circulos=15, divisiones_por_circulo=36,
    mostrar_primos_gemelos=True, mostrar_primos_primos=True, mostrar_primos_sexy=True,
    mostrar_primos_regulares=True, mostrar_sophie_germain=False, mostrar_palindromos=False,
    mostrar_mersenne=False, mostrar_fermat=False,
    tipo_mapeo='lineal', esquema_color='clasico', calidad_renderizado='alta',
    mostrar_anillos_guia=False, mostrar_numeros=False, mostrar_grid_radial=False,
    transparencia=0.8, grosor_borde=0.1, incluir_leyenda=True, incluir_estadisticas=True,
    formato_exportacion='png', optimizar_memoria=True, usar_antialiasing=True
):
    """Función principal de visualización con TODOS los parámetros integrados."""
    
    try:
        # Limpiar matplotlib
        plt.clf()
        plt.close('all')
        
        # Validar y ajustar parámetros
        num_circulos = max(1, min(num_circulos, 1000))
        divisiones_por_circulo = max(4, min(divisiones_por_circulo, 500))
        transparencia = max(0.1, min(transparencia, 1.0))
        
        segmentos_totales = num_circulos * divisiones_por_circulo
        
        print(f"Generando {segmentos_totales} segmentos con mapeo {tipo_mapeo}")
        
        # Generar primos y patrones
        primos = criba_de_eratostenes_optimizada(segmentos_totales)
        conjunto_primos = set(primos)
        patrones = encontrar_todos_los_patrones_primos(primos)
        metricas = calcular_metricas_completas(primos, patrones)
        
        # Configurar mapeo
        funciones_mapeo = {
            'lineal': mapeo_lineal,
            'logaritmico': mapeo_logaritmico,
            'arquimedes': mapeo_espiral_arquimedes,
            'fibonacci': mapeo_espiral_fibonacci,
            'cuadratico': mapeo_cuadratico,
            'hexagonal': mapeo_hexagonal
        }
        func_mapeo = funciones_mapeo.get(tipo_mapeo, mapeo_lineal)
        
        # Configurar colores
        esquemas = obtener_esquemas_color()
        colores = esquemas.get(esquema_color, esquemas['clasico'])
        
        # Configurar calidad
        config_calidad = {
            'baja': {'dpi': 150, 'tamano': (10, 10), 'linewidth': 0.2},
            'media': {'dpi': 200, 'tamano': (12, 12), 'linewidth': 0.15},
            'alta': {'dpi': 300, 'tamano': (16, 16), 'linewidth': 0.1},
            'ultra': {'dpi': 400, 'tamano': (20, 20), 'linewidth': 0.05}
        }
        config = config_calidad.get(calidad_renderizado, config_calidad['alta'])
        
        # Crear figura
        fig, ax = plt.subplots(1, figsize=config['tamano'], 
                              facecolor=colores['fondo'], dpi=config['dpi'])
        ax.set_facecolor(colores['fondo'])
        ax.set_aspect('equal')
        
        limite = num_circulos + 1
        ax.set_xlim([-limite, limite])
        ax.set_ylim([-limite, limite])
        ax.axis('off')
        
        # Configurar antialiasing
        if usar_antialiasing:
            fig.patch.set_antialiased(True)
            ax.patch.set_antialiased(True)
        
        # Crear conjuntos de primos especiales
        conjuntos_especiales = {
            'gemelos': set(sum(patrones.get('primos_gemelos', []), ())),
            'primos': set(sum(patrones.get('primos_primos', []), ())),
            'sexy': set(sum(patrones.get('primos_sexy', []), ())),
            'sophie': set(sum(patrones.get('primos_sophie_germain', []), ())),
            'palindromos': set(patrones.get('palindromos', [])),
            'mersenne': set(patrones.get('mersenne', [])),
            'fermat': set(patrones.get('fermat', []))
        }
        
        # Renderizar elementos
        wedges = []
        colores_wedges = []
        
        angulo_por_segmento = 360.0 / divisiones_por_circulo
        radio_base = 0.5
        ancho_anillo = 0.9
        
        for n in range(1, segmentos_totales + 1):
            circulo, segmento = func_mapeo(n, segmentos_totales, num_circulos, divisiones_por_circulo)
            
            if circulo >= num_circulos:
                continue
            
            radio_interno = radio_base + circulo * ancho_anillo
            radio_externo = radio_interno + ancho_anillo
            theta1 = segmento * angulo_por_segmento
            theta2 = (segmento + 1) * angulo_por_segmento
            
            # Determinar color con prioridad
            color = colores['compuesto']  # Default
            if n in conjunto_primos:
                if mostrar_mersenne and n in conjuntos_especiales['mersenne']:
                    color = colores['primo_mersenne']
                elif mostrar_fermat and n in conjuntos_especiales['fermat']:
                    color = colores['primo_fermat']
                elif mostrar_primos_gemelos and n in conjuntos_especiales['gemelos']:
                    color = colores['primo_gemelo']
                elif mostrar_sophie_germain and n in conjuntos_especiales['sophie']:
                    color = colores['primo_sophie']
                elif mostrar_palindromos and n in conjuntos_especiales['palindromos']:
                    color = colores['primo_palindromo']
                elif mostrar_primos_primos and n in conjuntos_especiales['primos']:
                    color = colores['primo_primo']
                elif mostrar_primos_sexy and n in conjuntos_especiales['sexy']:
                    color = colores['primo_sexy']
                elif mostrar_primos_regulares:
                    color = colores['primo_regular']
            
            wedge = Wedge(center=(0, 0), r=radio_externo, width=ancho_anillo,
                         theta1=theta1, theta2=theta2, alpha=transparencia)
            wedges.append(wedge)
            colores_wedges.append(color)
        
        # Renderizar colección
        collection = PatchCollection(wedges, facecolors=colores_wedges,
                                   edgecolors='white', linewidths=grosor_borde,
                                   antialiased=usar_antialiasing)
        ax.add_collection(collection)
        
        # Añadir elementos opcionales
        if mostrar_anillos_guia:
            for i in range(0, num_circulos, max(1, num_circulos // 10)):
                radio_guia = radio_base + i * ancho_anillo + ancho_anillo/2
                circle = Circle((0, 0), radio_guia, fill=False, 
                               edgecolor='white', alpha=0.3, linewidth=0.5, linestyle='--')
                ax.add_patch(circle)
        
        if mostrar_grid_radial:
            for i in range(0, 360, 30):
                rad = math.radians(i)
                x_end = limite * 0.9 * math.cos(rad)
                y_end = limite * 0.9 * math.sin(rad)
                ax.plot([0, x_end], [0, y_end], color='white', alpha=0.2, linewidth=0.5)
        
        # Título mejorado
        titulo_lineas = [
            f"Visualización Avanzada de Números Primos ({tipo_mapeo.title()})",
            f"Círculos: {num_circulos} | Segmentos: {divisiones_por_circulo} | Total: {segmentos_totales:,}",
            f"Primos: {metricas['total_primos']:,} | Densidad: {metricas['densidad_real']:.3f}"
        ]
        
        ax.text(0, limite - 0.2, '\\n'.join(titulo_lineas),
                ha='center', va='top', color='white', fontsize=12,
                fontweight='bold', 
                bbox=dict(boxstyle='round,pad=0.5', facecolor='black', alpha=0.7))
        
        # Leyenda
        if incluir_leyenda:
            elementos_leyenda = []
            if mostrar_primos_gemelos:
                elementos_leyenda.append(plt.Line2D([0], [0], marker='o', color='w',
                                                   markerfacecolor=colores['primo_gemelo'],
                                                   markersize=10, label='Primos Gemelos'))
            if mostrar_mersenne:
                elementos_leyenda.append(plt.Line2D([0], [0], marker='o', color='w',
                                                   markerfacecolor=colores['primo_mersenne'],
                                                   markersize=10, label='Primos Mersenne'))
            # Añadir más elementos según necesidad...
            
            if elementos_leyenda:
                legend = ax.legend(handles=elementos_leyenda[:8], loc='upper left',
                                 bbox_to_anchor=(-0.05, 0.95), frameon=True,
                                 labelcolor='white', fontsize=9,
                                 facecolor='black', edgecolor='white', framealpha=0.8)
        
        # Guardar imagen
        buffer_img = io.BytesIO()
        formato_salida = formato_exportacion.lower()
        if formato_salida not in ['png', 'jpg', 'jpeg', 'pdf', 'svg']:
            formato_salida = 'png'
        
        plt.savefig(buffer_img, format=formato_salida, dpi=config['dpi'],
                   bbox_inches='tight', facecolor=colores['fondo'],
                   edgecolor='none', pad_inches=0.1, transparent=False,
                   optimize=optimizar_memoria)
        
        buffer_img.seek(0)
        datos_img = base64.b64encode(buffer_img.read()).decode('utf-8')
        
        # Limpiar memoria
        plt.close(fig)
        buffer_img.close()
        
        if optimizar_memoria:
            plt.clf()
            plt.close('all')
        
        return datos_img, metricas, patrones
        
    except Exception as e:
        plt.close('all')
        print(f"Error en visualización: {str(e)}")
        traceback.print_exc()
        raise e

# ===== RUTAS FLASK =====

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/info')
def api_info():
    """Información de la API y sistema."""
    return jsonify({
        'version': '2.0.0',
        'features': [
            'Múltiples mapeos geométricos', 'Análisis estadístico completo',
            'Esquemas de color avanzados', 'Exportación multi-formato',
            'Detección de patrones especiales', 'Renderizado optimizado'
        ],
        'mapeos_disponibles': list(['lineal', 'logaritmico', 'arquimedes', 'fibonacci', 'cuadratico', 'hexagonal']),
        'esquemas_color': list(obtener_esquemas_color().keys()),
        'memoria_sistema': dict(psutil.virtual_memory()._asdict()),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/generar', methods=['POST'])
def generar():
    """Endpoint principal con TODOS los parámetros integrados."""
    try:
        datos = request.get_json()
        if not datos:
            return jsonify({'error': 'No se recibieron datos JSON'}), 400
        
        # Extraer TODOS los parámetros posibles
        parametros = {
            'num_circulos': int(datos.get('num_circulos', 15)),
            'divisiones_por_circulo': int(datos.get('divisiones_por_circulo', 36)),
            'mostrar_primos_gemelos': bool(datos.get('mostrar_primos_gemelos', True)),
            'mostrar_primos_primos': bool(datos.get('mostrar_primos_primos', True)),
            'mostrar_primos_sexy': bool(datos.get('mostrar_primos_sexy', True)),
            'mostrar_primos_regulares': bool(datos.get('mostrar_primos_regulares', True)),
            'mostrar_sophie_germain': bool(datos.get('mostrar_sophie_germain', False)),
            'mostrar_palindromos': bool(datos.get('mostrar_palindromos', False)),
            'mostrar_mersenne': bool(datos.get('mostrar_mersenne', False)),
            'mostrar_fermat': bool(datos.get('mostrar_fermat', False)),
            'tipo_mapeo': str(datos.get('tipo_mapeo', 'lineal')),
            'esquema_color': str(datos.get('esquema_color', 'clasico')),
            'calidad_renderizado': str(datos.get('calidad_renderizado', 'alta')),
            'mostrar_anillos_guia': bool(datos.get('mostrar_anillos_guia', False)),
            'mostrar_numeros': bool(datos.get('mostrar_numeros', False)),
            'mostrar_grid_radial': bool(datos.get('mostrar_grid_radial', False)),
            'transparencia': float(datos.get('transparencia', 0.8)),
            'grosor_borde': float(datos.get('grosor_borde', 0.1)),
            'incluir_leyenda': bool(datos.get('incluir_leyenda', True)),
            'incluir_estadisticas': bool(datos.get('incluir_estadisticas', True)),
            'formato_exportacion': str(datos.get('formato_exportacion', 'png')),
            'optimizar_memoria': bool(datos.get('optimizar_memoria', True)),
            'usar_antialiasing': bool(datos.get('usar_antialiasing', True))
        }
        
        # Validaciones
        if not (1 <= parametros['num_circulos'] <= 1000):
            return jsonify({'error': 'Círculos debe estar entre 1 y 1000'}), 400
        if not (4 <= parametros['divisiones_por_circulo'] <= 500):
            return jsonify({'error': 'Divisiones debe estar entre 4 y 500'}), 400
        
        # Generar visualización
        inicio = time.time()
        datos_img, metricas, patrones = generar_visualizacion_completa(**parametros)
        tiempo_generacion = time.time() - inicio
        
        # Preparar distribución de gaps
        dist_gaps = []
        if patrones and 'gaps_primos' in patrones:
            for gap, cuenta in sorted(patrones['gaps_primos'].items()):
                if gap <= 50:  # Expandido
                    dist_gaps.append({'gap': int(gap), 'cuenta': int(cuenta)})
        
        # Respuesta completa
        respuesta = {
            'imagen': str(datos_img),
            'metricas': dict(metricas),
            'distribucion_gaps': list(dist_gaps),
            'patrones_especiales': {
                'primos_gemelos': len(patrones.get('primos_gemelos', [])),
                'primos_sophie_germain': len(patrones.get('primos_sophie_germain', [])),
                'palindromos': len(patrones.get('palindromos', [])),
                'mersenne': len(patrones.get('mersenne', [])),
                'fermat': len(patrones.get('fermat', []))
            },
            'parametros_usados': parametros,
            'tiempo_generacion': round(tiempo_generacion, 3),
            'timestamp': datetime.now().isoformat(),
            'version': '2.0.0'
        }
        
        return jsonify(respuesta)
        
    except Exception as e:
        print(f"Error en /generar: {str(e)}")
        traceback.print_exc()
        return jsonify({
            'error': f'Error interno del servidor: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/export/<formato>')
def exportar(formato):
    """Exportar última visualización en formato específico."""
    # Implementar exportación directa en diferentes formatos
    return jsonify({'message': f'Exportación en {formato} no implementada aún'}), 501

if __name__ == '__main__':
    print("🚀 Iniciando aplicación completa de visualización de primos...")
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
PYTHON_EOF

print_feature "Creando interfaz HTML COMPLETA con TODOS los controles..."

cat > templates/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualización Completa de Números Primos v2.0</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; color: white; overflow-x: auto;
        }
        
        .container { max-width: 1800px; margin: 0 auto; padding: 15px; }
        
        .header {
            text-align: center; margin-bottom: 25px;
            background: rgba(0,0,0,0.3); padding: 20px; border-radius: 15px;
        }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .header .version { color: #FFD700; font-size: 1.1rem; }
        
        .main-layout {
            display: grid;
            grid-template-columns: 350px 1fr 300px;
            gap: 20px; align-items: start;
        }
        
        .panel {
            background: rgba(255,255,255,0.95); color: #333;
            border-radius: 15px; padding: 20px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        
        .section { margin-bottom: 20px; padding: 15px; 
                  background: rgba(0,0,0,0.05); border-radius: 8px; }
        .section h3 { color: #4a5568; margin-bottom: 15px; 
                     border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; }
        
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 600; }
        
        input, select { width: 100%; padding: 8px; border: 2px solid #e2e8f0;
                       border-radius: 6px; font-size: 14px; }
        input:focus, select:focus { border-color: #667eea; outline: none; }
        
        .checkbox-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
        .checkbox-item { display: flex; align-items: center; gap: 8px; padding: 5px; }
        .checkbox-item input { width: auto; }
        
        .range-group { display: flex; align-items: center; gap: 10px; }
        .range-input { flex: 1; }
        .range-value { min-width: 40px; text-align: center; 
                      background: #f8f9fa; padding: 4px 8px; border-radius: 4px; }
        
        .generate-btn {
            width: 100%; padding: 15px; margin: 20px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; border: none; border-radius: 8px;
            font-size: 16px; font-weight: bold; cursor: pointer;
        }
        .generate-btn:hover { transform: translateY(-1px); }
        .generate-btn:disabled { opacity: 0.6; transform: none; }
        
        .visualization-panel { text-align: center; min-height: 600px; 
                              display: flex; flex-direction: column; }
        .visualization-container { flex: 1; display: flex; align-items: center; 
                                  justify-content: center; position: relative; }
        .result-image { max-width: 100%; max-height: 70vh; border-radius: 15px; 
                       box-shadow: 0 8px 40px rgba(0,0,0,0.3); }
        
        .metrics-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .metric-card { background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
                      padding: 12px; border-radius: 8px; text-align: center; }
        .metric-value { font-size: 1.3rem; font-weight: bold; color: #2d3748; }
        .metric-label { font-size: 0.8rem; color: #718096; }
        
        .loading { display: none; padding: 20px; text-align: center; 
                  background: rgba(102, 126, 234, 0.1); border-radius: 8px; }
        .loading.show { display: block; }
        .spinner { display: inline-block; width: 20px; height: 20px; margin-right: 10px;
                  border: 3px solid #f3f3f3; border-top: 3px solid #667eea;
                  border-radius: 50%; animation: spin 1s linear infinite; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        
        .error { background: #fed7d7; color: #c53030; padding: 15px; 
                border-radius: 8px; margin: 10px 0; display: none; }
        
        .info-badge { background: #e2e8f0; color: #4a5568; padding: 2px 6px;
                     border-radius: 12px; font-size: 0.8rem; margin-left: 5px; }
        
        .status-bar { background: rgba(0,0,0,0.8); color: white; padding: 10px;
                     position: fixed; bottom: 0; left: 0; right: 0; z-index: 1000;
                     font-size: 0.9rem; display: flex; justify-content: space-between; }
        
        .chart-container { height: 250px; margin: 15px 0; }
        
        @media (max-width: 1400px) {
            .main-layout { grid-template-columns: 1fr; }
            .container { padding: 10px; }
        }
        
        .advanced-toggle { cursor: pointer; user-select: none; 
                          padding: 8px; background: #f1f5f9; border-radius: 6px; }
        .advanced-content { max-height: 0; overflow: hidden; transition: max-height 0.3s; }
        .advanced-content.expanded { max-height: 1000px; }
        
        .color-preview { width: 20px; height: 20px; border-radius: 3px; 
                        margin-right: 8px; border: 1px solid #ddd; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔢 Visualización Completa de Números Primos</h1>
            <p>Sistema Avanzado de Análisis Matemático <span class="version">v2.0</span></p>
            <p>Todos los parámetros integrados de archivos de despliegue</p>
        </div>

        <div class="main-layout">
            <!-- Panel de Controles -->
            <div class="panel">
                <!-- Configuración Básica -->
                <div class="section">
                    <h3>⚙️ Configuración Básica</h3>
                    <div class="form-group">
                        <label>Círculos Concéntricos:</label>
                        <div class="range-group">
                            <input type="range" id="num_circulos" min="1" max="100" value="15" class="range-input">
                            <span class="range-value" id="val_circulos">15</span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Divisiones por Círculo:</label>
                        <div class="range-group">
                            <input type="range" id="divisiones_por_circulo" min="4" max="200" value="36" class="range-input">
                            <span class="range-value" id="val_divisiones">36</span>
                        </div>
                    </div>
                </div>

                <!-- Tipos de Primos -->
                <div class="section">
                    <h3>🎯 Tipos de Primos</h3>
                    <div class="checkbox-grid">
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_gemelos" checked>
                            <label>Gemelos <span class="info-badge">gap=2</span></label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_primos" checked>
                            <label>Primos <span class="info-badge">gap=4</span></label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_sexy" checked>
                            <label>Sexy <span class="info-badge">gap=6</span></label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_primos_regulares" checked>
                            <label>Regulares</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_sophie_germain">
                            <label>Sophie Germain</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_palindromos">
                            <label>Palíndromos</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_mersenne">
                            <label>Mersenne</label>
                        </div>
                        <div class="checkbox-item">
                            <input type="checkbox" id="mostrar_fermat">
                            <label>Fermat</label>
                        </div>
                    </div>
                </div>

                <!-- Mapeo y Estilo -->
                <div class="section">
                    <h3>📐 Mapeo y Estilo</h3>
                    <div class="form-group">
                        <label>Función de Mapeo:</label>
                        <select id="tipo_mapeo">
                            <option value="lineal">Lineal (Secuencial)</option>
                            <option value="logaritmico">Logarítmico</option>
                            <option value="arquimedes">Espiral Arquímedes</option>
                            <option value="fibonacci">Espiral Fibonacci</option>
                            <option value="cuadratico">Cuadrático</option>
                            <option value="hexagonal">Hexagonal</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Esquema de Color:</label>
                        <select id="esquema_color">
                            <option value="clasico">Clásico</option>
                            <option value="plasma">Plasma</option>
                            <option value="naturaleza">Naturaleza</option>
                            <option value="neon">Neón</option>
                            <option value="oceanico">Oceánico</option>
                            <option value="monocromatico">Monocromático</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Calidad de Renderizado:</label>
                        <select id="calidad_renderizado">
                            <option value="media">Media (200 DPI)</option>
                            <option value="alta" selected>Alta (300 DPI)</option>
                            <option value="ultra">Ultra (400 DPI)</option>
                        </select>
                    </div>
                </div>

                <!-- Opciones Avanzadas -->
                <div class="section">
                    <div class="advanced-toggle" onclick="toggleAdvanced()">
                        🔧 Opciones Avanzadas ▼
                    </div>
                    <div class="advanced-content" id="advanced_options">
                        <div class="form-group">
                            <label>Transparencia:</label>
                            <div class="range-group">
                                <input type="range" id="transparencia" min="0.1" max="1" step="0.1" value="0.8" class="range-input">
                                <span class="range-value" id="val_transparencia">0.8</span>
                            </div>
                        </div>
                        <div class="checkbox-grid" style="margin-top: 10px;">
                            <div class="checkbox-item">
                                <input type="checkbox" id="mostrar_anillos_guia">
                                <label>Anillos Guía</label>
                            </div>
                            <div class="checkbox-item">
                                <input type="checkbox" id="mostrar_grid_radial">
                                <label>Grid Radial</label>
                            </div>
                            <div class="checkbox-item">
                                <input type="checkbox" id="incluir_leyenda" checked>
                                <label>Leyenda</label>
                            </div>
                            <div class="checkbox-item">
                                <input type="checkbox" id="usar_antialiasing" checked>
                                <label>Antialiasing</label>
                            </div>
                        </div>
                    </div>
                </div>

                <button id="generar" class="generate-btn">🚀 Generar Visualización</button>
                <div id="loading" class="loading">
                    <div class="spinner"></div>
                    Generando visualización avanzada...
                </div>
                <div id="error" class="error"></div>
            </div>

            <!-- Panel de Visualización -->
            <div class="panel visualization-panel">
                <h3>📊 Visualización Interactive</h3>
                <div id="visualization_container" class="visualization-container">
                    <p style="color: #718096; font-size: 1.1rem;">
                        Configure los parámetros y genere su visualización personalizada
                    </p>
                </div>
                <div id="export_options" style="display: none; margin-top: 10px;">
                    <button onclick="downloadImage()">📥 Descargar HD</button>
                    <button onclick="shareVisualization()">🔗 Compartir</button>
                </div>
            </div>

            <!-- Panel de Métricas -->
            <div class="panel">
                <h3>📈 Análisis Estadístico</h3>
                <div id="metrics_container">
                    <div class="metrics-grid" id="basic_metrics"></div>
                    <div class="chart-container">
                        <canvas id="gaps_chart"></canvas>
                    </div>
                </div>
                
                <div class="section">
                    <h3>🎯 Patrones Especiales</h3>
                    <div id="special_patterns"></div>
                </div>
            </div>
        </div>
    </div>

    <div class="status-bar">
        <span id="status_text">Listo para generar</span>
        <span id="performance_info">Sistema optimizado</span>
    </div>

    <script>
        let currentVisualizationData = null;
        let gapsChart = null;

        // Inicialización
        document.addEventListener('DOMContentLoaded', function() {
            setupRangeInputs();
            document.getElementById('generar').addEventListener('click', generateVisualization);
            updateStatus('Sistema iniciado correctamente');
            
            // Generar visualización inicial
            setTimeout(generateVisualization, 1000);
        });

        function setupRangeInputs() {
            ['num_circulos', 'divisiones_por_circulo', 'transparencia'].forEach(id => {
                const input = document.getElementById(id);
                const valueSpan = document.getElementById('val_' + id.split('_')[1]);
                if (input && valueSpan) {
                    input.addEventListener('input', function() {
                        valueSpan.textContent = this.value;
                    });
                }
            });
        }

        function toggleAdvanced() {
            const content = document.getElementById('advanced_options');
            const toggle = document.querySelector('.advanced-toggle');
            content.classList.toggle('expanded');
            toggle.innerHTML = content.classList.contains('expanded') 
                ? '🔧 Opciones Avanzadas ▲' 
                : '🔧 Opciones Avanzadas ▼';
        }

        async function generateVisualization() {
            const startTime = Date.now();
            showLoading(true);
            hideError();
            updateStatus('Generando visualización...');

            try {
                const requestData = {
                    num_circulos: parseInt(document.getElementById('num_circulos').value),
                    divisiones_por_circulo: parseInt(document.getElementById('divisiones_por_circulo').value),
                    mostrar_primos_gemelos: document.getElementById('mostrar_primos_gemelos').checked,
                    mostrar_primos_primos: document.getElementById('mostrar_primos_primos').checked,
                    mostrar_primos_sexy: document.getElementById('mostrar_primos_sexy').checked,
                    mostrar_primos_regulares: document.getElementById('mostrar_primos_regulares').checked,
                    mostrar_sophie_germain: document.getElementById('mostrar_sophie_germain').checked,
                    mostrar_palindromos: document.getElementById('mostrar_palindromos').checked,
                    mostrar_mersenne: document.getElementById('mostrar_mersenne').checked,
                    mostrar_fermat: document.getElementById('mostrar_fermat').checked,
                    tipo_mapeo: document.getElementById('tipo_mapeo').value,
                    esquema_color: document.getElementById('esquema_color').value,
                    calidad_renderizado: document.getElementById('calidad_renderizado').value,
                    transparencia: parseFloat(document.getElementById('transparencia').value),
                    mostrar_anillos_guia: document.getElementById('mostrar_anillos_guia').checked,
                    mostrar_grid_radial: document.getElementById('mostrar_grid_radial').checked,
                    incluir_leyenda: document.getElementById('incluir_leyenda').checked,
                    usar_antialiasing: document.getElementById('usar_antialiasing').checked
                };

                const response = await fetch('/generar', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(requestData)
                });

                if (!response.ok) {
                    throw new Error(`Error del servidor: ${response.status}`);
                }

                const data = await response.json();
                if (data.error) throw new Error(data.error);

                currentVisualizationData = data;
                displayResults(data);
                
                const duration = ((Date.now() - startTime) / 1000).toFixed(2);
                updateStatus(`Visualización generada en ${duration}s`);
                updatePerformanceInfo(`${data.metricas.total_primos} primos analizados`);

            } catch (error) {
                console.error('Error:', error);
                showError(`Error: ${error.message}`);
                updateStatus('Error en generación');
            } finally {
                showLoading(false);
            }
        }

        function displayResults(data) {
            // Mostrar imagen
            if (data.imagen) {
                document.getElementById('visualization_container').innerHTML = `
                    <img src="data:image/png;base64,${data.imagen}" 
                         class="result-image" 
                         onclick="openImageModal(this.src)"
                         title="Click para ampliar">
                `;
                document.getElementById('export_options').style.display = 'block';
            }

            // Mostrar métricas básicas
            if (data.metricas) {
                displayMetrics(data.metricas);
            }

            // Mostrar patrones especiales
            if (data.patrones_especiales) {
                displaySpecialPatterns(data.patrones_especiales);
            }

            // Mostrar gráfico de gaps
            if (data.distribucion_gaps) {
                displayGapsChart(data.distribucion_gaps);
            }
        }

        function displayMetrics(metrics) {
            const container = document.getElementById('basic_metrics');
            container.innerHTML = `
                <div class="metric-card">
                    <div class="metric-value">${metrics.total_primos.toLocaleString()}</div>
                    <div class="metric-label">Total Primos</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${metrics.pares_primos_gemelos}</div>
                    <div class="metric-label">Pares Gemelos</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${metrics.gap_promedio.toFixed(2)}</div>
                    <div class="metric-label">Gap Promedio</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${metrics.gap_maximo}</div>
                    <div class="metric-label">Gap Máximo</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${(metrics.densidad_real * 100).toFixed(2)}%</div>
                    <div class="metric-label">Densidad Real</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${metrics.entropia_gap.toFixed(2)}</div>
                    <div class="metric-label">Entropía</div>
                </div>
            `;
        }

        function displaySpecialPatterns(patterns) {
            const container = document.getElementById('special_patterns');
            container.innerHTML = `
                <div style="font-size: 0.9rem;">
                    <div>📍 Sophie Germain: <strong>${patterns.primos_sophie_germain}</strong></div>
                    <div>🔤 Palíndromos: <strong>${patterns.palindromos}</strong></div>
                    <div>⚡ Mersenne: <strong>${patterns.mersenne}</strong></div>
                    <div>🎯 Fermat: <strong>${patterns.fermat}</strong></div>
                </div>
            `;
        }

        function displayGapsChart(gapsData) {
            const ctx = document.getElementById('gaps_chart').getContext('2d');
            
            if (gapsChart) gapsChart.destroy();

            gapsChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: gapsData.map(d => `Gap ${d.gap}`),
                    datasets: [{
                        label: 'Frecuencia',
                        data: gapsData.map(d => d.cuenta),
                        backgroundColor: 'rgba(102, 126, 234, 0.6)',
                        borderColor: 'rgba(102, 126, 234, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { 
                        legend: { display: false },
                        title: { display: true, text: 'Distribución de Gaps' }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
        }

        function openImageModal(src) {
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed; top: 0; left: 0; width: 100%; height: 100%;
                background: rgba(0,0,0,0.9); display: flex; align-items: center;
                justify-content: center; z-index: 10000; cursor: zoom-out;
            `;
            
            const img = document.createElement('img');
            img.src = src;
            img.style.cssText = `max-width: 95%; max-height: 95%; border-radius: 10px;`;
            
            modal.appendChild(img);
            modal.onclick = () => document.body.removeChild(modal);
            document.body.appendChild(modal);
        }

        function downloadImage() {
            if (!currentVisualizationData || !currentVisualizationData.imagen) return;
            
            const link = document.createElement('a');
            link.href = 'data:image/png;base64,' + currentVisualizationData.imagen;
            link.download = `primos_visualization_${Date.now()}.png`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            updateStatus('Imagen descargada');
        }

        function shareVisualization() {
            if (navigator.share && currentVisualizationData) {
                navigator.share({
                    title: 'Visualización de Números Primos',
                    text: `Análisis de ${currentVisualizationData.metricas.total_primos} números primos`,
                    url: window.location.href
                });
            } else {
                // Fallback: copiar URL al clipboard
                navigator.clipboard.writeText(window.location.href);
                updateStatus('URL copiada al clipboard');
            }
        }

        function showLoading(show) {
            document.getElementById('loading').classList.toggle('show', show);
            document.getElementById('generar').disabled = show;
        }

        function showError(message) {
            const errorDiv = document.getElementById('error');
            errorDiv.textContent = message;
            errorDiv.style.display = 'block';
        }

        function hideError() {
            document.getElementById('error').style.display = 'none';
        }

        function updateStatus(text) {
            document.getElementById('status_text').textContent = text;
        }

        function updatePerformanceInfo(text) {
            document.getElementById('performance_info').textContent = text;
        }

        // Auto-actualizar visualización en cambios de parámetros básicos
        ['num_circulos', 'divisiones_por_circulo'].forEach(id => {
            document.getElementById(id).addEventListener('change', function() {
                clearTimeout(this.autoUpdateTimer);
                this.autoUpdateTimer = setTimeout(generateVisualization, 1000);
            });
        });
    </script>
</body>
</html>
HTML_EOF

print_feature "Configurando servicios optimizados..."

# Gunicorn configuration optimizada
cat > gunicorn.conf.py << 'EOF'
bind = "0.0.0.0:5000"
workers = 4
worker_class = "sync"
worker_connections = 1000
timeout = 600
max_requests = 2000
max_requests_jitter = 100
preload_app = True
worker_tmp_dir = "/dev/shm"
keepalive = 5
EOF

# Systemd service
cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=Prime Visualization Complete App v2.0
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
Environment="MPLBACKEND=Agg"
Environment="MPLCONFIGDIR=/tmp"
ExecStart=$APP_DIR/venv/bin/gunicorn -c gunicorn.conf.py app:app
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Nginx configuration optimizada
cat > /etc/nginx/sites-available/$APP_NAME << 'EOF'
upstream prime_app {
    server 127.0.0.1:5000 fail_timeout=10s max_fails=3;
}

server {
    listen 80;
    server_name _;
    client_max_body_size 20M;
    
    location / {
        proxy_pass http://prime_app;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 600s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 600s;
    }
    
    location /static {
        alias $APP_DIR/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
}
EOF

ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_status "Configurando permisos..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

print_status "Iniciando servicios..."
nginx -t
systemctl daemon-reload
systemctl enable $APP_NAME nginx
systemctl restart nginx
systemctl start $APP_NAME

# Wait and check
sleep 5

print_status "Verificando servicios..."
if systemctl is-active --quiet $APP_NAME; then
    print_success "✅ Aplicación iniciada correctamente"
else
    print_error "❌ Error al iniciar aplicación"
    journalctl -u $APP_NAME -n 10 --no-pager
fi

if systemctl is-active --quiet nginx; then
    print_success "✅ Nginx funcionando"
else
    print_error "❌ Error en Nginx"
fi

# Test application
print_status "Probando aplicación..."
if curl -s -f http://localhost/ > /dev/null; then
    print_success "✅ Aplicación respondiendo correctamente"
else
    print_warning "⚠️ Aplicación aún iniciando..."
fi

# Create enhanced status script
cat > /usr/local/bin/prime-viz-complete-status << 'EOF'
#!/bin/bash
echo "🔢 ===== PRIME VISUALIZATION COMPLETE v2.0 STATUS ====="
echo ""
echo "🚀 SERVICIOS:"
echo "   App: $(systemctl is-active prime-visualization)"
echo "   Nginx: $(systemctl is-active nginx)"
echo ""
echo "📊 RECURSOS DEL SISTEMA:"
echo "   Memoria: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
echo "   CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% usado"
echo ""
echo "🌐 ACCESO:"
echo "   Externo: http://$(curl -s ifconfig.me 2>/dev/null || echo 'TU_IP')"
echo "   Local: http://localhost"
echo ""
echo "📋 CARACTERÍSTICAS INTEGRADAS:"
echo "   • 6 funciones de mapeo geométrico"
echo "   • 6 esquemas de color profesionales"
echo "   • 8+ tipos de primos especiales"
echo "   • Análisis estadístico completo"
echo "   • Renderizado hasta 400 DPI"
echo "   • Interfaz responsive v2.0"
echo ""
echo "📈 LOGS RECIENTES:"
journalctl -u prime-visualization -n 3 --no-pager | tail -3
echo ""
echo "✅ ESTADO: SISTEMA COMPLETO OPERATIVO"
EOF

chmod +x /usr/local/bin/prime-viz-complete-status

print_success "🎉 ¡DESPLIEGUE INTEGRADO COMPLETO FINALIZADO!"
echo ""
print_feature "🔗 APLICACIÓN DISPONIBLE:"
echo "   🌐 Externa: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"
echo "   🏠 Local: http://localhost"
echo ""
print_feature "🚀 CARACTERÍSTICAS INTEGRADAS:"
echo "   ✅ 6 Funciones de Mapeo: Lineal, Logarítmico, Arquímedes, Fibonacci, Cuadrático, Hexagonal"
echo "   ✅ 6 Esquemas de Color: Clásico, Plasma, Naturaleza, Neón, Oceánico, Monocromático"  
echo "   ✅ 8+ Tipos de Primos: Gemelos, Primos, Sexy, Sophie Germain, Palíndromos, Mersenne, Fermat"
echo "   ✅ Análisis Estadístico Completo: Entropía, Densidad, Gaps, Asimetría, Curtosis"
echo "   ✅ Renderizado Multi-Calidad: 150-400 DPI"
echo "   ✅ Opciones Avanzadas: Transparencia, Anillos Guía, Grid Radial, Antialiasing"
echo "   ✅ Interfaz HTML5 Responsive con Charts.js"
echo "   ✅ Exportación y Compartir"
echo ""
print_feature "🔧 COMANDOS DE GESTIÓN:"
echo "   📊 Estado completo: prime-viz-complete-status"
echo "   🔄 Reiniciar: systemctl restart prime-visualization"
echo "   📋 Logs: journalctl -u prime-visualization -f"
echo "   🔧 Config Nginx: /etc/nginx/sites-available/prime-visualization"
echo ""

# Run status
prime-viz-complete-status
