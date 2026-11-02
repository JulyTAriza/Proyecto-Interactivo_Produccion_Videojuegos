# res://src/scenes/gamification/catch_energy/falling_item.gd
# ---------------------------------------------------------------------------
# OBJETO QUE CAE (Laboratorio 5)
# ---------------------------------------------------------------------------
# RigidBody2D: el motor de físicas lo mueve (gravedad, impulsos, rebotes
# definidos en su PhysicsMaterial). Tiene contact_monitor activo para poder
# emitir body_entered; si toca el suelo (grupo "floor") se destruye y el
# jugador pierde esa energía. Pertenece al grupo "collectable".
# ---------------------------------------------------------------------------
extends RigidBody2D

## Texturas posibles (recursos del catálogo de bienestar del proyecto).
@export var texturas: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not texturas.is_empty():
		sprite.texture = texturas.pick_random()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("floor"):
		queue_free()
