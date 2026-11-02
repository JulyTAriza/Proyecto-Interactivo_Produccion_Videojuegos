# res://tests/test_kit_subtotal.gd
# ---------------------------------------------------------------------------
# Laboratorio 10 — RETO AUTÓNOMO (1/2): cálculo del subtotal del Kit
# Anti-Fatiga a partir de los recursos WellnessItemData (Lab 9).
# Casos normales, vacíos y límite.
# ---------------------------------------------------------------------------
extends GdUnitTestSuite

const GlobalManagerScript = preload("res://src/core/global_manager.gd")
var manager

func before() -> void:
	manager = GlobalManagerScript.new()

func after() -> void:
	manager.free()

func test_catalog_has_valid_resources() -> void:
	assert_int(manager.wellness_items.size()).is_equal(9)
	for item: WellnessItemData in manager.wellness_items:
		assert_bool(item.is_valid()).override_failure_message("Recurso inválido: %s" % item.resource_path).is_true()
		assert_object(item.texture).is_not_null()

func test_full_kit_subtotal_is_sum_of_resource_prices() -> void:
	var sel: Dictionary = {"bebida": "agua", "snack": "barra", "actividad": "mindfulness"}
	assert_int(manager.calculate_kit_subtotal(sel)).is_equal(3000 + 3500 + 12000)

func test_empty_kit_subtotal_is_zero() -> void:
	assert_int(manager.calculate_kit_subtotal({"bebida": "", "snack": "", "actividad": ""})).is_equal(0)

func test_unknown_ids_do_not_add_to_subtotal() -> void:
	var sel: Dictionary = {"bebida": "cafe_triple", "snack": "fruta", "actividad": ""}
	assert_int(manager.calculate_kit_subtotal(sel)).is_equal(5000)

func test_kit_relief_is_sum_of_resource_relief() -> void:
	var sel: Dictionary = {"bebida": "te", "snack": "frutos_secos", "actividad": "siesta"}
	assert_int(manager.calculate_kit_relief(sel)).is_equal(4 + 4 + 7)

## Límite con cupones: el kit más barato posible ($3.000 + $3.500 + $8.000
## = $14.500) no alcanza el cupón de 2 estrellas (mín. $15.000).
func test_cheapest_full_kit_vs_coupon_minimum() -> void:
	var sel: Dictionary = {"bebida": "agua", "snack": "barra", "actividad": "pausa_activa"}
	var subtotal: int = manager.calculate_kit_subtotal(sel)
	manager.coupons = [{"value": 3000, "minimum_purchase": 15000}]
	assert_int(subtotal).is_equal(14500)
	assert_bool(manager.get_best_coupon(subtotal).is_empty()).is_true()
