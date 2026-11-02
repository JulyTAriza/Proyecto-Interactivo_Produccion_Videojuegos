# res://src/scenes/gamification/infusion_rush/infusion_rush_main.gd
# ---------------------------------------------------------------------------
# INFUSIÓN RUSH — Controlador de la partida (Laboratorio 6)
# ---------------------------------------------------------------------------
# Prepara y entrega infusiones relajantes antes de que se acabe el tiempo.
# Este controlador NO maneja el estado de cada taza (eso lo hace la FSM de
# cup.gd): solo lleva el progreso global (entregas, tiempo, victoria o
# derrota) y, al ganar, publica el cupón en el EventBus.
# ---------------------------------------------------------------------------
extends Node2D

const JUEGO_ID: String = "infusion_rush"

@export var target_cups: int = 4
@export var coupon_value: int = 4000
@export var coupon_minimum_value: int = 18000

@onready var delivery_area: Area2D = $DeliveryArea
@onready var timer_gameover: Timer = $TimerGameover
@onready var lbl_count: Label = $CanvasLayer/UI/HUD/LabelCupCount
@onready var lbl_timer: Label = $CanvasLayer/UI/HUD/LabelTimeCounter
@onready var lbl_intentos: Label = $CanvasLayer/UI/HUD/LblIntentos
@onready var panel: Control = $CanvasLayer/UI/Panel
@onready var lbl_title: Label = $CanvasLayer/UI/Panel/Margin/VBoxContainer/LabelTitle
@onready var lbl_desc: Label = $CanvasLayer/UI/Panel/Margin/VBoxContainer/LabelDesc
@onready var lbl_final: Label = $CanvasLayer/UI/Panel/Margin/VBoxContainer/LabelCount
@onready var btn_panel: Button = $CanvasLayer/UI/Panel/Margin/VBoxContainer/BtnVolverJuegos

var cups_delivered: int = 0
var finished: bool = false
var last_coupon: Dictionary = {}

func _ready() -> void:
	panel.hide()
	delivery_area.cup_delivered.connect(_on_cup_delivered)
	timer_gameover.timeout.connect(_on_general_timer_timeout)
	if not GlobalManager.registrar_intento(JUEGO_ID):
		_terminar()
		show_panel("Sin intentos", "Ya usaste tus %d intentos de esta sesión." % GlobalManager.MAX_INTENTOS_SESION, "")
		return
	lbl_intentos.text = "Intentos restantes en la sesión: %d" % GlobalManager.intentos_restantes(JUEGO_ID)
	_actualizar_contador()
	timer_gameover.start()

func _process(_delta: float) -> void:
	if not finished:
		lbl_timer.text = "Tiempo: %d" % ceili(timer_gameover.time_left)

func _on_cup_delivered() -> void:
	if finished:
		return
	cups_delivered += 1
	_actualizar_contador()
	if cups_delivered >= target_cups:
		finish_game()
	else:
		var spawns: Array = get_tree().get_nodes_in_group("cup_spawn")
		spawns.pick_random().spawn_cup()

func _actualizar_contador() -> void:
	lbl_count.text = "Infusiones: %d / %d" % [cups_delivered, target_cups]

func _on_general_timer_timeout() -> void:
	if finished:
		return
	_terminar()
	show_panel("Pedido incompleto", "Se agotó el tiempo.", "Infusiones entregadas: %d / %d" % [cups_delivered, target_cups])

func finish_game() -> void:
	if finished:
		return
	_terminar()
	last_coupon = GlobalManager.crear_cupon(coupon_value, coupon_minimum_value, "INFUSION",
		"Infusión Rush (%d infusiones)" % cups_delivered)
	EventBus.coupon_obtained.emit(last_coupon)
	show_panel("¡Pedido completado!", "Entregaste todas las infusiones. Ganaste un cupón de $%s (compra mínima $%s)." % [
		FormatUtil.pesos(coupon_value), FormatUtil.pesos(coupon_minimum_value)],
		"Infusiones entregadas: %d / %d" % [cups_delivered, target_cups])

## Flujo común de finalización (victoria o derrota): detiene el reloj,
## bloquea las tazas, deja de generar y oculta el HUD de juego.
func _terminar() -> void:
	finished = true
	timer_gameover.stop()
	for spawn in get_tree().get_nodes_in_group("cup_spawn"):
		for hijo in spawn.get_children():
			if hijo.has_method("bloquear"):
				hijo.bloquear()
	hide_hud()

func hide_hud() -> void:
	lbl_timer.hide()
	lbl_count.hide()

func show_panel(title: String, desc: String, count: String) -> void:
	lbl_title.text = title
	lbl_desc.text = desc
	lbl_final.text = count
	lbl_final.visible = not count.is_empty()
	panel.show()
	btn_panel.grab_focus.call_deferred()
