#!/usr/bin/env python3
"""Test directo de rutas Flask"""

import sys
sys.path.insert(0, '/var/www/prime-visualization')

try:
    from app import app
    from flask import render_template

    print("🔍 Testing Flask app routes...")

    # Test de la ruta con test_client
    with app.test_client() as client:
        response = client.get('/')
        print("\n🌐 Route '/' test:")
        print("Status:", response.status_code)
        print("Content-Type:", response.content_type)
        print("Content length:", len(response.data))
        
        if response.status_code != 200:
            print("Error data:", response.data.decode())
        else:
            print("✅ Route works! First 200 chars:")
            print(response.data.decode()[:200])
            
        # Test API route too
        api_response = client.get('/api/info')
        print("\n🔧 Route '/api/info' test:")
        print("Status:", api_response.status_code)
        
except Exception as e:
    print("❌ Error:", e)
    import traceback
    traceback.print_exc()