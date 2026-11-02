# res://src/scenes/gamification/catch_energy/catch_energy.gd
# ---------------------------------------------------------------------------
# ATRAPA LA ENERGÍA — Controlador de la partida (Laboratorio 5)
# ---------------------------------------------------------------------------
# Minijuego de físicas: el jugador (CharacterBody2D) se mueve con las
# acciones del Input Map y recoge recursos de bienestar (RigidBody2D) que
# generan varios spawners. Las paredes del embudo y el suelo son
# StaticBody2D. La interfaz (HUD y panel de resultado) vive en un
# CanvasLayer para quedar fija respecto a la pantalla.
#
# Al ganar, el minijuego PUBLICA el cupón en EventBus.coupon_obtained.
# No conoce la tienda ni la factura: GlobalManager lo recibe, lo guarda y
# la factura aplica el mejor cupón válido (desacoplamiento, ADR-004).
# ---------------------------------------------------------------------------
extends Node2D

const JUEGO_ID: String = "catch_energy"

@export var target_items: int = 8
@export var max_spawned_items: int = 16
@export var coupon_value: int = 2500
@export var coupon_minimum_value: int = 12000

@onready var objective: Label = $CanvasLayer/UI/HUD/Objective
@onready var lbl_intentos: Label = $CanvasLayer/UI/HUD/LblIntentos
@onready var result_panel: Control = $CanvasLayer/UI/ResultPanel
@onready var result_label: Label = $CanvasLayer/UI/ResultPanel/Margin/VBox/ResultLabel
@onready var btn_resultado: Button = $CanvasLayer/UI/ResultPanel/Margin/VBox/BtnVolverJuegos

var current_spawned_items: int = 0
var collected_items: int = 0
var game_finished: bool = false
var last_coupon: Dictionary = {}

func _ready() -> void:
	result_panel.hide()
	var spawners: Array = get_tree().get_nodes_in_group("spawner")
	for spawn in spawners:
		spawn.spawned_item.connect(_on_item_spawned)
	if not GlobalManager.registrar_intento(JUEGO_ID):
		# Reto 1 del Lab 5: sin intentos disponibles no se inicia la partida.
		_detener_partida()
		result_label.text = "Ya usaste tus %d intentos de esta sesión.\nVuelve a abrir la aplicación para participar de nuevo." % GlobalManager.MAX_INTENTOS_SESION
		result_panel.show()
		btn_resultado.grab_focus.call_deferred()
		return
	lbl_intentos.text = "Intentos restantes en la sesión: %d" % GlobalManager.intentos_restantes(JUEGO_ID)
	_actualizar_objetivo()

func _on_item_spawned() -> void:
	current_spawned_items += 1
	if current_spawned_items > max_spawned_items:
		lose_game()

## Conectada desde el editor a la señal collected_food del jugador.
func _on_player_collected_food() -> void:
	if game_finished:
		return
	collected_items += 1
	_actualizar_objetivo()
	if collected_items >= target_items:
		win_game()

func _actualizar_objetivo() -> void:
	objective.text = "Energía recolectada: %d / %d" % [collected_items, target_items]

func win_game() -> void:
	if game_finished:
		return
	clean_game()
	last_coupon = GlobalManager.crear_cupon(coupon_value, coupon_minimum_value, "ENERGIA",
		"Atrapa la Energía (%d de %d)" % [collected_items, target_items])
	EventBus.coupon_obtained.emit(last_coupon)
	result_label.text = "¡Cupón obtenido: $%s!\nVálido en compras desde $%s." % [
		FormatUtil.pesos(coupon_value), FormatUtil.pesos(coupon_minimum_value)]
	result_panel.show()
	btn_resultado.grab_focus.call_deferred()

func lose_game() -> void:
	if game_finished:
		return
	clean_game()
	result_label.text = "No obtuviste el cupón.\nRecolectaste %d de %d." % [collected_items, target_items]
	result_panel.show()
	btn_resultado.grab_focus.call_deferred()

func clean_game() -> void:
	if game_finished:
		return
	_detener_partida()
	var jugador: Node = get_node_or_null("Player")
	if jugador:
		jugador.queue_free()

func _detener_partida() -> void:
	game_finished = true
	for spawn in get_tree().get_nodes_in_group("spawner"):
		spawn.queue_free()
