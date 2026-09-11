# res://src/scenes/menu/menu_panel.gd
# ---------------------------------------------------------------------------
# MENU PANEL — Menú principal
# ---------------------------------------------------------------------------
# La navegación hacia Simulación, Configuración y Créditos ya NO se
# resuelve por código: se delega de forma declarativa a instancias del
# componente reutilizable ButtonNav, configuradas desde el Inspector.
# Este script conserva únicamente la responsabilidad que ButtonNav no
# cubre: el cierre limpio de la aplicación.
# ---------------------------------------------------------------------------
extends Control

@onready var btn_salir: Button = $Margin/VBoxRoot/VBoxMenu/BtnSalir

func _ready() -> void:
	print("Panel de menú cargado (navegación declarativa vía ButtonNav).")
	btn_salir.pressed.connect(_on_btn_salir_pressed)

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
