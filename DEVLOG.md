# DEVLOG — Bitácora de Desarrollo

## [2026-08-03] - Configuración inicial e interacción local

**Autor:** July Tatiana Ariza

### Resumen
Se configuró el entorno de desarrollo con Godot Engine 4.7.1 (renderizador
Compatibility) y se estructuró el repositorio inicial bajo la convención
snake_case dentro de la carpeta `src/`, sentando las bases del proyecto
integrador que evolucionará a lo largo del semestre.

### Cambios realizados
- Creación de `main.tscn`: menú de inicio con un `VBoxContainer` y los
  botones `BtnSimular` y `BtnSalir`.
- Creación de `main_level_1.tscn`: pantalla de simulación con un
  `GridContainer` y botones de selección de ingredientes.
- Implementación de `main.gd` y `main_level_1.gd` con tipado estático
  estricto, captura de nodos mediante `@onready` y conexión de señales
  directamente por código.
- Uso de `.bind()` para parametrizar dinámicamente el callback
  `_on_ingrediente_selected(nombre: String, costo: int)`.
- Configuración de la navegación entre escenas mediante el nodo
  `SceneChanger`.
- Personalización del nombre, la descripción y el ícono del proyecto en
  la configuración de Godot.

### Problemas encontrados y solución
- El script `main_level_1.gd` no quedó adjuntado al nodo raíz al momento
  de crearlo, por lo que los botones de ingredientes no respondían a la
  interacción. Se solucionó adjuntando manualmente el script existente
  al nodo `MainLevel1`.
- El botón `BtnVolver` quedó con dos conexiones de señal simultáneas
  (una hacia `SceneChanger` y otra dentro de `main_level_1.gd`), lo que
  generaba un error de referencia nula tras el cambio de escena. Se
  resolvió eliminando la conexión redundante dentro de `main_level_1.gd`,
  dejando a `SceneChanger` como único responsable de la navegación.

### Próximos pasos
- Refactorizar la navegación para centralizarla completamente en
  `SceneChanger`, eliminando llamadas directas dispersas en los scripts
  de interfaz.
- Preparar la grabación del video de sustentación técnica.

---

## [2026-09-03] - Refactorización a Event Bus y navegación desacoplada

**Autor:** July Tatiana Ariza

Se refactorizó por completo la arquitectura plana heredada del
Laboratorio 1 hacia un modelo modular con co-localización de escenas y
scripts bajo `src/`. Se eliminó la dependencia directa a
`get_tree().change_scene_to_file()` y se reemplazó por un `EventBus`
global (Autoload) que centraliza la comunicación entre pantallas
mediante el patrón Observer, con las señales tipadas
`navigation_requested(target_scene_path: String)` y
`parameter_changed(param_name: String, value: Variant)`. El nuevo
orquestador `main_app.gd` se suscribe a estas señales, libera con
`queue_free()` la escena previa y limpia su referencia
(`current_scene = null`) antes de instanciar la siguiente, previniendo
fugas de memoria. Se reubicaron y renombraron las escenas del Lab 1
(`main.tscn` → `menu_panel.tscn`, `main_level_1.tscn` →
`step_1_base.tscn`) y se crearon dos paneles nuevos —`config_panel` y
`credits_panel`— ambos co-localizados con su script y navegando
exclusivamente a través del `EventBus`, sin conocerse entre sí. Se
eliminó el script huérfano `change_scene.gd` y la carpeta vacía
`src/scripts/`, y se actualizó `project.godot` con el nombre del
proyecto ("Laboratorio 2"), la nueva escena principal
(`src/core/main_app.tscn`) y el registro del Autoload `EventBus`.
Finalmente, se redactó el ADR `doc/adr/0001-uso-de-event-bus.md`
justificando formalmente la decisión arquitectónica. El principal reto
fue decidir cómo tipar `parameter_changed`, dado que el valor puede
variar según el parámetro; se optó por `Variant` de forma explícita
para conservar tipado estricto sin sacrificar flexibilidad. Como
próximos pasos queda persistir el estado de selección de ingredientes
entre paneles mediante un recurso o Autoload de estado compartido, y
añadir transiciones visuales (fade/tween) al cambiar de escena en
`MainApp`.
