# res://src/core/main_app.gd
# ---------------------------------------------------------------------------
# MAIN APP — Orquestador central de navegación desacoplada
# ---------------------------------------------------------------------------
# Escena principal del proyecto. Se suscribe de forma asíncrona a la señal
# global "navigation_requested" del EventBus y gestiona el ciclo de vida
# (instanciación y liberación de memoria) de los paneles visuales dentro
# de SceneContainer, evitando fugas de memoria (memory leaks).
#
# Además administra de forma centralizada la pila de historial de
# navegación (navigation_history), utilizada por los componentes
# reutilizables ButtonNav para saber si deben "avanzar" (append) o
# "retroceder" (pop_back) en el flujo de pantallas.
# ---------------------------------------------------------------------------
extends Control

const MENU_SCENE_PATH: String = "res://src/scenes/menu/menu_panel.tscn"

@onready var scene_container: Control = $SceneContainer

var current_scene: Node = null

## Pila física con el historial de escenas visitadas por el usuario.
var navigation_history: Array[String] = []

func _ready() -> void:
	print("MainApp iniciado. Suscribiéndose al EventBus...")
	EventBus.navigation_requested.connect(_on_navigation_requested)

	# Carga inicial: el menú principal (no descarta nada del historial).
	_on_navigation_requested(MENU_SCENE_PATH, false)

func _on_navigation_requested(target_scene_path: String, discard_previous: bool) -> void:
	print("MainApp: navegación solicitada hacia -> %s (discard_previous=%s)" % [target_scene_path, discard_previous])

	# 1. Actualizar la pila de historial de navegación.
	if discard_previous:
		# Caso típico de los botones de "Volver": se retira el último
		# elemento registrado antes de instanciar el panel de destino.
		if navigation_history.size() > 0:
			navigation_history.pop_back()
	else:
		# Navegación hacia adelante: se registra la nueva escena.
		navigation_history.append(target_scene_path)

	print("MainApp: estado actual de navigation_history -> ", navigation_history)

	# 2. Liberar de forma segura la escena activa previa (si existe).
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# 3. Cargar e instanciar la nueva escena solicitada.
	var new_scene_resource: PackedScene = load(target_scene_path) as PackedScene
	if new_scene_resource == null:
		push_error("MainApp: no fue posible cargar la escena en la ruta: %s" % target_scene_path)
		return

	var new_scene_instance: Node = new_scene_resource.instantiate()
	scene_container.add_child(new_scene_instance)
	current_scene = new_scene_instance
