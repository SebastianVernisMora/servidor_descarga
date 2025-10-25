#!/usr/bin/env python3
"""
Versión SSL-ready de la aplicación Flask
Configurada para trabajar detrás de nginx con proxy reverso
"""

import os
import sys
from app_optimized import app

if __name__ == '__main__':
    # Configuración para producción con SSL
    port = int(os.environ.get('PORT', 5001))
    
    print("🔐 Iniciando aplicación con soporte SSL...")
    print(f"🌐 Aplicación corriendo en puerto {port} (detrás de nginx)")
    print("🚀 Acceso público vía HTTPS configurado con Let's Encrypt")
    
    # Ejecutar en modo producción
    app.run(
        host='127.0.0.1',  # Solo localhost, nginx maneja el SSL
        port=port,
        debug=False,
        threaded=True
    )