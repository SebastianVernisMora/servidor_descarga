#!/usr/bin/env python3
"""
Aplicación Flask configurable que lee desde .blackbox
"""
import os
import sys
from load_config import load_blackbox_config

# Cargar configuración
config = load_blackbox_config()

# Aplicar configuración al entorno
os.environ['BLACKBOX_API_KEY'] = str(config.get('BLACKBOX_API_KEY', ''))

# Importar la aplicación original
from app_optimized import app

# Aplicar configuraciones a Flask
app.config.update({
    'MAX_CONTENT_LENGTH': config.get('MAX_CONTENT_LENGTH', 52428800),
    'DEBUG': config.get('DEBUG_MODE', False)
})

if __name__ == '__main__':
    port = config.get('APP_PORT', 5001)
    host = config.get('HOST', '127.0.0.1')
    debug = config.get('DEBUG_MODE', False)
    threaded = config.get('THREADED', True)
    
    print("🚀 Iniciando aplicación con configuración .blackbox...")
    print(f"📋 Puerto: {port}")
    print(f"📋 Host: {host}")
    print(f"📋 Debug: {debug}")
    print(f"📋 SSL: {'✓' if config.get('ENABLE_SSL') else '✗'}")
    print(f"📋 Cache: {'✓' if config.get('ENABLE_CACHE') else '✗'}")
    print(f"📋 IA: {'✓' if config.get('BLACKBOX_API_KEY') else '✗'}")
    
    app.run(
        host=host,
        port=port,
        debug=debug,
        threaded=threaded
    )