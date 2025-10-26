#!/usr/bin/env python3
"""
Generador de mapas estáticos de ALTA DENSIDAD
Desde 1000 círculos y 360 segmentos con saltos de 100 círculos y 10 segmentos.
"""

import os
import sys
import json
import math
import itertools
from datetime import datetime
import hashlib
from pathlib import Path

# Reutilizar funciones del generador original
sys.path.append('/home/admin/servidor_descarga')

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

def calcular_posicion(numero, total_numeros, num_circulos, divisiones_por_circulo, tipo_mapeo='lineal'):
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
    else:
        # Default a lineal para mapas densos
        circulo = (numero - 1) // divisiones_por_circulo
        segmento = (numero - 1) % divisiones_por_circulo
    
    # Asegurar límites
    circulo = min(circulo, num_circulos - 1)
    segmento = min(segmento, divisiones_por_circulo - 1)
    
    return circulo, segmento

def generar_configuraciones_densas():
    """Generar configuraciones de alta densidad."""
    configuraciones = []
    
    # CONFIGURACIONES DE ALTA DENSIDAD
    # Desde 1000 círculos, saltos de 100
    # Desde 360 segmentos, saltos de 10
    
    print("🔥 Generando configuraciones de ALTA DENSIDAD...")
    
    # Rangos densos
    circulos_densos = list(range(1000, 2001, 100))  # 1000, 1100, 1200, ..., 2000
    segmentos_densos = list(range(360, 401, 10))    # 360, 370, 380, 390, 400
    
    # Solo mapeo lineal para mapas densos (mejor rendimiento)
    mapeos_densos = ['lineal']
    
    # Filtros optimizados para alta densidad
    filtros_densos = [
        {'regulares': True, 'gemelos': True, 'primos': True, 'compuestos': False},  # Solo primos
        {'regulares': True, 'gemelos': True, 'primos': True, 'compuestos': True},   # Completo básico
    ]
    
    for circulos in circulos_densos:
        for segmentos in segmentos_densos:
            for mapeo in mapeos_densos:
                for filtros in filtros_densos:
                    total_elementos = circulos * segmentos
                    
                    # Limitar a máximo 1M elementos por rendimiento
                    if total_elementos <= 1000000:  
                        configuraciones.append({
                            'num_circulos': circulos,
                            'divisiones_por_circulo': segmentos,
                            'tipo_mapeo': mapeo,
                            'filtros': filtros,
                            'total_elementos': total_elementos
                        })
    
    print(f"✅ {len(configuraciones)} configuraciones densas generadas")
    print(f"📊 Rango de elementos: {min(c['total_elementos'] for c in configuraciones):,} - {max(c['total_elementos'] for c in configuraciones):,}")
    
    return configuraciones

def generar_datos_mapa_denso(parametros):
    """Generar datos para mapa denso optimizado."""
    num_circulos = parametros['num_circulos']
    divisiones_por_circulo = parametros['divisiones_por_circulo']
    tipo_mapeo = parametros['tipo_mapeo']
    filtros = parametros['filtros']
    
    total_numeros = num_circulos * divisiones_por_circulo
    
    print(f"  📊 Generando mapa: {num_circulos} círculos × {divisiones_por_circulo} segmentos = {total_numeros:,} elementos")
    
    # Optimización: Solo calcular primos hasta el total necesario
    print(f"  🔢 Calculando primos hasta {total_numeros:,}...")
    primos = criba_de_eratostenes_optimizada(total_numeros)
    conjunto_primos = set(primos)
    
    # Identificar tipos de primos
    gemelos = set()
    for p in primos:
        if p + 2 in conjunto_primos:
            gemelos.add(p)
            gemelos.add(p + 2)
    
    elementos = []
    
    # Optimización: Solo procesar cada 10º número en mapas muy grandes
    step = max(1, total_numeros // 50000)  # Máximo 50k puntos por mapa
    
    print(f"  ⚡ Procesando elementos (step={step})...")
    
    for numero in range(1, total_numeros + 1, step):
        es_primo = numero in conjunto_primos
        
        if not filtros.get('compuestos', True) and not es_primo:
            continue
        if not filtros.get('primos', True) and es_primo:
            continue
            
        tipos = []
        if es_primo:
            if filtros.get('regulares', True):
                tipos.append('regular')
            if filtros.get('gemelos', True) and numero in gemelos:
                tipos.append('gemelo')
        else:
            tipos.append('compuesto')
        
        if not tipos:
            continue
            
        circulo, segmento = calcular_posicion(numero, total_numeros, num_circulos, divisiones_por_circulo, tipo_mapeo)
        
        elementos.append({
            'numero': numero,
            'es_primo': es_primo,
            'tipos': tipos,
            'circulo': circulo,
            'segmento': segmento
        })
    
    print(f"  ✅ {len(elementos):,} elementos procesados")
    
    return {
        'elementos': elementos,
        'metadata': {
            'num_circulos': num_circulos,
            'divisiones_por_circulo': divisiones_por_circulo,
            'tipo_mapeo': tipo_mapeo,
            'filtros': filtros,
            'total_numeros': total_numeros,
            'elementos_renderizados': len(elementos),
            'step': step,
            'timestamp': datetime.now().isoformat()
        }
    }

def generar_hash_parametros(parametros):
    """Generar hash único para combinación de parámetros."""
    # Solo usar parámetros relevantes para el hash
    param_hash = {
        'num_circulos': parametros['num_circulos'],
        'divisiones_por_circulo': parametros['divisiones_por_circulo'],
        'tipo_mapeo': parametros['tipo_mapeo'],
        'filtros': parametros['filtros']
    }
    param_str = json.dumps(param_hash, sort_keys=True)
    return hashlib.md5(param_str.encode()).hexdigest()[:12]

def main():
    """Función principal."""
    print("🔥 GENERADOR DE MAPAS ESTÁTICOS DE ALTA DENSIDAD")
    print("=" * 60)
    print("📊 Configuración:")
    print("   • Círculos: 1000-2000 (saltos de 100)")
    print("   • Segmentos: 360-400 (saltos de 10)")
    print("   • Hasta 1,000,000 elementos por mapa")
    print("=" * 60)
    
    # Crear directorio de salida
    output_dir = Path("static_maps")
    output_dir.mkdir(exist_ok=True)
    
    # Generar configuraciones
    configuraciones = generar_configuraciones_densas()
    
    print(f"\n🚀 Iniciando generación de {len(configuraciones)} mapas densos...")
    
    mapas_generados = 0
    
    for i, config in enumerate(configuraciones):
        print(f"\n[{i+1}/{len(configuraciones)}] Generando mapa denso...")
        
        try:
            # Generar datos
            datos = generar_datos_mapa_denso(config)
            
            # Generar hash
            hash_config = generar_hash_parametros(config)
            
            # Guardar datos JSON
            json_path = output_dir / f"data_{hash_config}.json"
            with open(json_path, 'w') as f:
                json.dump(datos, f, separators=(',', ':'))
            
            file_size_kb = json_path.stat().st_size / 1024
            print(f"  💾 Guardado: {json_path.name} ({file_size_kb:.1f} KB)")
            
            mapas_generados += 1
            
        except Exception as e:
            print(f"  ❌ Error generando mapa: {e}")
            continue
    
    # Actualizar índice
    try:
        index_path = output_dir / "index.json"
        if index_path.exists():
            with open(index_path, 'r') as f:
                index_data = json.load(f)
        else:
            index_data = {"maps": [], "total_count": 0, "version": "1.0"}
        
        # Actualizar contadores
        index_data["total_count"] = len(list(output_dir.glob("data_*.json")))
        index_data["generated_at"] = datetime.now().isoformat()
        index_data["dense_maps_added"] = mapas_generados
        
        with open(index_path, 'w') as f:
            json.dump(index_data, f, indent=2)
        
        print(f"\n✅ Índice actualizado: {index_data['total_count']} mapas totales")
        
    except Exception as e:
        print(f"⚠️ Error actualizando índice: {e}")
    
    print(f"\n🔥 GENERACIÓN COMPLETADA")
    print(f"✅ {mapas_generados} mapas densos generados exitosamente")
    print(f"📁 Directorio: {output_dir}")
    print(f"💾 Tamaño total: {sum(f.stat().st_size for f in output_dir.glob('*')) / 1024 / 1024:.1f} MB")

if __name__ == "__main__":
    main()