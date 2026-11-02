# res://tests/test_global_manager.gd
# ---------------------------------------------------------------------------
# Laboratorio 10 — Pruebas UNITARIAS de reglas de negocio de GlobalManager
# (UNI-01: selección del mejor cupón) + casos límite y persistencia aislada.
# Se instancia el script directamente (sin agregarlo al árbol): _ready() no
# se ejecuta, por lo que no se conecta al EventBus ni lee datos reales.
# ---------------------------------------------------------------------------
class_name TestGlobalManager
extends GdUnitTestSuite

const GlobalManagerScript = preload("res://src/core/global_manager.gd")
const TEST_SAVE_PATH: String = "user://test_unit_save_data.json"

var manager

func before() -> void:
	manager = GlobalManagerScript.new()

func after() -> void:
	manager.free()

func before_test() -> void:
	manager.coupons = []
	manager.purchases = []
	manager.save_path = TEST_SAVE_PATH

func after_test() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))

# --- Casos exigidos por la guía (UNI-01) ------------------------------------

func test_returns_coupon_when_subtotal_is_sufficient() -> void:
	manager.coupons = [{"value": 2000, "minimum_purchase": 10000}]
	var result = manager.get_best_coupon(12000)
	assert_object(result).is_equal({"value": 2000, "minimum_purchase": 10000})

func test_returns_empty_when_no_coupon_valid() -> void:
	manager.coupons = [{"value": 2000, "minimum_purchase": 10000}]
	var result = manager.get_best_coupon(9999)
	assert_bool(result.is_empty()).is_true()

func test_selects_highest_value_coupon() -> void:
	manager.coupons = [
		{"value": 1000, "minimum_purchase": 5000},
		{"value": 3000, "minimum_purchase": 10000}
	]
	var result = manager.get_best_coupon(12000)
	assert_object(result).is_equal({"value": 3000, "minimum_purchase": 10000})

# --- Casos límite adicionales ------------------------------------------------

## Límite exacto: subtotal == compra mínima SÍ debe aplicar (>=, no >).
func test_coupon_applies_when_subtotal_equals_minimum() -> void:
	manager.coupons = [{"value": 2000, "minimum_purchase": 10000}]
	assert_bool(manager.get_best_coupon(10000).is_empty()).is_false()

## Un cupón más valioso pero inalcanzable no debe ganar al alcanzable.
func test_ignores_higher_coupon_that_is_not_reachable() -> void:
	manager.coupons = [
		{"value": 5000, "minimum_purchase": 20000},
		{"value": 2000, "minimum_purchase": 10000}
	]
	assert_int(int(manager.get_best_coupon(15000)["value"])).is_equal(2000)

func test_apply_coupon_never_returns_negative_total() -> void:
	assert_int(manager.apply_coupon(1500, {"value": 2000, "minimum_purchase": 0})).is_equal(0)

func test_apply_coupon_respects_minimum_purchase() -> void:
	assert_int(manager.apply_coupon(9000, {"value": 2000, "minimum_purchase": 10000})).is_equal(9000)
	assert_int(manager.apply_coupon(25000, {"value": 5000, "minimum_purchase": 20000})).is_equal(20000)

## Regresión del Issue #1: JSON devuelve 2000.0; tras guardar y cargar, los
## valores deben seguir siendo enteros y el cupón debe seguir siendo elegible.
func test_save_and_load_round_trip_keeps_int_values() -> void:
	manager.coupons = [{"id": "A", "value": 3000, "minimum_purchase": 15000}]
	manager.save_coupons()
	manager.coupons = []
	manager.load_coupons()
	assert_int(manager.coupons.size()).is_equal(1)
	assert_int(typeof(manager.coupons[0]["value"])).is_equal(TYPE_INT)
	assert_object(manager.get_best_coupon(15000)).is_equal({"id": "A", "value": 3000, "minimum_purchase": 15000})

## Regresión del Issue #5 (hallado en la sesión de depuración).
func test_load_normalizes_purchase_numbers() -> void:
	manager.purchases = [{"items": ["te"], "subtotal": 22500, "discount": 3000, "total": 19500,
		"coupon": {"id": "X", "value": 3000, "minimum_purchase": 15000}}]
	manager.save_coupons()
	manager.purchases = []
	manager.load_coupons()
	var compra: Dictionary = manager.purchases[0]
	assert_int(typeof(compra["total"])).is_equal(TYPE_INT)
	assert_int(typeof(compra["coupon"]["value"])).is_equal(TYPE_INT)
	assert_int(compra["total"]).is_equal(19500)

func test_load_ignores_corrupt_file() -> void:
	var f: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	manager.coupons = [{"value": 1, "minimum_purchase": 0}]
	manager.load_coupons()
	assert_int(manager.coupons.size()).is_equal(0)

func test_add_coupon_rejects_invalid_values() -> void:
	manager.add_coupon({"value": 0, "minimum_purchase": 100})
	manager.add_coupon({"minimum_purchase": 100})
	assert_int(manager.coupons.size()).is_equal(0)
