#!/usr/bin/env python3
"""
Pre-generador de mapas estáticos HTML para todas las combinaciones de parámetros.
Genera archivos HTML estáticos con mapas pre-calculados para servir directamente.
"""

import os
import json
import math
import itertools
from datetime import datetime
import hashlib
from pathlib import Path

def criba_de_eratostenes_optimizada(n):
    """Criba de Eratóstenes optimizada."""
    if n < 2:
        return []
    
    sieve = [True] * (n + 1)
    sieve[0] = sieve[1] = False
    
    for i in range(2, int(n**0.5) + 1):
        if sieve[i]:
            for j in range(i*i, n + 1, i):
                sieve[j] = False
    
    return [i for i in range(2, n + 1) if sieve[i]]

def calcular_posicion(numero, total_numeros, num_circulos, divisiones_por_circulo, tipo_mapeo):
    """Calcular posición según tipo de mapeo."""
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
    
    return circulo, segmento

def analizar_patrones_primos(primos):
    """Analizar patrones en lista de primos."""
    conjunto_primos = set(primos)
    patrones = {
        'gemelos': [],
        'primos': [],
        'sexy': [],
        'sophie_germain': [],
        'palindromicos': [],
        'mersenne': [],
        'fermat': []
    }
    
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
            
        # Mersenne (casos pequeños conocidos)
        if primo in [3, 7, 31, 127, 8191]:
            patrones['mersenne'].append(primo)
            
        # Fermat (casos conocidos)
        if primo in [3, 5, 17, 257, 65537]:
            patrones['fermat'].append(primo)
    
    return patrones

def generar_elementos_mapa(num_circulos, divisiones_por_circulo, tipo_mapeo, filtros_tipos):
    """Generar elementos del mapa con tipos clasificados."""
    total_numeros = num_circulos * divisiones_por_circulo
    
    # Generar primos
    primos = criba_de_eratostenes_optimizada(total_numeros)
    conjunto_primos = set(primos)
    
    # Analizar patrones
    patrones = analizar_patrones_primos(primos)
    
    elementos = []
    
    for numero in range(1, total_numeros + 1):
        es_primo = numero in conjunto_primos
        
        # Determinar tipos
        tipos = []
        
        if es_primo:
            if numero in patrones['gemelos'] and filtros_tipos.get('gemelos', False):
                tipos.append('gemelo')
            if numero in patrones['primos'] and filtros_tipos.get('primos', False):
                tipos.append('primo')
            if numero in patrones['sexy'] and filtros_tipos.get('sexy', False):
                tipos.append('sexy')
            if numero in patrones['sophie_germain'] and filtros_tipos.get('sophie_germain', False):
                tipos.append('sophie_germain')
            if numero in patrones['palindromicos'] and filtros_tipos.get('palindromicos', False):
                tipos.append('palindromico')
            if numero in patrones['mersenne'] and filtros_tipos.get('mersenne', False):
                tipos.append('mersenne')
            if numero in patrones['fermat'] and filtros_tipos.get('fermat', False):
                tipos.append('fermat')
                
            if not tipos and filtros_tipos.get('regulares', True):
                tipos.append('regular')
        else:
            if filtros_tipos.get('compuestos', True):
                tipos.append('compuesto')
        
        # Calcular posición
        circulo, segmento = calcular_posicion(numero, total_numeros, num_circulos, divisiones_por_circulo, tipo_mapeo)
        
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
    
    return elementos, estadisticas

def generar_html_estatico(elementos, estadisticas, parametros):
    """Generar HTML estático pre-renderizado."""
    
    html_template = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mapa Primos Pre-generado - {parametros['num_circulos']}x{parametros['divisiones_por_circulo']}</title>
    
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        
        :root {{
            --primary-color: #667eea;
            --secondary-color: #764ba2;
            --accent-color: #FFD700;
            --bg-dark: rgba(0, 0, 0, 0.9);
            --prime-regular: #4D96FF;
            --prime-twin: #FF0000;
            --prime-cousin: #FF8C00;
            --prime-sexy: #FF1493;
            --prime-sophie: #9400D3;
            --prime-palindromic: #FFD700;
            --prime-mersenne: #00FFFF;
            --prime-fermat: #ADFF2F;
            --composite: #404040;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            min-height: 100vh;
            color: white;
        }}
        
        .header {{
            background: var(--bg-dark);
            padding: 1rem 2rem;
            text-align: center;
            border-bottom: 2px solid var(--accent-color);
        }}
        
        .title {{
            font-size: 1.8rem;
            font-weight: bold;
            background: linear-gradient(45deg, var(--accent-color), #FF6B9D, #00FFFF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.5rem;
        }}
        
        .subtitle {{
            opacity: 0.8;
            font-size: 0.9rem;
        }}
        
        .container {{
            display: flex;
            height: calc(100vh - 120px);
            gap: 1rem;
            padding: 1rem;
        }}
        
        .info-panel {{
            width: 300px;
            background: rgba(255, 255, 255, 0.1);
            padding: 1.5rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            overflow-y: auto;
        }}
        
        .map-panel {{
            flex: 1;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            position: relative;
            overflow: hidden;
        }}
        
        .interactive-map {{
            width: 100%;
            height: 100%;
            position: relative;
            background: radial-gradient(ellipse at center, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            overflow: hidden;
            cursor: crosshair;
        }}
        
        .prime-map-container {{
            width: 100%;
            height: 100%;
            position: relative;
            transform-origin: center center;
            transition: transform 0.4s ease;
        }}
        
        .prime-element {{
            position: absolute;
            border-radius: 50%;
            cursor: pointer;
            transition: all 0.2s ease;
            border: 2px solid rgba(255,255,255,0.1);
            z-index: 10;
        }}
        
        .prime-element:hover {{
            transform: scale(3);
            z-index: 100;
            border-width: 3px;
            filter: brightness(1.4) saturate(1.3);
            box-shadow: 0 0 20px rgba(255,255,255,0.8);
        }}
        
        /* Tipos de números */
        .prime-element.compuesto {{ background: var(--composite); opacity: 0.4; }}
        .prime-element.regular {{ background: var(--prime-regular); box-shadow: 0 0 6px rgba(77, 150, 255, 0.4); }}
        .prime-element.gemelo {{ background: var(--prime-twin); box-shadow: 0 0 12px rgba(255, 0, 0, 0.6); }}
        .prime-element.primo {{ background: var(--prime-cousin); box-shadow: 0 0 8px rgba(255, 140, 0, 0.5); }}
        .prime-element.sexy {{ background: var(--prime-sexy); box-shadow: 0 0 10px rgba(255, 20, 147, 0.5); }}
        .prime-element.sophie_germain {{ background: var(--prime-sophie); box-shadow: 0 0 12px rgba(148, 0, 211, 0.6); }}
        .prime-element.palindromico {{ background: var(--prime-palindromic); box-shadow: 0 0 15px rgba(255, 215, 0, 0.8); }}
        .prime-element.mersenne {{ background: var(--prime-mersenne); box-shadow: 0 0 20px rgba(0, 255, 255, 1); }}
        .prime-element.fermat {{ background: var(--prime-fermat); box-shadow: 0 0 18px rgba(173, 255, 47, 0.9); }}
        .prime-element.multiple-types {{ 
            background: linear-gradient(45deg, var(--prime-twin), var(--prime-mersenne), var(--prime-palindromic));
            box-shadow: 0 0 25px rgba(255, 255, 255, 0.9);
        }}
        
        .stats-section {{
            margin-bottom: 2rem;
        }}
        
        .stats-title {{
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--accent-color);
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }}
        
        .stats-item {{
            display: flex;
            justify-content: space-between;
            margin-bottom: 0.75rem;
            padding: 0.5rem;
            background: rgba(255,255,255,0.05);
            border-radius: 8px;
            font-size: 0.9rem;
        }}
        
        .stats-label {{ color: #cbd5e0; }}
        .stats-value {{ 
            font-weight: 700; 
            color: var(--accent-color);
        }}
        
        .tooltip {{
            position: absolute;
            background: var(--bg-dark);
            color: white;
            padding: 1rem;
            border-radius: 10px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.3);
            pointer-events: none;
            opacity: 0;
            transform: scale(0.8);
            transition: all 0.3s ease;
            z-index: 1000;
            min-width: 200px;
            backdrop-filter: blur(20px);
            border: 2px solid var(--accent-color);
        }}
        
        .tooltip.visible {{
            opacity: 1;
            transform: scale(1);
        }}
        
        .tooltip-number {{
            font-size: 1.5rem;
            font-weight: 900;
            color: var(--accent-color);
            margin-bottom: 0.5rem;
        }}
        
        .tooltip-info {{
            font-size: 0.9rem;
            line-height: 1.4;
        }}
        
        .controls {{
            position: absolute;
            top: 1rem;
            right: 1rem;
            display: flex;
            gap: 0.5rem;
        }}
        
        .control-btn {{
            padding: 0.5rem;
            background: var(--primary-color);
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 1rem;
            transition: all 0.2s ease;
        }}
        
        .control-btn:hover {{
            background: var(--secondary-color);
            transform: translateY(-1px);
        }}
        
        .generated-info {{
            position: absolute;
            bottom: 1rem;
            left: 1rem;
            font-size: 0.8rem;
            opacity: 0.6;
            background: rgba(0,0,0,0.5);
            padding: 0.5rem;
            border-radius: 5px;
        }}
        
        @media (max-width: 768px) {{
            .container {{ flex-direction: column; }}
            .info-panel {{ width: 100%; max-height: 200px; }}
            .map-panel {{ height: 60vh; }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">
            <i class="fas fa-infinity"></i>
            Mapa Pre-generado de Números Primos
        </div>
        <div class="subtitle">
            {parametros['num_circulos']} círculos × {parametros['divisiones_por_circulo']} segmentos | {parametros['tipo_mapeo'].title()} | Pre-calculado
        </div>
    </div>
    
    <div class="container">
        <div class="info-panel">
            <div class="stats-section">
                <div class="stats-title">
                    <i class="fas fa-chart-bar"></i>
                    Estadísticas
                </div>
                <div class="stats-item">
                    <span class="stats-label">Rango:</span>
                    <span class="stats-value">1 - {estadisticas['total_numeros']:,}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Total Primos:</span>
                    <span class="stats-value">{estadisticas['total_primos']:,}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Densidad:</span>
                    <span class="stats-value">{estadisticas['densidad_primos']:.2f}%</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Elementos:</span>
                    <span class="stats-value">{len(elementos):,}</span>
                </div>
            </div>
            
            <div class="stats-section">
                <div class="stats-title">
                    <i class="fas fa-atom"></i>
                    Patrones
                </div>
                <div class="stats-item">
                    <span class="stats-label">Gemelos:</span>
                    <span class="stats-value">{estadisticas['patrones']['gemelos']}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Primos:</span>
                    <span class="stats-value">{estadisticas['patrones']['primos']}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Sophie Germain:</span>
                    <span class="stats-value">{estadisticas['patrones']['sophie_germain']}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Mersenne:</span>
                    <span class="stats-value">{estadisticas['patrones']['mersenne']}</span>
                </div>
            </div>
            
            <div class="stats-section">
                <div class="stats-title">
                    <i class="fas fa-cog"></i>
                    Configuración
                </div>
                <div class="stats-item">
                    <span class="stats-label">Círculos:</span>
                    <span class="stats-value">{parametros['num_circulos']}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Segmentos:</span>
                    <span class="stats-value">{parametros['divisiones_por_circulo']}</span>
                </div>
                <div class="stats-item">
                    <span class="stats-label">Mapeo:</span>
                    <span class="stats-value">{parametros['tipo_mapeo'].title()}</span>
                </div>
            </div>
        </div>
        
        <div class="map-panel">
            <div class="controls">
                <button class="control-btn" onclick="zoomIn()">
                    <i class="fas fa-search-plus"></i>
                </button>
                <button class="control-btn" onclick="zoomOut()">
                    <i class="fas fa-search-minus"></i>
                </button>
                <button class="control-btn" onclick="resetZoom()">
                    <i class="fas fa-compress-arrows-alt"></i>
                </button>
            </div>
            
            <div class="interactive-map" id="interactive-map">
                <div class="prime-map-container" id="map-container">
                    <!-- Elementos pre-generados -->
                </div>
            </div>
            
            <div class="generated-info">
                Pre-generado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | {len(elementos):,} elementos
            </div>
        </div>
    </div>
    
    <!-- Tooltip -->
    <div class="tooltip" id="tooltip">
        <div class="tooltip-number" id="tooltip-number">2</div>
        <div class="tooltip-info" id="tooltip-info">Información matemática</div>
    </div>

    <script>
        // Datos pre-generados
        const mapData = {json.dumps({'elementos': elementos[:500], 'estadisticas': estadisticas}, indent=2)};
        
        let currentZoom = 1;
        
        // Renderizar mapa pre-generado
        function renderMap() {{
            const mapContainer = document.getElementById('map-container');
            const mapWidth = mapContainer.offsetWidth || 800;
            const mapHeight = mapContainer.offsetHeight || 600;
            const centerX = mapWidth / 2;
            const centerY = mapHeight / 2;
            const maxRadius = Math.min(centerX, centerY) - 60;
            
            mapData.elementos.forEach(elemento => {{
                const div = document.createElement('div');
                div.className = 'prime-element';
                div.dataset.number = elemento.numero;
                
                // Aplicar clases de tipo
                if (elemento.tipos && elemento.tipos.length > 0) {{
                    if (elemento.tipos.length > 1) {{
                        div.classList.add('multiple-types');
                    }} else {{
                        div.classList.add(elemento.tipos[0]);
                    }}
                }}
                
                // Posición
                const radius = elemento.posicion.radio * maxRadius;
                const angle = elemento.posicion.angulo;
                const x = centerX + radius * Math.cos(angle);
                const y = centerY + radius * Math.sin(angle);
                
                // Tamaño
                let size = Math.max(3, 8 - elemento.circulo * 0.3);
                if (elemento.tipos.includes('mersenne') || elemento.tipos.includes('fermat')) {{
                    size *= 1.5;
                }}
                
                div.style.width = `${{size}}px`;
                div.style.height = `${{size}}px`;
                div.style.left = `${{x - size/2}}px`;
                div.style.top = `${{y - size/2}}px`;
                
                // Eventos
                div.addEventListener('mouseenter', (e) => showTooltip(e, elemento));
                div.addEventListener('mouseleave', hideTooltip);
                div.addEventListener('mousemove', updateTooltipPosition);
                
                mapContainer.appendChild(div);
            }});
        }}
        
        // Tooltip
        function showTooltip(event, elemento) {{
            const tooltip = document.getElementById('tooltip');
            const tooltipNumber = document.getElementById('tooltip-number');
            const tooltipInfo = document.getElementById('tooltip-info');
            
            tooltipNumber.textContent = elemento.numero.toLocaleString();
            tooltipInfo.innerHTML = `
                <strong>${{elemento.es_primo ? 'PRIMO' : 'COMPUESTO'}}</strong><br>
                Tipos: ${{elemento.tipos.join(', ')}}<br>
                Círculo: ${{elemento.circulo + 1}}, Segmento: ${{elemento.segmento + 1}}<br>
                ${{elemento.numero % 2 === 0 ? 'Par' : 'Impar'}} • ${{elemento.numero}} ≡ ${{elemento.numero % 6}} (mod 6)
            `;
            
            updateTooltipPosition(event);
            tooltip.classList.add('visible');
        }}
        
        function hideTooltip() {{
            document.getElementById('tooltip').classList.remove('visible');
        }}
        
        function updateTooltipPosition(event) {{
            const tooltip = document.getElementById('tooltip');
            tooltip.style.left = `${{event.clientX + 20}}px`;
            tooltip.style.top = `${{event.clientY - 10}}px`;
        }}
        
        // Controles de zoom
        function zoomIn() {{
            currentZoom *= 1.3;
            if (currentZoom > 5) currentZoom = 5;
            applyZoom();
        }}
        
        function zoomOut() {{
            currentZoom *= 0.7;
            if (currentZoom < 0.3) currentZoom = 0.3;
            applyZoom();
        }}
        
        function resetZoom() {{
            currentZoom = 1;
            applyZoom();
        }}
        
        function applyZoom() {{
            const mapContainer = document.getElementById('map-container');
            mapContainer.style.transform = `scale(${{currentZoom}})`;
        }}
        
        // Inicializar
        document.addEventListener('DOMContentLoaded', function() {{
            console.log('🎨 Renderizando mapa pre-generado...');
            renderMap();
            console.log('✅ Mapa pre-generado cargado:', mapData.elementos.length, 'elementos');
        }});
    </script>
</body>
</html>"""
    
    return html_template

def generar_parametros_combinaciones():
    """Definir combinaciones de parámetros a pre-generar."""
    
    # Parámetros base
    circulos_opciones = [5, 8, 10, 12, 15, 18, 20]
    segmentos_opciones = [12, 18, 24, 30, 36, 42, 48]
    mapeos_opciones = ['lineal', 'logaritmico', 'arquimedes', 'fibonacci']
    
    # Filtros de tipos más comunes
    filtros_comunes = [
        {'regulares': True, 'gemelos': True, 'primos': True, 'compuestos': True},  # Básico
        {'regulares': True, 'gemelos': True, 'primos': True, 'sexy': True, 'compuestos': True},  # Intermedio
        {'regulares': True, 'gemelos': True, 'primos': True, 'sexy': True, 'sophie_germain': True, 'mersenne': True, 'compuestos': True},  # Completo
        {'regulares': True, 'compuestos': False},  # Solo primos regulares
        {'gemelos': True, 'compuestos': False},  # Solo gemelos
    ]
    
    combinaciones = []
    
    for num_circulos in circulos_opciones:
        for divisiones in segmentos_opciones:
            for mapeo in mapeos_opciones:
                for filtros in filtros_comunes:
                    # Limitar combinaciones para evitar archivos demasiado grandes
                    if num_circulos * divisiones <= 1000:  # Máximo 1000 números
                        combinaciones.append({
                            'num_circulos': num_circulos,
                            'divisiones_por_circulo': divisiones,
                            'tipo_mapeo': mapeo,
                            'filtros': filtros
                        })
    
    return combinaciones

def generar_hash_parametros(parametros):
    """Generar hash único para combinación de parámetros."""
    param_str = json.dumps(parametros, sort_keys=True)
    return hashlib.md5(param_str.encode()).hexdigest()[:12]

def pre_generar_mapas_estaticos():
    """Función principal de pre-generación."""
    
    print("🚀 Iniciando pre-generación de mapas estáticos...")
    print("=" * 50)
    
    # Crear directorio de salida
    output_dir = Path("static_maps")
    output_dir.mkdir(exist_ok=True)
    
    # Generar índice de mapas
    indice_mapas = {}
    
    # Obtener combinaciones de parámetros
    combinaciones = generar_parametros_combinaciones()
    
    print(f"📊 Total combinaciones a generar: {len(combinaciones)}")
    print()
    
    for i, parametros in enumerate(combinaciones, 1):
        try:
            print(f"⚡ [{i}/{len(combinaciones)}] Generando: {parametros['num_circulos']}x{parametros['divisiones_por_circulo']} ({parametros['tipo_mapeo']})")
            
            # Generar elementos y estadísticas
            elementos, estadisticas = generar_elementos_mapa(
                parametros['num_circulos'],
                parametros['divisiones_por_circulo'], 
                parametros['tipo_mapeo'],
                parametros['filtros']
            )
            
            # Generar HTML estático
            html_content = generar_html_estatico(elementos, estadisticas, parametros)
            
            # Crear nombre de archivo único
            param_hash = generar_hash_parametros(parametros)
            filename = f"map_{param_hash}.html"
            filepath = output_dir / filename
            
            # Guardar archivo HTML
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            # Guardar datos JSON por separado para la API
            json_filename = f"data_{param_hash}.json"
            json_filepath = output_dir / json_filename
            
            with open(json_filepath, 'w', encoding='utf-8') as f:
                json.dump({
                    'elementos': elementos,
                    'estadisticas': estadisticas,
                    'parametros': parametros,
                    'timestamp': datetime.now().isoformat()
                }, f, indent=2)
            
            # Agregar al índice
            indice_mapas[param_hash] = {
                'parametros': parametros,
                'html_file': filename,
                'json_file': json_filename,
                'elementos_count': len(elementos),
                'primos_count': estadisticas['total_primos'],
                'densidad': estadisticas['densidad_primos'],
                'file_size_kb': os.path.getsize(filepath) // 1024,
                'generated': datetime.now().isoformat()
            }
            
            print(f"   ✅ {len(elementos):,} elementos | {estadisticas['total_primos']} primos | {os.path.getsize(filepath)//1024}KB")
            
        except Exception as e:
            print(f"   ❌ Error: {str(e)}")
            continue
    
    # Guardar índice principal
    indice_filepath = output_dir / "index.json"
    with open(indice_filepath, 'w', encoding='utf-8') as f:
        json.dump({
            'generated': datetime.now().isoformat(),
            'total_maps': len(indice_mapas),
            'maps': indice_mapas
        }, f, indent=2)
    
    # Crear página de índice HTML
    crear_pagina_indice(output_dir, indice_mapas)
    
    print()
    print("🎉 PRE-GENERACIÓN COMPLETADA!")
    print(f"📁 Directorio: {output_dir.absolute()}")
    print(f"📊 Mapas generados: {len(indice_mapas)}")
    print(f"💾 Tamaño total: {sum(os.path.getsize(output_dir / info['html_file']) for info in indice_mapas.values()) // 1024}KB")
    print(f"🌐 Índice disponible: {indice_filepath}")
    
    return indice_mapas

def crear_pagina_indice(output_dir, indice_mapas):
    """Crear página HTML de índice de todos los mapas."""
    
    mapas_html = ""
    for param_hash, info in indice_mapas.items():
        param = info['parametros']
        mapas_html += f"""
        <div class="map-card" onclick="window.open('{info['html_file']}', '_blank')">
            <div class="map-title">{param['num_circulos']}×{param['divisiones_por_circulo']} - {param['tipo_mapeo'].title()}</div>
            <div class="map-stats">
                <div>📊 {info['elementos_count']:,} elementos</div>
                <div>🔢 {info['primos_count']} primos</div>
                <div>📈 {info['densidad']:.1f}% densidad</div>
                <div>💾 {info['file_size_kb']}KB</div>
            </div>
        </div>"""
    
    html_indice = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Índice de Mapas Pre-generados</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            min-height: 100vh;
            color: white;
        }}
        .header {{
            text-align: center;
            padding: 2rem;
            background: rgba(0,0,0,0.3);
        }}
        .title {{
            font-size: 2.5rem;
            margin-bottom: 1rem;
            background: linear-gradient(45deg, #FFD700, #FF6B9D, #00FFFF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        .stats {{
            display: flex;
            justify-content: center;
            gap: 2rem;
            margin: 2rem 0;
        }}
        .stat-item {{
            text-align: center;
            padding: 1rem;
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
        }}
        .stat-number {{
            font-size: 2rem;
            font-weight: bold;
            color: #FFD700;
        }}
        .maps-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1.5rem;
            padding: 2rem;
            max-width: 1400px;
            margin: 0 auto;
        }}
        .map-card {{
            background: rgba(255,255,255,0.1);
            padding: 1.5rem;
            border-radius: 15px;
            cursor: pointer;
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }}
        .map-card:hover {{
            transform: translateY(-5px);
            border-color: #FFD700;
            box-shadow: 0 10px 30px rgba(255, 215, 0, 0.3);
        }}
        .map-title {{
            font-size: 1.2rem;
            font-weight: bold;
            margin-bottom: 1rem;
            color: #FFD700;
        }}
        .map-stats {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.5rem;
            font-size: 0.9rem;
            opacity: 0.8;
        }}
        @media (max-width: 768px) {{
            .maps-grid {{ grid-template-columns: 1fr; }}
            .stats {{ flex-direction: column; gap: 1rem; }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">Mapas Pre-generados de Números Primos</div>
        <div class="stats">
            <div class="stat-item">
                <div class="stat-number">{len(indice_mapas)}</div>
                <div>Mapas Generados</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">{sum(info['elementos_count'] for info in indice_mapas.values()):,}</div>
                <div>Elementos Totales</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">{sum(info['file_size_kb'] for info in indice_mapas.values())}KB</div>
                <div>Tamaño Total</div>
            </div>
        </div>
    </div>
    
    <div class="maps-grid">
        {mapas_html}
    </div>
</body>
</html>"""
    
    with open(output_dir / "index.html", 'w', encoding='utf-8') as f:
        f.write(html_indice)

if __name__ == "__main__":
    indice_mapas = pre_generar_mapas_estaticos()