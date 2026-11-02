# res://tests/test_focus_rush_rules.gd
# ---------------------------------------------------------------------------
# Laboratorio 10 — RETO AUTÓNOMO (2/2): reglas del minijuego Enfoque Rush
# (transiciones de la FSM, combos, estrellas y cupón otorgado).
# ---------------------------------------------------------------------------
extends GdUnitTestSuite

const S = FocusRushRules.GameState

func test_valid_fsm_transitions() -> void:
	assert_bool(FocusRushRules.is_transition_allowed(S.INSTRUCCIONES, S.CUENTA_REGRESIVA)).is_true()
	assert_bool(FocusRushRules.is_transition_allowed(S.JUGANDO, S.PAUSADO)).is_true()
	assert_bool(FocusRushRules.is_transition_allowed(S.PAUSADO, S.JUGANDO)).is_true()
	assert_bool(FocusRushRules.is_transition_allowed(S.JUGANDO, S.VICTORIA)).is_true()

func test_invalid_fsm_transitions_are_rejected() -> void:
	# No se puede ganar sin jugar, ni pausar desde las instrucciones, ni
	# volver a ganar (y cobrar otro cupón) desde la pantalla de victoria.
	assert_bool(FocusRushRules.is_transition_allowed(S.INSTRUCCIONES, S.VICTORIA)).is_false()
	assert_bool(FocusRushRules.is_transition_allowed(S.INSTRUCCIONES, S.PAUSADO)).is_false()
	assert_bool(FocusRushRules.is_transition_allowed(S.VICTORIA, S.VICTORIA)).is_false()
	assert_bool(FocusRushRules.is_transition_allowed(S.PAUSADO, S.VICTORIA)).is_false()

func test_combo_multiplier_boundaries() -> void:
	assert_int(FocusRushRules.combo_multiplier(0)).is_equal(1)
	assert_int(FocusRushRules.combo_multiplier(4)).is_equal(1)
	assert_int(FocusRushRules.combo_multiplier(5)).is_equal(2)
	assert_int(FocusRushRules.combo_multiplier(9)).is_equal(2)
	assert_int(FocusRushRules.combo_multiplier(10)).is_equal(3)
	assert_int(FocusRushRules.points_for_idea(12)).is_equal(30)

func test_stars_depend_on_goal_time_and_lives() -> void:
	assert_int(FocusRushRules.stars_for(199, 30.0, 0)).is_equal(0)   # no llegó a la meta
	assert_int(FocusRushRules.stars_for(200, 5.0, 2)).is_equal(1)    # ganó justo
	assert_int(FocusRushRules.stars_for(200, 15.0, 1)).is_equal(2)   # límite de 15 s
	assert_int(FocusRushRules.stars_for(220, 20.0, 0)).is_equal(3)   # sin perder vidas

func test_coupon_tiers() -> void:
	assert_bool(FocusRushRules.build_coupon(0, 150).is_empty()).is_true()
	var c3: Dictionary = FocusRushRules.build_coupon(3, 230)
	assert_int(int(c3["value"])).is_equal(5000)
	assert_int(int(c3["minimum_purchase"])).is_equal(20000)
	assert_str(str(c3["id"])).starts_with("CUP-")

func test_difficulty_is_progressive_and_bounded() -> void:
	assert_float(FocusRushRules.spawn_interval(0.0)).is_greater(FocusRushRules.spawn_interval(45.0))
	assert_float(FocusRushRules.fall_speed(45.0)).is_greater(FocusRushRules.fall_speed(0.0))
	assert_float(FocusRushRules.distractor_chance(999.0)).is_equal(0.45)
