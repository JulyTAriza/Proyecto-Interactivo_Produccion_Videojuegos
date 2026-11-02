# res://src/scenes/gamification/catch_energy/player.gd
# ---------------------------------------------------------------------------
# JUGADOR de "Atrapa la Energía" (Laboratorio 5)
# ---------------------------------------------------------------------------
# CharacterBody2D controlado por código. La entrada se lee mediante las
# ACCIONES del Input Map (move_left / move_right), no mediante teclas
# concretas: "move_left" significa "el usuario quiere ir a la izquierda",
# venga de A, de la flecha izquierda o de otro dispositivo.
#
# La recolección se detecta con un Area2D (AreaRecolect) independiente de
# la colisión física del cuerpo. El jugador no sabe cómo se gana: solo
# emite la señal collected_food y el controlador de la escena decide.
# ---------------------------------------------------------------------------
extends CharacterBody2D

signal collected_food

@export var speed: float = 420.0

@onready var area_recolect: Area2D = $AreaRecolect

func _ready() -> void:
	area_recolect.body_entered.connect(_on_collect_area_body_entered)

func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed
	velocity.y = 0.0
	move_and_slide()

func _on_collect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("collectable"):
		collected_food.emit()
		body.queue_free()
