#!/usr/bin/env python3
"""
Script para probar las optimizaciones de memoria de la aplicación.
"""

import requests
import time
import psutil
import os

def get_memory_usage():
    """Obtener uso de memoria del proceso."""
    process = psutil.Process()
    return process.memory_info().rss / (1024*1024)  # MB

def test_memory_optimization():
    """Probar optimizaciones de memoria."""
    base_url = "http://localhost:5001"
    
    print("🧪 Iniciando pruebas de optimización de memoria...")
    print(f"Memoria inicial: {get_memory_usage():.2f} MB\n")
    
    # Test 1: Generar múltiples visualizaciones
    print("📊 Test 1: Generando múltiples visualizaciones...")
    for i in range(5):
        try:
            response = requests.post(f"{base_url}/generar", json={
                'num_circulos': 20 + i * 5,
                'divisiones_por_circulo': 36,
                'usar_cache': True,
                'comprimir_salida': True,
                'optimizar_memoria': True
            }, timeout=30)
            
            if response.status_code == 200:
                memory_now = get_memory_usage()
                print(f"  Visualización {i+1}: {memory_now:.2f} MB")
            else:
                print(f"  Error en visualización {i+1}: {response.status_code}")
                
        except Exception as e:
            print(f"  Error en visualización {i+1}: {e}")
    
    print(f"\nMemoria después de visualizaciones: {get_memory_usage():.2f} MB")
    
    # Test 2: Verificar estadísticas del cache
    print("\n💾 Test 2: Verificando cache en disco...")
    try:
        response = requests.get(f"{base_url}/cache/stats")
        if response.status_code == 200:
            stats = response.json()
            print(f"  Archivos en cache: {stats['cache']['entries']}")
            print(f"  Tamaño total: {stats['cache']['total_size_mb']:.2f} MB")
            print(f"  Hit ratio: {stats['cache']['hit_ratio']:.2%}")
        else:
            print(f"  Error obteniendo estadísticas: {response.status_code}")
    except Exception as e:
        print(f"  Error: {e}")
    
    # Test 3: Optimización manual de memoria
    print("\n🚀 Test 3: Optimización manual de memoria...")
    try:
        response = requests.post(f"{base_url}/memory/optimize")
        if response.status_code == 200:
            result = response.json()
            print(f"  Objetos recolectados: {result['objects_collected']}")
            print(f"  Memoria después: {result['memory_usage_mb']} MB")
        else:
            print(f"  Error: {response.status_code}")
    except Exception as e:
        print(f"  Error: {e}")
    
    # Test 4: Estadísticas detalladas
    print("\n📈 Test 4: Estadísticas detalladas de memoria...")
    try:
        response = requests.get(f"{base_url}/memory/stats")
        if response.status_code == 200:
            stats = response.json()
            print(f"  Memoria proceso: {stats['process_memory']['rss_mb']:.2f} MB")
            print(f"  Porcentaje uso: {stats['process_memory']['percent']:.1f}%")
            print(f"  Cache disco: {stats['disk_cache']['entries']} archivos")
            print(f"  Objetos GC: {stats['gc_stats']['objects']}")
        else:
            print(f"  Error: {response.status_code}")
    except Exception as e:
        print(f"  Error: {e}")
    
    # Test 5: Limpiar cache
    print("\n🧹 Test 5: Limpiando cache...")
    try:
        response = requests.post(f"{base_url}/cache/clear")
        if response.status_code == 200:
            print("  ✅ Cache limpiado exitosamente")
        else:
            print(f"  Error: {response.status_code}")
    except Exception as e:
        print(f"  Error: {e}")
    
    print(f"\nMemoria final: {get_memory_usage():.2f} MB")
    print("✅ Pruebas completadas!")

if __name__ == "__main__":
    test_memory_optimization()