# Quick Reference Card

## 🚀 Deploy Production
```bash
./scripts/deployment/deploy_static_final.sh
```

## 🛑 Stop Application
```bash
pkill -f static_app.py
```

## 📊 Check Status
```bash
# System info
curl http://localhost:3000/api/info

# View logs
tail -f static_deployment.log

# Check port
lsof -i:3000
```

## 🔧 Development
```bash
# Run dynamic version
python3 app_optimized.py

# Run tests
python3 test_memory_optimization.py

# Pre-generate maps
python3 pregenerate_static_maps.py
```

## 📁 Key Locations
- Scripts: `scripts/`
- Documentation: `docs/`
- Static maps: `static_maps/`
- Old files: `archive/`

## 🌐 Endpoints
- Main: http://localhost:3000/
- Maps API: http://localhost:3000/api/maps
- Number API: http://localhost:3000/api/number/97

## 💡 Remember
- Work on `dev` branch
- No side effects in edits
- Always commit after changes
- Update docs when needed