# res://src/scenes/credits/credits_panel.gd
extends Control

const MENU_SCENE_PATH: String = "res://src/scenes/menu/menu_panel.tscn"

@onready var btn_volver: Button = $VBoxCreditos/BtnVolver

func _ready() -> void:
	print("Panel de créditos cargado de forma desacoplada.")
	btn_volver.pressed.connect(_on_btn_volver_pressed)

func _on_btn_volver_pressed() -> void:
	EventBus.navigation_requested.emit(MENU_SCENE_PATH)
