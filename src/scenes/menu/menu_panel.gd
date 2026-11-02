# res://src/scenes/menu/menu_panel.gd
# ---------------------------------------------------------------------------
# MENU PANEL — Menú principal
# ---------------------------------------------------------------------------
# La navegación hacia todas las pantallas se delega de forma declarativa a
# instancias del componente reutilizable ButtonNav, configuradas desde el
# Inspector. Este script conserva únicamente lo que ButtonNav no cubre:
# el cierre limpio de la aplicación (oculto en la versión Web, donde
# get_tree().quit() no tiene efecto) y el resumen de estado del sistema.
# ---------------------------------------------------------------------------
extends Control

@onready var btn_salir: Button = $Margin/VBoxRoot/HBoxSecciones/VBoxOtros/BtnSalir
@onready var btn_simular: Button = $Margin/VBoxRoot/HBoxSecciones/VBoxEvaluacion/BtnSimular
@onready var lbl_estado: Label = $Margin/VBoxRoot/LblEstado

func _ready() -> void:
	print("Panel de menú cargado (navegación declarativa vía ButtonNav).")
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	btn_salir.visible = not OS.has_feature("web")
	EventBus.coupons_changed.connect(_on_coupons_changed)
	EventBus.coupons_requested.emit()
	btn_simular.grab_focus.call_deferred()

func _on_coupons_changed(coupons: Array) -> void:
	lbl_estado.text = "Estado del Sistema: Listo.   Cupones disponibles: %d   ·   Compras realizadas: %d" % [coupons.size(), GlobalManager.purchases.size()]

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
