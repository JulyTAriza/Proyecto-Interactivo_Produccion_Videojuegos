# res://src/scenes/minigame/focus_rush.gd
# ---------------------------------------------------------------------------
# FOCUS RUSH — Minijuego de atención ("Enfoque Rush")
# ---------------------------------------------------------------------------
# Videojuego de reflejos y atención selectiva coherente con el dominio del
# Detector de Fatiga Cognitiva. Caen tres tipos de estímulos:
#   - IDEA (círculo amarillo con visto bueno): atrápala para sumar puntos y racha.
#   - DISTRACTOR (rombo rojo, !): evítalo; si lo atrapas pierdes una vida.
#   - PAUSA ACTIVA (hexágono verde, +): recupera una vida (máx. 3).
#
# Controles: flechas izquierda/derecha o A / D (teclado), o mover el mouse / arrastrar el dedo
# sobre el campo. Esc o P pausa. Enter/Espacio confirma en los menús.
#
# Objetivo: llegar a 200 puntos antes de que pasen 45 segundos sin perder
# las 3 vidas. Al ganar se entrega un cupón de descuento (1 a 3 estrellas)
# vía EventBus.coupon_obtained, que GlobalManager persiste en disco.
#
# FSM (ver FocusRushRules.TRANSICIONES):
#   INSTRUCCIONES -> CUENTA_REGRESIVA -> JUGANDO <-> PAUSADO
#   JUGANDO -> VICTORIA | DERROTA ;  VICTORIA | DERROTA -> CUENTA_REGRESIVA
# ---------------------------------------------------------------------------
extends Control

const MENU_SCENE_PATH: String = "res://src/scenes/menu/menu_panel.tscn"
const COUPON_SCENE_PATH: String = "res://src/scenes/coupon/coupon_event.tscn"
const State = FocusRushRules.GameState
const Kind = FocusRushRules.StimulusKind

const VELOCIDAD_JUGADOR: float = 520.0

const ICONO_JUGAR: Texture2D = preload("res://src/assets/icons/icon_play.svg")
const ICONO_VOLVER: Texture2D = preload("res://src/assets/icons/icon_back.svg")
const ICONO_CUPON: Texture2D = preload("res://src/assets/icons/icon_coupon.svg")
const ICONO_SALIR: Texture2D = preload("res://src/assets/icons/icon_exit.svg")

@onready var play_area: Control = $Margin/VBox/PlayArea
@onready var lbl_puntos: Label = $Margin/VBox/HUD/LblPuntos
@onready var lbl_tiempo: Label = $Margin/VBox/HUD/LblTiempo
@onready var lbl_vidas: Label = $Margin/VBox/HUD/LblVidas
@onready var lbl_combo: Label = $Margin/VBox/HUD/LblCombo
@onready var barra_meta: ProgressBar = $Margin/VBox/BarraMeta
@onready var overlay: Control = $Overlay
@onready var lbl_overlay_titulo: Label = $Overlay/Center/Panel/Margin/VBox/LblTitulo
@onready var lbl_overlay_texto: Label = $Overlay/Center/Panel/Margin/VBox/LblTexto
@onready var btn_primario: Button = $Overlay/Center/Panel/Margin/VBox/HBox/BtnPrimario
@onready var btn_secundario: Button = $Overlay/Center/Panel/Margin/VBox/HBox/BtnSecundario
@onready var lbl_cuenta: Label = $LblCuenta

var current_state: State = State.INSTRUCCIONES

var score: int = 0
var lives: int = FocusRushRules.VIDAS_INICIALES
var lives_lost: int = 0
var streak: int = 0
var best_streak: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var countdown: float = 0.0
var target_x: float = -1.0
var last_coupon: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	print("Enfoque Rush cargado. Estado inicial: INSTRUCCIONES")
	rng.randomize()
	btn_primario.pressed.connect(_on_btn_primario)
	btn_secundario.pressed.connect(_on_btn_secundario)
	play_area.gui_input.connect(_on_play_area_input)
	play_area.resized.connect(_on_play_area_resized)
	barra_meta.max_value = FocusRushRules.META_PUNTOS
	_reiniciar_partida()
	_enter_instrucciones()

# ---------------------------------------------------------------------------
# FSM — único punto donde cambia current_state
# ---------------------------------------------------------------------------

func change_state(new_state: State) -> bool:
	if not FocusRushRules.is_transition_allowed(current_state, new_state):
		push_warning("FocusRush: transición inválida %s -> %s" % [State.keys()[current_state], State.keys()[new_state]])
		return false
	print("FocusRush: %s -> %s" % [State.keys()[current_state], State.keys()[new_state]])
	current_state = new_state
	match new_state:
		State.CUENTA_REGRESIVA:
			_enter_cuenta_regresiva()
		State.JUGANDO:
			_enter_jugando()
		State.PAUSADO:
			_enter_pausado()
		State.VICTORIA:
			_enter_victoria()
		State.DERROTA:
			_enter_derrota()
	return true

func _enter_instrucciones() -> void:
	_mostrar_overlay(
		"Enfoque Rush",
		"Atrapa las IDEAS (círculo amarillo con visto bueno) para sumar puntos.\n" +
		"Esquiva los DISTRACTORES (rombo rojo con !): cada uno te quita una vida.\n" +
		"Las PAUSAS ACTIVAS (hexágono verde con +) te devuelven una vida.\n\n" +
		"Meta: %d puntos en %d segundos. Cada 5 ideas seguidas tu racha multiplica los puntos.\n\n" % [FocusRushRules.META_PUNTOS, int(FocusRushRules.DURACION_PARTIDA)] +
		"Controles: flechas izquierda/derecha o A/D, o mueve el mouse sobre el campo. Esc o P para pausar.",
		"Comenzar", "Volver al menú")

func _enter_cuenta_regresiva() -> void:
	_reiniciar_partida()
	overlay.visible = false
	countdown = 3.0
	lbl_cuenta.visible = true
	lbl_cuenta.text = "3"

func _enter_jugando() -> void:
	overlay.visible = false
	lbl_cuenta.visible = false
	play_area.grab_focus()

func _enter_pausado() -> void:
	_mostrar_overlay("Pausa", "Tómate un respiro. El tiempo está detenido.\n\nPuntos: %d   ·   Vidas: %d" % [score, lives], "Continuar", "Abandonar partida")

func _enter_victoria() -> void:
	var tiempo_restante: float = maxf(FocusRushRules.DURACION_PARTIDA - elapsed, 0.0)
	var estrellas: int = FocusRushRules.stars_for(score, tiempo_restante, lives_lost)
	last_coupon = FocusRushRules.build_coupon(estrellas, score)
	# El minijuego NO guarda nada: solo emite la intención. GlobalManager
	# agrega el cupón a la colección y lo persiste en user://save_data.json.
	EventBus.coupon_obtained.emit(last_coupon)
	_mostrar_overlay(
		"¡Victoria! %d de 3 estrellas" % estrellas,
		"Llegaste a %d puntos con %d s de sobra (racha máxima: %d).\n\n" % [score, int(tiempo_restante), best_streak] +
		"Ganaste un cupón de $%s para compras desde $%s.\nYa quedó guardado en tu colección." % [
			FormatUtil.pesos(int(last_coupon["value"])), FormatUtil.pesos(int(last_coupon["minimum_purchase"]))],
		"Ver mi cupón", "Jugar de nuevo")

func _enter_derrota() -> void:
	var motivo: String = "Perdiste las 3 vidas: los distractores ganaron esta vez." if lives <= 0 else "Se acabó el tiempo antes de llegar a la meta."
	_mostrar_overlay("Fin de la partida", "%s\n\nPuntos: %d de %d   ·   Racha máxima: %d\nNo se otorgó cupón. ¡Inténtalo otra vez!" % [motivo, score, FocusRushRules.META_PUNTOS, best_streak], "Reintentar", "Volver al menú")

# ---------------------------------------------------------------------------
# Botones del overlay (su significado depende del estado actual)
# ---------------------------------------------------------------------------

func _on_btn_primario() -> void:
	match current_state:
		State.INSTRUCCIONES, State.DERROTA:
			change_state(State.CUENTA_REGRESIVA)
		State.PAUSADO:
			change_state(State.JUGANDO)
		State.VICTORIA:
			EventBus.navigation_requested.emit(COUPON_SCENE_PATH, false)

func _on_btn_secundario() -> void:
	match current_state:
		State.INSTRUCCIONES, State.DERROTA:
			EventBus.navigation_requested.emit(MENU_SCENE_PATH, true)
		State.PAUSADO:
			lives = 0
			change_state(State.DERROTA)
		State.VICTORIA:
			change_state(State.CUENTA_REGRESIVA)

# ---------------------------------------------------------------------------
# Bucle de juego
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	match current_state:
		State.CUENTA_REGRESIVA:
			countdown -= delta
			lbl_cuenta.text = str(int(ceil(countdown))) if countdown > 0.0 else "¡Ya!"
			if countdown <= -0.4:
				change_state(State.JUGANDO)
		State.JUGANDO:
			_actualizar_juego(delta)
	_actualizar_efectos(delta)
	play_area.queue_redraw()

func _actualizar_juego(delta: float) -> void:
	elapsed += delta
	_mover_jugador(delta)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_generar_estimulo()
		spawn_timer = FocusRushRules.spawn_interval(elapsed)

	var rect_jugador: Rect2 = play_area.player_rect().grow(play_area.RADIO_ESTIMULO * 0.6)
	var vivos: Array = []
	for s in play_area.stimuli:
		s["pos"] += Vector2(0, s["speed"] * delta)
		if rect_jugador.has_point(s["pos"]):
			_al_atrapar(s)
		elif s["pos"].y > play_area.size.y + play_area.RADIO_ESTIMULO:
			_al_escapar(s)
		else:
			vivos.append(s)
	play_area.stimuli = vivos

	_actualizar_hud()

	if score >= FocusRushRules.META_PUNTOS:
		change_state(State.VICTORIA)
	elif lives <= 0:
		change_state(State.DERROTA)
	elif elapsed >= FocusRushRules.DURACION_PARTIDA:
		change_state(State.DERROTA)

func _mover_jugador(delta: float) -> void:
	var eje: float = Input.get_axis("move_left", "move_right")
	var medio: float = play_area.ANCHO_JUGADOR / 2.0
	if absf(eje) > 0.01:
		target_x = -1.0
		play_area.player_x += eje * VELOCIDAD_JUGADOR * delta
	elif target_x >= 0.0:
		play_area.player_x = move_toward(play_area.player_x, target_x, VELOCIDAD_JUGADOR * 1.6 * delta)
	play_area.player_x = clampf(play_area.player_x, medio, maxf(play_area.size.x - medio, medio))

func _generar_estimulo() -> void:
	var tipo: int = Kind.IDEA
	var dado: float = rng.randf()
	if dado < FocusRushRules.distractor_chance(elapsed):
		tipo = Kind.DISTRACTOR
	elif dado > 0.93 and lives < FocusRushRules.VIDAS_INICIALES:
		tipo = Kind.PAUSA
	var r: float = play_area.RADIO_ESTIMULO
	var x: float = rng.randf_range(r + 6.0, maxf(play_area.size.x - r - 6.0, r + 7.0))
	play_area.stimuli.append({
		"kind": tipo,
		"pos": Vector2(x, -r),
		"speed": FocusRushRules.fall_speed(elapsed) * rng.randf_range(0.85, 1.15),
	})

func _al_atrapar(s: Dictionary) -> void:
	var p: Vector2 = s["pos"]
	match int(s["kind"]):
		Kind.IDEA:
			var puntos: int = FocusRushRules.points_for_idea(streak)
			score += puntos
			streak += 1
			best_streak = maxi(best_streak, streak)
			_flotante("+%d" % puntos, p, play_area.COLOR_IDEA)
			_pulso(lbl_puntos)
		Kind.DISTRACTOR:
			lives -= 1
			lives_lost += 1
			streak = 0
			play_area.flash = 1.0
			_flotante("-1 vida", p, play_area.COLOR_DISTRACTOR)
			_pulso(lbl_vidas)
		Kind.PAUSA:
			lives = mini(lives + 1, FocusRushRules.VIDAS_INICIALES)
			_flotante("+1 vida", p, play_area.COLOR_PAUSA)
			_pulso(lbl_vidas)

func _al_escapar(s: Dictionary) -> void:
	if int(s["kind"]) == Kind.IDEA and streak > 0:
		streak = 0
		_flotante("racha perdida", Vector2(s["pos"].x, play_area.size.y - 60), Color("#cbd5e1"))

# ---------------------------------------------------------------------------
# Entrada del usuario
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == State.JUGANDO:
			change_state(State.PAUSADO)
			get_viewport().set_input_as_handled()
		elif current_state == State.PAUSADO:
			change_state(State.JUGANDO)
			get_viewport().set_input_as_handled()

func _on_play_area_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		target_x = (event as InputEventMouseMotion).position.x
	elif event is InputEventScreenDrag:
		target_x = (event as InputEventScreenDrag).position.x
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		target_x = (event as InputEventScreenTouch).position.x

## Si la ventana pierde el foco en plena partida, se pausa automáticamente.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and current_state == State.JUGANDO:
		change_state(State.PAUSADO)

func _on_play_area_resized() -> void:
	if play_area.player_x <= 0.0:
		play_area.player_x = play_area.size.x / 2.0

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _reiniciar_partida() -> void:
	score = 0
	lives = FocusRushRules.VIDAS_INICIALES
	lives_lost = 0
	streak = 0
	best_streak = 0
	elapsed = 0.0
	spawn_timer = 0.3
	target_x = -1.0
	last_coupon = {}
	play_area.stimuli = []
	play_area.floaters = []
	play_area.player_x = play_area.size.x / 2.0
	_actualizar_hud()

func _actualizar_hud() -> void:
	lbl_puntos.text = "Puntos: %d / %d" % [score, FocusRushRules.META_PUNTOS]
	lbl_tiempo.text = "Tiempo: %d s" % int(ceil(maxf(FocusRushRules.DURACION_PARTIDA - elapsed, 0.0)))
	# Las vidas se muestran con número explícito (no solo con color/iconos).
	lbl_vidas.text = "Vidas: %d de %d" % [lives, FocusRushRules.VIDAS_INICIALES]
	lbl_combo.text = "Racha: %d (x%d)" % [streak, FocusRushRules.combo_multiplier(streak)]
	barra_meta.value = score

func _mostrar_overlay(titulo: String, texto: String, primario: String, secundario: String) -> void:
	overlay.visible = true
	lbl_overlay_titulo.text = titulo
	lbl_overlay_texto.text = texto
	btn_primario.text = primario
	btn_secundario.text = secundario
	# Iconografía de apoyo según la acción que representa cada botón.
	btn_primario.icon = ICONO_CUPON if current_state == State.VICTORIA else ICONO_JUGAR
	match current_state:
		State.VICTORIA:
			btn_secundario.icon = ICONO_JUGAR
		State.PAUSADO:
			btn_secundario.icon = ICONO_SALIR
		_:
			btn_secundario.icon = ICONO_VOLVER
	btn_primario.grab_focus.call_deferred()

func _flotante(texto: String, pos: Vector2, color: Color) -> void:
	play_area.floaters.append({"text": texto, "pos": pos + Vector2(-60, -10), "color": color, "life": 1.0})

func _actualizar_efectos(delta: float) -> void:
	var vivos: Array = []
	for f in play_area.floaters:
		f["life"] -= delta * 1.2
		f["pos"] += Vector2(0, -50 * delta)
		if f["life"] > 0.0:
			vivos.append(f)
	play_area.floaters = vivos
	play_area.flash = maxf(play_area.flash - delta * 2.5, 0.0)

## Animación Tween de "pulso" para resaltar un indicador del HUD.
func _pulso(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(control, "scale", Vector2(1.18, 1.18), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12)
