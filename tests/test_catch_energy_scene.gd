# res://tests/test_catch_energy_scene.gd
# ---------------------------------------------------------------------------
# Pruebas del minijuego de físicas "Atrapa la Energía" (Laboratorio 5).
# Se ejecuta la escena real: spawners, RigidBody2D, CharacterBody2D y Area2D.
# ---------------------------------------------------------------------------
extends GdUnitTestSuite

const ESCENA: String = "res://src/scenes/gamification/catch_energy/catch_energy.tscn"
const TEST_SAVE_PATH: String = "user://test_catch_save_data.json"

var ruta_original: String
var cupones_originales: Array

func before_test() -> void:
	ruta_original = GlobalManager.save_path
	cupones_originales = GlobalManager.coupons.duplicate(true)
	GlobalManager.save_path = TEST_SAVE_PATH
	GlobalManager.coupons = []
	GlobalManager.intentos_sesion = {}

func after_test() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	GlobalManager.save_path = ruta_original
	GlobalManager.coupons = cupones_originales
	GlobalManager.intentos_sesion = {}

## El jugador se mueve con las ACCIONES del Input Map, no con teclas fijas.
func test_player_moves_with_input_actions() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var jugador: CharacterBody2D = runner.scene().get_node("Player")
	var x_inicial: float = jugador.global_position.x
	Input.action_press("move_right")
	await runner.simulate_frames(20)
	Input.action_release("move_right")
	assert_float(jugador.global_position.x).is_greater(x_inicial + 50.0)

## Los spawners generan RigidBody2D del grupo "collectable".
func test_spawners_generate_collectable_rigid_bodies() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	await runner.simulate_frames(130, 16)
	var objetos: Array = runner.scene().get_tree().get_nodes_in_group("collectable")
	assert_int(objetos.size()).is_greater(0)
	assert_object(objetos[0]).is_instanceof(RigidBody2D)

## Un bot sigue al objeto más bajo; al recolectar la meta se gana el
## cupón y GlobalManager lo recibe por el EventBus.
func test_bot_collects_goal_and_wins_coupon() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var juego: Node = runner.scene()
	var frames: int = 0
	while not juego.game_finished and frames < 60 * 90:
		_bot(juego)
		await runner.simulate_frames(1, 16)
		frames += 1
	assert_bool(juego.game_finished).is_true()
	assert_int(juego.collected_items).is_greater_equal(juego.target_items)
	assert_int(GlobalManager.coupons.size()).is_equal(1)
	assert_str(str(GlobalManager.coupons[0]["code"])).starts_with("ENERGIA")

## Reto 1 del Lab 5: máximo tres intentos por sesión.
func test_fourth_attempt_is_blocked() -> void:
	GlobalManager.intentos_sesion = {"catch_energy": GlobalManager.MAX_INTENTOS_SESION}
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var juego: Node = runner.scene()
	await runner.simulate_frames(2)
	assert_bool(juego.game_finished).is_true()
	assert_bool(juego.result_panel.visible).is_true()
	assert_int(juego.get_tree().get_nodes_in_group("spawner").size()).is_equal(0)

func _bot(juego: Node) -> void:
	var jugador: Node2D = juego.get_node_or_null("Player")
	if jugador == null:
		return
	var objetivo: Node2D = null
	for o in juego.get_tree().get_nodes_in_group("collectable"):
		var item: Node2D = o
		if objetivo == null or item.global_position.y > objetivo.global_position.y:
			objetivo = item
	Input.action_release("move_left")
	Input.action_release("move_right")
	if objetivo == null:
		return
	var dx: float = objetivo.global_position.x - jugador.global_position.x
	if dx > 12.0:
		Input.action_press("move_right")
	elif dx < -12.0:
		Input.action_press("move_left")
