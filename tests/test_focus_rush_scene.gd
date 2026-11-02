# res://tests/test_focus_rush_scene.gd
# ---------------------------------------------------------------------------
# Laboratorio 10 — Pruebas de la ESCENA del minijuego con scene_runner.
# Validan la FSM real de focus_rush.tscn y su integración con GlobalManager.
# ---------------------------------------------------------------------------
extends GdUnitTestSuite

const S = FocusRushRules.GameState
const TEST_SAVE_PATH: String = "user://test_scene_save_data.json"

var ruta_original: String
var cupones_originales: Array

func before_test() -> void:
	ruta_original = GlobalManager.save_path
	cupones_originales = GlobalManager.coupons.duplicate(true)
	GlobalManager.save_path = TEST_SAVE_PATH
	GlobalManager.coupons = []

func after_test() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	GlobalManager.save_path = ruta_original
	GlobalManager.coupons = cupones_originales
	GlobalManager.last_coupon = {}

func _iniciar_partida(runner: GdUnitSceneRunner) -> Node:
	var juego: Node = runner.scene()
	assert_int(juego.current_state).is_equal(S.INSTRUCCIONES)
	juego.change_state(S.CUENTA_REGRESIVA)
	juego.change_state(S.JUGANDO)
	return juego

## Issue #4: abandonar desde la pausa mostraba "Perdiste las 3 vidas".
func test_abandon_from_pause_shows_abandon_message() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://src/scenes/minigame/focus_rush.tscn")
	var juego: Node = _iniciar_partida(runner)
	juego.change_state(S.PAUSADO)
	juego._on_btn_secundario()  # "Abandonar partida"
	assert_int(juego.current_state).is_equal(S.DERROTA)
	assert_str(juego.lbl_overlay_texto.text).contains("Abandonaste la partida")

## Al alcanzar la meta, el juego pasa a VICTORIA y entrega UN cupón vía
## EventBus, que GlobalManager agrega y guarda.
func test_reaching_goal_wins_and_grants_one_coupon() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://src/scenes/minigame/focus_rush.tscn")
	var juego: Node = _iniciar_partida(runner)
	juego.score = FocusRushRules.META_PUNTOS
	await runner.simulate_frames(3)
	assert_int(juego.current_state).is_equal(S.VICTORIA)
	assert_int(GlobalManager.coupons.size()).is_equal(1)
	assert_bool(FileAccess.file_exists(TEST_SAVE_PATH)).is_true()
	# Una victoria no puede repetirse sin jugar otra partida.
	assert_bool(juego.change_state(S.VICTORIA)).is_false()
	assert_int(GlobalManager.coupons.size()).is_equal(1)

func test_running_out_of_time_is_a_defeat_without_coupon() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://src/scenes/minigame/focus_rush.tscn")
	var juego: Node = _iniciar_partida(runner)
	juego.elapsed = FocusRushRules.DURACION_PARTIDA
	await runner.simulate_frames(2)
	assert_int(juego.current_state).is_equal(S.DERROTA)
	assert_str(juego.lbl_overlay_texto.text).contains("Se acabó el tiempo")
	assert_int(GlobalManager.coupons.size()).is_equal(0)
