#!/usr/bin/env python3
"""
Servidor simple y robusto sin dependencias del índice complejo.
"""

from flask import Flask, jsonify, send_file
import os
import json
from datetime import datetime
from pathlib import Path

app = Flask(__name__)

STATIC_MAPS_DIR = Path("/home/admin/servidor_descarga/static_maps")

@app.route('/')
def home():
    """Página principal."""
    return send_file("/home/admin/servidor_descarga/index.html")

@app.route('/api/info')
def api_info():
    """Info del sistema."""
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        total_size_mb = sum(f.stat().st_size for f in STATIC_MAPS_DIR.glob("*")) / 1024 / 1024
        
        return jsonify({
            'status': 'active',
            'total_maps': total_maps,
            'total_size_mb': round(total_size_mb, 1),
            'timestamp': datetime.now().isoformat(),
            'version': 'simple-server'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/maps')
def api_maps():
    """Lista básica de mapas."""
    try:
        total_maps = len(list(STATIC_MAPS_DIR.glob("data_*.json")))
        return jsonify({
            'total_count': total_maps,
            'timestamp': datetime.now().isoformat(),
            'message': f'{total_maps} mapas disponibles'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("🔥 SERVIDOR SIMPLE INICIANDO...")
    print(f"📁 Mapas: {STATIC_MAPS_DIR}")
    print(f"🗺️ Total: {len(list(STATIC_MAPS_DIR.glob('data_*.json')))} mapas")
    print("🌐 Puerto 3000 - Acceso público completo")
    
    app.run(host='0.0.0.0', port=3000, debug=False)