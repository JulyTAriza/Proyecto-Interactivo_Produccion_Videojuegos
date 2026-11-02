# res://src/scenes/gamification/infusion_rush/cup.gd
# ---------------------------------------------------------------------------
# TAZA — Máquina de Estado Finito (Laboratorio 6)
# ---------------------------------------------------------------------------
# Cada instancia de cup.tscn tiene su PROPIA máquina de estados, por eso
# varias tazas pueden estar al mismo tiempo en estados distintos.
#
#   FRIA -> DISPONIBLE -> ARRASTRANDO -+-> INFUSIONANDO -> LISTA -> ARRASTRANDO -> ENTREGADA
#                            ^         +-> DISPONIBLE (se soltó fuera)
#                            |         +-> LISTA      (una taza lista se soltó fuera)
#
# - El ESTADO decide qué significa la misma entrada ("interact" = clic):
#   en FRIA o INFUSIONANDO acelera el temporizador; en DISPONIBLE o LISTA
#   toma la taza para arrastrarla.
# - change_state() es el ÚNICO punto que cambia el estado y valida las
#   transiciones permitidas.
# - Cada transición tiene su animación Tween (play_transition_animation),
#   elegida por la pareja (estado anterior, estado nuevo).
# - Un solo Timer se reutiliza: mide el enfriamiento y la infusión, porque
#   la taza solo puede estar en un estado a la vez.
# ---------------------------------------------------------------------------
extends CharacterBody2D

enum CupState { FRIA, DISPONIBLE, ARRASTRANDO, INFUSIONANDO, LISTA, ENTREGADA }

const RADIO_INTERACCION: float = 40.0

@export var cold_duration: float = 6.0
@export var brewing_duration: float = 8.0

@onready var timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

var current_state: CupState = CupState.FRIA
var previous_state: CupState = CupState.FRIA
var mouse_over: bool = false
## true cuando el minijuego terminó: la taza deja de aceptar interacción.
var bloqueada: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	timer.timeout.connect(_on_timer_timeout)
	sprite.modulate = Color(0.35, 0.55, 1.0)
	timer.start(cold_duration)
	animate_enter_cold()

func _on_mouse_entered() -> void:
	mouse_over = true

func _on_mouse_exited() -> void:
	mouse_over = false

## Además de la señal mouse_entered (input_pickable), se comprueba la
## distancia al puntero: así la interacción funciona aunque otra capa de la
## interfaz intercepte el evento de "picking".
func is_pointer_over() -> bool:
	return mouse_over or global_position.distance_to(get_global_mouse_position()) <= RADIO_INTERACCION

func _on_timer_timeout() -> void:
	match current_state:
		CupState.FRIA:
			change_state(CupState.DISPONIBLE)
		CupState.INFUSIONANDO:
			var station: Area2D = get_station()
			if change_state(CupState.LISTA) and station:
				station.deactivate()

# ---------------------------------------------------------------------------
# Transiciones
# ---------------------------------------------------------------------------

func is_transition_allowed(from: CupState, to: CupState) -> bool:
	match from:
		CupState.FRIA:
			return to == CupState.DISPONIBLE
		CupState.DISPONIBLE:
			return to == CupState.ARRASTRANDO
		CupState.ARRASTRANDO:
			return to in [CupState.INFUSIONANDO, CupState.ENTREGADA, CupState.DISPONIBLE, CupState.LISTA]
		CupState.INFUSIONANDO:
			return to == CupState.LISTA
		CupState.LISTA:
			return to == CupState.ARRASTRANDO
		CupState.ENTREGADA:
			return false
	return false

func change_state(next_state: CupState) -> bool:
	if not is_transition_allowed(current_state, next_state):
		return false
	previous_state = current_state
	current_state = next_state
	play_transition_animation(previous_state, current_state)
	if current_state == CupState.INFUSIONANDO:
		timer.start(brewing_duration)
	return true

# ---------------------------------------------------------------------------
# Comportamiento por estado
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if bloqueada:
		return
	match current_state:
		CupState.FRIA:
			process_fria(delta)
		CupState.DISPONIBLE:
			process_disponible(delta)
		CupState.ARRASTRANDO:
			process_arrastrando(delta)
		CupState.INFUSIONANDO:
			process_infusionando(delta)
		CupState.LISTA:
			process_lista(delta)
		CupState.ENTREGADA:
			process_entregada(delta)

func process_fria(_delta: float) -> void:
	if is_pointer_over() and Input.is_action_just_pressed("interact"):
		timer.start(maxf(timer.time_left - 1.0, 0.1))
		animate_interaction()
	var progress: float = 1.0 - (timer.time_left / cold_duration)
	sprite.modulate = Color(0.35, 0.55, 1.0).lerp(Color.WHITE, progress)

func process_disponible(delta: float) -> void:
	velocity.y += 980.0 * delta
	move_and_slide()
	if is_pointer_over() and Input.is_action_just_pressed("interact"):
		velocity = Vector2.ZERO
		change_state(CupState.ARRASTRANDO)

func process_arrastrando(_delta: float) -> void:
	global_position = get_global_mouse_position()
	scale.x = lerpf(scale.x, 1.15, 0.15)
	scale.y = lerpf(scale.y, 0.87, 0.15)
	if Input.is_action_just_released("interact"):
		release_cup()

func process_infusionando(_delta: float) -> void:
	if is_pointer_over() and Input.is_action_just_pressed("interact"):
		timer.start(maxf(timer.time_left - 1.0, 0.1))
		animate_interaction()
	var progress: float = 1.0 - (timer.time_left / brewing_duration)
	sprite.modulate = Color(1.0, 0.95, 0.9).lerp(Color(0.55, 1.0, 0.6), progress)

func process_lista(delta: float) -> void:
	velocity.y += 980.0 * delta
	move_and_slide()
	if is_pointer_over() and Input.is_action_just_pressed("interact"):
		velocity = Vector2.ZERO
		change_state(CupState.ARRASTRANDO)

func process_entregada(_delta: float) -> void:
	pass

## Al soltar la taza se decide la transición según DÓNDE se soltó y de qué
## estado venía (previous_state distingue los dos usos de ARRASTRANDO).
func release_cup() -> void:
	var delivery_area: Area2D = get_delivery_area()
	var station: Area2D = get_station()
	if delivery_area and previous_state == CupState.LISTA:
		if change_state(CupState.ENTREGADA):
			delivery_area.confirm_delivery()
	elif station and previous_state == CupState.DISPONIBLE and not station.ocupada:
		if change_state(CupState.INFUSIONANDO):
			global_position = station.global_position + Vector2(0, 10)
			station.activate()
	elif previous_state == CupState.LISTA:
		change_state(CupState.LISTA)
	else:
		change_state(CupState.DISPONIBLE)

func get_station() -> Area2D:
	for area in interaction_area.get_overlapping_areas():
		if area.is_in_group("station"):
			return area
	return null

func get_delivery_area() -> Area2D:
	for area in interaction_area.get_overlapping_areas():
		if area.is_in_group("delivery"):
			return area
	return null

func bloquear() -> void:
	bloqueada = true
	timer.stop()

# ---------------------------------------------------------------------------
# Animaciones programáticas (Tween) asociadas a cada TRANSICIÓN
# ---------------------------------------------------------------------------

func play_transition_animation(from_state: CupState, to_state: CupState) -> void:
	match [from_state, to_state]:
		[CupState.FRIA, CupState.DISPONIBLE]:
			animate_cold_to_available()
		[CupState.DISPONIBLE, CupState.ARRASTRANDO]:
			animate_available_to_dragging()
		[CupState.ARRASTRANDO, CupState.DISPONIBLE]:
			animate_dragging_to_available()
		[CupState.ARRASTRANDO, CupState.INFUSIONANDO]:
			animate_dragging_to_brewing()
		[CupState.INFUSIONANDO, CupState.LISTA]:
			animate_brewing_to_ready()
		[CupState.LISTA, CupState.ARRASTRANDO]:
			animate_ready_to_dragging()
		[CupState.ARRASTRANDO, CupState.LISTA]:
			animate_dragging_to_available()
		[CupState.ARRASTRANDO, CupState.ENTREGADA]:
			animate_delivery()

func animate_enter_cold() -> void:
	scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)

func animate_interaction() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.06)
	tween.tween_property(self, "scale", Vector2(0.95, 1.05), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func animate_cold_to_available() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", rotation + TAU, 0.35)
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.12)
	tween.chain().tween_property(self, "scale", Vector2(0.95, 1.05), 0.08)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.35)

func animate_available_to_dragging() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 0.9), 0.08)
	tween.tween_property(self, "scale", Vector2(0.95, 1.05), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func animate_dragging_to_available() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func animate_dragging_to_brewing() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.08)
	tween.tween_property(self, "scale", Vector2(0.96, 1.04), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func animate_brewing_to_ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	sprite.modulate = Color(0.45, 1.0, 0.55)

func animate_ready_to_dragging() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 0.92), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func animate_delivery() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()
