# res://src/scenes/simulation/step_1_base.gd
# ---------------------------------------------------------------------------
# STEP 1 BASE — Pantalla de simulación / evaluación
# ---------------------------------------------------------------------------
# Laboratorio 6 — Máquina de Estado Finito (FSM) aplicada al flujo real de
# evaluación de esta pantalla (no es un ejercicio aislado, es el
# componente central del proyecto integrador):
#
# Estados:
#   EN_EVALUACION -> el usuario puede elegir perfil base y marcar síntomas.
#                     Estado inicial.
#   GUARDANDO     -> se está persistiendo la evaluación en el historial;
#                     mientras tanto, la interfaz bloquea nuevas entradas
#                     para evitar guardar dos veces o modificar datos a
#                     medio guardar.
#   GUARDADA      -> la evaluación quedó registrada en el historial. Solo
#                     permite iniciar una evaluación nueva (que regresa a
#                     EN_EVALUACION).
#
# Transiciones permitidas:
#   EN_EVALUACION -> GUARDANDO   (el usuario presiona "Finalizar")
#   GUARDANDO     -> GUARDADA    (termina la animación de confirmación)
#   GUARDADA      -> EN_EVALUACION (el usuario presiona "Nueva Evaluación")
#
# Todo cambio de estado pasa por change_state(), la única función que
# decide si una transición es válida. El estado actual determina qué
# interacciones son válidas: los botones de perfil/síntomas solo
# reaccionan mientras current_state == EN_EVALUACION.
# ---------------------------------------------------------------------------
extends Control

enum EvaluationState { EN_EVALUACION, GUARDANDO, GUARDADA }

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
@onready var lbl_confirmacion: Label = $Margin/Scroll/VBoxContainer/LblConfirmacion
@onready var btn_nueva_evaluacion: Button = $Margin/Scroll/VBoxContainer/BtnNuevaEvaluacion

var current_state: EvaluationState = EvaluationState.EN_EVALUACION

# Botones cuya interactividad depende del estado actual (todos los de
# selección, más "Finalizar"). Se agrupan para no repetir la misma lista
# de "disabled = true/false" en varios lugares.
var botones_de_evaluacion: Array[Button] = []

func _ready() -> void:
	print("Panel de evaluación cargado. Emitiendo intenciones al EventBus.")

	botones_de_evaluacion = [
		btn_estudiante, btn_profesional, btn_deportista,
		btn_concentracion, btn_mente_en_blanco, btn_errores,
		btn_cansancio, btn_relectura, btn_finalizar,
	]

	btn_estudiante.pressed.connect(_on_base_pressed.bind("estudiante"))
	btn_profesional.pressed.connect(_on_base_pressed.bind("profesional"))
	btn_deportista.pressed.connect(_on_base_pressed.bind("deportista"))

	btn_concentracion.pressed.connect(_on_item_pressed.bind("concentracion"))
	btn_mente_en_blanco.pressed.connect(_on_item_pressed.bind("mente_en_blanco"))
	btn_errores.pressed.connect(_on_item_pressed.bind("errores_atencion"))
	btn_cansancio.pressed.connect(_on_item_pressed.bind("cansancio_mental"))
	btn_relectura.pressed.connect(_on_item_pressed.bind("relectura"))

	btn_finalizar.pressed.connect(_on_btn_finalizar_pressed)
	btn_nueva_evaluacion.pressed.connect(_on_btn_nueva_evaluacion_pressed)

	EventBus.total_changed.connect(_on_total_changed)
	EventBus.total_requested.emit()
	btn_estudiante.grab_focus.call_deferred()

# ---------------------------------------------------------------------------
# Entradas del usuario — cada una respeta el estado actual antes de actuar
# ---------------------------------------------------------------------------

func _on_base_pressed(base_name: String) -> void:
	if current_state != EvaluationState.EN_EVALUACION:
		return
	EventBus.base_selected.emit(base_name)

func _on_item_pressed(item_id: String) -> void:
	if current_state != EvaluationState.EN_EVALUACION:
		return
	EventBus.item_added.emit(item_id)

func _on_btn_finalizar_pressed() -> void:
	change_state(EvaluationState.GUARDANDO)

func _on_btn_nueva_evaluacion_pressed() -> void:
	change_state(EvaluationState.EN_EVALUACION)

func _on_total_changed(new_total: int) -> void:
	lbl_total.text = "Índice de Fatiga Total: %d" % new_total

# ---------------------------------------------------------------------------
# Función central de la FSM — único lugar donde "current_state" cambia
# ---------------------------------------------------------------------------

func change_state(new_state: EvaluationState) -> void:
	if not _is_transition_allowed(current_state, new_state):
		push_warning("Step1Base: transición inválida %s -> %s, ignorada" % [
			EvaluationState.keys()[current_state], EvaluationState.keys()[new_state]
		])
		return

	current_state = new_state

	match new_state:
		EvaluationState.GUARDANDO:
			_enter_guardando()
		EvaluationState.GUARDADA:
			_enter_guardada()
		EvaluationState.EN_EVALUACION:
			_enter_en_evaluacion()

func _is_transition_allowed(from: EvaluationState, to: EvaluationState) -> bool:
	match from:
		EvaluationState.EN_EVALUACION:
			return to == EvaluationState.GUARDANDO
		EvaluationState.GUARDANDO:
			return to == EvaluationState.GUARDADA
		EvaluationState.GUARDADA:
			return to == EvaluationState.EN_EVALUACION
	return false

# ---------------------------------------------------------------------------
# Comportamiento propio de CADA estado
# ---------------------------------------------------------------------------

## Mientras se guarda: se bloquean todos los botones de evaluación (para
## no permitir un segundo "Finalizar" ni modificar la respuesta a medio
## guardar) y se dispara el guardado real en GlobalManager.
func _enter_guardando() -> void:
	for boton: Button in botones_de_evaluacion:
		boton.disabled = true

	EventBus.evaluation_finalized.emit()
	_reproducir_animacion_confirmacion()

## La evaluación ya quedó en el historial: se muestra el botón para
## iniciar una nueva, se mantienen bloqueados los de la evaluación
## anterior (ya no tiene sentido seguir marcando síntomas de un intento
## que ya se cerró).
func _enter_guardada() -> void:
	btn_nueva_evaluacion.visible = true

## Vuelve al estado inicial: oculta la confirmación, reactiva los
## controles para que el usuario pueda responder desde cero (GlobalManager
## ya reinició "estado_simulacion" al finalizar la evaluación anterior).
func _enter_en_evaluacion() -> void:
	lbl_confirmacion.visible = false
	lbl_confirmacion.modulate.a = 0.0
	btn_nueva_evaluacion.visible = false

	for boton: Button in botones_de_evaluacion:
		boton.disabled = false

# ---------------------------------------------------------------------------
# Animación Tween asociada a la TRANSICIÓN GUARDANDO -> GUARDADA
# ---------------------------------------------------------------------------

func _reproducir_animacion_confirmacion() -> void:
	lbl_confirmacion.visible = true
	lbl_confirmacion.modulate.a = 0.0
	lbl_confirmacion.scale = Vector2(0.85, 0.85)
	lbl_confirmacion.pivot_offset = lbl_confirmacion.size / 2.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl_confirmacion, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(lbl_confirmacion, "scale", Vector2(1.0, 1.0), 0.4)
	tween.tween_callback(_on_confirmation_animation_finished)

func _on_confirmation_animation_finished() -> void:
	change_state(EvaluationState.GUARDADA)
