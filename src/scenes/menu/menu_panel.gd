# res://src/scenes/menu/menu_panel.gd
extends Control

const STEP_1_SCENE_PATH: String = "res://src/scenes/simulation/step_1_base.tscn"
const CONFIG_SCENE_PATH: String = "res://src/scenes/config/config_panel.tscn"
const CREDITS_SCENE_PATH: String = "res://src/scenes/credits/credits_panel.tscn"

@onready var btn_simular: Button = $VBoxMenu/BtnSimular
@onready var btn_config: Button = $VBoxMenu/BtnConfig
@onready var btn_creditos: Button = $VBoxMenu/BtnCreditos
@onready var btn_salir: Button = $VBoxMenu/BtnSalir
@onready var lbl_estado: Label = $LblEstado

func _ready() -> void:
	print("Panel de menú cargado (desacoplado vía EventBus).")

	# Conexión local con parametrización dinámica mediante bind():
	# un único callback controlador para todas las opciones de navegación.
	btn_simular.pressed.connect(_on_navigate_pressed.bind(STEP_1_SCENE_PATH))
	btn_config.pressed.connect(_on_navigate_pressed.bind(CONFIG_SCENE_PATH))
	btn_creditos.pressed.connect(_on_navigate_pressed.bind(CREDITS_SCENE_PATH))
	btn_salir.pressed.connect(_on_btn_salir_pressed)

func _on_navigate_pressed(target_scene_path: String) -> void:
	lbl_estado.text = "Estado del Sistema: Cargando módulo..."
	# Emisión asíncrona: el panel NO conoce a MainApp, solo notifica al bus.
	EventBus.navigation_requested.emit(target_scene_path)

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
