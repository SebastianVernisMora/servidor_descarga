# TODO: Integración Completa de Parámetros de Despliegue

## ✅ Análisis de Archivos Completado
- [x] Revisado `deploy_integrated_complete.sh` - archivo más completo con todos los parámetros
- [x] Revisado `deploy_simple.sh` - versión simplificada 
- [x] Revisado `deploy_final_fixed.sh` - versión corregida
- [x] Revisado `deploy_full.sh` - versión completa con características avanzadas

## 📋 Parámetros Identificados por Categoría

### 🎯 Parámetros de Configuración Básica
- [x] `num_circulos` - Número de círculos concéntricos (1-1000)
- [x] `divisiones_por_circulo` - Divisiones por círculo (4-500)
- [x] `tipo_mapeo` - Función de mapeo geométrico
- [x] `esquema_color` - Esquema de colores
- [x] `calidad_renderizado` - Calidad de renderizado (baja/media/alta/ultra)

### 🔍 Tipos de Primos y Patrones
- [x] `mostrar_primos_gemelos` - Primos gemelos (gap=2)
- [x] `mostrar_primos_primos` - Primos primos (gap=4)
- [x] `mostrar_primos_sexy` - Primos sexy (gap=6)
- [x] `mostrar_primos_regulares` - Primos regulares
- [x] `mostrar_sophie_germain` - Primos Sophie Germain
- [x] `mostrar_palindromos` - Primos palíndromos
- [x] `mostrar_mersenne` - Primos Mersenne
- [x] `mostrar_fermat` - Primos Fermat

### 📐 Funciones de Mapeo Geométrico
- [x] `mapeo_lineal` - Distribución secuencial estándar
- [x] `mapeo_logaritmico` - Mapeo logarítmico (enfatiza números pequeños)
- [x] `mapeo_espiral_arquimedes` - Espiral de Arquímedes (r = aθ)
- [x] `mapeo_espiral_fibonacci` - Espiral de Fibonacci (basado en razón áurea)
- [x] `mapeo_cuadratico` - Mapeo cuadrático (distribución no lineal)
- [x] `mapeo_hexagonal` - Mapeo hexagonal (empaquetado hexagonal)

### 🎨 Esquemas de Color
- [x] `clasico` - Esquema clásico con colores primarios
- [x] `plasma` - Esquema vibrante plasma
- [x] `naturaleza` - Esquema orgánico natural
- [x] `neon` - Esquema neón brillante
- [x] `oceanico` - Esquema oceánico
- [x] `monocromatico` - Escala de grises

### ⚙️ Opciones Avanzadas
- [x] `transparencia` - Nivel de transparencia (0.1-1.0)
- [x] `grosor_borde` - Grosor del borde
- [x] `mostrar_anillos_guia` - Mostrar anillos de guía
- [x] `mostrar_numeros` - Mostrar números en elementos
- [x] `mostrar_grid_radial` - Mostrar grid radial
- [x] `incluir_leyenda` - Incluir leyenda
- [x] `incluir_estadisticas` - Incluir estadísticas
- [x] `usar_antialiasing` - Usar antialiasing
- [x] `optimizar_memoria` - Optimizar uso de memoria

### 📊 Análisis Estadístico
- [x] Análisis de gaps entre primos
- [x] Cálculo de entropía de Shannon
- [x] Análisis de densidad por rangos
- [x] Coeficiente de variación
- [x] Tests de aleatoriedad (runs test)
- [x] Métricas de asimetría y curtosis
- [x] Densidad real vs teórica

### 🖥️ Configuraciones de Sistema
- [x] DPI de renderizado variable (150-400)
- [x] Formatos de exportación múltiples (PNG, JPG, PDF, SVG)
- [x] Configuración de matplotlib optimizada
- [x] Gestión de memoria mejorada
- [x] Configuraciones de Gunicorn optimizadas
- [x] Configuraciones de Nginx con cache

## 🚀 Próximos Pasos
- [ ] Crear script maestro de despliegue integrado
- [ ] Validar compatibilidad de todos los parámetros
- [ ] Probar configuraciones de alta carga
- [ ] Crear documentación de parámetros
- [ ] Implementar tests automatizados

## 📝 Notas
- El archivo `deploy_integrated_complete.sh` es el más completo y contiene TODOS los parámetros identificados
- Incluye funciones matemáticas avanzadas, análisis estadístico completo y configuraciones optimizadas
- La aplicación soporta hasta 6 tipos de mapeo geométrico y 6 esquemas de color
- Sistema completo de métricas estadísticas con más de 20 indicadores diferentes
