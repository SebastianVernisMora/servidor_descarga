#!/usr/bin/env python3
"""
Aplicación Flask que sirve mapas pre-generados estáticos para máximo rendimiento.
No hace cálculos en tiempo real - usa archivos HTML/JSON pre-calculados.
"""

from flask import Flask, request, jsonify, send_from_directory, send_file, Response
import os
import json
import hashlib
from datetime import datetime
import traceback
from pathlib import Path

app = Flask(__name__)

# Configuración
STATIC_MAPS_DIR = Path("/home/sebastianvernis/servidor_descarga/static_maps")
CACHE_INDEX = None

def cargar_indice_mapas():
    """Cargar índice de mapas pre-generados."""
    global CACHE_INDEX
    try:
        with open(STATIC_MAPS_DIR / "index.json", 'r') as f:
            CACHE_INDEX = json.load(f)
        print(f"✅ Índice cargado: {len(CACHE_INDEX['maps'])} mapas disponibles")
        return True
    except Exception as e:
        print(f"❌ Error cargando índice: {e}")
        return False

def generar_hash_parametros(parametros):
    """Generar hash para combinación de parámetros."""
    # Normalizar parámetros para matching consistente
    normalized = {
        'num_circulos': int(parametros.get('num_circulos', 10)),
        'divisiones_por_circulo': int(parametros.get('divisiones_por_circulo', 24)),
        'tipo_mapeo': parametros.get('tipo_mapeo', 'lineal'),
        'filtros': {
            'regulares': parametros.get('mostrar_regulares', True),
            'gemelos': parametros.get('mostrar_gemelos', True),
            'primos': parametros.get('mostrar_primos', True),
            'sexy': parametros.get('mostrar_sexy', False),
            'sophie_germain': parametros.get('mostrar_sophie_germain', False),
            'palindromicos': parametros.get('mostrar_palindromicos', False),
            'mersenne': parametros.get('mostrar_mersenne', False),
            'fermat': parametros.get('mostrar_fermat', False),
            'compuestos': parametros.get('mostrar_compuestos', True)
        }
    }
    
    param_str = json.dumps(normalized, sort_keys=True)
    return hashlib.md5(param_str.encode()).hexdigest()[:12]

def encontrar_mapa_similar(parametros):
    """Encontrar el mapa pre-generado más similar a los parámetros solicitados."""
    if not CACHE_INDEX:
        return None
    
    target_circulos = int(parametros.get('num_circulos', 10))
    target_divisiones = int(parametros.get('divisiones_por_circulo', 24))
    target_mapeo = parametros.get('tipo_mapeo', 'lineal')
    
    mejores_matches = []
    
    for map_hash, info in CACHE_INDEX['maps'].items():
        param_map = info['parametros']
        
        # Calcular score de similitud
        score = 0
        
        # Exactitud en mapeo (más importante)
        if param_map['tipo_mapeo'] == target_mapeo:
            score += 50
        
        # Proximidad en círculos
        diff_circulos = abs(param_map['num_circulos'] - target_circulos)
        score += max(0, 25 - diff_circulos * 5)
        
        # Proximidad en divisiones  
        diff_divisiones = abs(param_map['divisiones_por_circulo'] - target_divisiones)
        score += max(0, 25 - diff_divisiones * 2)
        
        mejores_matches.append({
            'hash': map_hash,
            'info': info,
            'score': score
        })
    
    # Ordenar por score y retornar el mejor
    mejores_matches.sort(key=lambda x: x['score'], reverse=True)
    
    if mejores_matches and mejores_matches[0]['score'] > 30:
        return mejores_matches[0]
    
    return None

@app.route('/')
def home():
    """Página principal - interfaz mejorada interactiva."""
    return send_file(STATIC_MAPS_DIR / "index.html")

@app.route('/enhanced')
def enhanced_interface():
    """Interfaz mejorada - redirigir a selector."""
    return send_file(STATIC_MAPS_DIR / "index.html")

@app.route('/api/interactive-map', methods=['POST'])
def get_pregenerated_map():
    """API que retorna datos de mapas pre-generados."""
    try:
        parametros = request.get_json() or {}
        
        # Intentar encontrar mapa exacto
        param_hash = generar_hash_parametros(parametros)
        
        # Buscar en archivos JSON pre-generados
        json_file = STATIC_MAPS_DIR / f"data_{param_hash}.json"
        
        if json_file.exists():
            # Mapa exacto encontrado
            with open(json_file, 'r') as f:
                data = json.load(f)
            
            print(f"✅ Mapa exacto servido: {param_hash}")
            return jsonify({
                'elementos': data['elementos'],
                'estadisticas': data['estadisticas'],
                'timestamp': datetime.now().isoformat(),
                'version': '3.3.0-enhanced',
                'source': 'pre-generated-exact',
                'hash': param_hash
            })
        
        else:
            # Buscar mapa similar
            match = encontrar_mapa_similar(parametros)
            
            if match:
                json_file = STATIC_MAPS_DIR / match['info']['json_file']
                with open(json_file, 'r') as f:
                    data = json.load(f)
                
                print(f"✅ Mapa similar servido: {match['hash']} (score: {match['score']})")
                return jsonify({
                    'elementos': data['elementos'],
                    'estadisticas': data['estadisticas'],
                    'timestamp': datetime.now().isoformat(),
                    'version': '3.3.0-enhanced',
                    'source': 'pre-generated-similar',
                    'hash': match['hash'],
                    'similarity_score': match['score'],
                    'note': 'Mapa similar al solicitado - pre-calculado para máximo rendimiento'
                })
            
            else:
                # Generar mínimo dinámico como fallback
                return jsonify({
                    'error': 'Combinación no disponible en mapas pre-generados',
                    'available_combinations': len(CACHE_INDEX['maps']) if CACHE_INDEX else 0,
                    'suggestion': 'Usa /api/maps para ver mapas disponibles',
                    'timestamp': datetime.now().isoformat()
                }), 404
    
    except Exception as e:
        print(f"❌ Error sirviendo mapa: {e}")
        traceback.print_exc()
        return jsonify({
            'error': f'Error del servidor: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/maps')
def list_available_maps():
    """Listar mapas pre-generados disponibles."""
    if not CACHE_INDEX:
        return jsonify({'error': 'Índice de mapas no disponible'}), 500
    
    # Preparar resumen de mapas disponibles
    resumen = {
        'total_maps': len(CACHE_INDEX['maps']),
        'generated': CACHE_INDEX['generated'],
        'combinations': {},
        'mapeos_disponibles': set(),
        'rangos_circulos': {'min': float('inf'), 'max': 0},
        'rangos_segmentos': {'min': float('inf'), 'max': 0}
    }
    
    for map_hash, info in CACHE_INDEX['maps'].items():
        param = info['parametros']
        
        # Recopilar estadísticas
        resumen['mapeos_disponibles'].add(param['tipo_mapeo'])
        resumen['rangos_circulos']['min'] = min(resumen['rangos_circulos']['min'], param['num_circulos'])
        resumen['rangos_circulos']['max'] = max(resumen['rangos_circulos']['max'], param['num_circulos'])
        resumen['rangos_segmentos']['min'] = min(resumen['rangos_segmentos']['min'], param['divisiones_por_circulo'])
        resumen['rangos_segmentos']['max'] = max(resumen['rangos_segmentos']['max'], param['divisiones_por_circulo'])
        
        # Agrupar por configuración base
        config_key = f"{param['num_circulos']}x{param['divisiones_por_circulo']}-{param['tipo_mapeo']}"
        if config_key not in resumen['combinations']:
            resumen['combinations'][config_key] = {
                'parametros': param,
                'elementos_count': info['elementos_count'],
                'primos_count': info['primos_count'],
                'densidad': info['densidad'],
                'file_size_kb': info['file_size_kb'],
                'html_url': f"/static_map/{info['html_file']}",
                'json_url': f"/api/map-data/{map_hash}",
                'hash': map_hash
            }
    
    resumen['mapeos_disponibles'] = list(resumen['mapeos_disponibles'])
    
    return jsonify(resumen)

@app.route('/api/map-data/<map_hash>')
def get_map_data(map_hash):
    """Obtener datos JSON de un mapa específico."""
    try:
        if not CACHE_INDEX or map_hash not in CACHE_INDEX['maps']:
            return jsonify({'error': 'Mapa no encontrado'}), 404
        
        info = CACHE_INDEX['maps'][map_hash]
        json_file = STATIC_MAPS_DIR / info['json_file']
        
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        return jsonify(data)
        
    except Exception as e:
        return jsonify({'error': f'Error cargando mapa: {str(e)}'}), 500

@app.route('/static_map/<filename>')
def serve_static_map(filename):
    """Servir archivo HTML de mapa estático."""
    try:
        if not filename.endswith('.html'):
            return jsonify({'error': 'Solo archivos HTML'}), 400
        
        file_path = STATIC_MAPS_DIR / filename
        if not file_path.exists():
            return jsonify({'error': 'Mapa no encontrado'}), 404
        
        return send_file(file_path)
        
    except Exception as e:
        return jsonify({'error': f'Error: {str(e)}'}), 500

@app.route('/api/info')
def api_info():
    """Información de la API estática."""
    return jsonify({
        'version': '3.3.0-enhanced',
        'name': 'Enhanced Interactive Prime Visualization',
        'features': [
            'Interactive HTML interface with advanced tooltips',
            'Real-time mathematical analysis',
            'Pre-generated maps for maximum performance',
            'Advanced prime pattern visualization',
            'Mobile-responsive design',
            'Zoom and pan controls',
            'Multiple mathematical mappings',
            'Live statistics dashboard'
        ],
        'performance': {
            'map_loading': 'Instant (pre-generated)',
            'calculation_time': '0ms (pre-calculated)',
            'memory_usage': 'Minimal (static files)',
            'cache_type': 'Static HTML/JSON files'
        },
        'statistics': {
            'total_maps': len(CACHE_INDEX['maps']) if CACHE_INDEX else 0,
            'total_size_kb': sum(info['file_size_kb'] for info in CACHE_INDEX['maps'].values()) if CACHE_INDEX else 0,
            'generated': CACHE_INDEX['generated'] if CACHE_INDEX else None
        },
        'endpoints': {
            'home': '/ (map selector)',
            'maps_list': '/api/maps',
            'map_data': '/api/map-data/<hash>',
            'static_map': '/static_map/<filename>',
            'interactive_api': '/api/interactive-map (POST)'
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/number/<int:number>')
def analyze_number_static(number):
    """Análisis básico de números (sin pre-generación pesada)."""
    try:
        if number < 1 or number > 10000:
            return jsonify({'error': 'Número debe estar entre 1 y 10,000'}), 400
        
        # Análisis básico y rápido
        def es_primo_simple(n):
            if n < 2: return False
            if n == 2: return True
            if n % 2 == 0: return False
            for i in range(3, int(n**0.5) + 1, 2):
                if n % i == 0: return False
            return True
        
        es_primo = es_primo_simple(number)
        
        analisis = {
            'numero': number,
            'es_primo': es_primo,
            'propiedades': [],
            'formulas': [],
            'tipos_primo': []
        }
        
        # Propiedades básicas
        analisis['propiedades'].append("Número primo" if es_primo else "Número compuesto")
        analisis['propiedades'].append("Par" if number % 2 == 0 else "Impar")
        
        # Fórmulas básicas
        analisis['formulas'].extend([
            f"{number} ≡ {number % 6} (mod 6)",
            f"{number} ≡ {number % 10} (mod 10)",
            f"Binario: {bin(number)[2:]}",
            f"Hexadecimal: {hex(number)[2:].upper()}"
        ])
        
        if es_primo and number > 2:
            # Verificar tipos especiales básicos
            if es_primo_simple(number - 2) or es_primo_simple(number + 2):
                twin = (number - 2) if es_primo_simple(number - 2) else (number + 2)
                analisis['tipos_primo'].append(f"Primo gemelo con {twin}")
            
            if es_primo_simple(number - 4) or es_primo_simple(number + 4):
                cousin = (number - 4) if es_primo_simple(number - 4) else (number + 4)
                analisis['tipos_primo'].append(f"Primo primo con {cousin}")
        
        elif not es_primo:
            # Factorización básica
            factors = []
            temp = number
            for i in range(2, int(number**0.5) + 1):
                while temp % i == 0:
                    factors.append(i)
                    temp //= i
            if temp > 1:
                factors.append(temp)
            
            if factors:
                analisis['formulas'].append(f"{number} = {' × '.join(map(str, factors))}")
        
        return jsonify(analisis)
        
    except Exception as e:
        return jsonify({
            'error': f'Error analizando número: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/random-map')
def get_random_map():
    """Obtener un mapa aleatorio de los pre-generados."""
    if not CACHE_INDEX:
        return jsonify({'error': 'Índice no disponible'}), 500
    
    import random
    map_hash = random.choice(list(CACHE_INDEX['maps'].keys()))
    info = CACHE_INDEX['maps'][map_hash]
    
    return jsonify({
        'html_url': f"/static_map/{info['html_file']}",
        'json_url': f"/api/map-data/{map_hash}",
        'parametros': info['parametros'],
        'estadisticas': {
            'elementos': info['elementos_count'],
            'primos': info['primos_count'],
            'densidad': info['densidad'],
            'tamaño_kb': info['file_size_kb']
        },
        'hash': map_hash
    })

# Manejo de errores
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Ruta no encontrada',
        'available_routes': [
            '/ (interfaz interactiva mejorada)',
            '/enhanced (selector de mapas estáticos)', 
            '/api/maps (lista de mapas disponibles)',
            '/api/interactive-map (mapa interactivo optimizado)',
            '/api/number/<int> (análisis matemático de número)',
            '/api/random-map (mapa aleatorio)',
            '/static_map/<filename> (mapa HTML pre-generado)'
        ],
        'total_maps_available': len(CACHE_INDEX['maps']) if CACHE_INDEX else 0
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'error': 'Error interno del servidor',
        'message': 'Consulta los logs para más información',
        'timestamp': datetime.now().isoformat()
    }), 500

if __name__ == '__main__':
    print("🚀 Iniciando servidor MEJORADO con interfaz interactiva avanzada...")
    print("=" * 70)
    
    # Cargar índice de mapas
    if cargar_indice_mapas():
        print(f"📊 {len(CACHE_INDEX['maps'])} mapas pre-generados listos para servir")
        print(f"💾 Tamaño total: {sum(info['file_size_kb'] for info in CACHE_INDEX['maps'].values())}KB")
        print("⚡ Rendimiento: MÁXIMO (mapas pre-calculados + interfaz responsiva)")
        print()
        print("🌐 URLs disponibles:")
        print("   🎮 Interfaz Interactiva:   http://localhost:3000/")
        print("   🎯 API Mapas Dinámicos:    POST http://localhost:3000/api/interactive-map")
        print("   📊 Lista de Mapas:         GET http://localhost:3000/api/maps")
        print("   🎲 Mapa Aleatorio:         GET http://localhost:3000/api/random-map")
        print("   📈 Info del Sistema:       GET http://localhost:3000/api/info")
        print("   🧮 Análisis de Números:    GET http://localhost:3000/api/number/<n>")
        print()
        print("🎨 NUEVAS CARACTERÍSTICAS:")
        print("   ✨ Tooltips matemáticos avanzados con análisis en tiempo real")
        print("   🔍 Controles de zoom y navegación mejorados")
        print("   📱 Diseño completamente responsive para móviles")
        print("   🎯 8 tipos diferentes de primos con visualización especializada")
        print("   ⚡ Carga instantánea usando mapas pre-generados")
        print("   🌈 Animaciones y efectos visuales mejorados")
        print()
        print("🔥 SERVIDOR INTERACTIVO MEJORADO INICIANDO EN PUERTO 3000...")
        
        app.run(host='0.0.0.0', port=3000, debug=False, threaded=True)
    else:
        print("❌ No se pudo cargar el índice de mapas pre-generados")
        print("💡 Ejecuta primero: python3 pregenerate_static_maps.py")
        exit(1)