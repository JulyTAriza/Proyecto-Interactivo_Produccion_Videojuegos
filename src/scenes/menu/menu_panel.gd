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
	if not btn_salir.visible:
		# Sin "Cerrar aplicación", el ciclo vertical de la columna se cierra
		# entre Configuración y Créditos.
		var config: Control = btn_salir.get_node(btn_salir.focus_neighbor_bottom)
		var creditos: Control = btn_salir.get_node(btn_salir.focus_neighbor_top)
		creditos.focus_neighbor_bottom = creditos.get_path_to(config)
		config.focus_neighbor_top = config.get_path_to(creditos)
	EventBus.coupons_changed.connect(_on_coupons_changed)
	EventBus.coupons_requested.emit()
	btn_simular.grab_focus.call_deferred()

func _on_coupons_changed(coupons: Array) -> void:
	lbl_estado.text = "Estado del Sistema: Listo.   Cupones disponibles: %d   ·   Compras realizadas: %d" % [coupons.size(), GlobalManager.purchases.size()]

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
