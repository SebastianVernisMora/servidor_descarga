# INVENTARIO DE ARCHIVOS - Aplicación de Números Primos

## 📁 ARCHIVOS ACTIVOS (Directorio Principal)

### 🚀 Aplicación Principal
- **`app_optimized.py`** - Aplicación Flask optimizada v3.1 (MEMORIA EN DISCO)
- **`CRUSH.md`** - Documentación principal y comandos

### 🧪 Testing y Monitoreo
- **`test_memory_optimization.py`** - Tests de optimización de memoria
- **`test_flask_route.py`** - Tests de rutas Flask
- **`monitor_memory.sh`** - Monitoreo en tiempo real de memoria
- **`verify_fixes.sh`** - Verificación de correcciones aplicadas

### 🔧 Scripts de Corrección Activos
- **`deploy_optimized_app.sh`** - Deploy de aplicación optimizada
- **`fix_routes.sh`** - Corrección de rutas Flask
- **`force_cleanup.sh`** - Limpieza forzada de memoria
- **`restart_and_test.sh`** - Reinicio y testing

### ⚙️ Utilidades
- **`load_config.py`** - Carga de configuración
- **`organize_files.sh`** - Organización de archivos

### 🔒 Comandos Privilegiados
- **`.blackbox_commands`** - Comandos sudo para ejecutar

### 📂 Directorios de Cache
- **`cache_primes/`** - Cache de números primos en disco
- **`cache/`** - Cache general (si existe)

## 🗄️ ARCHIVOS ARCHIVADOS

### `archive/old_scripts/` (Scripts Deploy Obsoletos)
- deploy.sh, deploy_final_fixed.sh, deploy_fixed.sh
- deploy_full.sh, deploy_integrated_complete.sh
- deploy_simple.sh, redeploy.sh, redeploy_fixed.sh
- update_app.sh, update_deploy_v3.sh

### `archive/ssl_stuff/` (Configuración SSL)
- setup_aws_ssl.sh, setup_ssl.sh
- aws_ssl_commands.md, ssl_instructions.md
- update_app_ssl.py

### `archive/old_todos/` (TODOs Completados)
- 26 archivos TODO_*.md con tareas completadas

### `archive/old_docs/` (Documentación Obsoleta)
- DEPLOYMENT_SUMMARY.md, README_deployment.md
- manual_deploy_steps.md

### `archive/old_apps/` (Aplicaciones Obsoletas)
- app_configurable.py

## 📊 ESTADÍSTICAS
- **Archivos activos:** 12
- **Archivos archivados:** 47
- **Reducción:** 80% de archivos movidos a archivo
- **Estado:** ✅ Directorio limpio y organizado

## 🎯 PRÓXIMOS PASOS
1. Ejecutar comandos de `.blackbox_commands`
2. Verificar con `./verify_fixes.sh`
3. Confirmar aplicación funcionando en dominio
4. Opcional: Comprimir `archive/` para backup permanente

---
*Actualizado: $(date)*