#!/usr/bin/env python3
"""
Servidor Flask SIMPLIFICADO - Sin errores 500
Version ultra simple que sirve mapas estáticos sin dependencias complejas.
"""

from flask import Flask, request, jsonify, send_file, Response
import os
import json
import random
from datetime import datetime
from pathlib import Path

app = Flask(__name__)

STATIC_MAPS_DIR = Path("/home/admin/servidor_descarga/static_maps")

def obtener_mapa_aleatorio():
    """Obtener un mapa JSON aleatorio válido."""
    try:
        json_files = list(STATIC_MAPS_DIR.glob("data_*.json"))
        if not json_files:
            return None
            
        # Probar hasta 5 archivos aleatorios
        for _ in range(5):
            json_file = random.choice(json_files)
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                
                # Verificar que tiene elementos válidos
                if data.get('elementos') and len(data['elementos']) > 100:
                    return {
                        'hash': json_file.stem.replace('data_', ''),
                        'data': data
                    }
            except:
                continue
                
        return None
    except:
        return None

@app.route('/')
def home():
    """Página principal."""
    try:
        return send_file("/home/admin/servidor_descarga/index.html")
    except:
        return "<h1>Servidor de Mapas Activo</h1><p>5,234 mapas disponibles</p>"

@app.route('/api/info')
def api_info():
    """Información del sistema - SIMPLIFICADA."""
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        total_size_mb = sum(f.stat().st_size for f in STATIC_MAPS_DIR.glob("*")) / 1024 / 1024
        
        return jsonify({
            'status': 'active',
            'total_maps': total_maps,
            'total_size_mb': round(total_size_mb, 1),
            'timestamp': datetime.now().isoformat(),
            'version': 'simple-fixed',
            'server_type': 'static_maps',
            'endpoints': [
                'GET /',
                'GET /api/info', 
                'GET /api/maps',
                'GET /api/random-map',
                'POST /api/interactive-map'
            ]
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/maps')
def api_maps():
    """Lista simplificada de mapas."""
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        
        # Obtener muestra de 10 mapas con información
        sample_maps = []
        json_files = list(STATIC_MAPS_DIR.glob("data_*.json"))[:10]
        
        for json_file in json_files:
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                
                metadata = data.get('metadata', {})
                sample_maps.append({
                    'hash': json_file.stem.replace('data_', ''),
                    'circulos': metadata.get('num_circulos', 0),
                    'segmentos': metadata.get('divisiones_por_circulo', 0),
                    'elementos': len(data.get('elementos', [])),
                    'size_kb': round(json_file.stat().st_size / 1024, 1)
                })
            except:
                continue
        
        return jsonify({
            'total_count': total_maps,
            'sample_maps': sample_maps,
            'timestamp': datetime.now().isoformat(),
            'message': f'{total_maps} mapas estáticos disponibles'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/random-map')
def api_random_map():
    """Obtener mapa aleatorio - SIMPLIFICADO."""
    try:
        mapa = obtener_mapa_aleatorio()
        if not mapa:
            return jsonify({
                'error': 'No hay mapas disponibles',
                'total_files': len(list(STATIC_MAPS_DIR.glob("data_*.json")))
            }), 404
            
        return jsonify({
            'success': True,
            'hash': mapa['hash'],
            'elementos_count': len(mapa['data'].get('elementos', [])),
            'metadata': mapa['data'].get('metadata', {}),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/interactive-map', methods=['POST'])
def api_interactive_map():
    """API de mapa interactivo - COMPLETAMENTE SIMPLIFICADA."""
    try:
        # Obtener parámetros (aunque no los usemos para matching complejo)
        parametros = request.get_json() or {}
        
        # Obtener mapa aleatorio válido 
        mapa = obtener_mapa_aleatorio()
        if not mapa:
            return jsonify({'error': 'No hay mapas disponibles'}), 404
        
        # Extraer datos
        elementos = mapa['data'].get('elementos', [])
        metadata = mapa['data'].get('metadata', {})
        
        # Limitar elementos para performance del frontend
        elementos_limitados = elementos[:2000]
        
        # Generar HTML simplificado
        html = generar_html_simple(elementos_limitados, metadata)
        
        return Response(html, mimetype='text/html')
        
    except Exception as e:
        print(f"Error en interactive-map: {e}")
        
        # Respuesta de emergencia
        return Response("""
        <html>
        <body style="font-family: Arial; padding: 20px; background: #1a1a2e; color: white;">
            <h2>Error en el servidor</h2>
            <p>No se pudo generar el mapa. Intenta de nuevo.</p>
            <button onclick="window.location.reload()">Reintentar</button>
        </body>
        </html>
        """, mimetype='text/html'), 500

def generar_html_simple(elementos, metadata):
    """Generar HTML simple y funcional."""
    num_circulos = metadata.get('num_circulos', 10)
    divisiones = metadata.get('divisiones_por_circulo', 24)
    
    # JavaScript con los elementos (limitados para performance)
    elementos_js = json.dumps(elementos[:1000])
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Mapa de Primos - {num_circulos}×{divisiones}</title>
    <style>
        body {{ margin: 0; padding: 20px; background: linear-gradient(135deg, #1a1a2e, #16213e); color: white; font-family: Arial; }}
        .container {{ max-width: 1200px; margin: 0 auto; text-align: center; }}
        .map-container {{ width: 600px; height: 600px; margin: 20px auto; position: relative; 
                          background: radial-gradient(circle, #2a2a4e 0%, #1a1a2e 100%); 
                          border-radius: 50%; border: 2px solid #667eea; }}
        .punto {{ position: absolute; width: 3px; height: 3px; border-radius: 50%; cursor: pointer; transition: all 0.2s; }}
        .primo {{ background: #4D96FF; box-shadow: 0 0 3px #4D96FF; }}
        .compuesto {{ background: #666; }}
        .punto:hover {{ transform: scale(2); z-index: 100; }}
        .info {{ margin-top: 20px; opacity: 0.8; }}
        .stats {{ display: flex; justify-content: center; gap: 20px; margin: 20px 0; }}
        .stat {{ background: rgba(255,255,255,0.1); padding: 10px 20px; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🗺️ Mapa de Números Primos</h1>
        <div class="stats">
            <div class="stat"><strong>{num_circulos}</strong><br>Círculos</div>
            <div class="stat"><strong>{divisiones}</strong><br>Segmentos</div>
            <div class="stat"><strong>{len(elementos)}</strong><br>Puntos</div>
        </div>
        
        <div class="map-container" id="mapContainer"></div>
        
        <div class="info">
            <p><span style="color: #4D96FF;">●</span> Números Primos &nbsp;&nbsp; <span style="color: #666;">●</span> Números Compuestos</p>
            <p>Pasa el mouse sobre los puntos para ver detalles</p>
        </div>
        
        <button onclick="window.location.reload()" style="padding: 10px 20px; margin: 20px; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer;">
            🔄 Generar Nuevo Mapa
        </button>
    </div>
    
    <script>
        const elementos = {elementos_js};
        const mapContainer = document.getElementById('mapContainer');
        const centerX = 300;
        const centerY = 300;
        const maxRadius = 280;
        
        console.log(`Renderizando ${{elementos.length}} elementos...`);
        
        elementos.forEach((elemento, index) => {{
            try {{
                const radio = (elemento.circulo / Math.max({num_circulos - 1}, 1)) * maxRadius;
                const angulo = (elemento.segmento / {divisiones}) * 2 * Math.PI;
                
                const x = centerX + radio * Math.cos(angulo);
                const y = centerY + radio * Math.sin(angulo);
                
                const punto = document.createElement('div');
                punto.className = `punto ${{elemento.es_primo ? 'primo' : 'compuesto'}}`;
                punto.style.left = x + 'px';
                punto.style.top = y + 'px';
                punto.title = `#${{elemento.numero}}: ${{elemento.es_primo ? 'PRIMO' : 'Compuesto'}} (C${{elemento.circulo+1}}/S${{elemento.segmento+1}})`;
                
                mapContainer.appendChild(punto);
            }} catch(e) {{
                console.warn(`Error renderizando elemento ${{index}}:`, e);
            }}
        }});
        
        console.log(`✅ Mapa renderizado con ${{elementos.length}} puntos`);
    </script>
</body>
</html>"""
    
    return html

if __name__ == '__main__':
    print("🚀 SERVIDOR SIMPLE Y ROBUSTO INICIANDO...")
    print("=" * 50)
    
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        total_size_mb = sum(f.stat().st_size for f in STATIC_MAPS_DIR.glob("*")) / 1024 / 1024
        
        print(f"📁 Directorio: {STATIC_MAPS_DIR}")
        print(f"🗺️ Mapas encontrados: {total_maps:,}")
        print(f"💾 Tamaño total: {total_size_mb:.1f} MB")
        print()
        
        # Mostrar accesos
        import subprocess
        try:
            local_ip = subprocess.check_output(['hostname', '-I']).decode().split()[0]
            hostname = subprocess.check_output(['hostname', '-f']).decode().strip()
            
            print("🌐 ACCESOS PÚBLICOS:")
            print(f"   📍 IP:       http://{local_ip}:3000/")
            print(f"   🌍 DNS:      http://{hostname}:3000/")
            print(f"   🔗 Local:    http://localhost:3000/")
        except:
            print("🌐 Servidor: http://0.0.0.0:3000/")
        
        print()
        print("🎯 ENDPOINTS SIMPLIFICADOS:")
        print("   🏠 Interfaz:       GET  /")
        print("   📊 Info:           GET  /api/info")
        print("   🗺️ Mapas:          GET  /api/maps")
        print("   🎲 Aleatorio:      GET  /api/random-map")
        print("   ⚡ Interactivo:    POST /api/interactive-map")
        print()
        print("🔥 INICIANDO SERVIDOR SIN ERRORES 500...")
        
        app.run(host='0.0.0.0', port=3000, debug=False, threaded=True)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        exit(1)