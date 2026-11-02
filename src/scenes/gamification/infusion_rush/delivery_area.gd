# res://src/scenes/gamification/infusion_rush/delivery_area.gd
# ---------------------------------------------------------------------------
# ZONA DE ENTREGA (Laboratorio 6)
# ---------------------------------------------------------------------------
# No decide si una taza puede entregarse (eso lo valida la FSM de la taza):
# solo comunica que la entrega fue válida y anima el cierre de la bandeja.
# ---------------------------------------------------------------------------
extends Area2D

signal cup_delivered

@onready var sprite: Sprite2D = $Sprite2D

func confirm_delivery() -> void:
	cup_delivered.emit()
	_animar_cierre()

## Tween de "cierre": la bandeja se aplasta, se desvanece y vuelve vacía.
func _animar_cierre() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.15, 0.7), 0.12)
	tween.tween_property(sprite, "modulate:a", 0.2, 0.15)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.01)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.25)
