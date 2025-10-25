#!/usr/bin/env python3
"""
Generador EXTENDIDO de mapas - Configuraciones ultra densas y especiales
Para continuar generando después de completar las configuraciones básicas.
"""

import os
import sys
import json
import math
import itertools
from datetime import datetime
import hashlib
from pathlib import Path
import gc

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

def generar_configuraciones_extendidas():
    """Generar configuraciones EXTENDIDAS y ULTRA DENSAS."""
    configuraciones = []
    
    print("🔥 Generando configuraciones EXTENDIDAS...")
    
    # CONFIGURACIONES ULTRA DENSAS - Rangos mucho más extensos
    
    # Rangos mega densos
    circulos_mega = list(range(2000, 10001, 500))    # 2000, 2500, ..., 10000
    segmentos_mega = list(range(400, 1001, 50))      # 400, 450, ..., 1000
    
    # Rangos súper extensos
    circulos_super = list(range(10000, 25001, 2500)) # 10k, 12.5k, ..., 25k
    segmentos_super = list(range(100, 501, 50))      # 100, 150, ..., 500
    
    # Rangos extremos (configuraciones especiales)
    circulos_extremos = [50000, 75000, 100000]       # Ultra extremos
    segmentos_extremos = [24, 36, 48, 60]            # Segmentos básicos para extremos
    
    # Solo mapeo lineal para ultra densidad (mejor rendimiento)
    mapeos = ['lineal']
    
    # Filtros optimizados para configuraciones grandes
    filtros_extendidos = [
        # Solo primos (más eficiente para mapas grandes)
        {'regulares': True, 'gemelos': True, 'primos': True, 'compuestos': False},
        
        # Solo tipos especiales
        {'regulares': False, 'gemelos': True, 'sexy': True, 'primos': True, 'compuestos': False},
        
        # Básico con compuestos
        {'regulares': True, 'primos': True, 'compuestos': True},
        
        # Solo números regulares
        {'regulares': True, 'compuestos': False}
    ]
    
    rangos_extendidos = [
        (circulos_mega, segmentos_mega, 'mega', 5000000),      # Hasta 5M elementos
        (circulos_super, segmentos_super, 'super', 10000000),  # Hasta 10M elementos  
        (circulos_extremos, segmentos_extremos, 'extremo', 6000000)  # Casos especiales
    ]
    
    for circulos_rango, segmentos_rango, tipo, limite_max in rangos_extendidos:
        for circulos in circulos_rango:
            for segmentos in segmentos_rango:
                for mapeo in mapeos:
                    for filtros in filtros_extendidos:
                        total_elementos = circulos * segmentos
                        
                        # Límite de seguridad ajustado por tipo
                        if total_elementos <= limite_max:
                            configuraciones.append({
                                'num_circulos': circulos,
                                'divisiones_por_circulo': segmentos,
                                'tipo_mapeo': mapeo,
                                'filtros': filtros,
                                'total_elementos': total_elementos,
                                'tipo': tipo,
                                'prioridad': 'extrema' if total_elementos > 1000000 else 'ultra'
                            })
    
    # CONFIGURACIONES ESPECIALES - Números específicos interesantes
    
    # Configuraciones con números matemáticamente significativos
    especiales = [
        # Potencias de 2
        (1024, 512), (2048, 256), (4096, 128),
        # Números primos grandes como círculos
        (1009, 360), (2003, 180), (3001, 120),
        # Fibonacci grandes
        (1597, 233), (2584, 377),
        # Configuraciones "cuadradas" 
        (3162, 316), (4472, 447),  # aprox sqrt(10M) y sqrt(20M)
    ]
    
    for circulos, segmentos in especiales:
        for filtros in filtros_extendidos[:2]:  # Solo 2 filtros para especiales
            total_elementos = circulos * segmentos
            if total_elementos <= 2000000:  # Límite más conservador
                configuraciones.append({
                    'num_circulos': circulos,
                    'divisiones_por_circulo': segmentos,
                    'tipo_mapeo': 'lineal',
                    'filtros': filtros,
                    'total_elementos': total_elementos,
                    'tipo': 'especial',
                    'prioridad': 'alta'
                })
    
    # Ordenar por tamaño (pequeños primero)
    configuraciones.sort(key=lambda x: x['total_elementos'])
    
    print(f"✅ {len(configuraciones)} configuraciones extendidas generadas")
    if configuraciones:
        print(f"📊 Rango: {min(c['total_elementos'] for c in configuraciones):,} - {max(c['total_elementos'] for c in configuraciones):,} elementos")
        
        # Estadísticas por tipo
        tipos = {}
        for config in configuraciones:
            tipo = config['tipo']
            tipos[tipo] = tipos.get(tipo, 0) + 1
        
        print("📈 Por tipo:")
        for tipo, count in tipos.items():
            print(f"   {tipo}: {count} configuraciones")
    
    return configuraciones

def generar_hash_parametros(parametros):
    """Generar hash único para combinación de parámetros."""
    param_hash = {
        'num_circulos': parametros['num_circulos'],
        'divisiones_por_circulo': parametros['divisiones_por_circulo'],
        'tipo_mapeo': parametros['tipo_mapeo'],
        'filtros': parametros['filtros']
    }
    param_str = json.dumps(param_hash, sort_keys=True)
    return hashlib.md5(param_str.encode()).hexdigest()[:12]

def verificar_mapa_existe(hash_config):
    """Verificar si ya existe un mapa con este hash."""
    output_dir = Path("static_maps")
    json_path = output_dir / f"data_{hash_config}.json"
    return json_path.exists()

def generar_datos_mapa_ultradenso(parametros):
    """Generar datos para mapa ultra denso."""
    num_circulos = parametros['num_circulos']
    divisiones_por_circulo = parametros['divisiones_por_circulo']
    tipo_mapeo = parametros['tipo_mapeo']
    filtros = parametros['filtros']
    
    total_numeros = num_circulos * divisiones_por_circulo
    
    print(f"  📊 Generando mapa ULTRA: {num_circulos:,} círculos × {divisiones_por_circulo:,} segmentos = {total_numeros:,} elementos")
    
    # Optimización extrema para mapas ultra grandes
    if total_numeros > 5000000:  # 5M+
        step = max(1, total_numeros // 10000)  # Máximo 10k puntos
        print(f"  🔥 Mapa EXTREMO detectado, usando step={step} (máx 10k puntos)")
    elif total_numeros > 1000000:  # 1M+
        step = max(1, total_numeros // 15000)  # Máximo 15k puntos
        print(f"  ⚡ Mapa MEGA detectado, usando step={step} (máx 15k puntos)")
    elif total_numeros > 500000:   # 500k+
        step = max(1, total_numeros // 25000)  # Máximo 25k puntos
    else:
        step = max(1, total_numeros // 50000)  # Máximo 50k puntos
    
    print(f"  🔢 Calculando primos hasta {total_numeros:,} (step={step})...")
    
    # Solo calcular primos hasta donde necesitamos con step
    max_numero = min(total_numeros, total_numeros // step * step + step)
    primos = criba_de_eratostenes_optimizada(max_numero)
    conjunto_primos = set(primos)
    
    # Limpiar memoria temprano
    del primos
    gc.collect()
    
    elementos = []
    procesados = 0
    
    print(f"  ⚡ Procesando elementos (objetivo: máximo {50000} puntos)...")
    
    for numero in range(1, total_numeros + 1, step):
        if procesados >= 50000:  # Límite absoluto para rendimiento
            break
            
        es_primo = numero in conjunto_primos
        
        # Filtros simplificados para ultra densidad
        if not filtros.get('compuestos', True) and not es_primo:
            continue
        if not filtros.get('primos', True) and es_primo:
            continue
            
        tipos = []
        if es_primo and filtros.get('regulares', True):
            tipos.append('regular')
        elif not es_primo and filtros.get('compuestos', True):
            tipos.append('compuesto')
        
        if not tipos:
            continue
            
        # Posición lineal simplificada
        circulo = (numero - 1) // divisiones_por_circulo
        segmento = (numero - 1) % divisiones_por_circulo
        
        # Límites de seguridad
        circulo = min(circulo, num_circulos - 1)
        segmento = min(segmento, divisiones_por_circulo - 1)
        
        elementos.append({
            'numero': numero,
            'es_primo': es_primo,
            'tipos': tipos,
            'circulo': circulo,
            'segmento': segmento
        })
        
        procesados += 1
    
    # Limpiar memoria
    del conjunto_primos
    gc.collect()
    
    print(f"  ✅ {len(elementos):,} elementos procesados de {total_numeros:,} posibles")
    
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
            'timestamp': datetime.now().isoformat(),
            'ultra_dense': True,
            'tipo': parametros.get('tipo', 'extendido')
        }
    }

def main():
    """Función principal para configuraciones extendidas."""
    print("🚀 GENERADOR DE MAPAS EXTENDIDOS - ULTRA DENSIDAD")
    print("=" * 60)
    print("📊 Configuración:")
    print("   • Círculos: 2,000-100,000")
    print("   • Segmentos: 100-1,000")
    print("   • Hasta 10,000,000 elementos por mapa")
    print("   • Configuraciones especiales matemáticas")
    print("=" * 60)
    
    # Crear directorio de salida
    output_dir = Path("static_maps")
    output_dir.mkdir(exist_ok=True)
    
    # Generar configuraciones extendidas
    configuraciones = generar_configuraciones_extendidas()
    
    if not configuraciones:
        print("ℹ️ No hay configuraciones extendidas para generar")
        return
    
    print(f"\n🚀 Iniciando generación de {len(configuraciones)} mapas extendidos...")
    
    mapas_generados = 0
    errores = 0
    
    for i, config in enumerate(configuraciones):
        print(f"\n[{i+1}/{len(configuraciones)}] Generando mapa extendido...")
        
        try:
            # Verificar si ya existe
            hash_config = generar_hash_parametros(config)
            
            if verificar_mapa_existe(hash_config):
                print(f"  ⏭️ Mapa {hash_config} ya existe, omitiendo...")
                continue
            
            # Generar datos
            datos = generar_datos_mapa_ultradenso(config)
            
            # Guardar JSON
            json_path = output_dir / f"data_{hash_config}.json"
            with open(json_path, 'w') as f:
                json.dump(datos, f, separators=(',', ':'))
            
            file_size_kb = json_path.stat().st_size / 1024
            file_size_mb = file_size_kb / 1024
            print(f"  💾 Guardado: {hash_config} ({file_size_mb:.1f} MB)")
            
            mapas_generados += 1
            
            # Limpiar memoria cada 5 mapas
            if mapas_generados % 5 == 0:
                gc.collect()
                print(f"  🧹 Memoria limpiada - {mapas_generados} mapas generados")
            
        except Exception as e:
            errores += 1
            print(f"  ❌ Error generando mapa: {e}")
            
            if errores > 10:
                print("⚠️ Demasiados errores, deteniendo...")
                break
    
    # Finalización
    try:
        total_maps = len(list(output_dir.glob("data_*.json")))
        index_data = {
            "maps": [],
            "total_count": total_maps,
            "generated_at": datetime.now().isoformat(),
            "extended_maps_added": mapas_generados,
            "version": "3.0-extended"
        }
        
        with open(output_dir / "index.json", 'w') as f:
            json.dump(index_data, f, indent=2)
        
        print(f"\n✅ Índice actualizado: {total_maps} mapas totales")
        
    except Exception as e:
        print(f"⚠️ Error actualizando índice: {e}")
    
    print(f"\n🔥 GENERACIÓN EXTENDIDA COMPLETADA")
    print(f"✅ {mapas_generados} mapas extendidos generados")
    print(f"❌ {errores} errores encontrados")
    print(f"📁 Directorio: {output_dir}")
    print(f"💾 Tamaño total: {sum(f.stat().st_size for f in output_dir.glob('*')) / 1024 / 1024:.1f} MB")

if __name__ == "__main__":
    main()