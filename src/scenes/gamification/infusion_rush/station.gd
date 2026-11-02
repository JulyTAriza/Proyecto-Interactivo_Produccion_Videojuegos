# res://src/scenes/gamification/infusion_rush/station.gd
# ---------------------------------------------------------------------------
# ESTACIÓN DE INFUSIÓN (equivalente al "horno" del Laboratorio 6)
# ---------------------------------------------------------------------------
# No decide nada sobre la taza: la taza controla su propia FSM y la
# estación solo reacciona al resultado cambiando su color.
# ---------------------------------------------------------------------------
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var ocupada: bool = false

func activate() -> void:
	ocupada = true
	sprite.modulate = Color(1.0, 0.6, 0.35)

func deactivate() -> void:
	ocupada = false
	sprite.modulate = Color.WHITE
