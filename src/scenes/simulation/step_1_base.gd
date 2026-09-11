# res://src/scenes/simulation/step_1_base.gd
# ---------------------------------------------------------------------------
# STEP 1 BASE — Pantalla de simulación / evaluación
# ---------------------------------------------------------------------------
# Interfaz interactiva y reactiva que NO maneja costos ni totales locales.
# Los botones de perfil base y de síntomas ("ingredientes" del índice de
# fatiga) emiten intenciones de cambio de estado a través del EventBus
# (base_selected / item_added). Este script jamás llama directamente a
# GlobalManager: el Label de total se limita a escuchar pasivamente la
# señal total_changed y refrescar su texto.
#
# La jerarquía visual usa MarginContainer + ScrollContainer + VBoxContainer
# para que el layout sea realmente responsivo: cada Label/Button reserva
# automáticamente el alto que necesita (sin offsets fijos en píxeles), y si
# el contenido no cabe en la ventana, aparece scroll en vez de superponerse.
# ---------------------------------------------------------------------------
extends Control

const ROOT_PATH: String = "Margin/Scroll/VBoxContainer"

@onready var btn_estudiante: Button = $Margin/Scroll/VBoxContainer/HBoxBase/BtnEstudiante
@onready var btn_profesional: Button = $Margin/Scroll/VBoxContainer/HBoxBase/BtnProfesional
@onready var btn_deportista: Button = $Margin/Scroll/VBoxContainer/HBoxBase/BtnDeportista

@onready var btn_concentracion: Button = $Margin/Scroll/VBoxContainer/BtnConcentracion
@onready var btn_mente_en_blanco: Button = $Margin/Scroll/VBoxContainer/BtnMenteEnBlanco
@onready var btn_errores: Button = $Margin/Scroll/VBoxContainer/BtnErrores
@onready var btn_cansancio: Button = $Margin/Scroll/VBoxContainer/BtnCansancio
@onready var btn_relectura: Button = $Margin/Scroll/VBoxContainer/BtnRelectura

@onready var lbl_total: Label = $Margin/Scroll/VBoxContainer/LblTotal
@onready var btn_finalizar: Button = $Margin/Scroll/VBoxContainer/BtnFinalizar

func _ready() -> void:
	print("Panel de evaluación cargado. Emitiendo intenciones al EventBus.")

	# Botones de perfil base: un único callback controlador parametrizado
	# dinámicamente mediante .bind(), tal como exige el patrón del curso.
	btn_estudiante.pressed.connect(_on_base_pressed.bind("estudiante"))
	btn_profesional.pressed.connect(_on_base_pressed.bind("profesional"))
	btn_deportista.pressed.connect(_on_base_pressed.bind("deportista"))

	# Botones de síntomas ("ítems adicionales" del índice de fatiga).
	btn_concentracion.pressed.connect(_on_item_pressed.bind("concentracion"))
	btn_mente_en_blanco.pressed.connect(_on_item_pressed.bind("mente_en_blanco"))
	btn_errores.pressed.connect(_on_item_pressed.bind("errores_atencion"))
	btn_cansancio.pressed.connect(_on_item_pressed.bind("cansancio_mental"))
	btn_relectura.pressed.connect(_on_item_pressed.bind("relectura"))

	# Guardar evaluación: registra el intento actual en el historial
	# persistente y reinicia el estado para una nueva evaluación.
	btn_finalizar.pressed.connect(_on_btn_finalizar_pressed)

	# El Label se suscribe de forma pasiva/reactiva al total global.
	EventBus.total_changed.connect(_on_total_changed)

	# Pide el total ACTUAL (posiblemente restaurado de una sesión previa)
	# en lugar de asumir que arranca en cero: así la persistencia es
	# visible para el usuario apenas entra a la pantalla.
	EventBus.total_requested.emit()

func _on_base_pressed(base_name: String) -> void:
	EventBus.base_selected.emit(base_name)

func _on_item_pressed(item_id: String) -> void:
	EventBus.item_added.emit(item_id)

func _on_btn_finalizar_pressed() -> void:
	EventBus.evaluation_finalized.emit()

func _on_total_changed(new_total: int) -> void:
	lbl_total.text = "Índice de Fatiga Total: %d" % new_total
