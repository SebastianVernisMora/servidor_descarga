#!/usr/bin/env python3
"""
Generador de mapas estáticos en segundo plano - PERSISTENTE
Similar a PM2 pero usando Python y procesos persistentes.
"""

import os
import sys
import json
import time
import math
import signal
import threading
from datetime import datetime, timedelta
from pathlib import Path
import hashlib
import gc
import traceback

# Flag global para control de ejecución
RUNNING = True
STATS = {
    'started_at': datetime.now().isoformat(),
    'maps_generated': 0,
    'errors': 0,
    'current_task': 'iniciando',
    'last_activity': datetime.now().isoformat(),
    'total_size_mb': 0
}

def signal_handler(signum, frame):
    """Manejar señales de terminación."""
    global RUNNING
    print(f"\n🛑 Señal {signum} recibida. Cerrando generador...")
    RUNNING = False

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def log_activity(message):
    """Log con timestamp."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")
    STATS['last_activity'] = datetime.now().isoformat()

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

def generar_configuraciones_completas():
    """Generar TODAS las configuraciones posibles para mapas."""
    configuraciones = []
    
    # CONFIGURACIONES EXTENSIVAS - Todas las combinaciones posibles
    
    # Rangos básicos (compatibilidad con mapas originales)
    circulos_basicos = list(range(5, 51, 5))  # 5, 10, 15, ..., 50
    segmentos_basicos = list(range(12, 61, 6))  # 12, 18, 24, ..., 60
    
    # Rangos medios
    circulos_medios = list(range(60, 201, 20))  # 60, 80, 100, ..., 200
    segmentos_medios = list(range(60, 181, 12))  # 60, 72, 84, ..., 180
    
    # Rangos altos
    circulos_altos = list(range(250, 501, 50))  # 250, 300, ..., 500
    segmentos_altos = list(range(180, 301, 30))  # 180, 210, ..., 300
    
    # Rangos súper densos
    circulos_densos = list(range(600, 1001, 100))  # 600, 700, ..., 1000
    segmentos_densos = list(range(300, 361, 30))   # 300, 330, 360
    
    # Rangos ultra densos (los ya generados + extensiones)
    circulos_ultra = list(range(1000, 3001, 200))  # 1000, 1200, ..., 3000
    segmentos_ultra = list(range(360, 501, 20))    # 360, 380, ..., 500
    
    # Mapeos disponibles
    mapeos = ['lineal', 'logaritmico', 'arquimedes', 'fibonacci']
    
    # Filtros variados
    filtros_opciones = [
        # Básicos
        {'regulares': True, 'gemelos': False, 'primos': True, 'compuestos': False},
        {'regulares': True, 'gemelos': True, 'primos': True, 'compuestos': False},
        {'regulares': True, 'gemelos': True, 'primos': True, 'compuestos': True},
        
        # Especializados
        {'regulares': False, 'gemelos': True, 'primos': True, 'compuestos': False},  # Solo gemelos
        {'regulares': True, 'gemelos': False, 'sexy': True, 'primos': True, 'compuestos': False},  # Con sexy
        {'regulares': True, 'gemelos': True, 'sophie_germain': True, 'primos': True, 'compuestos': False},  # Con Sophie
        
        # Completos
        {'regulares': True, 'gemelos': True, 'sexy': True, 'sophie_germain': True, 'mersenne': True, 'primos': True, 'compuestos': True},
        {'regulares': True, 'gemelos': True, 'palindromicos': True, 'fermat': True, 'primos': True, 'compuestos': False},
    ]
    
    rangos = [
        (circulos_basicos, segmentos_basicos, ['lineal', 'logaritmico']),
        (circulos_medios, segmentos_medios, ['lineal', 'arquimedes']),
        (circulos_altos, segmentos_altos, ['lineal']),
        (circulos_densos, segmentos_densos, ['lineal']),
        (circulos_ultra, segmentos_ultra, ['lineal'])
    ]
    
    log_activity("🔥 Generando configuraciones COMPLETAS...")
    
    for circulos_rango, segmentos_rango, mapeos_rango in rangos:
        for circulos in circulos_rango:
            for segmentos in segmentos_rango:
                for mapeo in mapeos_rango:
                    for filtros in filtros_opciones:
                        total_elementos = circulos * segmentos
                        
                        # Límite de seguridad: máximo 2M elementos
                        if total_elementos <= 2000000:
                            configuraciones.append({
                                'num_circulos': circulos,
                                'divisiones_por_circulo': segmentos,
                                'tipo_mapeo': mapeo,
                                'filtros': filtros,
                                'total_elementos': total_elementos,
                                'prioridad': 'ultra' if total_elementos > 500000 else 'alta' if total_elementos > 100000 else 'normal'
                            })
    
    # Ordenar por prioridad (más pequeños primero para generar rápidamente)
    configuraciones.sort(key=lambda x: (x['total_elementos'], x['tipo_mapeo'] != 'lineal'))
    
    log_activity(f"✅ {len(configuraciones)} configuraciones generadas")
    log_activity(f"📊 Rango: {min(c['total_elementos'] for c in configuraciones):,} - {max(c['total_elementos'] for c in configuraciones):,} elementos")
    
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

def generar_datos_mapa_optimizado(parametros):
    """Generar datos para mapa optimizado para background."""
    num_circulos = parametros['num_circulos']
    divisiones_por_circulo = parametros['divisiones_por_circulo']
    tipo_mapeo = parametros['tipo_mapeo']
    filtros = parametros['filtros']
    
    total_numeros = num_circulos * divisiones_por_circulo
    
    # Optimización agresiva para mapas grandes
    if total_numeros > 500000:
        step = max(1, total_numeros // 20000)  # Máximo 20k puntos para mapas muy grandes
    elif total_numeros > 100000:
        step = max(1, total_numeros // 50000)  # Máximo 50k puntos para mapas grandes
    else:
        step = 1  # Sin optimización para mapas pequeños
    
    # Calcular primos hasta el total necesario
    primos = criba_de_eratostenes_optimizada(total_numeros)
    conjunto_primos = set(primos)
    
    # Liberar memoria temprana
    del primos
    gc.collect()
    
    # Identificar tipos de primos básicos
    elementos = []
    
    for numero in range(1, total_numeros + 1, step):
        if not RUNNING:  # Permitir interrupción
            break
            
        es_primo = numero in conjunto_primos
        
        if not filtros.get('compuestos', True) and not es_primo:
            continue
        if not filtros.get('primos', True) and es_primo:
            continue
            
        tipos = []
        if es_primo:
            if filtros.get('regulares', True):
                tipos.append('regular')
            # Simplificar tipos para optimizar velocidad
        else:
            if filtros.get('compuestos', True):
                tipos.append('compuesto')
        
        if not tipos:
            continue
            
        # Calcular posición (solo lineal para speed)
        circulo = (numero - 1) // divisiones_por_circulo
        segmento = (numero - 1) % divisiones_por_circulo
        
        # Limites de seguridad
        circulo = min(circulo, num_circulos - 1)
        segmento = min(segmento, divisiones_por_circulo - 1)
        
        elementos.append({
            'numero': numero,
            'es_primo': es_primo,
            'tipos': tipos,
            'circulo': circulo,
            'segmento': segmento
        })
    
    # Limpiar memoria
    del conjunto_primos
    gc.collect()
    
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
            'background_generated': True
        }
    }

def guardar_estadisticas():
    """Guardar estadísticas del proceso."""
    stats_path = Path("background_generator_stats.json")
    try:
        with open(stats_path, 'w') as f:
            json.dump(STATS, f, indent=2)
    except Exception as e:
        log_activity(f"⚠️ Error guardando estadísticas: {e}")

def proceso_generador_continuo():
    """Proceso principal que genera mapas continuamente."""
    global STATS
    
    log_activity("🚀 INICIANDO GENERADOR DE MAPAS PERSISTENTE")
    log_activity("=" * 60)
    
    output_dir = Path("static_maps")
    output_dir.mkdir(exist_ok=True)
    
    # Generar todas las configuraciones
    configuraciones = generar_configuraciones_completas()
    total_configs = len(configuraciones)
    
    log_activity(f"📋 {total_configs} configuraciones en cola")
    
    mapas_generados_sesion = 0
    errores_sesion = 0
    
    for i, config in enumerate(configuraciones):
        if not RUNNING:
            log_activity("🛑 Deteniendo generador...")
            break
            
        try:
            # Verificar si ya existe
            hash_config = generar_hash_parametros(config)
            
            if verificar_mapa_existe(hash_config):
                if i % 100 == 0:  # Log cada 100 skips
                    log_activity(f"⏭️ [{i+1}/{total_configs}] Mapa {hash_config} ya existe, omitiendo...")
                continue
            
            # Actualizar estado
            STATS['current_task'] = f"Generando {config['num_circulos']}×{config['divisiones_por_circulo']} [{config['prioridad']}]"
            
            log_activity(f"🔨 [{i+1}/{total_configs}] Generando: {config['num_circulos']}×{config['divisiones_por_circulo']} = {config['total_elementos']:,} elementos")
            
            # Generar datos
            start_time = time.time()
            datos = generar_datos_mapa_optimizado(config)
            generation_time = time.time() - start_time
            
            # Guardar JSON
            json_path = output_dir / f"data_{hash_config}.json"
            with open(json_path, 'w') as f:
                json.dump(datos, f, separators=(',', ':'))
            
            file_size_kb = json_path.stat().st_size / 1024
            file_size_mb = file_size_kb / 1024
            
            log_activity(f"  ✅ Guardado: {hash_config} ({file_size_kb:.1f} KB) en {generation_time:.1f}s")
            
            # Actualizar estadísticas
            mapas_generados_sesion += 1
            STATS['maps_generated'] += 1
            STATS['total_size_mb'] += file_size_mb
            
            # Cada 10 mapas, limpiar memoria y guardar stats
            if mapas_generados_sesion % 10 == 0:
                gc.collect()
                guardar_estadisticas()
                
                total_archivos = len(list(output_dir.glob("data_*.json")))
                log_activity(f"📊 Progreso: {mapas_generados_sesion} generados | {total_archivos} totales | {STATS['total_size_mb']:.1f} MB")
            
            # Pausa pequeña para no saturar el sistema
            time.sleep(0.1)
            
        except Exception as e:
            errores_sesion += 1
            STATS['errors'] += 1
            log_activity(f"❌ Error generando mapa {i+1}: {str(e)}")
            
            # Si hay demasiados errores consecutivos, pausa más larga
            if errores_sesion > 5:
                log_activity("⚠️ Muchos errores, pausando 30s...")
                time.sleep(30)
                errores_sesion = 0
    
    # Finalización
    STATS['current_task'] = 'completado'
    STATS['finished_at'] = datetime.now().isoformat()
    guardar_estadisticas()
    
    # Actualizar índice final
    try:
        total_maps = len(list(output_dir.glob("data_*.json")))
        index_data = {
            "maps": [],
            "total_count": total_maps,
            "generated_at": datetime.now().isoformat(),
            "background_generated": mapas_generados_sesion,
            "version": "2.0"
        }
        
        with open(output_dir / "index.json", 'w') as f:
            json.dump(index_data, f, indent=2)
        
        log_activity(f"✅ Índice actualizado: {total_maps} mapas totales")
        
    except Exception as e:
        log_activity(f"⚠️ Error actualizando índice: {e}")
    
    log_activity("🔥 GENERACIÓN CONTINUA COMPLETADA")
    log_activity(f"📊 Total generados en esta sesión: {mapas_generados_sesion}")
    log_activity(f"📁 Directorio: {output_dir}")

def main():
    """Función principal."""
    global RUNNING
    
    try:
        # Thread para mostrar progreso cada 5 minutos
        def mostrar_progreso():
            while RUNNING:
                time.sleep(300)  # 5 minutos
                if RUNNING:
                    log_activity(f"💓 Vivo - {STATS['current_task']} - {STATS['maps_generated']} mapas generados")
        
        progress_thread = threading.Thread(target=mostrar_progreso, daemon=True)
        progress_thread.start()
        
        # Iniciar generación continua
        proceso_generador_continuo()
        
    except KeyboardInterrupt:
        log_activity("🛑 Interrupción por teclado")
    except Exception as e:
        log_activity(f"❌ Error fatal: {e}")
        traceback.print_exc()
    finally:
        RUNNING = False
        guardar_estadisticas()
        log_activity("🔚 Generador de mapas persistente finalizado")

if __name__ == "__main__":
    main()