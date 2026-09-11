# DEVLOG — Bitácora de Desarrollo

## [2026-08-21] - Laboratorios 0 y 1: Configuración inicial e interacción local (acoplada)

**Autor:** July Tatiana Ariza

### Resumen
Se configuró el entorno de desarrollo con Godot Engine 4.7.1 (renderizador
Compatibility) y se estructuró el repositorio bajo la convención snake_case
dentro de la carpeta `src/`.

### Cambios realizados
- Creación de `main.tscn`: menú de inicio con `VBoxContainer` y botones
  `BtnSimular` / `BtnSalir`.
- Creación de `main_level_1.tscn`: pantalla de simulación con `GridContainer`
  y botones de selección de ingredientes.
- Implementación de `main.gd` y `main_level_1.gd` con tipado estático estricto,
  captura de nodos con `@onready`, y conexión de señales por código.
- Uso de `.bind()` para parametrizar dinámicamente el callback
  `_on_ingrediente_selected(nombre: String, costo: int)`.
- Configuración de navegación entre escenas mediante el nodo `SceneChanger`.
- Personalización de nombre, descripción e ícono del proyecto.

### Problemas encontrados y solución
- El script `main_level_1.gd` no quedó adjuntado al nodo raíz tras crearlo,
  por lo que los botones de ingredientes no reaccionaban. Se resolvió
  adjuntando el script existente al nodo `MainLevel1`.
- El botón `BtnVolver` quedó con dos conexiones de señal simultáneas
  (una hacia `SceneChanger` y otra dentro de `main_level_1.gd`), causando
  un error de referencia nula tras el cambio de escena. Se eliminó la
  conexión redundante dentro de `main_level_1.gd`.

### Próximos pasos
- Refactorizar la navegación para centralizarla completamente en `SceneChanger`.
- Preparar la grabación del video de sustentación.

## [2026-09-02] - Laboratorios 2 y 3: Co-localización y navegación desacoplada (Event Bus)

**Autor:** July Tatiana Ariza

### Resumen
Se refactorizó por completo la arquitectura plana del Laboratorio 1 hacia
un modelo modular con co-localización de escenas y scripts. Se eliminó la
dependencia directa a `get_tree().change_scene_to_file()` y se reemplazó
por un `EventBus` global (Autoload) que centraliza la comunicación entre
pantallas mediante el patrón Observer.

### Cambios realizados
- Creación de `src/core/event_bus.gd` registrado como Autoload `EventBus`,
  con las señales tipadas `navigation_requested` y `parameter_changed`.
- Creación de `src/core/main_app.gd` / `main_app.tscn` como orquestador
  central: se suscribe al bus, libera con `queue_free()` la escena previa
  y limpia la referencia (`current_scene = null`) antes de instanciar la
  siguiente, previniendo fugas de memoria.
- Reubicación y renombramiento de `main.tscn`/`main.gd` a
  `src/scenes/menu/menu_panel.tscn` / `.gd`, ahora con botones adicionales
  de Configuración y Créditos.
- Reubicación de `main_level_1.tscn`/`main_level_1.gd` a
  `src/scenes/simulation/step_1_base.tscn` / `.gd`.
- Creación de dos paneles nuevos: `src/scenes/config/config_panel.tscn` y
  `src/scenes/credits/credits_panel.tscn`, ambos co-localizados con su
  script y navegando exclusivamente vía `EventBus`.
- Eliminación del script huérfano `change_scene.gd` y de la carpeta vacía
  `src/scripts/`.
- Actualización de `project.godot`: nombre del proyecto a "Laboratorio 2",
  escena principal `src/core/main_app.tscn` y registro del Autoload.
- Redacción del ADR `doc/adr/0001-uso-de-event-bus.md` justificando la
  decisión arquitectónica.

### Problemas encontrados y solución
- Al desacoplar la navegación, inicialmente cada panel intentaba cargar
  directamente la siguiente escena, replicando el problema del Lab 1. Se
  corrigió delegando esa responsabilidad exclusivamente a `MainApp`,
  manteniendo a los paneles ciegos entre sí.
- Fue necesario decidir cómo tipar la señal `parameter_changed` dado que
  el valor puede ser de distinta naturaleza según el parámetro; se usó
  `Variant` de forma explícita para mantener tipado estricto sin perder
  flexibilidad.

### Próximos pasos
- Persistir el estado de selección de ingredientes entre paneles usando
  un recurso o Autoload de estado compartido.
- Añadir transiciones visuales (fade/tween) al cambiar de escena en
  `MainApp`.

## [2026-09-04] - Laboratorio 3 (continuación): Transformación de dominio a Detector de Fatiga Cognitiva

**Autor:** July Tatiana Ariza

### Resumen
Manteniendo intacta la arquitectura de navegación desacoplada (EventBus +
MainApp) del refactor anterior, se reemplazó el contenido de cada panel
para convertir el proyecto en una aplicación real: un test breve de
autoevaluación psicológica de fatiga cognitiva.

### Cambios realizados
- `step_1_base.gd`/`.tscn`: se reemplazó el selector de ingredientes por
  un cuestionario de 5 preguntas navegables (Anterior/Siguiente), cada una
  respondida con un `HSlider` de 0 a 10. Al finalizar, se calcula el
  índice total, el porcentaje y una categoría de alerta (Bajo/Moderado/
  Alto/Crítico), notificada vía `EventBus.parameter_changed`.
- `config_panel.gd`/`.tscn`: ahora permite ajustar el umbral de alerta
  crítica (50%-100%) mediante un `HSlider`, emitido también por el
  EventBus para que otros paneles puedan reaccionar sin acoplarse.
- `menu_panel.tscn`: se agregó título y subtítulo describiendo la app, y
  se renombraron los botones al nuevo dominio ("Iniciar Evaluación").
- `credits_panel.tscn`: se agregó el nombre de la aplicación.
- `project.godot`: nombre y descripción actualizados a "Detector de
  Fatiga Cognitiva".
- `README.md`: descripción del proyecto actualizada.

### Próximos pasos
- Guardar el historial de resultados de evaluaciones anteriores.
- Usar el umbral configurado en `ConfigPanel` para resaltar visualmente
  el resultado cuando se supere (actualmente solo se emite el evento).

## [2026-09-11] - Laboratorio 4 (Sprint Review 1): GlobalManager, ButtonNav y cierre integrador

**Autor:** July Tatiana Ariza

### Resumen
Entrega integradora del Sprint 1 (Laboratorio 4). Se centralizó por
completo el estado de la simulación en un nuevo Autoload
(`GlobalManager`) y se extrajo la navegación repetida en cada panel hacia
un componente reutilizable (`ButtonNav`), configurable 100% desde el
Inspector. `MainApp` ahora también gestiona una pila física de historial
de navegación.

### Cambios realizados
- Creación de `src/core/global_manager.gd`, registrado como Autoload
  `GlobalManager` (cargado después de `EventBus`). Centraliza
  `estado_simulacion: Dictionary` (perfil base + síntomas marcados) y
  recalcula el índice total de fatiga de forma centralizada.
- Actualización de `event_bus.gd`: se reemplazó la señal genérica
  `parameter_changed` por cuatro señales tipadas de forma estricta:
  `navigation_requested(target_scene, discard_previous)`,
  `base_selected(base_name)`, `item_added(item_id)` y
  `total_changed(new_total)`.
- Creación del componente reutilizable
  `src/components/navigation/button_nav.tscn` / `.gd`, con propiedades
  exportadas `target_scene` (`@export_file`) y `discard_previous`
  (`@export`). Se instanció en `menu_panel`, `config_panel`,
  `credits_panel` y `step_1_base`, eliminando toda navegación programada
  a mano en esos cuatro paneles.
- Eliminación completa de `config_panel.gd` y `credits_panel.gd`: ambos
  paneles resuelven su navegación de regreso de forma puramente
  declarativa mediante una instancia de `ButtonNav`.
- Rediseño de `step_1_base.tscn` / `.gd`: los controles pasaron de un
  cuestionario por `HSlider` a botones de "perfil base" (Estudiante /
  Profesional / Deportista) y botones de "síntomas" que emiten
  `base_selected` / `item_added` al `EventBus` mediante `.connect()` y
  `.bind()`. El `Label` de total ya no calcula nada: solo escucha
  `total_changed` de forma pasiva.
- Actualización de `main_app.gd`: se agregó `navigation_history:
  Array[String]`, con `.append()` para navegación hacia adelante y
  `.pop_back()` para regresos (`discard_previous = true`), imprimiendo el
  estado de la pila en consola tras cada navegación.
- Reorganización de la documentación de arquitectura: se renombró el ADR
  original a `ADR-002-uso-de-event-bus.md`, se creó
  `ADR-001-patron-colocacion.md` (documentando retroactivamente la
  decisión del Laboratorio 2) y se redactó
  `ADR-003-global-manager-button-nav.md` para esta entrega.
- Creación de `CHANGELOG.md` con el resumen de la versión 1.0.0 (cierre
  del Sprint 1).

### Problemas encontrados y solución
- Al eliminar `config_panel.gd`, se perdió el control interactivo de
  umbral de alerta agregado en el Laboratorio 3 (un `HSlider` requiere un
  script que reaccione a `value_changed`). Se decidió retirarlo
  temporalmente del panel de Configuración en lugar de dejar un script
  "casi vacío" solo para ese control, ya que el requisito de la rúbrica es
  explícito: Configuración y Créditos no deben tener script propio. Queda
  registrado como trabajo futuro (ver ADR-003).
- El orden de los Autoloads importaba: si `GlobalManager` se registraba
  antes que `EventBus` en `project.godot`, su `_ready()` fallaba al
  intentar conectarse a una señal que aún no existía. Se corrigió
  garantizando que `EventBus` se declare primero en la sección
  `[autoload]`.
- Al migrar `Step1Base` de sliders a botones de síntomas, se evaluó dejar
  que cada botón reflejara visualmente cuántas veces fue presionado; se
  decidió posponerlo para no romper el principio de que la GUI solo
  escucha `total_changed` y no consulta el estado interno de
  `GlobalManager` directamente.

### Próximos pasos
- Reintroducir la configuración de umbral de alerta mediante un nuevo
  Autoload dedicado (`SettingsManager`) que no dependa de un script local
  en `ConfigPanel`.
- Acotar la cantidad máxima de veces que un mismo síntoma puede sumarse
  al total, para reflejar mejor una escala clínica de frecuencia.
- Agregar transición visual (fade/tween) en `MainApp` al cambiar de panel.

## [2026-09-11] - Corrección de layout responsivo + Persistencia (mejora adicional)

**Autor:** July Tatiana Ariza

### Resumen
Dos frentes de trabajo tras revisar el resultado en ejecución: (1) se
corrigió un bug real de maquetación donde el texto se superponía en
`Step1Base` por usar offsets fijos en píxeles, y (2) se agregó
persistencia real en disco (`user://`) para el estado de la simulación y
un historial de evaluaciones guardadas, cerrando una deuda pendiente
anotada desde el Laboratorio 2.

### Cambios realizados
- **Fix de layout**: se reescribieron `menu_panel.tscn`, `step_1_base.tscn`,
  `config_panel.tscn` y `credits_panel.tscn` reemplazando offsets fijos
  por `MarginContainer` + `VBoxContainer`/`HBoxContainer` (y
  `ScrollContainer` en `Step1Base`), para que cada `Label`/`Button` reserve
  automáticamente el espacio que su contenido necesita. Se actualizaron
  las rutas `@onready` en `menu_panel.gd` y `step_1_base.gd` acorde a la
  nueva jerarquía de nodos.
- **Persistencia de estado** (`global_manager.gd`): `estado_simulacion` se
  serializa como JSON en `user://fatiga_estado.json` en cada recálculo, y
  se restaura al iniciar la aplicación. Se agregó la señal
  `EventBus.total_requested` para que `Step1Base` pida el total vigente
  (potencialmente restaurado) en lugar de asumir que siempre arranca en 0.
- **Historial de evaluaciones**: nuevo botón "Finalizar y Guardar
  Evaluación" en `Step1Base` que emite `EventBus.evaluation_finalized`.
  `GlobalManager` guarda el registro en `user://fatiga_historial.json` y
  reinicia el estado para una nueva evaluación.
- **Nueva pantalla `HistoryPanel`**
  (`src/scenes/history/history_panel.tscn` / `.gd`): quinta pantalla,
  adicional a las 4 exigidas por la rúbrica, accesible desde un nuevo
  botón en `MenuPanel`. Renderiza dinámicamente el historial recibido vía
  `EventBus.history_updated`, sin leer `GlobalManager` directamente.
- Documentación: `doc/adr/ADR-004-persistencia-historial.md` (marcado
  explícitamente como mejora fuera del alcance mínimo del Sprint 1).

### Problemas encontrados y solución
- Las señales de Godot no "recuerdan" emisiones pasadas: si `Step1Base` se
  conectaba a `total_changed` después de que `GlobalManager` ya había
  restaurado el estado al arrancar la app, el `Label` mostraba `0` aunque
  hubiera un total persistido. Se resolvió agregando un patrón de
  petición/respuesta explícito (`total_requested` → `total_changed`) en
  vez de depender de una emisión que ya había ocurrido.
- Se consideró que `HistoryPanel` leyera `GlobalManager.historial_evaluaciones`
  directamente al ser un panel de solo lectura, pero se descartó para no
  romper la consistencia arquitectónica del resto del proyecto: se aplicó
  el mismo patrón `*_requested` / `*_updated` ya usado para el total.

### Próximos pasos
- Evaluar guardado diferido (debounce) si en el futuro se agregan más
  campos de estado que se actualicen con alta frecuencia.
- Permitir borrar registros individuales del historial desde la propia
  pantalla `HistoryPanel`.
