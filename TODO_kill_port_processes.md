# TODO: Detener procesos en puertos activos

## Pasos a seguir:
- [x] 1. Identificar procesos usando puertos TCP activos
- [x] 2. Identificar procesos usando puertos UDP activos  
- [x] 3. Crear lista consolidada de PIDs únicos
- [x] 4. Mostrar procesos que serán terminados
- [x] 5. Terminar procesos de forma controlada (SIGTERM primero)
- [x] 6. Forzar terminación si es necesario (SIGKILL) - No fue necesario
- [x] 7. Verificar que no queden procesos activos en puertos
- [x] 8. Generar reporte final

## Notas:
- Excluir procesos del sistema críticos si es necesario
- Usar kill -15 (SIGTERM) antes que kill -9 (SIGKILL)
- Verificar permisos para terminar procesos
