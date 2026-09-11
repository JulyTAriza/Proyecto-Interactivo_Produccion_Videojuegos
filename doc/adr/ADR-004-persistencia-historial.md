# ADR-004: Persistencia en disco (user://) y bitácora de evaluaciones

## Estado
Aceptado

> **Nota de alcance:** este ADR documenta una mejora **adicional**, agregada
> por iniciativa propia después del cierre formal del Sprint 1. La rúbrica
> del Laboratorio 4 exige explícitamente 3 ADRs (001-003) y 4 pantallas
> integradas; este documento y la pantalla `HistoryPanel` son un extra que
> demuestra persistencia real entre sesiones, no un reemplazo de ningún
> entregable oficial. Se documenta por separado para no generar confusión
> al momento de calificar contra el checklist del enunciado.

## Contexto
Hasta el cierre del Sprint 1, `GlobalManager` centralizaba el estado de la
simulación en memoria (`estado_simulacion: Dictionary`). Esto resolvía el
problema de que el estado se perdiera al cambiar de escena (porque
`MainApp` libera con `queue_free()` la escena anterior), pero **no**
resolvía dos escenarios reales de uso:

1. Si el usuario cierra la aplicación a la mitad de una evaluación, todo
   el progreso se pierde al volver a abrirla.
2. No existe ningún registro histórico de evaluaciones anteriores; cada
   resultado calculado se pierde apenas el usuario navega fuera de
   `Step1Base`, aunque haya alcanzado a ver su índice de fatiga.

Esto último ya estaba señalado como deuda pendiente en el propio
`DEVLOG.md` desde el Laboratorio 2 ("Guardar el historial de resultados
de evaluaciones anteriores").

## Decisión

### 1. Persistencia del estado en curso
`GlobalManager` serializa `estado_simulacion` como JSON en
`user://fatiga_estado.json` cada vez que se recalcula el total
(`_recalcular_total()` llama a `_guardar_estado()` antes de emitir
`total_changed`). Al iniciar (`_ready()`), intenta leer y parsear ese
archivo; si no existe o está corrupto, se usa el estado por defecto sin
detener la aplicación (falla de forma segura).

### 2. Solicitud explícita del total vigente (`total_requested`)
Como las señales de Godot no se "recuerdan" (un nodo que se conecta tarde
no recibe una emisión pasada), se agregó la señal
`EventBus.total_requested`. `Step1Base` la emite en su `_ready()` para
pedir el total actual (posiblemente restaurado de una sesión anterior) en
lugar de asumir que siempre arranca en cero.

### 3. Bitácora de evaluaciones (`evaluation_finalized` + `history_*`)
Se agregó un botón "Finalizar y Guardar Evaluación" en `Step1Base` que
emite `EventBus.evaluation_finalized`. `GlobalManager` es el único
suscriptor: empaqueta un registro (`fecha`, `base`, `items`, `total`), lo
agrega a `historial_evaluaciones`, lo persiste en
`user://fatiga_historial.json` y **reinicia** `estado_simulacion` para
permitir una nueva evaluación desde cero.

Se creó una quinta pantalla, `HistoryPanel`
(`res://src/scenes/history/history_panel.tscn`), accesible desde un botón
`ButtonNav` adicional en `MenuPanel`. Igual que `Step1Base`, nunca lee
`GlobalManager` directamente: emite `history_requested` al cargar y
renderiza dinámicamente lo que reciba en `history_updated`.

## Consecuencias

### Positivas
- **Persistencia real entre sesiones**, no solo entre cambios de escena:
  cerrar y reabrir la aplicación conserva el progreso.
- **Historial auditable**: cada evaluación finalizada queda como un
  registro inmutable con fecha, perfil y resultado.
- **Mismo patrón arquitectónico**: ninguna pantalla nueva rompe la regla
  de "GUI solo habla con EventBus"; `HistoryPanel` sigue exactamente el
  mismo patrón petición/respuesta ya usado por `total_requested`.

### Negativas / Trade-offs
- **I/O síncrono en cada recálculo**: `_guardar_estado()` escribe a disco
  en cada clic. Para un proyecto de este tamaño el impacto es
  imperceptible, pero en una simulación con actualizaciones muy
  frecuentes convendría *debounce* o guardado diferido.
- **Sin versionado de esquema**: si en un futuro sprint cambia la forma
  del `Dictionary` persistido, los archivos JSON antiguos podrían dejar de
  ser compatibles. Se mitiga parcialmente validando las claves esperadas
  antes de aceptar el contenido cargado (`_cargar_estado()`).
- **Historial sin límite ni edición**: no hay forma de borrar un registro
  individual ni un tope máximo de evaluaciones guardadas; queda como
  trabajo futuro si el archivo crece demasiado.
