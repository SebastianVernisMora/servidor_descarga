#!/usr/bin/env python3
"""
Aplicación de Visualización de Números Primos - Versión Optimizada v3.0
Mejoras implementadas:
- Cacheo inteligente de visualizaciones
- Endpoints asíncronos
- Compresión de imágenes optimizada
- Chat de IA integrado con BLACKBOX API
- Sistema de ayuda contextual
"""

import os
import sys
import asyncio
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from flask import Flask, render_template, request, jsonify, send_file, send_from_directory, make_response
import io
import base64
import json
from collections import defaultdict, Counter
import math
import traceback
from datetime import datetime, timedelta
import time
from matplotlib.patches import Wedge, Circle, Rectangle
from matplotlib.collections import PatchCollection
import matplotlib.patheffects as path_effects
from scipy import stats
import requests
import psutil
import hashlib
import gzip
from threading import Thread
import concurrent.futures
from functools import wraps
import pickle
import tempfile
import shutil
import gc

# Configurar matplotlib para mejor rendimiento
plt.ioff()
matplotlib.rcParams.update({
    'figure.max_open_warning': 0,
    'savefig.pad_inches': 0.1,
    'font.family': 'sans-serif',
    'axes.grid': False,
    'figure.facecolor': 'black',
    'savefig.facecolor': 'black'
})

app = Flask(__name__)
app.config.update({
    'JSON_AS_ASCII': False,
    'MAX_CONTENT_LENGTH': 50 * 1024 * 1024,  # 50MB max
    'SEND_FILE_MAX_AGE_DEFAULT': 3600,
    'CACHE_TYPE': 'simple',
    'CACHE_DEFAULT_TIMEOUT': 3600
})

# ===== SISTEMA DE CACHE EN DISCO OPTIMIZADO PARA MEMORIA =====
class DiskBasedCache:
    """Sistema de cache basado en disco para optimizar memoria RAM."""
    
    def __init__(self, cache_dir='cache', max_files=50, ttl=3600, max_file_size=50*1024*1024):
        self.cache_dir = cache_dir
        self.max_files = max_files
        self.ttl = ttl
        self.max_file_size = max_file_size
        self.hits = 0
        self.requests = 0
        
        # Crear directorio de cache
        os.makedirs(self.cache_dir, exist_ok=True)
        
        # Limpiar cache viejo al iniciar
        self._cleanup_expired_files()
        
    def get_key(self, params):
        """Generar clave única para parámetros."""
        sorted_params = sorted(params.items())
        key_str = json.dumps(sorted_params, sort_keys=True)
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def _get_file_path(self, key):
        """Obtener ruta del archivo de cache."""
        return os.path.join(self.cache_dir, f"{key}.cache")
    
    def _is_file_expired(self, file_path):
        """Verificar si un archivo de cache ha expirado."""
        try:
            if not os.path.exists(file_path):
                return True
            file_time = os.path.getmtime(file_path)
            return (time.time() - file_time) > self.ttl
        except:
            return True
    
    def _cleanup_expired_files(self):
        """Limpiar archivos expirados del cache."""
        try:
            for filename in os.listdir(self.cache_dir):
                if filename.endswith('.cache'):
                    file_path = os.path.join(self.cache_dir, filename)
                    if self._is_file_expired(file_path):
                        os.remove(file_path)
        except:
            pass
    
    def _enforce_max_files(self):
        """Mantener el número máximo de archivos en cache."""
        try:
            cache_files = [f for f in os.listdir(self.cache_dir) if f.endswith('.cache')]
            if len(cache_files) >= self.max_files:
                # Ordenar por tiempo de acceso (más viejo primero)
                file_times = []
                for filename in cache_files:
                    file_path = os.path.join(self.cache_dir, filename)
                    try:
                        mtime = os.path.getmtime(file_path)
                        file_times.append((mtime, file_path))
                    except:
                        continue
                
                file_times.sort()  # Más viejo primero
                files_to_remove = len(file_times) - self.max_files + 5  # Remover 5 extra
                
                for i in range(min(files_to_remove, len(file_times))):
                    try:
                        os.remove(file_times[i][1])
                    except:
                        continue
        except:
            pass
    
    def get(self, params):
        """Obtener visualización del cache en disco."""
        self.requests += 1
        key = self.get_key(params)
        file_path = self._get_file_path(key)
        
        try:
            if not self._is_file_expired(file_path):
                # Cargar desde disco
                with open(file_path, 'rb') as f:
                    data = pickle.load(f)
                
                # Actualizar tiempo de acceso
                os.utime(file_path, None)
                self.hits += 1
                return data
        except:
            pass
        
        return None
    
    def set(self, params, data):
        """Guardar visualización en cache de disco."""
        try:
            key = self.get_key(params)
            file_path = self._get_file_path(key)
            
            # Verificar tamaño antes de guardar
            temp_buffer = io.BytesIO()
            pickle.dump(data, temp_buffer)
            data_size = temp_buffer.tell()
            
            if data_size > self.max_file_size:
                print(f"Cache: Archivo muy grande ({data_size} bytes), no guardado")
                return
            
            # Guardar en archivo temporal primero
            temp_path = file_path + '.tmp'
            with open(temp_path, 'wb') as f:
                temp_buffer.seek(0)
                shutil.copyfileobj(temp_buffer, f)
            
            # Mover archivo temporal al definitivo (operación atómica)
            shutil.move(temp_path, file_path)
            
            # Liberar memoria del buffer
            temp_buffer.close()
            del temp_buffer
            
            # Limpiar archivos viejos
            self._enforce_max_files()
            
        except Exception as e:
            print(f"Cache: Error guardando {key}: {e}")
    
    def clear(self):
        """Limpiar todo el cache."""
        try:
            shutil.rmtree(self.cache_dir)
            os.makedirs(self.cache_dir, exist_ok=True)
            self.hits = 0
            self.requests = 0
        except Exception as e:
            print(f"Cache: Error limpiando: {e}")
    
    def stats(self):
        """Estadísticas del cache."""
        try:
            cache_files = [f for f in os.listdir(self.cache_dir) if f.endswith('.cache')]
            total_size = sum(os.path.getsize(os.path.join(self.cache_dir, f)) 
                           for f in cache_files if os.path.exists(os.path.join(self.cache_dir, f)))
            
            return {
                'entries': len(cache_files),
                'max_files': self.max_files,
                'total_size_mb': round(total_size / (1024*1024), 2),
                'hit_ratio': self.hits / max(self.requests, 1),
                'hits': self.hits,
                'requests': self.requests,
                'storage_type': 'disk'
            }
        except:
            return {
                'entries': 0,
                'max_files': self.max_files,
                'total_size_mb': 0,
                'hit_ratio': 0,
                'hits': self.hits,
                'requests': self.requests,
                'storage_type': 'disk'
            }

# Instancia global del cache en disco
cache = DiskBasedCache(cache_dir='cache_primes', max_files=30, ttl=7200)  # 2 horas TTL

# ===== CLIENTE API BLACKBOX =====
class BlackboxClient:
    """Cliente para API de BLACKBOX."""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.getenv('BLACKBOX_API_KEY')
        self.base_url = "https://api.blackbox.ai/chat/completions"
        self.session = requests.Session()
        
    def analyze_visualization_data(self, metrics, patterns, params):
        """Analizar datos de visualización con IA."""
        if not self.api_key:
            return {"error": "API key no configurada"}
        
        system_prompt = """Eres un experto en teoría de números y análisis de patrones matemáticos. 
        Analiza los datos de visualización de números primos y proporciona insights profundos sobre:
        1. Patrones únicos encontrados
        2. Predicciones sobre distribución
        3. Recomendaciones de parámetros
        4. Interpretación matemática
        """
        
        user_message = f"""
        Analiza esta visualización de números primos:
        
        Parámetros: {json.dumps(params, indent=2)}
        
        Métricas:
        - Total primos: {metrics.get('total_primos', 0)}
        - Densidad: {metrics.get('densidad_real', 0):.4f}
        - Gap promedio: {metrics.get('gap_promedio', 0):.2f}
        - Entropía: {metrics.get('entropia_gap', 0):.4f}
        
        Patrones especiales:
        - Primos gemelos: {patterns.get('primos_gemelos', 0)}
        - Sophie Germain: {patterns.get('primos_sophie_germain', 0)}
        - Mersenne: {patterns.get('mersenne', 0)}
        
        Por favor proporciona un análisis detallado y sugerencias de optimización.
        """
        
        try:
            response = self.session.post(
                self.base_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "blackbox",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_message}
                    ],
                    "max_tokens": 1000,
                    "temperature": 0.7
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return {"error": f"API error: {response.status_code}"}
                
        except Exception as e:
            return {"error": f"Request failed: {str(e)}"}
    
    def chat(self, message, context=None):
        """Chat general con contexto."""
        if not self.api_key:
            return {"error": "API key no configurada"}
        
        messages = [
            {"role": "system", "content": "Eres un asistente experto en matemáticas y visualización de datos."}
        ]
        
        if context:
            messages.append({"role": "system", "content": f"Contexto: {context}"})
        
        messages.append({"role": "user", "content": message})
        
        try:
            response = self.session.post(
                self.base_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "blackbox",
                    "messages": messages,
                    "max_tokens": 500,
                    "temperature": 0.7
                },
                timeout=20
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return {"error": f"API error: {response.status_code}"}
                
        except Exception as e:
            return {"error": f"Request failed: {str(e)}"}

# Instancia global del cliente
blackbox_client = BlackboxClient()

# ===== FUNCIONES MATEMÁTICAS OPTIMIZADAS =====

def criba_de_eratostenes_optimizada(limite):
    """Criba de Eratóstenes optimizada para memoria - sin cache LRU."""
    if limite < 2: return tuple()
    if limite == 2: return (2,)
    
    # Cache manual simple en disco para rangos grandes
    cache_key = f"primes_{limite}"
    cache_file = f"cache_primes/primes_{limite}.pkl"
    
    # Intentar cargar desde disco
    try:
        if os.path.exists(cache_file):
            with open(cache_file, 'rb') as f:
                return pickle.load(f)
    except:
        pass
    
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
    
    result = tuple(i for i in range(2, limite + 1) if es_primo[i])
    
    # Guardar en disco solo para rangos grandes (>10000)
    if limite > 10000:
        try:
            os.makedirs('cache_primes', exist_ok=True)
            with open(cache_file, 'wb') as f:
                pickle.dump(result, f)
        except:
            pass
    
    # Limpiar memoria explícitamente
    del es_primo
    gc.collect()
    
    return result

def encontrar_todos_los_patrones_primos(primos):
    """Análisis exhaustivo optimizado de patrones de primos."""
    if not primos or len(primos) < 2:
        return {}
    
    patrones = {
        'primos_gemelos': [],
        'primos_primos': [],
        'primos_sexy': [],
        'primos_sophie_germain': [],
        'gaps_primos': defaultdict(int),
        'distribucion_gaps': [],
        'palindromos': [],
        'mersenne': [],
        'fermat': []
    }
    
    conjunto_primos = set(primos)
    
    # Análisis de gaps en paralelo
    for i, p in enumerate(primos[:-1]):
        gap = primos[i+1] - p
        patrones['distribucion_gaps'].append(gap)
        patrones['gaps_primos'][gap] += 1
        
        # Verificaciones paralelas
        if p + 2 in conjunto_primos:
            patrones['primos_gemelos'].append((p, p + 2))
        if p + 4 in conjunto_primos:
            patrones['primos_primos'].append((p, p + 4))
        if p + 6 in conjunto_primos:
            patrones['primos_sexy'].append((p, p + 6))
        if 2*p + 1 in conjunto_primos:
            patrones['primos_sophie_germain'].append((p, 2*p + 1))
        if str(p) == str(p)[::-1] and len(str(p)) > 1:
            patrones['palindromos'].append(p)
    
    # Mersenne y Fermat optimizados
    max_primo = max(primos)
    for n in range(2, 25):
        mersenne = 2**n - 1
        if mersenne <= max_primo and mersenne in conjunto_primos:
            patrones['mersenne'].append(mersenne)
    
    for n in range(5):
        fermat = 2**(2**n) + 1
        if fermat <= max_primo and fermat in conjunto_primos:
            patrones['fermat'].append(fermat)
    
    return patrones

def calcular_metricas_completas(primos, patrones):
    """Calcular métricas estadísticas optimizadas."""
    if not primos or len(primos) < 2:
        return inicializar_metricas_vacias()
    
    gaps = patrones.get('distribucion_gaps', [])
    gap_counts = Counter(gaps) if gaps else Counter()
    
    # Cálculos vectorizados con numpy
    gaps_array = np.array(gaps) if gaps else np.array([])
    
    # Entropía de Shannon optimizada
    entropia = 0
    if len(gaps) > 0:
        total_gaps = len(gaps)
        for count in gap_counts.values():
            p = count / total_gaps
            if p > 0: 
                entropia -= p * math.log2(p)
    
    # Estadísticas básicas
    gap_mean = float(np.mean(gaps_array)) if len(gaps_array) > 0 else 0
    gap_std = float(np.std(gaps_array)) if len(gaps_array) > 0 else 0
    
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
        'gap_mediana': float(np.median(gaps_array)) if len(gaps_array) > 0 else 0,
        'gap_moda': int(gap_counts.most_common(1)[0][0]) if gap_counts else 0,
        'desviacion_gap': float(gap_std),
        'varianza_gap': float(np.var(gaps_array)) if len(gaps_array) > 0 else 0,
        'coeficiente_variacion': float(gap_std / gap_mean) if gap_mean > 0 else 0,
        'entropia_gap': float(entropia),
        'asimetria_gap': float(stats.skew(gaps_array)) if len(gaps_array) > 3 else 0,
        'curtosis_gap': float(stats.kurtosis(gaps_array)) if len(gaps_array) > 3 else 0,
        'densidad_real': float(densidad_real),
        'densidad_teorica': float(densidad_teorica),
        'ratio_densidades': float(densidad_real / densidad_teorica) if densidad_teorica > 0 else 0,
        'densidad_primos_gemelos': float(len(patrones.get('primos_gemelos', [])) / len(primos)),
        'densidad_primos_especiales': float((len(patrones.get('primos_gemelos', [])) + 
                                           len(patrones.get('primos_primos', [])) + 
                                           len(patrones.get('primos_sexy', []))) / len(primos)),
        'timestamp': datetime.now().isoformat()
    }

def inicializar_metricas_vacias():
    """Métricas iniciales cuando no hay datos suficientes."""
    return {k: 0 if k != 'timestamp' else datetime.now().isoformat() 
            for k in ['total_primos', 'primo_maximo', 'primo_minimo', 'rango_total',
                     'pares_primos_gemelos', 'pares_primos_primos', 'pares_primos_sexy',
                     'gap_promedio', 'gap_maximo', 'gap_minimo', 'desviacion_gap', 
                     'entropia_gap', 'densidad_real', 'timestamp']}

# ===== FUNCIONES DE MAPEO GEOMÉTRICO (MISMAS) =====

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
    q = int(math.sqrt(n))
    r = n - q * q
    circulo = min(q % num_circulos, num_circulos - 1)
    segmento = (r * divisiones) // (2 * q + 1) if q > 0 else 0
    return circulo, segmento % divisiones

# ===== ESQUEMAS DE COLOR =====

def obtener_esquemas_color():
    """Todos los esquemas de color disponibles."""
    return {
        'clasico': {
            'primo_gemelo': '#FF0000', 'primo_primo': '#FF8C00', 'primo_sexy': '#FF1493',
            'primo_sophie': '#9400D3', 'primo_palindromo': '#FFD700', 'primo_mersenne': '#00FFFF',
            'primo_fermat': '#ADFF2F', 'primo_regular': '#0000FF', 'primo_multiple': '#FFFFFF',
            'compuesto': '#808080', 'fondo': '#000000'
        },
        'plasma': {
            'primo_gemelo': '#F0F921', 'primo_primo': '#FD9467', 'primo_sexy': '#E16462',
            'primo_sophie': '#B12A90', 'primo_palindromo': '#6A00A8', 'primo_mersenne': '#2D115F',
            'primo_fermat': '#0D0887', 'primo_regular': '#440154', 'primo_multiple': '#FFFFFF',
            'compuesto': '#482777', 'fondo': '#0D0887'
        },
        'naturaleza': {
            'primo_gemelo': '#FF6B6B', 'primo_primo': '#4ECDC4', 'primo_sexy': '#45B7D1',
            'primo_sophie': '#96CEB4', 'primo_palindromo': '#FFEAA7', 'primo_mersenne': '#DDA0DD',
            'primo_fermat': '#98D8C8', 'primo_regular': '#74B9FF', 'primo_multiple': '#F39C12',
            'compuesto': '#DCDCDC', 'fondo': '#2D3436'
        },
        'neon': {
            'primo_gemelo': '#FF073A', 'primo_primo': '#FF8C42', 'primo_sexy': '#FFF700',
            'primo_sophie': '#39FF14', 'primo_palindromo': '#00FFFF', 'primo_mersenne': '#BF00FF',
            'primo_fermat': '#FF1493', 'primo_regular': '#0080FF', 'primo_multiple': '#FFD700',
            'compuesto': '#404040', 'fondo': '#000000'
        },
        'oceanico': {
            'primo_gemelo': '#FF6B9D', 'primo_primo': '#C44569', 'primo_sexy': '#F8B500',
            'primo_sophie': '#6A0572', 'primo_palindromo': '#AB83A1', 'primo_mersenne': '#1B9AAA',
            'primo_fermat': '#06FFA5', 'primo_regular': '#4D96FF', 'primo_multiple': '#E74C3C',
            'compuesto': '#9BADB7', 'fondo': '#2C3A47'
        },
        'monocromatico': {
            'primo_gemelo': '#FFFFFF', 'primo_primo': '#E0E0E0', 'primo_sexy': '#C0C0C0',
            'primo_sophie': '#A0A0A0', 'primo_palindromo': '#808080', 'primo_mersenne': '#606060',
            'primo_fermat': '#404040', 'primo_regular': '#303030', 'primo_multiple': '#FF0000',
            'compuesto': '#202020', 'fondo': '#000000'
        }
    }

# ===== FUNCIÓN DE VISUALIZACIÓN OPTIMIZADA =====

def comprimir_imagen(datos_img, nivel_compresion=6):
    """Comprimir imagen base64 con gzip."""
    try:
        img_bytes = base64.b64decode(datos_img)
        compressed = gzip.compress(img_bytes, compresslevel=nivel_compresion)
        return base64.b64encode(compressed).decode('utf-8'), True
    except:
        return datos_img, False

def generar_visualizacion_completa(
    num_circulos=10000, divisiones_por_circulo=1300,
    mostrar_primos_gemelos=True, mostrar_primos_primos=True, mostrar_primos_sexy=True,
    mostrar_primos_regulares=True, mostrar_sophie_germain=True, mostrar_palindromos=False,
    mostrar_mersenne=False, mostrar_fermat=False,
    tipo_mapeo='lineal', esquema_color='clasico', calidad_renderizado='alta',
    mostrar_anillos_guia=False, mostrar_numeros=False, mostrar_grid_radial=False,
    transparencia=0.8, grosor_borde=0.1, incluir_leyenda=True, incluir_estadisticas=True,
    formato_exportacion='png', optimizar_memoria=True, usar_antialiasing=True,
    usar_cache=True, comprimir_salida=True
):
    """Función principal de visualización OPTIMIZADA con cache."""
    
    # Preparar parámetros para cache
    parametros_cache = {
        'num_circulos': num_circulos, 'divisiones_por_circulo': divisiones_por_circulo,
        'mostrar_primos_gemelos': mostrar_primos_gemelos, 'mostrar_primos_primos': mostrar_primos_primos,
        'mostrar_primos_sexy': mostrar_primos_sexy, 'mostrar_primos_regulares': mostrar_primos_regulares,
        'mostrar_sophie_germain': mostrar_sophie_germain, 'mostrar_palindromos': mostrar_palindromos,
        'mostrar_mersenne': mostrar_mersenne, 'mostrar_fermat': mostrar_fermat,
        'tipo_mapeo': tipo_mapeo, 'esquema_color': esquema_color, 'calidad_renderizado': calidad_renderizado,
        'mostrar_anillos_guia': mostrar_anillos_guia, 'mostrar_grid_radial': mostrar_grid_radial,
        'transparencia': transparencia, 'grosor_borde': grosor_borde, 'incluir_leyenda': incluir_leyenda,
        'formato_exportacion': formato_exportacion, 'usar_antialiasing': usar_antialiasing
    }
    
    # Intentar obtener del cache
    if usar_cache:
        cached_result = cache.get(parametros_cache)
        if cached_result:
            cache.hits = getattr(cache, 'hits', 0) + 1
            return cached_result
    
    cache.requests = getattr(cache, 'requests', 0) + 1
    
    try:
        # Limpiar matplotlib
        plt.clf()
        plt.close('all')
        
        # Validar y ajustar parámetros
        num_circulos = max(1, min(num_circulos, 10000))
        divisiones_por_circulo = max(2, min(divisiones_por_circulo, 1300))
        transparencia = max(0.1, min(transparencia, 1.0))
        
        segmentos_totales = num_circulos * divisiones_por_circulo
        
        # Generar primos y patrones (con cache)
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
        
        # Configurar calidad - Optimizado para zoom extremo 500x+
        config_calidad = {
            'baja': {'dpi': 200, 'tamano': (15, 15), 'linewidth': 0.3, 'markersize': 1.0},
            'media': {'dpi': 400, 'tamano': (20, 20), 'linewidth': 0.25, 'markersize': 1.2},
            'alta': {'dpi': 600, 'tamano': (30, 30), 'linewidth': 0.2, 'markersize': 1.5},
            'ultra': {'dpi': 800, 'tamano': (40, 40), 'linewidth': 0.15, 'markersize': 2.0},
            'extremo': {'dpi': 1200, 'tamano': (60, 60), 'linewidth': 0.1, 'markersize': 3.0}
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
        
        # Encontrar primos que pertenecen a múltiples categorías
        primos_multiples = {}
        for numero in conjunto_primos:
            categorias = []
            if numero in conjuntos_especiales['gemelos']:
                categorias.append('gemelos')
            if numero in conjuntos_especiales['primos']:
                categorias.append('primos')
            if numero in conjuntos_especiales['sexy']:
                categorias.append('sexy')
            if numero in conjuntos_especiales['sophie']:
                categorias.append('sophie')
            if numero in conjuntos_especiales['palindromos']:
                categorias.append('palindromos')
            if numero in conjuntos_especiales['mersenne']:
                categorias.append('mersenne')
            if numero in conjuntos_especiales['fermat']:
                categorias.append('fermat')
            
            if len(categorias) > 1:
                primos_multiples[numero] = categorias
        
        # ===== RENDERIZADO ULTRA-OPTIMIZADO CON NUMPY =====
        
        # Pre-calcular arrays con numpy para máximo rendimiento
        indices = np.arange(1, segmentos_totales + 1)
        
        # Mapeo vectorizado masivo
        if tipo_mapeo == 'lineal':
            circulos = np.minimum((indices - 1) // divisiones_por_circulo, num_circulos - 1)
            segmentos = (indices - 1) % divisiones_por_circulo
        else:
            # Fallback para mapeos complejos
            mapeo_results = np.array([func_mapeo(n, segmentos_totales, num_circulos, divisiones_por_circulo) 
                                     for n in indices])
            circulos = np.minimum(mapeo_results[:, 0], num_circulos - 1)
            segmentos = mapeo_results[:, 1]
        
        # Filtrar por círculo válido
        mask_valido = circulos < num_circulos
        indices = indices[mask_valido]
        circulos = circulos[mask_valido]
        segmentos = segmentos[mask_valido]
        
        # Pre-calcular parámetros geométricos - Ajustados para alta definición
        angulo_por_segmento = 360.0 / divisiones_por_circulo
        radio_base = 1.0  # Incrementado para mejor separación
        ancho_anillo = 0.95  # Optimizado para zoom extremo
        
        # Factor de escala para zoom extremo
        zoom_factor = min(2.0, max(1.0, segmentos_totales / 10000))
        
        radios_internos = radio_base + circulos * ancho_anillo
        radios_externos = radios_internos + ancho_anillo
        thetas1 = segmentos * angulo_por_segmento
        thetas2 = (segmentos + 1) * angulo_por_segmento
        
        # Vectorizar determinación de colores
        es_primo = np.isin(indices, list(conjunto_primos))
        colores_finales = np.full(len(indices), colores['compuesto'], dtype=object)
        
        # Aplicar colores con prioridad a primos múltiples
        # Primero marcar primos múltiples con color especial
        mask_multiples = np.isin(indices, list(primos_multiples.keys()))
        colores_finales[mask_multiples] = colores['primo_multiple']
        
        # Aplicar colores de primos especiales (excepto múltiples)
        if mostrar_mersenne and conjuntos_especiales['mersenne']:
            mask = np.isin(indices, list(conjuntos_especiales['mersenne'])) & ~mask_multiples
            colores_finales[mask] = colores['primo_mersenne']
        
        if mostrar_fermat and conjuntos_especiales['fermat']:
            mask = np.isin(indices, list(conjuntos_especiales['fermat'])) & ~mask_multiples
            colores_finales[mask] = colores['primo_fermat']
            
        if mostrar_primos_gemelos and conjuntos_especiales['gemelos']:
            mask = np.isin(indices, list(conjuntos_especiales['gemelos'])) & ~mask_multiples
            colores_finales[mask] = colores['primo_gemelo']
            
        if mostrar_sophie_germain and conjuntos_especiales['sophie']:
            mask = np.isin(indices, list(conjuntos_especiales['sophie'])) & ~mask_multiples
            colores_finales[mask] = colores['primo_sophie']
            
        if mostrar_palindromos and conjuntos_especiales['palindromos']:
            mask = np.isin(indices, list(conjuntos_especiales['palindromos'])) & es_primo & ~mask_multiples
            colores_finales[mask] = colores['primo_palindromo']
            
        if mostrar_primos_primos and conjuntos_especiales['primos']:
            mask = np.isin(indices, list(conjuntos_especiales['primos'])) & es_primo & ~mask_multiples
            colores_finales[mask] = colores['primo_primo']
            
        if mostrar_primos_sexy and conjuntos_especiales['sexy']:
            mask = np.isin(indices, list(conjuntos_especiales['sexy'])) & es_primo & ~mask_multiples
            colores_finales[mask] = colores['primo_sexy']
            
        if mostrar_primos_regulares:
            # Primos regulares para los que no tienen color asignado aún
            mask_regular = es_primo & (colores_finales == colores['compuesto']) & ~mask_multiples
            colores_finales[mask_regular] = colores['primo_regular']
        
        # Crear wedges optimizados para zoom extremo
        wedges = []
        edge_colors = []
        linewidths = []
        
        for i in range(len(indices)):
            # Ajustar grosor de borde según el zoom y posición
            borde_ajustado = max(config['linewidth'], grosor_borde * zoom_factor)
            
            # Color de borde más contrastante para primos múltiples
            if indices[i] in primos_multiples:
                edge_color = '#000000'  # Negro para máximo contraste
                borde_ajustado *= 2  # Borde más grueso
            else:
                edge_color = 'white'
            
            wedge = Wedge(center=(0, 0), r=radios_externos[i], width=ancho_anillo,
                         theta1=thetas1[i], theta2=thetas2[i], alpha=transparencia)
            wedges.append(wedge)
            edge_colors.append(edge_color)
            linewidths.append(borde_ajustado)
        
        colores_wedges = list(colores_finales)
        
        # Renderizar colección con bordes variables
        collection = PatchCollection(wedges, facecolors=colores_wedges,
                                   edgecolors=edge_colors, linewidths=linewidths,
                                   antialiased=True)  # Siempre antialiasing para zoom
        ax.add_collection(collection)
        
        # Añadir marcadores adicionales para primos múltiples (visibles en zoom)
        if len(primos_multiples) > 0:
            for numero, categorias in primos_multiples.items():
                if numero <= segmentos_totales:
                    # Calcular posición del marcador
                    if tipo_mapeo == 'lineal':
                        circulo = min((numero - 1) // divisiones_por_circulo, num_circulos - 1)
                        segmento = (numero - 1) % divisiones_por_circulo
                    else:
                        circulo, segmento = func_mapeo(numero, segmentos_totales, num_circulos, divisiones_por_circulo)
                        circulo = min(circulo, num_circulos - 1)
                    
                    if circulo < num_circulos:
                        radio = radio_base + circulo * ancho_anillo + ancho_anillo/2
                        angulo = (segmento + 0.5) * angulo_por_segmento
                        x = radio * np.cos(np.radians(angulo))
                        y = radio * np.sin(np.radians(angulo))
                        
                        # Añadir estrella pequeña para indicar múltiples categorías
                        ax.scatter(x, y, marker='*', s=config['markersize']*20, 
                                  c='black', alpha=0.8, zorder=10)
        
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
            f"Visualización Avanzada de Números Primos v3.0 ({tipo_mapeo.title()})",
            f"Círculos: {num_circulos} | Segmentos: {divisiones_por_circulo} | Total: {segmentos_totales:,}",
            f"Primos: {metricas['total_primos']:,} | Densidad: {metricas['densidad_real']:.3f} | Cache: {'✓' if usar_cache else '✗'}"
        ]
        
        ax.text(0, limite - 0.2, '\n'.join(titulo_lineas),
                ha='center', va='top', color='white', fontsize=12,
                fontweight='bold', 
                bbox=dict(boxstyle='round,pad=0.5', facecolor='black', alpha=0.7))
        
        # Leyenda optimizada
        if incluir_leyenda:
            elementos_leyenda = []
            if mostrar_primos_gemelos and len(conjuntos_especiales['gemelos']) > 0:
                elementos_leyenda.append(plt.Line2D([0], [0], marker='o', color='w',
                                                   markerfacecolor=colores['primo_gemelo'],
                                                   markersize=10, label=f'Gemelos ({len(conjuntos_especiales["gemelos"])})'))
            if mostrar_mersenne and len(conjuntos_especiales['mersenne']) > 0:
                elementos_leyenda.append(plt.Line2D([0], [0], marker='o', color='w',
                                                   markerfacecolor=colores['primo_mersenne'],
                                                   markersize=10, label=f'Mersenne ({len(conjuntos_especiales["mersenne"])})'))
            if mostrar_sophie_germain and len(conjuntos_especiales['sophie']) > 0:
                elementos_leyenda.append(plt.Line2D([0], [0], marker='o', color='w',
                                                   markerfacecolor=colores['primo_sophie'],
                                                   markersize=10, label=f'S.Germain ({len(conjuntos_especiales["sophie"])})'))
            
            if elementos_leyenda:
                legend = ax.legend(handles=elementos_leyenda[:6], loc='upper left',
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
                   edgecolor='none', pad_inches=0.1, transparent=False)
        
        buffer_img.seek(0)
        datos_img = base64.b64encode(buffer_img.read()).decode('utf-8')
        
        # Comprimir imagen si está habilitado
        compressed = False
        if comprimir_salida:
            datos_img, compressed = comprimir_imagen(datos_img)
        
        # Limpiar memoria agresivamente
        plt.close(fig)
        buffer_img.close()
        
        if optimizar_memoria:
            plt.clf()
            plt.close('all')
            # Limpiar variables grandes
            del wedges, colores_finales, indices, circulos, segmentos
            del primos, conjunto_primos
            if 'patrones_cache' in locals():
                del patrones_cache
            gc.collect()
        
        # Preparar resultado
        resultado = (datos_img, metricas, patrones, compressed)
        
        # Guardar en cache de disco
        if usar_cache:
            cache.set(parametros_cache, resultado)
            # Forzar liberación de memoria tras guardar en cache
            gc.collect()
        
        return resultado
        
    except Exception as e:
        plt.close('all')
        # Limpiar memoria en caso de error
        gc.collect()
        print(f"Error en visualización: {str(e)}")
        traceback.print_exc()
        raise e

# ===== RUTAS FLASK OPTIMIZADAS =====

@app.route('/')
def index():
    """Página principal - interfaz dinámica con selector de parámetros."""
    return send_from_directory('.', 'index_dynamic.html')

@app.route('/login.html')
def login():
    """Página de login."""
    return send_from_directory('.', 'login.html')

@app.route('/index_enhanced.html')
def main_app():
    """Aplicación principal (requiere autenticación en frontend)."""
    return send_from_directory('.', 'index_enhanced.html')

@app.route('/index_interactive.html')
def interactive_map():
    """Nueva interfaz de mapa interactivo HTML."""
    return send_from_directory('.', 'index_interactive.html')

@app.route('/index_prime_map.html')
def prime_map():
    """Mapa interactivo avanzado con matemáticas detalladas."""
    return send_from_directory('.', 'index_prime_map.html')

@app.route('/enhanced')
def enhanced_interactive():
    """Nueva interfaz HTML mejorada con API responsiva."""
    return send_from_directory('.', 'index_interactive_enhanced.html')

@app.route('/index_interactive_enhanced.html')
def enhanced_interactive_direct():
    """Acceso directo a la interfaz mejorada."""
    return send_from_directory('.', 'index_interactive_enhanced.html')

@app.route('/classic')
def classic_view():
    """Vista clásica con imágenes renderizadas."""
    return send_from_directory('.', 'index_fixed.html')

@app.route('/api/info')
def api_info():
    """Información de la API y sistema mejorada."""
    return jsonify({
        'version': '3.1.0',
        'features': [
            'Cache inteligente en DISCO (RAM optimizada)',
            'Compresión optimizada de imágenes',
            'Chat de IA con BLACKBOX integrado',
            'Sistema de ayuda contextual',
            'Análisis predictivo de patrones',
            'Endpoints asíncronos',
            'Múltiples mapeos geométricos',
            'Esquemas de color avanzados',
            'Gestión agresiva de memoria',
            'Recolección automática de basura'
        ],
        'mapeos_disponibles': ['lineal', 'logaritmico', 'arquimedes', 'fibonacci', 'cuadratico', 'hexagonal'],
        'esquemas_color': list(obtener_esquemas_color().keys()),
        'cache_stats': cache.stats(),
        'blackbox_status': 'configurado' if blackbox_client.api_key else 'no configurado',
        'memoria_proceso': dict(psutil.Process().memory_info()._asdict()),
        'memoria_sistema': dict(psutil.virtual_memory()._asdict()),
        'optimizaciones': {
            'cache_tipo': 'disco',
            'lru_cache_removido': True,
            'gc_automatico': True,
            'matplotlib_cleanup': True
        },
        'timestamp': datetime.now().isoformat()
    })

# ===== FUNCIÓN PARA GENERAR NOMBRES DE ARCHIVO PARAMÉTRICOS =====

def generar_nombre_archivo_parametrico(parametros):
    """Genera un nombre de archivo descriptivo basado en los parámetros de análisis."""
    from datetime import datetime
    
    # Timestamp actual
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    
    # Componentes básicos
    circulos = f"{parametros['num_circulos']}c"
    segmentos = f"{parametros['divisiones_por_circulo']}s"
    mapeo = parametros['tipo_mapeo']
    esquema = parametros['esquema_color']
    
    # Determinar tipos de primos habilitados
    tipos_habilitados = []
    if parametros.get('mostrar_primos_gemelos', False):
        tipos_habilitados.append('gemelos')
    if parametros.get('mostrar_sophie_germain', False):
        tipos_habilitados.append('sophie')
    if parametros.get('mostrar_mersenne', False):
        tipos_habilitados.append('mersenne')
    if parametros.get('mostrar_fermat', False):
        tipos_habilitados.append('fermat')
    if parametros.get('mostrar_palindromos', False):
        tipos_habilitados.append('palindromos')
    if parametros.get('mostrar_primos_primos', False):
        tipos_habilitados.append('primos')
    if parametros.get('mostrar_primos_sexy', False):
        tipos_habilitados.append('sexy')
    if parametros.get('mostrar_primos_regulares', True):
        tipos_habilitados.append('regulares')
    
    # Si no hay tipos específicos, usar "todos"
    tipos_str = "-".join(tipos_habilitados[:4]) if tipos_habilitados else "todos"  # Limitar longitud
    
    # Construir nombre final
    nombre_archivo = f"primos_{circulos}_{segmentos}_{mapeo}_{esquema}_{tipos_str}_{timestamp}.png"
    
    # Limpiar caracteres problemáticos
    nombre_archivo = nombre_archivo.replace(' ', '_').replace('/', '-').replace('\\', '-')
    
    return nombre_archivo

@app.route('/descargar-imagen', methods=['POST'])
def descargar_imagen():
    """Endpoint para descargar imagen con nombre paramétrico."""
    try:
        datos = request.get_json()
        if not datos:
            return jsonify({'error': 'No se recibieron datos JSON'}), 400
        
        # Extraer parámetros (mismos que el endpoint /generar)
        parametros = {
            'num_circulos': int(datos.get('num_circulos', 10000)),
            'divisiones_por_circulo': int(datos.get('divisiones_por_circulo', 1300)),
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
            'usar_antialiasing': bool(datos.get('usar_antialiasing', True)),
            'usar_cache': bool(datos.get('usar_cache', True)),
            'comprimir_salida': bool(datos.get('comprimir_salida', False))  # No comprimir para descarga
        }
        
        # Generar imagen
        inicio = time.time()
        datos_img, metricas, patrones, compressed = generar_visualizacion_completa(**parametros)
        tiempo_generacion = time.time() - inicio
        
        # Generar nombre paramétrico
        nombre_archivo = generar_nombre_archivo_parametrico(parametros)
        
        # Decodificar imagen base64
        try:
            if compressed:
                # Si está comprimida, descomprimir primero
                img_compressed = base64.b64decode(datos_img)
                img_bytes = gzip.decompress(img_compressed)
            else:
                img_bytes = base64.b64decode(datos_img)
        except Exception as e:
            return jsonify({'error': f'Error decodificando imagen: {str(e)}'}), 500
        
        # Crear respuesta de descarga
        response = make_response(img_bytes)
        response.headers['Content-Type'] = f'image/{parametros["formato_exportacion"]}'
        response.headers['Content-Disposition'] = f'attachment; filename="{nombre_archivo}"'
        response.headers['X-Filename'] = nombre_archivo
        response.headers['X-Generation-Time'] = str(round(tiempo_generacion, 3))
        response.headers['X-Total-Primos'] = str(metricas['total_primos'])
        response.headers['X-Cache-Used'] = str(parametros['usar_cache'])
        
        return response
        
    except Exception as e:
        print(f"Error en /descargar-imagen: {str(e)}")
        traceback.print_exc()
        return jsonify({
            'error': f'Error generando descarga: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500
@app.route('/generar', methods=['POST'])
def generar():
    """Endpoint principal OPTIMIZADO con cache y análisis IA."""
    try:
        datos = request.get_json()
        if not datos:
            return jsonify({'error': 'No se recibieron datos JSON'}), 400
        
        # Extraer TODOS los parámetros posibles
        parametros = {
            'num_circulos': int(datos.get('num_circulos', 10000)),
            'divisiones_por_circulo': int(datos.get('divisiones_por_circulo', 1300)),
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
            'usar_antialiasing': bool(datos.get('usar_antialiasing', True)),
            'usar_cache': bool(datos.get('usar_cache', True)),
            'comprimir_salida': bool(datos.get('comprimir_salida', True))
        }
        
        # Validaciones
        if not (1 <= parametros['num_circulos'] <= 10000):
            return jsonify({'error': 'Círculos debe estar entre 1 y 10,000'}), 400
        if not (2 <= parametros['divisiones_por_circulo'] <= 1300):
            return jsonify({'error': 'Divisiones debe estar entre 2 y 1,300'}), 400
        
        # Generar visualización
        inicio = time.time()
        datos_img, metricas, patrones, compressed = generar_visualizacion_completa(**parametros)
        tiempo_generacion = time.time() - inicio
        
        # Preparar distribución de gaps
        dist_gaps = []
        if patrones and 'gaps_primos' in patrones:
            for gap, cuenta in sorted(patrones['gaps_primos'].items()):
                if gap <= 50:
                    dist_gaps.append({'gap': int(gap), 'cuenta': int(cuenta)})
        
        # Análisis con IA (si está habilitado)
        analisis_ia = None
        if datos.get('incluir_analisis_ia', False) and blackbox_client.api_key:
            try:
                analisis_ia = blackbox_client.analyze_visualization_data(metricas, patrones, parametros)
            except Exception as e:
                print(f"Error en análisis IA: {e}")
        
        # Respuesta completa
        respuesta = {
            'imagen': str(datos_img),
            'imagen_comprimida': compressed,
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
            'cache_utilizado': parametros['usar_cache'],
            'analisis_ia': analisis_ia,
            'cache_stats': cache.stats(),
            'timestamp': datetime.now().isoformat(),
            'version': '3.0.0'
        }
        
        return jsonify(respuesta)
        
    except Exception as e:
        print(f"Error en /generar: {str(e)}")
        traceback.print_exc()
        return jsonify({
            'error': f'Error interno del servidor: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/chat', methods=['POST'])
def chat():
    """Endpoint de chat con IA BLACKBOX."""
    try:
        datos = request.get_json()
        if not datos:
            return jsonify({'error': 'No se recibieron datos JSON'}), 400
        
        mensaje = datos.get('mensaje', '')
        contexto = datos.get('contexto', None)
        
        if not mensaje:
            return jsonify({'error': 'Mensaje requerido'}), 400
        
        # Realizar chat
        respuesta = blackbox_client.chat(mensaje, contexto)
        
        return jsonify({
            'respuesta': respuesta,
            'timestamp': datetime.now().isoformat(),
            'api_status': 'configurado' if blackbox_client.api_key else 'no configurado'
        })
        
    except Exception as e:
        print(f"Error en /chat: {str(e)}")
        return jsonify({
            'error': f'Error en chat: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/cache/stats')
def cache_stats():
    """Estadísticas del sistema de cache."""
    return jsonify({
        'cache': cache.stats(),
        'memoria_proceso': dict(psutil.Process().memory_info()._asdict()),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/cache/clear', methods=['POST'])
def clear_cache():
    """Limpiar cache de disco manualmente."""
    try:
        cache.clear()
        # Forzar recolector de basura
        gc.collect()
        return jsonify({
            'message': 'Cache de disco limpiado exitosamente',
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': f'Error limpiando cache: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/memory/optimize', methods=['POST'])
def optimize_memory():
    """Optimizar memoria forzando limpieza."""
    try:
        # Limpiar matplotlib
        plt.close('all')
        plt.clf()
        
        # Forzar recolector de basura
        collected = gc.collect()
        
        # Obtener estadísticas de memoria
        process = psutil.Process()
        memory_info = process.memory_info()
        
        return jsonify({
            'message': 'Memoria optimizada',
            'objects_collected': collected,
            'memory_usage_mb': round(memory_info.rss / (1024*1024), 2),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': f'Error optimizando memoria: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/memory/stats')
def memory_stats():
    """Estadísticas detalladas de memoria y cache."""
    try:
        # Memoria del proceso
        process = psutil.Process()
        memory_info = process.memory_info()
        
        # Memoria del sistema
        system_memory = psutil.virtual_memory()
        
        # Estadísticas del cache
        cache_stats = cache.stats()
        
        return jsonify({
            'process_memory': {
                'rss_mb': round(memory_info.rss / (1024*1024), 2),
                'vms_mb': round(memory_info.vms / (1024*1024), 2),
                'percent': process.memory_percent()
            },
            'system_memory': {
                'total_gb': round(system_memory.total / (1024*1024*1024), 2),
                'available_gb': round(system_memory.available / (1024*1024*1024), 2),
                'used_percent': system_memory.percent
            },
            'disk_cache': cache_stats,
            'gc_stats': {
                'collections': gc.get_stats(),
                'objects': len(gc.get_objects())
            },
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': f'Error obteniendo estadísticas: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/number/<int:number>')
def analyze_number(number):
    """Análisis matemático detallado de un número específico."""
    try:
        if number < 1 or number > 1000000:
            return jsonify({'error': 'Número debe estar entre 1 y 1,000,000'}), 400
        
        # Generar primos hasta el número
        primos = criba_de_eratostenes_optimizada(max(number + 100, 1000))
        es_primo = number in primos
        conjunto_primos = set(primos)
        
        # Análisis básico
        analisis = {
            'numero': number,
            'es_primo': es_primo,
            'factorizacion': [],
            'propiedades': [],
            'formulas': [],
            'tipos_primo': []
        }
        
        if es_primo:
            # Análisis de primo
            posicion = list(primos).index(number) + 1
            analisis['propiedades'].append(f"Número primo #{posicion}")
            
            # Tipos especiales de primo
            if number > 2 and (number - 2 in conjunto_primos or number + 2 in conjunto_primos):
                twin_pair = number - 2 if number - 2 in conjunto_primos else number + 2
                analisis['tipos_primo'].append(f"Primo gemelo con {twin_pair}")
            
            if number > 4 and (number - 4 in conjunto_primos or number + 4 in conjunto_primos):
                cousin_pair = number - 4 if number - 4 in conjunto_primos else number + 4
                analisis['tipos_primo'].append(f"Primo primo con {cousin_pair}")
            
            if 2 * number + 1 in conjunto_primos:
                analisis['tipos_primo'].append(f"Sophie Germain: 2×{number}+1 = {2*number+1}")
            
            # Verificar si es Mersenne
            temp = number + 1
            p = 0
            while temp > 1 and temp % 2 == 0:
                temp //= 2
                p += 1
            if temp == 1 and p in conjunto_primos and p > 1:
                analisis['tipos_primo'].append(f"Mersenne: 2^{p} - 1")
                analisis['formulas'].append(f"M_{p} = 2^{p} - 1 = {number}")
                # Número perfecto asociado
                perfecto = (2**(p-1)) * number
                analisis['formulas'].append(f"Perfecto asociado: 2^{p-1} × M_{p} = {perfecto}")
            
            # Palíndromo
            if str(number) == str(number)[::-1] and len(str(number)) > 1:
                analisis['tipos_primo'].append("Palindrómico")
            
            # Fórmulas para primos
            analisis['formulas'].append(f"π({number}) ≈ {number}/ln({number}) ≈ {round(number / math.log(number))}")
            
            # Gap con primos adyacentes
            primo_idx = list(primos).index(number)
            if primo_idx > 0:
                gap_anterior = number - primos[primo_idx - 1]
                analisis['formulas'].append(f"Gap anterior: {gap_anterior}")
            if primo_idx < len(primos) - 1:
                gap_siguiente = primos[primo_idx + 1] - number
                analisis['formulas'].append(f"Gap siguiente: {gap_siguiente}")
            
        else:
            # Análisis de compuesto
            factors = []
            temp = number
            for i in range(2, int(math.sqrt(number)) + 1):
                while temp % i == 0:
                    factors.append(i)
                    temp //= i
            if temp > 1:
                factors.append(temp)
            
            analisis['factorizacion'] = factors
            
            if factors:
                analisis['formulas'].append(f"{number} = {' × '.join(map(str, factors))}")
            
            # Función totiente de Euler
            phi = number
            for p in set(factors):
                phi = phi * (p - 1) // p
            analisis['formulas'].append(f"φ({number}) = {phi}")
            
            # Verificar si es cuadrado perfecto
            sqrt_n = int(math.sqrt(number))
            if sqrt_n * sqrt_n == number:
                analisis['propiedades'].append(f"Cuadrado perfecto: {sqrt_n}²")
            
            # Verificar si es cubo perfecto
            cbrt_n = round(number**(1/3))
            if cbrt_n ** 3 == number:
                analisis['propiedades'].append(f"Cubo perfecto: {cbrt_n}³")
        
        # Propiedades generales
        analisis['propiedades'].append("Par" if number % 2 == 0 else "Impar")
        analisis['formulas'].append(f"{number} ≡ {number % 6} (mod 6)")
        analisis['formulas'].append(f"{number} ≡ {number % 10} (mod 10)")
        analisis['formulas'].append(f"Binario: {bin(number)[2:]}")
        
        return jsonify(analisis)
        
    except Exception as e:
        return jsonify({
            'error': f'Error analizando número: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/hires')
def hires_maps_index():
    """Página de índice de mapas de alta resolución."""
    return send_from_directory('static_maps_hires', 'index.html')

@app.route('/api/hires-map/<map_hash>')
def get_hires_map(map_hash):
    """Servir mapa de alta resolución pre-generado."""
    try:
        file_path = f"static_maps_hires/hires_{map_hash}.json"
        if os.path.exists(file_path):
            return send_file(file_path, as_attachment=False, mimetype='application/json')
        else:
            return jsonify({'error': f'Mapa {map_hash} no encontrado'}), 404
    except Exception as e:
        return jsonify({'error': f'Error sirviendo mapa: {str(e)}'}), 500

@app.route('/api/hires-maps')
def list_hires_maps():
    """Listar todos los mapas de alta resolución disponibles."""
    try:
        index_path = "static_maps_hires/index_hires.json"
        if os.path.exists(index_path):
            with open(index_path, 'r') as f:
                return jsonify(json.load(f))
        else:
            return jsonify({'error': 'Índice de mapas de alta resolución no encontrado'}), 404
    except Exception as e:
        return jsonify({'error': f'Error listando mapas: {str(e)}'}), 500

@app.route('/api/interactive-map', methods=['POST'])
def generate_interactive_map_data():
    """Generar datos para el mapa interactivo HTML responsivo."""
    try:
        datos = request.get_json() or {}
        
        # Parámetros del mapa
        num_circulos = int(datos.get('num_circulos', 10000))
        divisiones_por_circulo = int(datos.get('divisiones_por_circulo', 1300))
        tipo_mapeo = datos.get('tipo_mapeo', 'lineal')
        
        # Filtros de tipos de primos
        mostrar_tipos = {
            'regulares': datos.get('mostrar_regulares', True),
            'gemelos': datos.get('mostrar_gemelos', True),
            'primos': datos.get('mostrar_primos', True),
            'sexy': datos.get('mostrar_sexy', False),
            'sophie_germain': datos.get('mostrar_sophie_germain', False),
            'palindromicos': datos.get('mostrar_palindromicos', False),
            'mersenne': datos.get('mostrar_mersenne', False),
            'fermat': datos.get('mostrar_fermat', False),
            'compuestos': datos.get('mostrar_compuestos', True)
        }
        
        total_numeros = num_circulos * divisiones_por_circulo
        
        # Generar primos usando criba optimizada
        primos = criba_de_eratostenes_optimizada(total_numeros)
        conjunto_primos = set(primos)
        
        # Analizar patrones de primos
        patrones = {
            'gemelos': [],
            'primos': [],
            'sexy': [],
            'sophie_germain': [],
            'palindromicos': [],
            'mersenne': [],
            'fermat': []
        }
        
        # Clasificar primos por tipos
        for primo in primos:
            # Primos gemelos
            if (primo - 2 in conjunto_primos or primo + 2 in conjunto_primos):
                patrones['gemelos'].append(primo)
            
            # Primos primos  
            if (primo - 4 in conjunto_primos or primo + 4 in conjunto_primos):
                patrones['primos'].append(primo)
            
            # Primos sexy
            if (primo - 6 in conjunto_primos or primo + 6 in conjunto_primos):
                patrones['sexy'].append(primo)
                
            # Sophie Germain
            if 2 * primo + 1 in conjunto_primos:
                patrones['sophie_germain'].append(primo)
                
            # Palindrómicos
            str_primo = str(primo)
            if str_primo == str_primo[::-1] and len(str_primo) > 1:
                patrones['palindromicos'].append(primo)
                
            # Mersenne
            temp = primo + 1
            p = 0
            while temp > 1 and temp % 2 == 0:
                temp //= 2
                p += 1
            if temp == 1 and p in conjunto_primos and p > 1:
                patrones['mersenne'].append(primo)
                
            # Fermat (casos conocidos pequeños)
            if primo in [3, 5, 17, 257, 65537]:
                patrones['fermat'].append(primo)
        
        # Generar elementos para el mapa
        elementos = []
        
        for numero in range(1, total_numeros + 1):
            es_primo = numero in conjunto_primos
            
            # Determinar tipos especiales
            tipos = []
            
            if es_primo:
                if numero in patrones['gemelos'] and mostrar_tipos['gemelos']:
                    tipos.append('gemelo')
                if numero in patrones['primos'] and mostrar_tipos['primos']:
                    tipos.append('primo')
                if numero in patrones['sexy'] and mostrar_tipos['sexy']:
                    tipos.append('sexy')
                if numero in patrones['sophie_germain'] and mostrar_tipos['sophie_germain']:
                    tipos.append('sophie_germain')
                if numero in patrones['palindromicos'] and mostrar_tipos['palindromicos']:
                    tipos.append('palindromico')
                if numero in patrones['mersenne'] and mostrar_tipos['mersenne']:
                    tipos.append('mersenne')
                if numero in patrones['fermat'] and mostrar_tipos['fermat']:
                    tipos.append('fermat')
                    
                if not tipos and mostrar_tipos['regulares']:
                    tipos.append('regular')
            else:
                if mostrar_tipos['compuestos']:
                    tipos.append('compuesto')
            
            # Calcular posición según mapeo
            if tipo_mapeo == 'lineal':
                circulo = (numero - 1) // divisiones_por_circulo
                segmento = (numero - 1) % divisiones_por_circulo
            elif tipo_mapeo == 'logaritmico':
                pos_log = math.log(numero) / math.log(total_numeros)
                pos_total = int(pos_log * num_circulos * divisiones_por_circulo)
                circulo = pos_total // divisiones_por_circulo
                segmento = pos_total % divisiones_por_circulo
            elif tipo_mapeo == 'arquimedes':
                theta = 2 * math.pi * math.sqrt(numero / total_numeros)
                r = math.sqrt(numero / total_numeros) * num_circulos
                circulo = min(int(r), num_circulos - 1)
                segmento = int((theta % (2 * math.pi)) / (2 * math.pi) * divisiones_por_circulo)
            elif tipo_mapeo == 'fibonacci':
                phi = (1 + math.sqrt(5)) / 2
                fib_theta = 2 * math.pi * numero / phi
                fib_r = math.sqrt(numero) / math.sqrt(total_numeros) * num_circulos
                circulo = min(int(fib_r), num_circulos - 1)
                segmento = int((fib_theta % (2 * math.pi)) / (2 * math.pi) * divisiones_por_circulo)
            else:
                circulo = (numero - 1) // divisiones_por_circulo
                segmento = (numero - 1) % divisiones_por_circulo
            
            # Solo incluir si tiene tipos válidos
            if tipos:
                elementos.append({
                    'numero': numero,
                    'es_primo': es_primo,
                    'tipos': tipos,
                    'circulo': circulo,
                    'segmento': segmento,
                    'posicion': {
                        'radio': (circulo + 0.5) / num_circulos,
                        'angulo': segmento * 2 * math.pi / divisiones_por_circulo - math.pi / 2
                    }
                })
        
        # Estadísticas del mapa
        estadisticas = {
            'total_numeros': total_numeros,
            'total_primos': len(primos),
            'densidad_primos': len(primos) / total_numeros * 100,
            'patrones': {
                'gemelos': len(patrones['gemelos']),
                'primos': len(patrones['primos']),
                'sexy': len(patrones['sexy']),
                'sophie_germain': len(patrones['sophie_germain']),
                'palindromicos': len(patrones['palindromicos']),
                'mersenne': len(patrones['mersenne']),
                'fermat': len(patrones['fermat'])
            },
            'configuracion': {
                'circulos': num_circulos,
                'segmentos': divisiones_por_circulo,
                'mapeo': tipo_mapeo
            }
        }
        
        respuesta = {
            'elementos': elementos,
            'estadisticas': estadisticas,
            'timestamp': datetime.now().isoformat(),
            'version': '3.2.0'
        }
        
        return jsonify(respuesta)
        
    except Exception as e:
        print(f"Error generando mapa interactivo: {str(e)}")
        traceback.print_exc()
        return jsonify({
            'error': f'Error generando mapa: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

# Funciones auxiliares para análisis matemático
def criba_de_eratostenes_optimizada(n):
    """Criba de Eratóstenes optimizada para memoria."""
    if n < 2:
        return []
    
    sieve = [True] * (n + 1)
    sieve[0] = sieve[1] = False
    
    for i in range(2, int(n**0.5) + 1):
        if sieve[i]:
            for j in range(i*i, n + 1, i):
                sieve[j] = False
    
    return [i for i in range(2, n + 1) if sieve[i]]

if __name__ == '__main__':
    import sys
    port = 3000  # Cambiado a puerto 3000
    if len(sys.argv) > 1 and '--port=' in sys.argv[1]:
        port = int(sys.argv[1].split('=')[1])
    
    print("🚀 Iniciando aplicación ULTRA-OPTIMIZADA de visualización de primos v3.2...")
    print(f"Cache: DISCO ✓ | IA: {'✓' if blackbox_client.api_key else '✗'} | Compresión: ✓ | Memoria: OPTIMIZADA ✓")
    print(f"Directorio cache: {cache.cache_dir} | Archivos máx: {cache.max_files}")
    print("🎯 Nuevo endpoint: /api/interactive-map para mapas HTML responsivos")
    print(f"Servidor iniciándose en puerto {port}...")
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
