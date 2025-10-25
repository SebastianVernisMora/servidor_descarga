#!/usr/bin/env python3
"""
Pre-generador de mapas estáticos de ALTA RESOLUCIÓN.
Genera mapas con más de 360 segmentos y 1,000 círculos.
Parámetros superiores para visualizaciones extremas.
"""

import os
import json
import math
import itertools
from datetime import datetime
import hashlib
from pathlib import Path
import sys

def criba_de_eratostenes_optimizada(n):
    """Criba de Eratóstenes optimizada para grandes números."""
    if n < 2:
        return []
    
    print(f"   🔢 Generando primos hasta {n:,}...")
    sieve = [True] * (n + 1)
    sieve[0] = sieve[1] = False
    
    sqrt_n = int(n**0.5) + 1
    for i in range(2, sqrt_n):
        if sieve[i]:
            for j in range(i*i, n + 1, i):
                sieve[j] = False
    
    primos = [i for i in range(2, n + 1) if sieve[i]]
    print(f"   ✅ {len(primos):,} primos encontrados")
    return primos

def calcular_posicion(numero, total_numeros, num_circulos, divisiones_por_circulo, tipo_mapeo):
    """Calcular posición según tipo de mapeo."""
    if tipo_mapeo == 'lineal':
        circulo = min((numero - 1) // divisiones_por_circulo, num_circulos - 1)
        segmento = (numero - 1) % divisiones_por_circulo
    elif tipo_mapeo == 'logaritmico':
        if total_numeros > 1:
            pos_log = math.log(numero) / math.log(total_numeros)
            pos_total = int(pos_log * num_circulos * divisiones_por_circulo)
            circulo = min(pos_total // divisiones_por_circulo, num_circulos - 1)
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
        circulo = min((numero - 1) // divisiones_por_circulo, num_circulos - 1)
        segmento = (numero - 1) % divisiones_por_circulo
    
    return circulo, segmento

def analizar_patrones_primos(primos, max_analisis=50000):
    """Analizar patrones en lista de primos (limitado para performance)."""
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
    
    print(f"   🔍 Analizando patrones en {len(primos):,} primos...")
    
    # Limitar análisis para números muy grandes
    primos_a_analizar = primos[:max_analisis] if len(primos) > max_analisis else primos
    
    for i, primo in enumerate(primos_a_analizar):
        if i % 10000 == 0 and i > 0:
            print(f"     📊 Procesando primo #{i:,}")
            
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
            
        # Mersenne (verificación más completa)
        temp = primo + 1
        p = 0
        while temp > 1 and temp % 2 == 0:
            temp //= 2
            p += 1
        if temp == 1 and p in conjunto_primos and p > 1:
            patrones['mersenne'].append(primo)
            
        # Fermat (casos conocidos)
        if primo in [3, 5, 17, 257, 65537]:
            patrones['fermat'].append(primo)
    
    print(f"   ✅ Patrones encontrados: Gemelos={len(patrones['gemelos'])}, Sophie={len(patrones['sophie_germain'])}")
    return patrones

def generar_datos_alta_resolucion(num_circulos, divisiones_por_circulo, tipo_mapeo, max_elementos=100000):
    """Generar datos optimizados para alta resolución."""
    total_numeros = num_circulos * divisiones_por_circulo
    
    print(f"   📐 Rango total: 1 - {total_numeros:,} números")
    
    # Generar primos
    primos = criba_de_eratostenes_optimizada(total_numeros)
    conjunto_primos = set(primos)
    
    # Analizar patrones
    patrones = analizar_patrones_primos(primos)
    
    # Filtros optimizados para alta resolución
    filtros_tipos = {
        'regulares': True,
        'gemelos': True,
        'primos': True,
        'sexy': True,
        'sophie_germain': True,
        'palindromicos': True,
        'mersenne': True,
        'fermat': True,
        'compuestos': False  # Omitir compuestos para reducir tamaño
    }
    
    elementos = []
    
    print(f"   🎨 Generando elementos del mapa...")
    
    # Muestreo inteligente para mapas muy grandes
    if total_numeros > max_elementos:
        print(f"   ⚡ Muestreo inteligente: {max_elementos:,} de {total_numeros:,} números")
        step = total_numeros // max_elementos
        numeros_a_procesar = range(1, total_numeros + 1, step)
    else:
        numeros_a_procesar = range(1, total_numeros + 1)
    
    for i, numero in enumerate(numeros_a_procesar):
        if i % 10000 == 0 and i > 0:
            print(f"     🔄 Procesando elemento #{i:,}")
            
        es_primo = numero in conjunto_primos
        
        # Determinar tipos
        tipos = []
        
        if es_primo:
            if numero in patrones['gemelos']:
                tipos.append('gemelo')
            if numero in patrones['primos']:
                tipos.append('primo')
            if numero in patrones['sexy']:
                tipos.append('sexy')
            if numero in patrones['sophie_germain']:
                tipos.append('sophie_germain')
            if numero in patrones['palindromicos']:
                tipos.append('palindromico')
            if numero in patrones['mersenne']:
                tipos.append('mersenne')
            if numero in patrones['fermat']:
                tipos.append('fermat')
                
            if not tipos:
                tipos.append('regular')
        
        # Solo incluir primos en alta resolución
        if tipos:
            # Calcular posición
            circulo, segmento = calcular_posicion(numero, total_numeros, num_circulos, divisiones_por_circulo, tipo_mapeo)
            
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
        'elementos_muestreados': len(elementos),
        'factor_muestreo': total_numeros / len(elementos) if len(elementos) > 0 else 1,
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
    
    print(f"   ✅ Generados {len(elementos):,} elementos de {total_numeros:,} números")
    return elementos, estadisticas

def generar_parametros_alta_resolucion():
    """Definir combinaciones de parámetros de ALTA RESOLUCIÓN."""
    
    print("🎯 Configurando parámetros de ALTA RESOLUCIÓN...")
    print("   Criterios: >360 segmentos Y >1,000 círculos")
    print()
    
    # Parámetros de alta resolución
    circulos_opciones = [1000, 1500, 2000, 2500, 3000, 4000, 5000]  # >1,000
    segmentos_opciones = [400, 500, 600, 800, 1000, 1200, 1300]      # >360
    mapeos_opciones = ['lineal', 'logaritmico', 'arquimedes']         # Mapeos principales
    
    combinaciones = []
    
    for num_circulos in circulos_opciones:
        for divisiones in segmentos_opciones:
            for mapeo in mapeos_opciones:
                # Filtrar combinaciones excesivamente grandes
                total_numeros = num_circulos * divisiones
                if total_numeros <= 15_000_000:  # Máximo 15M números
                    combinaciones.append({
                        'num_circulos': num_circulos,
                        'divisiones_por_circulo': divisiones,
                        'tipo_mapeo': mapeo,
                        'total_numeros': total_numeros
                    })
    
    # Ordenar por tamaño total
    combinaciones.sort(key=lambda x: x['total_numeros'])
    
    print(f"📊 Combinaciones de alta resolución: {len(combinaciones)}")
    for i, combo in enumerate(combinaciones[:5]):
        print(f"   {i+1}. {combo['num_circulos']}×{combo['divisiones_por_circulo']} = {combo['total_numeros']:,} números ({combo['tipo_mapeo']})")
    if len(combinaciones) > 5:
        print(f"   ... y {len(combinaciones)-5} más")
    print()
    
    return combinaciones

def generar_hash_parametros(parametros):
    """Generar hash único para combinación de parámetros."""
    param_str = json.dumps({
        'circulos': parametros['num_circulos'],
        'segmentos': parametros['divisiones_por_circulo'],
        'mapeo': parametros['tipo_mapeo']
    }, sort_keys=True)
    return hashlib.md5(param_str.encode()).hexdigest()[:12]

def pre_generar_alta_resolucion():
    """Función principal de pre-generación de alta resolución."""
    
    print("🚀 PRE-GENERACIÓN DE ALTA RESOLUCIÓN")
    print("=" * 60)
    print("Generando mapas estáticos con >360 segmentos y >1,000 círculos")
    print()
    
    # Crear directorio de salida
    output_dir = Path("static_maps_hires")
    output_dir.mkdir(exist_ok=True)
    
    # Generar índice de mapas
    indice_mapas = {}
    
    # Obtener combinaciones de parámetros de alta resolución
    combinaciones = generar_parametros_alta_resolucion()
    
    print(f"⚡ Iniciando generación de {len(combinaciones)} mapas de alta resolución...")
    print()
    
    for i, parametros in enumerate(combinaciones, 1):
        try:
            print(f"🎨 [{i}/{len(combinaciones)}] Generando: {parametros['num_circulos']:,}×{parametros['divisiones_por_circulo']:,} ({parametros['tipo_mapeo']})")
            print(f"    📊 Total números: {parametros['total_numeros']:,}")
            
            inicio = datetime.now()
            
            # Generar elementos y estadísticas
            elementos, estadisticas = generar_datos_alta_resolucion(
                parametros['num_circulos'],
                parametros['divisiones_por_circulo'], 
                parametros['tipo_mapeo']
            )
            
            tiempo_generacion = (datetime.now() - inicio).total_seconds()
            
            # Crear nombre de archivo único
            param_hash = generar_hash_parametros(parametros)
            
            # Guardar solo datos JSON (HTML sería demasiado pesado)
            json_filename = f"hires_{param_hash}.json"
            json_filepath = output_dir / json_filename
            
            data_completa = {
                'elementos': elementos,
                'estadisticas': estadisticas,
                'parametros': parametros,
                'metadata': {
                    'generated': datetime.now().isoformat(),
                    'generation_time_seconds': tiempo_generacion,
                    'file_type': 'high_resolution',
                    'version': '1.0'
                }
            }
            
            with open(json_filepath, 'w', encoding='utf-8') as f:
                json.dump(data_completa, f, indent=2)
            
            file_size_mb = os.path.getsize(json_filepath) / (1024 * 1024)
            
            # Agregar al índice
            indice_mapas[param_hash] = {
                'parametros': parametros,
                'json_file': json_filename,
                'elementos_count': len(elementos),
                'primos_count': estadisticas['total_primos'],
                'densidad': estadisticas['densidad_primos'],
                'file_size_mb': round(file_size_mb, 2),
                'generation_time': round(tiempo_generacion, 2),
                'generated': datetime.now().isoformat()
            }
            
            print(f"    ✅ {len(elementos):,} elementos | {estadisticas['total_primos']:,} primos | {file_size_mb:.1f}MB | {tiempo_generacion:.1f}s")
            print()
            
        except Exception as e:
            print(f"    ❌ Error: {str(e)}")
            print()
            continue
    
    # Guardar índice principal
    indice_filepath = output_dir / "index_hires.json"
    with open(indice_filepath, 'w', encoding='utf-8') as f:
        json.dump({
            'metadata': {
                'generated': datetime.now().isoformat(),
                'total_maps': len(indice_mapas),
                'criteria': '>360 segmentos AND >1,000 círculos',
                'file_type': 'high_resolution_index',
                'version': '1.0'
            },
            'summary': {
                'total_elements': sum(info['elementos_count'] for info in indice_mapas.values()),
                'total_primos': sum(info['primos_count'] for info in indice_mapas.values()),
                'total_size_mb': sum(info['file_size_mb'] for info in indice_mapas.values()),
                'avg_generation_time': sum(info['generation_time'] for info in indice_mapas.values()) / len(indice_mapas) if indice_mapas else 0
            },
            'maps': indice_mapas
        }, f, indent=2)
    
    # Crear página de índice HTML optimizada
    crear_indice_alta_resolucion(output_dir, indice_mapas)
    
    print("🎉 PRE-GENERACIÓN DE ALTA RESOLUCIÓN COMPLETADA!")
    print("=" * 60)
    print(f"📁 Directorio: {output_dir.absolute()}")
    print(f"📊 Mapas generados: {len(indice_mapas)}")
    print(f"🔢 Elementos totales: {sum(info['elementos_count'] for info in indice_mapas.values()):,}")
    print(f"🔢 Primos totales: {sum(info['primos_count'] for info in indice_mapas.values()):,}")
    print(f"💾 Tamaño total: {sum(info['file_size_mb'] for info in indice_mapas.values()):.1f}MB")
    print(f"⏱️  Tiempo promedio: {sum(info['generation_time'] for info in indice_mapas.values()) / len(indice_mapas):.1f}s por mapa")
    print(f"🌐 Índice disponible: {indice_filepath}")
    print()
    print("🚀 Para servir estos mapas, usa el endpoint /api/hires-map/<hash>")
    
    return indice_mapas

def crear_indice_alta_resolucion(output_dir, indice_mapas):
    """Crear página HTML de índice para mapas de alta resolución."""
    
    mapas_html = ""
    for param_hash, info in indice_mapas.items():
        param = info['parametros']
        mapas_html += f"""
        <div class="map-card" data-hash="{param_hash}">
            <div class="map-header">
                <div class="map-title">{param['num_circulos']:,}×{param['divisiones_por_circulo']:,}</div>
                <div class="map-type">{param['tipo_mapeo'].title()}</div>
            </div>
            <div class="map-stats">
                <div class="stat"><span>📊</span> {info['elementos_count']:,} elementos</div>
                <div class="stat"><span>🔢</span> {info['primos_count']:,} primos</div>
                <div class="stat"><span>📈</span> {info['densidad']:.2f}% densidad</div>
                <div class="stat"><span>💾</span> {info['file_size_mb']:.1f}MB</div>
                <div class="stat"><span>⏱️</span> {info['generation_time']:.1f}s generación</div>
            </div>
            <div class="map-actions">
                <button onclick="loadMap('{param_hash}')" class="load-btn">
                    <i class="fas fa-eye"></i> Ver Datos
                </button>
                <button onclick="downloadMap('{param_hash}')" class="download-btn">
                    <i class="fas fa-download"></i> Descargar JSON
                </button>
            </div>
        </div>"""
    
    html_indice = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mapas de Alta Resolución Pre-generados</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
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
            padding: 3rem 2rem;
            background: rgba(0,0,0,0.4);
            backdrop-filter: blur(10px);
        }}
        .title {{
            font-size: 3rem;
            margin-bottom: 1rem;
            background: linear-gradient(45deg, #FFD700, #FF6B9D, #00FFFF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-weight: 900;
        }}
        .subtitle {{
            font-size: 1.2rem;
            opacity: 0.8;
            margin-bottom: 2rem;
        }}
        .criteria {{
            background: rgba(255, 215, 0, 0.1);
            padding: 1rem 2rem;
            border-radius: 10px;
            border: 2px solid #FFD700;
            display: inline-block;
            font-weight: 600;
        }}
        .summary-stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 2rem;
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }}
        .summary-stat {{
            text-align: center;
            padding: 2rem;
            background: rgba(255,255,255,0.1);
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }}
        .summary-number {{
            font-size: 2.5rem;
            font-weight: 900;
            color: #FFD700;
            margin-bottom: 0.5rem;
        }}
        .maps-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 2rem;
            padding: 2rem;
            max-width: 1600px;
            margin: 0 auto;
        }}
        .map-card {{
            background: rgba(255,255,255,0.05);
            padding: 2rem;
            border-radius: 20px;
            border: 2px solid rgba(255,255,255,0.1);
            transition: all 0.3s ease;
            backdrop-filter: blur(5px);
        }}
        .map-card:hover {{
            transform: translateY(-5px);
            border-color: #FFD700;
            box-shadow: 0 15px 40px rgba(255, 215, 0, 0.2);
        }}
        .map-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }}
        .map-title {{
            font-size: 1.5rem;
            font-weight: 900;
            color: #FFD700;
        }}
        .map-type {{
            background: rgba(102, 126, 234, 0.8);
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: 600;
            text-transform: uppercase;
        }}
        .map-stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 0.75rem;
            margin-bottom: 2rem;
        }}
        .stat {{
            background: rgba(255,255,255,0.05);
            padding: 0.75rem;
            border-radius: 8px;
            font-size: 0.9rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }}
        .stat span {{
            font-size: 1rem;
        }}
        .map-actions {{
            display: flex;
            gap: 1rem;
        }}
        .load-btn, .download-btn {{
            flex: 1;
            padding: 1rem;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
        }}
        .load-btn {{
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }}
        .download-btn {{
            background: linear-gradient(135deg, #FF6B9D, #C44569);
            color: white;
        }}
        .load-btn:hover, .download-btn:hover {{
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(0,0,0,0.3);
        }}
        @media (max-width: 768px) {{
            .maps-grid {{ grid-template-columns: 1fr; }}
            .summary-stats {{ grid-template-columns: repeat(2, 1fr); }}
            .title {{ font-size: 2rem; }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">Mapas de Alta Resolución</div>
        <div class="subtitle">Números Primos Pre-generados</div>
        <div class="criteria">
            <i class="fas fa-trophy"></i>
            Criterio: &gt;360 segmentos Y &gt;1,000 círculos
        </div>
    </div>
    
    <div class="summary-stats">
        <div class="summary-stat">
            <div class="summary-number">{len(indice_mapas)}</div>
            <div>Mapas Generados</div>
        </div>
        <div class="summary-stat">
            <div class="summary-number">{sum(info['elementos_count'] for info in indice_mapas.values()):,}</div>
            <div>Elementos Totales</div>
        </div>
        <div class="summary-stat">
            <div class="summary-number">{sum(info['primos_count'] for info in indice_mapas.values()):,}</div>
            <div>Primos Totales</div>
        </div>
        <div class="summary-stat">
            <div class="summary-number">{sum(info['file_size_mb'] for info in indice_mapas.values()):.0f}MB</div>
            <div>Tamaño Total</div>
        </div>
    </div>
    
    <div class="maps-grid">
        {mapas_html}
    </div>
    
    <script>
        function loadMap(hash) {{
            // Mostrar datos del mapa en una nueva ventana
            const url = `/api/hires-map/${{hash}}`;
            window.open(url, '_blank');
        }}
        
        function downloadMap(hash) {{
            // Descargar archivo JSON directamente
            const link = document.createElement('a');
            link.href = `hires_${{hash}}.json`;
            link.download = `hires_map_${{hash}}.json`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }}
        
        console.log('📊 Mapas de alta resolución cargados:', {len(indice_mapas)});
    </script>
</body>
</html>"""
    
    with open(output_dir / "index.html", 'w', encoding='utf-8') as f:
        f.write(html_indice)

if __name__ == "__main__":
    try:
        indice_mapas = pre_generar_alta_resolucion()
        print("\n🎯 Pre-generación completada exitosamente!")
        print("Los mapas están listos para servirse con la aplicación estática.")
    except KeyboardInterrupt:
        print("\n⚠️  Pre-generación cancelada por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error durante la pre-generación: {e}")
        sys.exit(1)