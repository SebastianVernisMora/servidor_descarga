#!/usr/bin/env python3
"""
Aplicación Flask ARREGLADA que sirve mapas pre-generados estáticos.
Versión simplificada sin dependencia del índice complejo.
"""

from flask import Flask, request, jsonify, send_from_directory, send_file, Response
import os
import json
import hashlib
import random
from datetime import datetime
import traceback
from pathlib import Path

app = Flask(__name__)

# Configuración
STATIC_MAPS_DIR = Path("/home/admin/servidor_descarga/static_maps")

def obtener_lista_mapas():
    """Obtener lista simple de mapas disponibles."""
    try:
        mapas = []
        json_files = list(STATIC_MAPS_DIR.glob("data_*.json"))
        
        for json_file in json_files[:100]:  # Limitar a 100 para performance
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                
                metadata = data.get('metadata', {})
                if metadata and data.get('elementos'):
                    mapas.append({
                        'hash': json_file.stem.replace('data_', ''),
                        'circulos': metadata.get('num_circulos', 0),
                        'segmentos': metadata.get('divisiones_por_circulo', 0),
                        'elementos': len(data.get('elementos', [])),
                        'total_numeros': metadata.get('total_numeros', 0),
                        'tipo_mapeo': metadata.get('tipo_mapeo', 'lineal')
                    })
            except:
                continue
                
        return mapas
    except Exception as e:
        print(f"Error obteniendo lista de mapas: {e}")
        return []

def encontrar_mapa_aleatorio():
    """Encontrar un mapa aleatorio válido."""
    try:
        json_files = list(STATIC_MAPS_DIR.glob("data_*.json"))
        if not json_files:
            return None
            
        # Intentar hasta 10 archivos aleatorios
        for _ in range(10):
            json_file = random.choice(json_files)
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                
                if data.get('elementos') and len(data['elementos']) > 0:
                    return {
                        'hash': json_file.stem.replace('data_', ''),
                        'data': data
                    }
            except:
                continue
                
        return None
    except Exception as e:
        print(f"Error encontrando mapa aleatorio: {e}")
        return None

def buscar_mapa_por_hash(map_hash):
    """Buscar mapa específico por hash."""
    try:
        json_file = STATIC_MAPS_DIR / f"data_{map_hash}.json"
        if json_file.exists():
            with open(json_file, 'r') as f:
                return json.load(f)
        return None
    except Exception as e:
        print(f"Error buscando mapa {map_hash}: {e}")
        return None

@app.route('/')
def home():
    """Página principal - interfaz básica."""
    return send_file(Path("/home/admin/servidor_descarga/index.html"))

@app.route('/enhanced')
def enhanced_interface():
    """Interfaz mejorada."""
    return send_file(Path("/home/admin/servidor_descarga/index.html"))

@app.route('/api/info')
def api_info():
    """Información del sistema."""
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        total_size_mb = sum(f.stat().st_size for f in STATIC_MAPS_DIR.glob("*")) / 1024 / 1024
        
        return jsonify({
            'status': 'active',
            'total_maps': total_maps,
            'total_size_mb': round(total_size_mb, 1),
            'timestamp': datetime.now().isoformat(),
            'version': '3.0-fixed',
            'maps_directory': str(STATIC_MAPS_DIR),
            'server_type': 'static-fixed'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/maps')
def api_maps():
    """Lista de mapas disponibles."""
    try:
        mapas = obtener_lista_mapas()
        return jsonify({
            'maps': mapas,
            'total_count': len(mapas),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/random-map')
def api_random_map():
    """Obtener un mapa aleatorio."""
    try:
        mapa = encontrar_mapa_aleatorio()
        if not mapa:
            return jsonify({'error': 'No hay mapas disponibles'}), 404
            
        return jsonify({
            'hash': mapa['hash'],
            'data': mapa['data'],
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/interactive-map', methods=['POST'])
def get_pregenerated_map():
    """API que retorna datos de mapas pre-generados - SIMPLIFICADO."""
    try:
        parametros = request.get_json() or {}
        
        # Para simplificar, devolver un mapa aleatorio válido
        mapa = encontrar_mapa_aleatorio()
        if not mapa:
            return jsonify({'error': 'No hay mapas disponibles'}), 404
            
        # Convertir a formato esperado por el frontend
        elementos = mapa['data'].get('elementos', [])
        metadata = mapa['data'].get('metadata', {})
        
        # Generar HTML del mapa
        html_response = generar_html_mapa_simple(elementos, metadata, parametros)
        
        return Response(html_response, mimetype='text/html')
        
    except Exception as e:
        print(f"Error en API interactive-map: {e}")
        traceback.print_exc()
        return jsonify({
            'error': 'Error interno del servidor',
            'details': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/number/<int:number>')
def api_number_analysis(number):
    """Análisis matemático de un número específico."""
    try:
        # Análisis matemático básico
        es_primo = es_numero_primo(number)
        tipos = []
        
        if es_primo:
            tipos.append('primo')
            if number > 2 and es_numero_primo(number - 2):
                tipos.append('primo_gemelo')
            if number > 2 and es_numero_primo(number + 2):
                tipos.append('primo_gemelo')
        else:
            tipos.append('compuesto')
            
        return jsonify({
            'numero': number,
            'es_primo': es_primo,
            'tipos': tipos,
            'par_impar': 'par' if number % 2 == 0 else 'impar',
            'mod_6': number % 6,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def es_numero_primo(n):
    """Verificar si un número es primo."""
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False
    for i in range(3, int(n**0.5) + 1, 2):
        if n % i == 0:
            return False
    return True

def generar_html_mapa_simple(elementos, metadata, parametros):
    """Generar HTML simple del mapa."""
    num_circulos = metadata.get('num_circulos', 10)
    divisiones_por_circulo = metadata.get('divisiones_por_circulo', 24)
    
    elementos_js = json.dumps(elementos[:1000])  # Limitar elementos para performance
    
    html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Mapa Estático - {num_circulos}×{divisiones_por_circulo}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #1a1a2e; color: white; }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
        .header {{ text-align: center; margin-bottom: 20px; }}
        .map-container {{ width: 600px; height: 600px; margin: 20px auto; position: relative; background: radial-gradient(circle, #2a2a4e 0%, #1a1a2e 100%); border-radius: 50%; }}
        .punto {{ position: absolute; width: 4px; height: 4px; border-radius: 50%; cursor: pointer; }}
        .primo {{ background: #4D96FF; }}
        .compuesto {{ background: #808080; }}
        .info {{ text-align: center; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Mapa Estático de Números Primos</h1>
            <p>Círculos: {num_circulos} | Segmentos: {divisiones_por_circulo} | Elementos: {len(elementos)}</p>
        </div>
        
        <div class="map-container" id="mapContainer"></div>
        
        <div class="info">
            <p>Azul: Números primos | Gris: Números compuestos</p>
        </div>
    </div>
    
    <script>
        const elementos = {elementos_js};
        const mapContainer = document.getElementById('mapContainer');
        const centerX = 300;
        const centerY = 300;
        const maxRadius = 280;
        
        elementos.forEach(elemento => {{
            const radio = (elemento.circulo / {max(num_circulos-1, 1)}) * maxRadius;
            const angulo = (elemento.segmento / {max(divisiones_por_circulo, 1)}) * 2 * Math.PI;
            
            const x = centerX + radio * Math.cos(angulo);
            const y = centerY + radio * Math.sin(angulo);
            
            const punto = document.createElement('div');
            punto.className = `punto ${{elemento.es_primo ? 'primo' : 'compuesto'}}`;
            punto.style.left = x + 'px';
            punto.style.top = y + 'px';
            punto.title = `Número: ${{elemento.numero}} (${{elemento.es_primo ? 'Primo' : 'Compuesto'}})`;
            
            mapContainer.appendChild(punto);
        }});
    </script>
</body>
</html>
"""
    return html

if __name__ == '__main__':
    # Mostrar información de inicio
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        print("🚀 Iniciando servidor ARREGLADO con interfaz interactiva...")
        print("=" * 60)
        print(f"📁 Directorio de mapas: {STATIC_MAPS_DIR}")
        print(f"🗺️ Total de mapas encontrados: {total_maps:,}")
        print()
        print("🌐 ACCESOS PÚBLICOS DISPONIBLES:")
        
        # Obtener IPs para mostrar accesos disponibles
        import subprocess
        try:
            local_ip = subprocess.check_output(['hostname', '-I']).decode().split()[0]
            hostname = subprocess.check_output(['hostname', '-f']).decode().strip()
            
            print(f"   📍 IP PÚBLICA:   http://{local_ip}:3000/")
            print(f"   🌍 DNS/HOSTNAME: http://{hostname}:3000/")
            print(f"   🔗 LOCALHOST:    http://localhost:3000/")
            print()
        except:
            print("🌐 Servidor accesible en: http://0.0.0.0:3000/")
        
        print("🎯 ENDPOINTS DISPONIBLES:")
        print("   🏠 Interfaz:          GET http://localhost:3000/")
        print("   📊 Lista de Mapas:    GET http://localhost:3000/api/maps")
        print("   🎲 Mapa Aleatorio:    GET http://localhost:3000/api/random-map")
        print("   📈 Info del Sistema:  GET http://localhost:3000/api/info")
        print("   🧮 Análisis:          GET http://localhost:3000/api/number/<n>")
        print("   🗺️ Mapa Interactivo:  POST http://localhost:3000/api/interactive-map")
        print()
        print("🔥 SERVIDOR ARREGLADO INICIANDO EN PUERTO 3000...")
        
        app.run(host='0.0.0.0', port=3000, debug=False, threaded=True)
    except Exception as e:
        print(f"❌ Error iniciando servidor: {e}")
        traceback.print_exc()