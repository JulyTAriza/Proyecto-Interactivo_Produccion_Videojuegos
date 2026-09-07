# res://src/core/main_app.gd
# ---------------------------------------------------------------------------
# MAIN APP — Orquestador central de navegación desacoplada
# ---------------------------------------------------------------------------
# Escena principal del proyecto. Se suscribe de forma asíncrona a la señal
# global "navigation_requested" del EventBus y gestiona el ciclo de vida
# (instanciación y liberación de memoria) de los paneles visuales dentro
# de SceneContainer, evitando fugas de memoria (memory leaks).
# ---------------------------------------------------------------------------
extends Control

const MENU_SCENE_PATH: String = "res://src/scenes/menu/menu_panel.tscn"

@onready var scene_container: Control = $SceneContainer

var current_scene: Node = null

func _ready() -> void:
	print("MainApp iniciado. Suscribiéndose al EventBus...")
	EventBus.navigation_requested.connect(_on_navigation_requested)

	# Carga inicial: el menú principal.
	_on_navigation_requested(MENU_SCENE_PATH)

func _on_navigation_requested(target_scene_path: String) -> void:
	print("MainApp: navegación solicitada hacia -> ", target_scene_path)

	# 1. Liberar de forma segura la escena activa previa (si existe).
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# 2. Cargar e instanciar la nueva escena solicitada.
	var new_scene_resource: PackedScene = load(target_scene_path) as PackedScene
	if new_scene_resource == null:
		push_error("MainApp: no fue posible cargar la escena en la ruta: %s" % target_scene_path)
		return

	var new_scene_instance: Node = new_scene_resource.instantiate()
	scene_container.add_child(new_scene_instance)
	current_scene = new_scene_instance
