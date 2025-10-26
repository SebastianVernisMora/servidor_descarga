# CRUSH.md - Development Guide

## 🔥 SISTEMA PM2 - GENERADOR PERSISTENTE (1,168+ MAPAS)
```bash
# 🚀 INICIAR GENERADOR PERSISTENTE (estilo PM2)
./pm2_start.sh

# 📊 VER ESTADO DEL GENERADOR
./pm2_status.sh

# 📈 ESTADÍSTICAS DETALLADAS
./pm2_stats.sh

# 📋 VER LOGS EN TIEMPO REAL
./pm2_logs.sh

# 🔄 REINICIAR GENERADOR
./pm2_restart.sh

# 🛑 DETENER GENERADOR PERSISTENTE
./pm2_stop.sh

# 🌐 DESPLIEGUE PÚBLICO PUERTO 3000 - DNS e IP 
./deploy_public_port3000.sh

# 📊 VERIFICAR SERVIDOR PÚBLICO
python3 -c "import requests; print(requests.get('http://localhost:3000/api/info').json())"
```

## Build/Run Commands
```bash
# Run Flask app (default port 3000) - MAPA INTERACTIVO AVANZADO
python3 app_optimized.py

# Run with custom port
python3 app_optimized.py --port=8080

# Install dependencies
pip install -r requirements.txt

# Check system info and validate setup
curl http://localhost:3000/api/info

# Memory & Cache Operations
curl http://localhost:3000/memory/stats
curl -X POST http://localhost:3000/memory/optimize
curl -X POST http://localhost:3000/cache/clear

# API Testing
curl http://localhost:3000/api/number/97
curl -X POST http://localhost:3000/api/interactive-map -H "Content-Type: application/json" -d '{"num_circulos": 10, "divisiones_por_circulo": 24}'
```

## 🚀 AUTO-DEPLOY (DESPLIEGUE AUTOMÁTICO)
```bash
# ⚙️ CONFIGURAR UNA SOLA VEZ
./setup_autodeploy.sh

# 📊 MONITOREAR AUTO-DEPLOY
sudo systemctl status autodeploy        # Estado del servicio
tail -f logs/auto_deploy.log           # Logs en tiempo real
curl http://localhost:9000/status      # Estado API

# 🔧 CONTROL MANUAL
curl -X POST http://localhost:9000/manual-deploy  # Deploy manual
cat logs/deploy_history.log                       # Historial deploys

# 🔄 FLUJO AUTOMÁTICO:
# 1. Push a master/main → GitHub webhook → Auto-deploy
# 2. git pull + pip install + pm2 restart + health check
# 3. Servidor actualizado automáticamente
```

## APLICACIÓN ESTÁTICA (RENDIMIENTO MÁXIMO)
```bash
# 🔥 PRE-GENERAR MAPAS ESTÁTICOS (Una sola vez)
python3 pregenerate_static_maps.py

# 🌐 DESPLEGAR EN PUERTO PÚBLICO 3000 - VERSIÓN ESTÁTICA
python3 static_app.py --port=3000

# Verificar mapas disponibles
curl http://localhost:3000/api/maps | head -20
```

## Interfaces Estáticas Disponibles (PUERTO PÚBLICO 3000)
```bash
# 🔥 APLICACIÓN ESTÁTICA - RENDIMIENTO MÁXIMO - DESPLEGADA
http://localhost:3000/                   # Selector de 980 mapas pre-generados
http://localhost:3000/enhanced           # Selector de mapas (alias)
http://localhost:3000/api/maps           # Lista de mapas disponibles (JSON)
http://localhost:3000/api/interactive-map # Búsqueda en mapas pre-generados (POST)
http://localhost:3000/api/random-map     # Mapa aleatorio instantáneo
http://localhost:3000/api/number/97      # Análisis matemático rápido
http://localhost:3000/api/info           # Info del sistema estático
http://localhost:3000/static_map/map_XXX.html # Mapas HTML individuales

# 🌐 ACCESO PÚBLICO ESTÁTICO
http://TU_DOMINIO:3000/                  # 🔥 980 mapas instantáneos

# 📈 CARACTERÍSTICAS ESTÁTICAS:
# • 980 mapas HTML pre-generados (sin cálculos)
# • Respuesta <5ms (archivos estáticos)
# • RAM mínima (sin procesamiento)
# • Máximo rendimiento y escalabilidad
```

## Code Style Guidelines

### Python Conventions:
- **Imports**: Group stdlib, third-party, local with blank lines; no unused imports
- **Functions**: snake_case with docstrings for complex functions; use type hints
- **Variables**: snake_case, descriptive names (e.g., `num_circulos`, `datos_img`)
- **Constants**: ALL_CAPS with prefixes (e.g., `MAX_CONTENT_LENGTH`)
- **Classes**: PascalCase with docstrings

### Performance Patterns (MEMORIA OPTIMIZADA):
- **DISCO CACHE**: Use disk-based cache, not RAM (DiskBasedCache class)
- **NO LRU_CACHE**: Remove @lru_cache decorators to free RAM
- **GC AGGRESSIVE**: Use gc.collect() after large operations
- **MATPLOTLIB CLEANUP**: Always plt.close() and plt.clf() after plots
- Delete large variables explicitly: `del variable; gc.collect()`

### Error Handling:
- Try-except for external APIs and file operations
- Log with `print(f"Error: {str(e)}")` and `traceback.print_exc()`
- Return structured JSON: `{'error': 'desc', 'timestamp': datetime.now().isoformat()}`
- Use appropriate HTTP status codes (400/500)

### API Design:
- REST endpoints return consistent JSON with timestamp/version
- Validate inputs with sensible defaults
- Include cache headers and compression for large responses
- New /api/interactive-map endpoint for responsive HTML maps
- Async tooltip loading with /api/number/<int:number> for detailed math

### Frontend Patterns:
- Use fetch() API with proper error handling
- Implement debouncing for real-time controls (300ms)
- Responsive design with mobile-first approach
- CSS custom properties for theming and consistency