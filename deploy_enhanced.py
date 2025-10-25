#!/usr/bin/env python3
"""
Script para desplegar la funcionalidad mejorada sin permisos de administrador.
Crea una aplicación que funciona como proxy/wrapper de la aplicación existente.
"""

from flask import Flask, request, jsonify, send_from_directory, Response
import requests
import math
from datetime import datetime
import json
import traceback

# Crear aplicación de proxy
app = Flask(__name__)

# URL de la aplicación original (backup)
ORIGINAL_APP_URL = "http://localhost:5000"  # Puerto de backup si fuera necesario

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

@app.route('/api/interactive-map', methods=['POST'])
def generate_interactive_map_data():
    """API endpoint mejorado para mapa interactivo."""
    try:
        datos = request.get_json() or {}
        
        # Parámetros del mapa
        num_circulos = int(datos.get('num_circulos', 10))
        divisiones_por_circulo = int(datos.get('divisiones_por_circulo', 24))
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
        
        total_numeros = min(num_circulos * divisiones_por_circulo, 1000)  # Límite de seguridad
        
        # Generar primos
        primos = criba_de_eratostenes_optimizada(total_numeros)
        conjunto_primos = set(primos)
        
        # Analizar patrones
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
                
            # Mersenne (casos pequeños)
            if primo in [3, 7, 31, 127]:
                patrones['mersenne'].append(primo)
                
            # Fermat (casos conocidos pequeños)
            if primo in [3, 5, 17, 257]:
                patrones['fermat'].append(primo)
        
        # Generar elementos
        elementos = []
        
        for numero in range(1, total_numeros + 1):
            es_primo = numero in conjunto_primos
            
            # Determinar tipos
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
            
            # Calcular posición
            if tipo_mapeo == 'lineal':
                circulo = (numero - 1) // divisiones_por_circulo
                segmento = (numero - 1) % divisiones_por_circulo
            elif tipo_mapeo == 'logaritmico':
                if total_numeros > 1:
                    pos_log = math.log(numero) / math.log(total_numeros)
                    pos_total = int(pos_log * num_circulos * divisiones_por_circulo)
                    circulo = pos_total // divisiones_por_circulo
                    segmento = pos_total % divisiones_por_circulo
                else:
                    circulo = segmento = 0
            elif tipo_mapeo == 'arquimedes':
                theta = 2 * math.pi * math.sqrt(numero / total_numeros) if total_numeros > 0 else 0
                r = math.sqrt(numero / total_numeros) * num_circulos if total_numeros > 0 else 0
                circulo = min(int(r), num_circulos - 1)
                segmento = int((theta % (2 * math.pi)) / (2 * math.pi) * divisiones_por_circulo) if theta > 0 else 0
            elif tipo_mapeo == 'fibonacci':
                phi = (1 + math.sqrt(5)) / 2
                fib_theta = 2 * math.pi * numero / phi
                fib_r = math.sqrt(numero) / math.sqrt(total_numeros) * num_circulos if total_numeros > 0 else 0
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
                        'radio': (circulo + 0.5) / num_circulos if num_circulos > 0 else 0,
                        'angulo': segmento * 2 * math.pi / divisiones_por_circulo - math.pi / 2 if divisiones_por_circulo > 0 else 0
                    }
                })
        
        # Estadísticas
        estadisticas = {
            'total_numeros': total_numeros,
            'total_primos': len(primos),
            'densidad_primos': len(primos) / total_numeros * 100 if total_numeros > 0 else 0,
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
        return jsonify({
            'error': f'Error generando mapa: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/enhanced')
def enhanced_interactive():
    """Nueva interfaz HTML mejorada."""
    return send_from_directory('/home/admin', 'index_interactive_enhanced.html')

@app.route('/index_interactive_enhanced.html')
def enhanced_interactive_direct():
    """Acceso directo a la interfaz mejorada."""
    return send_from_directory('/home/admin', 'index_interactive_enhanced.html')

@app.route('/')
def home():
    """Página principal - servir interfaz mejorada."""
    return send_from_directory('/home/admin', 'index_interactive_enhanced.html')

@app.route('/classic')
def classic_view():
    """Vista clásica - redirigir al original si está disponible."""
    try:
        resp = requests.get(f"{ORIGINAL_APP_URL}/", timeout=3)
        return Response(
            resp.content,
            status=resp.status_code,
            headers=dict(resp.headers)
        )
    except:
        return jsonify({
            'error': 'Vista clásica no disponible', 
            'message': 'Use /enhanced para la interfaz mejorada'
        }), 503

# API básica de información
@app.route('/api/info')
def api_info():
    """Información de la API mejorada."""
    return jsonify({
        'version': '3.2.0',
        'name': 'Enhanced Prime Visualization',
        'features': [
            'Interactive HTML maps (no image rendering)',
            'Real-time mathematical tooltips',
            'Responsive API for dynamic maps',
            'Multiple mathematical mappings',
            'Prime type classification',
            'Mobile-responsive design'
        ],
        'endpoints': {
            'home': '/',
            'enhanced': '/enhanced',
            'interactive_map': '/api/interactive-map (POST)',
            'number_analysis': '/api/number/<int:number>',
            'classic_view': '/classic'
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/number/<int:number>')
def analyze_number(number):
    """Análisis matemático simplificado de un número."""
    try:
        if number < 1 or number > 100000:
            return jsonify({'error': 'Número debe estar entre 1 y 100,000'}), 400
        
        # Generar primos hasta el número
        primos = criba_de_eratostenes_optimizada(max(number + 10, 100))
        es_primo = number in primos
        conjunto_primos = set(primos)
        
        analisis = {
            'numero': number,
            'es_primo': es_primo,
            'propiedades': [],
            'formulas': [],
            'tipos_primo': []
        }
        
        if es_primo:
            posicion = list(primos).index(number) + 1
            analisis['propiedades'].append(f"Número primo #{posicion}")
            
            # Tipos especiales
            if number > 2 and (number - 2 in conjunto_primos or number + 2 in conjunto_primos):
                twin_pair = number - 2 if number - 2 in conjunto_primos else number + 2
                analisis['tipos_primo'].append(f"Primo gemelo con {twin_pair}")
            
            if number > 4 and (number - 4 in conjunto_primos or number + 4 in conjunto_primos):
                cousin_pair = number - 4 if number - 4 in conjunto_primos else number + 4
                analisis['tipos_primo'].append(f"Primo primo con {cousin_pair}")
            
            # Fórmulas para primos
            analisis['formulas'].append(f"π({number}) ≈ {number}/ln({number}) ≈ {round(number / math.log(number)) if number > 1 else 1}")
            
        else:
            # Análisis de compuestos
            factors = []
            temp = number
            for i in range(2, int(math.sqrt(number)) + 1):
                while temp % i == 0:
                    factors.append(i)
                    temp //= i
            if temp > 1:
                factors.append(temp)
            
            if factors:
                analisis['formulas'].append(f"{number} = {' × '.join(map(str, factors))}")
        
        # Propiedades generales
        analisis['propiedades'].append("Par" if number % 2 == 0 else "Impar")
        analisis['formulas'].append(f"{number} ≡ {number % 6} (mod 6)")
        analisis['formulas'].append(f"Binario: {bin(number)[2:]}")
        
        return jsonify(analisis)
        
    except Exception as e:
        return jsonify({
            'error': f'Error analizando número: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

# Manejo de rutas no encontradas
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Ruta no encontrada',
        'message': 'Usa / para la interfaz principal o /api/info para información',
        'available_routes': ['/', '/enhanced', '/api/interactive-map', '/api/info', '/classic']
    }), 404

if __name__ == '__main__':
    import sys
    port = 3000  # Puerto público principal
    if len(sys.argv) > 1 and '--port=' in sys.argv[1]:
        port = int(sys.argv[1].split('=')[1])
    
    print("🚀 Iniciando aplicación MEJORADA de visualización de primos v3.2...")
    print("🎯 Nueva interfaz interactiva disponible en /enhanced")
    print("🔧 API mejorada disponible en /api/interactive-map")
    print("🌐 Reemplazando aplicación en puerto público 3000...")
    print(f"Servidor iniciándose en puerto {port}...")
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)