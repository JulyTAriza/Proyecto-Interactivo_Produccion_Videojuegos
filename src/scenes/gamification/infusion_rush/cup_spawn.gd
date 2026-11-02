# res://src/scenes/gamification/infusion_rush/cup_spawn.gd
# ---------------------------------------------------------------------------
# MESA GENERADORA DE TAZAS (equivalente a PizzaSpawn del Laboratorio 6)
# ---------------------------------------------------------------------------
# Grupo "cup_spawn". Crea una taza sobre la mesa al iniciar; el
# controlador de la partida le pide otra después de cada entrega.
# ---------------------------------------------------------------------------
extends Node2D

@export var cup_scene: PackedScene
@export var spawn_on_ready: bool = true

func _ready() -> void:
	if spawn_on_ready:
		spawn_cup()

func spawn_cup() -> Node2D:
	var cup: Node2D = cup_scene.instantiate()
	add_child(cup)
	cup.global_position = global_position + Vector2(0, -50)
	return cup
