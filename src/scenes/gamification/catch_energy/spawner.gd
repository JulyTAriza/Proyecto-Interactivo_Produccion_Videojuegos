# res://src/scenes/gamification/catch_energy/spawner.gd
# ---------------------------------------------------------------------------
# GENERADOR DE OBJETOS (Laboratorio 5)
# ---------------------------------------------------------------------------
# El Timer decide CUÁNDO intentar generar; max_active_items decide SI se
# puede generar. Separar ambas condiciones permite ajustar la dificultad
# desde el Inspector sin tocar la mecánica de movimiento ni de colisión.
# Cada spawner pertenece al grupo "spawner" y avisa con spawned_item al
# controlador de la partida.
# ---------------------------------------------------------------------------
extends Node2D

signal spawned_item

@export var max_active_items: int = 4
@export var spawn_interval: float = 1.0
@export var collectable_scene: PackedScene
@export var use_parabola: bool = false

@onready var timer: Timer = $Timer

var active_items: int = 0

func _ready() -> void:
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_spawn_timer_timeout)
	timer.start()

func _on_spawn_timer_timeout() -> void:
	if active_items >= max_active_items:
		return
	spawned_item.emit()
	var spawn_position: Vector2 = global_position
	if use_parabola:
		spawn_from_side(spawn_position, Vector2(randf_range(-260.0, 260.0), -250.0))
	else:
		spawn_item(spawn_position)

func spawn_item(spawn_position: Vector2) -> void:
	var item: RigidBody2D = collectable_scene.instantiate()
	item.global_position = spawn_position
	get_parent().add_child(item)
	item.apply_central_impulse(Vector2(0, -100))
	_registrar(item)

func spawn_from_side(spawn_position: Vector2, impulse: Vector2) -> void:
	var item: RigidBody2D = collectable_scene.instantiate()
	item.global_position = spawn_position
	get_parent().add_child(item)
	item.apply_central_impulse(impulse)
	_registrar(item)

## Lleva la cuenta de objetos activos: cuando un objeto sale del árbol
## (recolectado o destruido al tocar el suelo) se libera su cupo.
func _registrar(item: Node) -> void:
	active_items += 1
	item.tree_exited.connect(func() -> void: active_items -= 1)

func detener() -> void:
	timer.stop()
