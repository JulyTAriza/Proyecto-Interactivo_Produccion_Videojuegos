# res://tests/test_coupon_event_bus_integration.gd
# ---------------------------------------------------------------------------
# Laboratorio 10 — Prueba de INTEGRACIÓN INT-01: registro de cupón vía EventBus
# Usa los Autoloads REALES (EventBus + GlobalManager en el árbol). Se
# redirige save_path a un archivo temporal para no tocar los datos reales.
# ---------------------------------------------------------------------------
extends GdUnitTestSuite

const TEST_SAVE_PATH: String = "user://test_integration_save_data.json"

var ruta_original: String
var cupones_originales: Array
var compras_originales: Array

func before_test() -> void:
	ruta_original = GlobalManager.save_path
	cupones_originales = GlobalManager.coupons.duplicate(true)
	compras_originales = GlobalManager.purchases.duplicate(true)
	GlobalManager.save_path = TEST_SAVE_PATH
	GlobalManager.coupons = []
	GlobalManager.purchases = []

func after_test() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	GlobalManager.save_path = ruta_original
	GlobalManager.coupons = cupones_originales
	GlobalManager.purchases = compras_originales

func _leer_cupones_en_disco() -> Array:
	var f: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	if f == null:
		return []
	return (JSON.parse_string(f.get_as_text()) as Dictionary).get("coupons", [])

## INT-01: emitir EventBus.coupon_obtained debe agregar el cupón a
## GlobalManager, guardarlo en disco y notificar coupons_changed.
func test_coupon_obtained_signal_persists_coupon() -> void:
	var recibido: Array = []
	var escucha: Callable = func(c: Array) -> void: recibido.append(c.size())
	EventBus.coupons_changed.connect(escucha)

	var cupon: Dictionary = {"id": "INT-01", "code": "ENFOQUE-3000", "value": 3000, "minimum_purchase": 15000}
	EventBus.coupon_obtained.emit(cupon)

	EventBus.coupons_changed.disconnect(escucha)
	assert_int(GlobalManager.coupons.size()).is_equal(1)
	assert_str(str(GlobalManager.coupons[0]["id"])).is_equal("INT-01")
	assert_int(_leer_cupones_en_disco().size()).is_equal(1)
	assert_array(recibido).contains_exactly([1])

## La compra registrada consume el cupón y actualiza el archivo.
func test_register_purchase_consumes_coupon_and_updates_file() -> void:
	EventBus.coupon_obtained.emit({"id": "C1", "value": 2000, "minimum_purchase": 10000})
	EventBus.coupon_obtained.emit({"id": "C2", "value": 5000, "minimum_purchase": 20000})
	var mejor: Dictionary = GlobalManager.get_best_coupon(25000)
	var resumen: Dictionary = GlobalManager.register_purchase(["bienestar_total"], 25000, mejor)
	assert_int(int(resumen["total"])).is_equal(20000)
	assert_int(GlobalManager.coupons.size()).is_equal(1)
	assert_str(str(_leer_cupones_en_disco()[0]["id"])).is_equal("C1")

## Kit vía EventBus: kit_item_selected recalcula y emite kit_changed.
func test_kit_selection_through_event_bus() -> void:
	GlobalManager.clear_kit()
	var subtotales: Array = []
	var escucha: Callable = func(_sel: Dictionary, sub: int) -> void: subtotales.append(sub)
	EventBus.kit_changed.connect(escucha)
	EventBus.kit_item_selected.emit("bebida", "te")
	EventBus.kit_item_selected.emit("actividad", "siesta")
	EventBus.kit_item_selected.emit("snack", "siesta")  # categoría incorrecta: se ignora
	EventBus.kit_changed.disconnect(escucha)
	assert_array(subtotales).contains_exactly([4500, 13500])
	GlobalManager.clear_kit()
