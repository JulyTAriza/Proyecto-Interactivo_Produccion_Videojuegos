# ADR-003: Centralización del Estado Global (GlobalManager) y componente reutilizable ButtonNav

## Estado
Aceptado

## Contexto
Al cierre del Sprint 1, el proyecto ya contaba con navegación desacoplada
mediante el `EventBus` (ADR-002), pero persistían dos problemas de
arquitectura:

1. **Estado local no persistente**: la lógica de cálculo del índice de
   fatiga vivía dentro del script de `Step1Base`. Si el usuario navegaba a
   otra pantalla y regresaba, el estado se perdía porque `MainApp` libera
   (`queue_free()`) la escena anterior. No existía un lugar único donde
   persistieran los datos de la simulación (perfil base seleccionado y
   síntomas marcados) independientemente de qué pantalla estuviera activa.
2. **Navegación duplicada en cada panel**: cada script de pantalla
   (`menu_panel.gd`, `config_panel.gd`, `credits_panel.gd`,
   `step_1_base.gd`) repetía el mismo patrón para volver al menú
   (`EventBus.navigation_requested.emit(MENU_SCENE_PATH)`), generando
   código redundante y una constante `MENU_SCENE_PATH` duplicada en cuatro
   archivos distintos.

## Decisión

### 1. GlobalManager (Autoload)
Se crea `res://src/core/global_manager.gd`, registrado como **Autoload**
bajo el identificador exacto `GlobalManager`, cargado **después** de
`EventBus` (del cual depende) en `project.godot`.

`GlobalManager` centraliza el estado de la simulación en un único
`Dictionary` (`estado_simulacion`), con los precios base y de ítems
definidos en constantes propias (`BASE_PRICES`, `ITEM_PRICES`). Es el
**único cerebro matemático** del sistema: escucha `base_selected` e
`item_added` del `EventBus`, recalcula el total en un único punto
(`_recalcular_total()`) y notifica el resultado mediante `total_changed`.
Ningún nodo de la GUI accede o modifica `estado_simulacion` directamente.

### 2. ButtonNav (Componente reutilizable)
Se crea la escena `res://src/components/navigation/button_nav.tscn` (nodo
raíz `Button`) con su script `button_nav.gd`, que expone al Inspector:

```gdscript
@export_file("*.tscn") var target_scene: String
@export var discard_previous: bool = false
```

Al presionarse, emite `EventBus.navigation_requested(target_scene,
discard_previous)`. Esto elimina por completo la necesidad de escribir
código de navegación en `MenuPanel`, `ConfigPanel`, `CreditsPanel` y
`Step1Base`: la navegación se configura **declarativamente** desde el
Inspector de cada instancia.

Como consecuencia directa, se **eliminan** los scripts `config_panel.gd`
y `credits_panel.gd`: ambos paneles ahora resuelven su regreso al menú
únicamente configurando una instancia de `ButtonNav`
(`discard_previous = true`), sin necesitar controlador propio.

### 3. Pila de historial en MainApp
`MainApp` amplía su responsabilidad de orquestador: mantiene el arreglo
`navigation_history: Array[String]`. Si `discard_previous` es `false`, la
ruta de la escena se agrega con `.append()`; si es `true`, se retira el
último elemento con `.pop_back()` antes de instanciar el panel de destino.
El estado de la pila se imprime en consola tras cada navegación exitosa.

## Consecuencias

### Positivas
- **Persistencia real del estado**: el índice de fatiga sobrevive a la
  destrucción de `Step1Base`, ya que vive en un Autoload independiente del
  ciclo de vida de las escenas visuales.
- **Cero duplicación de lógica de navegación**: los cuatro paneles dejan
  de repetir `MENU_SCENE_PATH` y la emisión manual de la señal.
- **Componente verdaderamente reutilizable**: `ButtonNav` no conoce nada
  del dominio de la aplicación; podría reutilizarse en un proyecto
  completamente distinto sin modificar una sola línea.
- **Trazabilidad de navegación**: `navigation_history` permite depurar y,
  a futuro, implementar funcionalidades como "volver N pantallas" o
  analítica de uso.

### Negativas / Trade-offs
- **Menor flexibilidad visual en Configuración**: al eliminar el script de
  `ConfigPanel`, se retiró temporalmente el control interactivo de umbral
  de alerta (implementado en el Laboratorio 3) porque ya no cuenta con
  lógica propia para reaccionar a un `HSlider`. Queda documentado en el
  DEVLOG como trabajo futuro, candidato a resolverse con un nuevo Autoload
  de configuración (`SettingsManager`) en un próximo sprint.
- **Ítems sin límite superior**: `GlobalManager` permite sumar un síntoma
  un número ilimitado de veces; se evaluará en un sprint futuro si conviene
  acotar la cantidad máxima por ítem para reflejar mejor la escala clínica
  real de frecuencia de síntomas.
- **Un Autoload adicional**: aumenta el número de singletons globales del
  proyecto (ahora `EventBus` + `GlobalManager`), lo que exige mantener
  disciplina para no acoplar lógica de dominio directamente en el bus.
