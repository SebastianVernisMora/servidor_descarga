# DIRECTIVAS BÁSICAS DEL PROGRAMA

## 🎯 PROPÓSITO PRINCIPAL
Visualización matemática de números primos mediante representación circular interactiva, optimizada para alto rendimiento y escalabilidad.

## 🏗️ ARQUITECTURA DEL SISTEMA

### Componentes Principales
1. **app_optimized.py** - Aplicación dinámica con cálculo en tiempo real
2. **static_app.py** - Servidor estático de mapas pre-generados
3. **pregenerate_static_maps.py** - Generador de mapas estáticos

### Modos de Operación
- **Modo Dinámico**: Cálculo en tiempo real (desarrollo)
- **Modo Estático**: Mapas pre-generados (producción)

## 📋 DIRECTIVAS FUNDAMENTALES

### 1. LÍMITES OPERATIVOS
- **Círculos máximos**: 10,000
- **Segmentos por círculo**: 1,300
- **Tamaño máximo de cache**: 50 archivos
- **TTL de cache**: 3600 segundos (1 hora)
- **Puerto predeterminado**: 3000

### 2. GESTIÓN DE MEMORIA
- **NO usar cache en RAM** - Solo cache en disco
- **Limpieza agresiva** - gc.collect() después de operaciones grandes
- **Cerrar matplotlib** - plt.close() y plt.clf() siempre
- **Eliminar variables grandes** - del variable; gc.collect()

### 3. FLUJO DE DESARROLLO
```
1. Desarrollo en rama 'dev'
2. NO hacer PR a 'main'
3. Commit al finalizar cada cambio
4. Actualizar documentación siempre
5. NO efectos secundarios en el código
```

### 4. ESTRUCTURA DE DATOS

#### Parámetros de Visualización
```python
{
    'num_circulos': int,          # 1-10,000
    'divisiones_por_circulo': int, # 2-1,300
    'color_scheme': str,          # 'rainbow', 'blue', 'green', etc.
    'highlight_twin_primes': bool,
    'show_labels': bool
}
```

#### Respuesta API Estándar
```json
{
    "status": "success|error",
    "timestamp": "ISO-8601",
    "version": "3.0",
    "data": {},
    "cache_hit": bool
}
```

## 🔄 FLUJO DE PROCESAMIENTO

### Generación de Visualización
1. **Validación** de parámetros de entrada
2. **Búsqueda en cache** (disco)
3. **Cálculo de primos** si no está en cache
4. **Generación de visualización** con matplotlib
5. **Optimización de imagen** (compresión)
6. **Almacenamiento en cache**
7. **Respuesta al cliente**

### Optimizaciones Críticas
- Pre-cálculo de primos hasta 13,000,000
- Cache basado en disco (no RAM)
- Compresión de imágenes automática
- Limpieza de memoria después de cada operación

## 🛡️ REGLAS DE SEGURIDAD
1. **Validación estricta** de todos los inputs
2. **Límites de tamaño** en uploads (50MB)
3. **Timeout** en operaciones largas
4. **Rate limiting** implícito por cache
5. **Sanitización** de parámetros

## 📊 MÉTRICAS Y MONITOREO

### Endpoints de Diagnóstico
- `/api/info` - Información del sistema
- `/memory/stats` - Estadísticas de memoria
- `/cache/stats` - Estadísticas de cache

### KPIs Principales
- Hit rate de cache (objetivo: >80%)
- Tiempo de respuesta (<100ms estático, <5s dinámico)
- Uso de memoria (<500MB)
- Archivos en cache (<50)

## 🚀 ESTRATEGIA DE DESPLIEGUE

### Producción (Estático)
```bash
1. python3 pregenerate_static_maps.py  # Generar mapas
2. ./scripts/deployment/deploy_static_final.sh  # Desplegar
3. Verificar en http://dominio:3000/
```

### Desarrollo (Dinámico)
```bash
1. python3 app_optimized.py  # Puerto 3000
2. Testear funcionalidades
3. Commit cambios
```

## 🔧 MANTENIMIENTO

### Tareas Regulares
1. **Limpieza de cache** - Automática por TTL
2. **Monitoreo de memoria** - scripts/maintenance/monitor_memory.sh
3. **Logs** - Revisar static_deployment.log
4. **Backups** - archive/ para respaldos

### Resolución de Problemas
- **Alta memoria**: Reiniciar aplicación
- **Cache lleno**: Limpiar manualmente cache/
- **Puerto ocupado**: pkill -f app.py

## 📝 CONVENCIONES DE CÓDIGO

### Nomenclatura
- Variables: `snake_case`
- Constantes: `UPPER_CASE`
- Clases: `PascalCase`
- Archivos: `lowercase_underscore.py`

### Documentación
- Docstrings para funciones complejas
- Comentarios en código crítico
- README actualizado
- CHANGELOG para cambios importantes

## 🎨 FILOSOFÍA DE DISEÑO

1. **Rendimiento sobre características** - Optimizar siempre
2. **Simplicidad en la interfaz** - UX minimalista
3. **Escalabilidad horizontal** - Diseñar para crecer
4. **Resiliencia** - Fallar elegantemente
5. **Observabilidad** - Métricas y logs claros

---

*Última actualización: Octubre 2024*
*Versión: 3.0*