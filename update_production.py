#!/usr/bin/env python3
"""
Script para actualizar la aplicación de producción con la versión estática.
"""

import os
import sys
import shutil
import json
from pathlib import Path

def update_production_app():
    """Actualizar app de producción con funcionalidad estática."""
    
    production_dir = Path("/var/www/prime-visualization")
    static_maps_dir = Path("/home/admin/static_maps")
    
    print("🔄 Actualizando aplicación de producción...")
    print("=" * 50)
    
    # Verificar permisos
    try:
        test_file = production_dir / "test_write.tmp"
        with open(test_file, 'w') as f:
            f.write("test")
        os.remove(test_file)
        print("✅ Permisos de escritura verificados")
    except PermissionError:
        print("❌ No hay permisos de escritura en directorio de producción")
        print("💡 Intenta ejecutar con: sudo python3 update_production.py")
        return False
    except Exception as e:
        print(f"❌ Error verificando permisos: {e}")
        return False
    
    # Crear backup de app actual
    try:
        backup_file = production_dir / f"app_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.py"
        shutil.copy2(production_dir / "app.py", backup_file)
        print(f"✅ Backup creado: {backup_file.name}")
    except Exception as e:
        print(f"⚠️  No se pudo crear backup: {e}")
    
    # Copiar directorio de mapas estáticos
    try:
        prod_static_dir = production_dir / "static_maps"
        if prod_static_dir.exists():
            shutil.rmtree(prod_static_dir)
        
        shutil.copytree(static_maps_dir, prod_static_dir)
        print(f"✅ {len(list(prod_static_dir.glob('*.html')))} mapas HTML copiados")
        print(f"✅ {len(list(prod_static_dir.glob('*.json')))} archivos JSON copiados")
    except Exception as e:
        print(f"❌ Error copiando mapas estáticos: {e}")
        return False
    
    # Leer app actual y agregar funcionalidad estática
    try:
        app_file = production_dir / "app.py"
        with open(app_file, 'r') as f:
            current_app = f.read()
        
        # Verificar si ya tiene las rutas estáticas
        if '/api/static-maps' in current_app or 'static_maps_dir' in current_app:
            print("✅ App ya tiene funcionalidad estática")
        else:
            # Agregar funcionalidad estática
            static_code = '''
# ===== FUNCIONALIDAD DE MAPAS ESTÁTICOS =====
import hashlib
from pathlib import Path

STATIC_MAPS_DIR = Path("static_maps")
STATIC_CACHE_INDEX = None

def load_static_maps_index():
    """Cargar índice de mapas estáticos."""
    global STATIC_CACHE_INDEX
    try:
        with open(STATIC_MAPS_DIR / "index.json", 'r') as f:
            STATIC_CACHE_INDEX = json.load(f)
        return True
    except:
        return False

@app.route('/static')
def static_maps_selector():
    """Selector de mapas estáticos."""
    return send_from_directory('static_maps', 'index.html')

@app.route('/api/static-maps')
def list_static_maps():
    """Listar mapas estáticos disponibles."""
    if not STATIC_CACHE_INDEX:
        if not load_static_maps_index():
            return jsonify({'error': 'Mapas estáticos no disponibles'}), 500
    
    return jsonify({
        'total_maps': len(STATIC_CACHE_INDEX['maps']),
        'maps_available': list(STATIC_CACHE_INDEX['maps'].keys())[:20],  # Primeros 20
        'generated': STATIC_CACHE_INDEX['generated'],
        'access_url': '/static_map/<filename>'
    })

@app.route('/static_map/<filename>')
def serve_static_map(filename):
    """Servir mapa HTML estático."""
    try:
        if not filename.endswith('.html'):
            return jsonify({'error': 'Solo archivos HTML'}), 400
        return send_from_directory('static_maps', filename)
    except:
        return jsonify({'error': 'Mapa no encontrado'}), 404

# Cargar índice al iniciar
load_static_maps_index()

'''
            
            # Insertar antes de if __name__
            if "if __name__ == '__main__':" in current_app:
                parts = current_app.split("if __name__ == '__main__':")
                updated_app = parts[0] + static_code + "if __name__ == '__main__':" + parts[1]
                
                # Guardar app actualizada
                with open(app_file, 'w') as f:
                    f.write(updated_app)
                
                print("✅ Funcionalidad estática agregada a app.py")
            else:
                print("⚠️  No se pudo encontrar punto de inserción en app.py")
        
    except Exception as e:
        print(f"❌ Error actualizando app.py: {e}")
        return False
    
    print("🎉 Aplicación de producción actualizada exitosamente!")
    return True

if __name__ == "__main__":
    from datetime import datetime
    
    success = update_production_app()
    
    if success:
        print("")
        print("📋 PASOS SIGUIENTES:")
        print("1. Reinicia el servidor gunicorn/supervisor")
        print("2. Verifica que nginx esté sirviendo correctamente")
        print("3. Accede a http://TU_DOMINIO/static para ver mapas estáticos")
        print("")
        print("🌐 URLs nuevas disponibles:")
        print("   http://TU_DOMINIO/static (selector de mapas)")
        print("   http://TU_DOMINIO/api/static-maps (lista de mapas)")
        print("   http://TU_DOMINIO/static_map/map_XXX.html (mapas individuales)")
    else:
        print("❌ Actualización fallida")
        sys.exit(1)