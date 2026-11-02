# res://tests/test_cup_fsm.gd
# ---------------------------------------------------------------------------
# Pruebas de la Máquina de Estado Finito de la taza (Laboratorio 6) y del
# flujo completo de "Infusión Rush" hasta obtener el cupón.
# ---------------------------------------------------------------------------
extends GdUnitTestSuite

const CS = preload("res://src/scenes/gamification/infusion_rush/cup.gd").CupState
const ESCENA: String = "res://src/scenes/gamification/infusion_rush/infusion_rush_main.tscn"
const TEST_SAVE_PATH: String = "user://test_infusion_save_data.json"

var ruta_original: String
var cupones_originales: Array

func before_test() -> void:
	ruta_original = GlobalManager.save_path
	cupones_originales = GlobalManager.coupons.duplicate(true)
	GlobalManager.save_path = TEST_SAVE_PATH
	GlobalManager.coupons = []
	GlobalManager.intentos_sesion = {}

func after_test() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	GlobalManager.save_path = ruta_original
	GlobalManager.coupons = cupones_originales
	GlobalManager.intentos_sesion = {}

func _primera_taza(juego: Node) -> Node:
	return juego.get_node("MesaSuperior").get_child(2)

## Transiciones permitidas y rechazadas de la FSM.
func test_transition_table() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var taza: Node = _primera_taza(runner.scene())
	assert_int(taza.current_state).is_equal(CS.FRIA)
	assert_bool(taza.change_state(CS.ARRASTRANDO)).is_false()   # fría: no se puede tomar
	assert_bool(taza.change_state(CS.ENTREGADA)).is_false()
	assert_bool(taza.change_state(CS.DISPONIBLE)).is_true()
	assert_bool(taza.change_state(CS.INFUSIONANDO)).is_false()  # hay que arrastrarla primero
	assert_bool(taza.change_state(CS.ARRASTRANDO)).is_true()
	assert_bool(taza.change_state(CS.INFUSIONANDO)).is_true()
	assert_bool(taza.change_state(CS.ENTREGADA)).is_false()     # sin terminar la infusión
	assert_bool(taza.change_state(CS.LISTA)).is_true()
	assert_int(taza.previous_state).is_equal(CS.INFUSIONANDO)

## Cada taza tiene su propio estado (varias instancias independientes).
func test_cups_keep_independent_states() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var juego: Node = runner.scene()
	var a: Node = _primera_taza(juego)
	var b: Node = juego.get_node("MesaInferior").get_child(2)
	a.change_state(CS.DISPONIBLE)
	assert_int(a.current_state).is_equal(CS.DISPONIBLE)
	assert_int(b.current_state).is_equal(CS.FRIA)

## El temporizador produce la transición FRIA -> DISPONIBLE.
func test_timer_warms_cup() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var taza: Node = _primera_taza(runner.scene())
	taza.timer.start(0.05)
	await runner.simulate_frames(10, 16)
	assert_int(taza.current_state).is_equal(CS.DISPONIBLE)

## Flujo completo: preparar en la estación, entregar 4 tazas y ganar.
func test_full_flow_delivers_and_wins_coupon() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var juego: Node = runner.scene()
	var estacion: Area2D = juego.get_node("EstacionA")
	var entrega: Area2D = juego.get_node("DeliveryArea")
	for i in juego.target_cups:
		var taza: Node = _taza_activa(juego)
		assert_object(taza).is_not_null()
		taza.change_state(CS.DISPONIBLE)
		taza.change_state(CS.ARRASTRANDO)
		# Se "suelta" la taza sobre la estación. Mientras se espera a que el
		# motor actualice los solapamientos, se pausa su _physics_process
		# para que no siga al puntero (en modo headless no hay mouse).
		taza.bloqueada = true
		taza.global_position = estacion.global_position
		await runner.simulate_frames(3, 16)
		taza.bloqueada = false
		taza.release_cup()
		assert_int(taza.current_state).is_equal(CS.INFUSIONANDO)
		assert_bool(estacion.ocupada).is_true()
		taza.timer.start(0.05)
		await runner.simulate_frames(10, 16)
		assert_int(taza.current_state).is_equal(CS.LISTA)
		assert_bool(estacion.ocupada).is_false()
		taza.change_state(CS.ARRASTRANDO)
		taza.bloqueada = true
		taza.global_position = entrega.global_position
		await runner.simulate_frames(3, 16)
		taza.bloqueada = false
		taza.release_cup()
		assert_int(taza.current_state).is_equal(CS.ENTREGADA)
		await runner.simulate_frames(25, 16)
	assert_int(juego.cups_delivered).is_equal(juego.target_cups)
	assert_bool(juego.finished).is_true()
	assert_int(GlobalManager.coupons.size()).is_equal(1)
	assert_str(str(GlobalManager.coupons[0]["code"])).starts_with("INFUSION")

## Al agotarse el tiempo se pierde y no hay cupón.
func test_time_out_is_defeat() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ESCENA)
	var juego: Node = runner.scene()
	juego.timer_gameover.start(0.05)
	await runner.simulate_frames(10, 16)
	assert_bool(juego.finished).is_true()
	assert_str(juego.lbl_title.text).is_equal("Pedido incompleto")
	assert_int(GlobalManager.coupons.size()).is_equal(0)

func _taza_activa(juego: Node) -> Node:
	for spawn in juego.get_tree().get_nodes_in_group("cup_spawn"):
		for hijo in spawn.get_children():
			if hijo is CharacterBody2D and hijo.current_state == CS.FRIA:
				return hijo
	return null
