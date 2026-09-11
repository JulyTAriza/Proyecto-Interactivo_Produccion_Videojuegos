# res://src/components/navigation/button_nav.gd
# ---------------------------------------------------------------------------
# BUTTON NAV — Componente de interfaz reutilizable de navegación
# ---------------------------------------------------------------------------
# Botón parametrizado desde el Inspector de Godot que encapsula la
# intención común de "navegar a otra escena" sin que el panel que lo
# contiene necesite escribir ningún código de navegación.
#
# Al presionarse, emite la señal navigation_requested del EventBus con la
# ruta configurada y la bandera discard_previous, que indica a MainApp si
# debe registrar (append) o retirar (pop_back) la escena en la pila de
# historial navigation_history.
# ---------------------------------------------------------------------------
extends Button

## Ruta de la escena de destino, seleccionable desde el Inspector.
@export_file("*.tscn") var target_scene: String

## true = este botón representa un "regreso" (retira el último elemento
## del historial antes de navegar). false = navegación hacia adelante
## (registra la escena de destino en el historial).
@export var discard_previous: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if target_scene.is_empty():
		push_warning("ButtonNav (%s): no se configuró 'target_scene' en el Inspector." % name)
		return

	EventBus.navigation_requested.emit(target_scene, discard_previous)
