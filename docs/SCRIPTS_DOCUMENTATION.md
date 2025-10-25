# Scripts Documentation

## Deployment Scripts (`scripts/deployment/`)

### deploy_static_final.sh
Despliega la versión estática de producción con mapas pre-generados.
- **Uso**: `./scripts/deployment/deploy_static_final.sh`
- **Puerto**: 3000
- **Log**: `static_deployment.log`

### deploy_optimized_app.sh
Despliega la aplicación dinámica con generación en tiempo real.
- **Uso**: `./scripts/deployment/deploy_optimized_app.sh`
- **Puerto**: 3000

### deploy_public.sh
Script para despliegue público con configuraciones adicionales.
- **Uso**: `./scripts/deployment/deploy_public.sh`

### deploy_to_domain.sh
Configura el despliegue para un dominio específico.
- **Uso**: `./scripts/deployment/deploy_to_domain.sh [DOMINIO]`

## Maintenance Scripts (`scripts/maintenance/`)

### monitor_memory.sh
Monitorea el uso de memoria del sistema y la aplicación.
- **Uso**: `./scripts/maintenance/monitor_memory.sh`
- **Salida**: Estado de memoria cada 5 segundos

### maintenance.sh
Script general de mantenimiento del sistema.
- **Uso**: `./scripts/maintenance/maintenance.sh`

### force_cleanup.sh
Fuerza la limpieza de procesos y liberación de puertos.
- **Uso**: `./scripts/maintenance/force_cleanup.sh`
- **Acción**: Mata procesos en puerto 3000

### restart_and_test.sh
Reinicia la aplicación y ejecuta pruebas básicas.
- **Uso**: `./scripts/maintenance/restart_and_test.sh`

### fix_routes.sh
Corrige problemas de rutas en la aplicación.
- **Uso**: `./scripts/maintenance/fix_routes.sh`

## Testing Scripts (`scripts/testing/`)

### verify_public_deployment.sh
Verifica que el despliegue público esté funcionando correctamente.
- **Uso**: `./scripts/testing/verify_public_deployment.sh`
- **Checks**: API endpoints, mapas estáticos, tiempo de respuesta

### verify_fixes.sh
Verifica que las correcciones aplicadas funcionen.
- **Uso**: `./scripts/testing/verify_fixes.sh`

## Utility Scripts (`scripts/`)

### archive_compress.sh
Comprime archivos para respaldo.
- **Uso**: `./scripts/archive_compress.sh`
- **Salida**: `archive_backup_[fecha].tar.gz`

### organize_files.sh
Organiza archivos del proyecto en sus directorios correspondientes.
- **Uso**: `./scripts/organize_files.sh`

### setup_nginx_redirect.sh
Configura redirecciones nginx para el servidor.
- **Uso**: `./scripts/setup_nginx_redirect.sh`

## Python Scripts Principales

### pregenerate_static_maps.py
Genera los 980 mapas estáticos HTML.
- **Uso**: `python3 pregenerate_static_maps.py`
- **Salida**: `static_maps/` con archivos HTML
- **Tiempo**: ~10-15 minutos

### app_optimized.py
Aplicación Flask principal con generación dinámica.
- **Uso**: `python3 app_optimized.py [--port=8080]`
- **Puerto default**: 3000

### static_app.py
Servidor estático optimizado para servir mapas pre-generados.
- **Uso**: `python3 static_app.py`
- **Puerto**: 3000
- **Características**: Menor uso de RAM, respuesta rápida

### test_memory_optimization.py
Pruebas de optimización de memoria.
- **Uso**: `python3 test_memory_optimization.py`

### test_flask_route.py
Pruebas de rutas Flask.
- **Uso**: `python3 test_flask_route.py`