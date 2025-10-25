# Índice de Documentación

## Documentación Principal
- [README Principal](../README.md) - Información general del proyecto
- [CRUSH - Guía de Desarrollo](../CRUSH.md) - Comandos y convenciones de desarrollo
- [DIRECTIVAS DEL PROGRAMA](../PROGRAM_DIRECTIVES.md) - Directivas básicas y arquitectura

## Guías de Despliegue
- [Guía de Despliegue](DEPLOYMENT_GUIDE.md) - Proceso completo de despliegue
- [Estado del Despliegue](DEPLOYMENT_STATUS.md) - Estado actual del sistema
- [Instrucciones Finales](FINAL_DEPLOYMENT_INSTRUCTIONS.md) - Pasos finales de configuración
- [Instrucciones en Español](INSTRUCCIONES_FINALES.md) - Guía en español
- [Resumen Despliegue Estático](STATIC_DEPLOYMENT_SUMMARY.md) - Detalles del despliegue estático

## Documentación Técnica
- [Documentación de Scripts](SCRIPTS_DOCUMENTATION.md) - Descripción de todos los scripts
- [Inventario del Sistema](INVENTORY.md) - Lista de componentes del sistema

## Tareas Pendientes (TODOs)
- [Mejoras de la App](TODO_deploy_app_improvements.md)
- [Despliegue Puerto 3000](TODO_deploy_port3000.md)
- [Mapa Interactivo](TODO_interactive_map.md)
- [Procesos de Puerto](TODO_kill_port_processes.md)

## Estructura del Proyecto

```
servidor_descarga/
├── Aplicaciones Principales
│   ├── app_optimized.py - App dinámica
│   ├── static_app.py - App estática
│   └── pregenerate_static_maps.py - Generador
│
├── Configuración
│   ├── requirements.txt - Dependencias
│   ├── package.json - Config Node
│   └── providers.json - Proveedores
│
├── Scripts/
│   ├── deployment/ - Despliegue
│   ├── maintenance/ - Mantenimiento
│   └── testing/ - Verificación
│
├── Recursos/
│   ├── static_maps/ - Mapas HTML
│   ├── archive/ - Respaldos
│   └── venv/ - Entorno virtual
│
└── Documentación/
    ├── docs/ - Esta carpeta
    ├── README.md - Principal
    └── CRUSH.md - Desarrollo
```

## Enlaces Rápidos

### Comandos Frecuentes
```bash
# Desplegar producción
./scripts/deployment/deploy_static_final.sh

# Ver logs
tail -f static_deployment.log

# Verificar sistema
curl http://localhost:3000/api/info

# Detener aplicación
pkill -f static_app.py
```

### APIs Principales
- http://localhost:3000/ - Interfaz principal
- http://localhost:3000/api/maps - Lista de mapas
- http://localhost:3000/api/number/97 - Análisis numérico