# res://src/core/global_manager.gd
# ---------------------------------------------------------------------------
# GLOBAL MANAGER (Autoload / Singleton) — "GlobalManager"
# ---------------------------------------------------------------------------
# Único cerebro matemático del sistema. Centraliza el estado de la
# simulación de fatiga cognitiva (perfil base seleccionado y síntomas
# marcados como "ítems adicionales") en una estructura Dictionary,
# completamente desacoplada de cualquier nodo de la interfaz gráfica.
#
# GlobalManager NUNCA conoce nodos de la GUI: solo escucha las intenciones
# del usuario a través de EventBus, actualiza su estado interno, recalcula
# el total y notifica el cambio propagando "total_changed".
#
# PERSISTENCIA: además de sobrevivir a un cambio de escena (por ser
# Autoload), el estado y el historial de evaluaciones se serializan como
# JSON en el directorio de usuario (user://), por lo que también
# sobreviven a cerrar y volver a abrir la aplicación.
# ---------------------------------------------------------------------------
extends Node

## Puntaje base asociado a cada perfil de evaluación disponible.
const BASE_PRICES: Dictionary = {
	"estudiante": 10,
	"profesional": 15,
	"deportista": 5,
}

## Puntaje que aporta cada síntoma/ítem adicional marcado por el usuario.
const ITEM_PRICES: Dictionary = {
	"concentracion": 8,
	"mente_en_blanco": 7,
	"errores_atencion": 6,
	"cansancio_mental": 9,
	"relectura": 5,
}

## Perfil base por defecto usado al iniciar la app o al reiniciar tras
## guardar una evaluación.
const DEFAULT_BASE: String = "estudiante"

## Rutas de persistencia en el directorio de usuario (multiplataforma:
## en Windows/Mac/Linux equivale a una carpeta de datos de la app; en
## exportaciones web usa IndexedDB de forma transparente).
const SAVE_PATH_ESTADO: String = "user://fatiga_estado.json"
const SAVE_PATH_HISTORIAL: String = "user://fatiga_historial.json"

## Laboratorio 7 — Archivo único de persistencia de cupones y compras.
## (Ruta exigida por la guía: user://save_data.json).
const SAVE_PATH: String = "user://save_data.json"

## Planes de descanso que vende la Tienda de Bienestar (BuyPanel, Lab 7).
## Precios en pesos colombianos (COP).
const PLANES_DESCANSO: Dictionary = {
	"pausa_activa": {"nombre": "Plan Pausa Activa", "precio": 8000,
		"detalle": "3 pausas guiadas de 5 minutos durante la jornada."},
	"descanso_profundo": {"nombre": "Plan Descanso Profundo", "precio": 15000,
		"detalle": "Siesta guiada de 20 minutos + respiración 4-7-8."},
	"bienestar_total": {"nombre": "Plan Bienestar Total", "precio": 25000,
		"detalle": "Pausas, hidratación, snack saludable y mindfulness."},
}

## Estado global de la simulación EN CURSO. Única fuente de verdad del
## sistema mientras el usuario está respondiendo.
## - "base": String -> perfil actualmente seleccionado.
## - "items": Dictionary[String, int] -> cantidad de veces que cada síntoma
##    ha sido marcado (cantidad de ítems adicionales).
## - "total": int -> índice de fatiga total, recalculado centralizadamente.
var estado_simulacion: Dictionary = {
	"base": DEFAULT_BASE,
	"items": {},
	"total": 0,
}

## Historial persistente de evaluaciones ya finalizadas y guardadas.
## Cada registro: { "fecha": String, "base": String, "items": Dictionary,
## "total": int }.
var historial_evaluaciones: Array = []

## Ruta efectiva del archivo de cupones. Es una variable (y no solo la
## constante) para que las pruebas automatizadas (Lab 10) puedan apuntar a
## un archivo temporal sin tocar los datos reales del usuario.
var save_path: String = SAVE_PATH

## Colección persistente de cupones disponibles. Cada cupón:
## { "id": String, "code": String, "value": int,
##   "minimum_purchase": int, "origin": String, "obtained_at": String }
var coupons: Array = []

## Registro persistente de compras confirmadas (se guarda junto a cupones).
var purchases: Array = []

## Último cupón obtenido (lo muestra la escena CouponEvent).
var last_coupon: Dictionary = {}

## Compra en curso en la Tienda de planes (BuyPanel -> PurchaseInvoice).
var compra_actual: Dictionary = {"plan_id": "", "subtotal": 0}

func _ready() -> void:
	print("GlobalManager iniciado. Cargando persistencia local (user://)...")
	_cargar_estado()
	_cargar_historial()
	load_coupons()

	EventBus.base_selected.connect(_on_base_selected)
	EventBus.item_added.connect(_on_item_added)
	EventBus.total_requested.connect(_on_total_requested)
	EventBus.evaluation_finalized.connect(_on_evaluation_finalized)
	EventBus.history_requested.connect(_on_history_requested)
	EventBus.coupon_obtained.connect(_on_coupon_obtained)
	EventBus.coupons_requested.connect(_on_coupons_requested)
	EventBus.plan_selected.connect(_on_plan_selected)

	# Notifica de inmediato el total restaurado (si lo había) para que la
	# UI, cuando se conecte, pueda pedirlo explícitamente vía
	# "total_requested" y reflejar la persistencia sin necesidad de que el
	# usuario toque nada.
	print("GlobalManager: estado restaurado -> ", estado_simulacion)
	print("GlobalManager: %d evaluación(es) previas cargadas del historial." % historial_evaluaciones.size())
	print("GlobalManager: %d cupón(es) cargados desde %s." % [coupons.size(), save_path])

func _on_base_selected(base_name: String) -> void:
	if not BASE_PRICES.has(base_name):
		push_warning("GlobalManager: perfil base desconocido -> %s" % base_name)
		return

	estado_simulacion["base"] = base_name
	print("GlobalManager: perfil base actualizado -> ", base_name)
	_recalcular_total()

func _on_item_added(item_id: String) -> void:
	if not ITEM_PRICES.has(item_id):
		push_warning("GlobalManager: ítem/síntoma desconocido -> %s" % item_id)
		return

	var items: Dictionary = estado_simulacion["items"]
	var cantidad_actual: int = items.get(item_id, 0)
	items[item_id] = cantidad_actual + 1
	print("GlobalManager: ítem añadido -> %s (x%d)" % [item_id, items[item_id]])
	_recalcular_total()

func _on_total_requested() -> void:
	EventBus.total_changed.emit(estado_simulacion.get("total", 0))

func _on_history_requested() -> void:
	EventBus.history_updated.emit(historial_evaluaciones)

## Guarda el intento actual como un registro inmutable del historial y
## reinicia el estado en curso para permitir una nueva evaluación.
func _on_evaluation_finalized() -> void:
	var registro: Dictionary = {
		"fecha": Time.get_datetime_string_from_system(),
		"base": estado_simulacion.get("base", DEFAULT_BASE),
		"items": (estado_simulacion.get("items", {}) as Dictionary).duplicate(),
		"total": estado_simulacion.get("total", 0),
	}
	historial_evaluaciones.append(registro)
	_guardar_historial()
	print("GlobalManager: evaluación finalizada y guardada -> ", registro)

	# Reinicia el estado en curso (nueva evaluación desde cero).
	estado_simulacion = {
		"base": DEFAULT_BASE,
		"items": {},
		"total": 0,
	}
	_recalcular_total()

	EventBus.history_updated.emit(historial_evaluaciones)

## Único punto de cálculo del índice total de fatiga. Se ejecuta cada vez
## que cambia el perfil base o se añade un nuevo síntoma, persiste el
## estado en disco y notifica el resultado a toda la interfaz gráfica
## mediante EventBus.total_changed.
func _recalcular_total() -> void:
	var total: int = BASE_PRICES.get(estado_simulacion["base"], 0)

	var items: Dictionary = estado_simulacion["items"]
	for item_id in items.keys():
		total += ITEM_PRICES.get(item_id, 0) * items[item_id]

	estado_simulacion["total"] = total
	_guardar_estado()
	EventBus.total_changed.emit(total)

# ---------------------------------------------------------------------------
# PERSISTENCIA EN DISCO (user://)
# ---------------------------------------------------------------------------

func _guardar_estado() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH_ESTADO, FileAccess.WRITE)
	if file == null:
		push_warning("GlobalManager: no fue posible guardar el estado en %s (error %d)." % [SAVE_PATH_ESTADO, FileAccess.get_open_error()])
		return

	file.store_string(JSON.stringify(estado_simulacion))
	file.close()

func _cargar_estado() -> void:
	if not FileAccess.file_exists(SAVE_PATH_ESTADO):
		print("GlobalManager: no hay estado previo guardado, se usa el estado por defecto.")
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH_ESTADO, FileAccess.READ)
	if file == null:
		push_warning("GlobalManager: no fue posible leer %s (error %d)." % [SAVE_PATH_ESTADO, FileAccess.get_open_error()])
		return

	var contenido: String = file.get_as_text()
	file.close()

	var datos: Variant = JSON.parse_string(contenido)
	if typeof(datos) == TYPE_DICTIONARY and datos.has("base") and datos.has("items") and datos.has("total"):
		estado_simulacion = datos
	else:
		push_warning("GlobalManager: archivo de estado corrupto o con formato inesperado; se descarta y se usa el estado por defecto.")

func _guardar_historial() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH_HISTORIAL, FileAccess.WRITE)
	if file == null:
		push_warning("GlobalManager: no fue posible guardar el historial en %s (error %d)." % [SAVE_PATH_HISTORIAL, FileAccess.get_open_error()])
		return

	file.store_string(JSON.stringify(historial_evaluaciones))
	file.close()

func _cargar_historial() -> void:
	if not FileAccess.file_exists(SAVE_PATH_HISTORIAL):
		print("GlobalManager: no hay historial previo guardado.")
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH_HISTORIAL, FileAccess.READ)
	if file == null:
		push_warning("GlobalManager: no fue posible leer %s (error %d)." % [SAVE_PATH_HISTORIAL, FileAccess.get_open_error()])
		return

	var contenido: String = file.get_as_text()
	file.close()

	var datos: Variant = JSON.parse_string(contenido)
	if typeof(datos) == TYPE_ARRAY:
		historial_evaluaciones = datos
	else:
		push_warning("GlobalManager: archivo de historial corrupto o con formato inesperado; se descarta.")

# ===========================================================================
# LABORATORIO 7 — CUPONES PERSISTENTES (FileAccess + JSON)
# ===========================================================================

func _on_coupon_obtained(coupon: Dictionary) -> void:
	add_coupon(coupon)

func _on_coupons_requested() -> void:
	EventBus.coupons_changed.emit(coupons)

## Agrega un cupón a la colección y lo guarda inmediatamente en disco
## (requisito: "guardar el cupón cuando es obtenido").
func add_coupon(coupon: Dictionary) -> void:
	var normalizado: Dictionary = _normalizar_cupon(coupon)
	if normalizado.is_empty():
		push_warning("GlobalManager: cupón inválido descartado -> %s" % coupon)
		return
	coupons.append(normalizado)
	last_coupon = normalizado
	save_coupons()
	print("GlobalManager: cupón obtenido y guardado -> ", normalizado)
	EventBus.coupons_changed.emit(coupons)

## Elimina un cupón consumido y actualiza el archivo (requisito: "actualizar
## el archivo cuando es consumido"). Busca primero por "id" y, si el cupón
## no tiene id (p. ej. en pruebas), por igualdad de contenido.
func remove_coupon(coupon: Dictionary) -> bool:
	var indice: int = -1
	var id_buscado: String = str(coupon.get("id", ""))
	for i in coupons.size():
		var actual: Dictionary = coupons[i]
		if not id_buscado.is_empty() and str(actual.get("id", "")) == id_buscado:
			indice = i
			break
		if id_buscado.is_empty() and actual == coupon:
			indice = i
			break
	if indice == -1:
		push_warning("GlobalManager: se intentó consumir un cupón inexistente -> %s" % coupon)
		return false
	coupons.remove_at(indice)
	save_coupons()
	print("GlobalManager: cupón consumido y archivo actualizado -> ", coupon)
	EventBus.coupons_changed.emit(coupons)
	return true

## Devuelve el cupón de MAYOR valor cuyo mínimo de compra se cumple con el
## subtotal dado (subtotal >= minimum_purchase). Si ninguno aplica,
## devuelve un Dictionary vacío.
func get_best_coupon(subtotal: int) -> Dictionary:
	var mejor: Dictionary = {}
	for c in coupons:
		var cupon: Dictionary = c
		if subtotal < int(cupon.get("minimum_purchase", 0)):
			continue
		if mejor.is_empty() or int(cupon.get("value", 0)) > int(mejor.get("value", 0)):
			mejor = cupon
	return mejor

## Total a pagar tras aplicar un cupón (nunca negativo).
func apply_coupon(subtotal: int, coupon: Dictionary) -> int:
	if coupon.is_empty():
		return subtotal
	if subtotal < int(coupon.get("minimum_purchase", 0)):
		return subtotal
	return maxi(subtotal - int(coupon.get("value", 0)), 0)

## Registra una compra confirmada: consume el cupón (si hay), guarda la
## compra en el historial persistente y notifica por EventBus.
func register_purchase(items: Array, subtotal: int, coupon: Dictionary) -> Dictionary:
	var total: int = apply_coupon(subtotal, coupon)
	var usado: Dictionary = coupon if total != subtotal else {}
	if not usado.is_empty():
		remove_coupon(usado)
	var resumen: Dictionary = {
		"items": items,
		"subtotal": subtotal,
		"discount": subtotal - total,
		"total": total,
		"coupon": usado,
		"fecha": Time.get_datetime_string_from_system(),
	}
	purchases.append(resumen)
	save_coupons()
	EventBus.purchase_completed.emit(resumen)
	return resumen

func save_coupons() -> void:
	var datos: Dictionary = {"coupons": coupons, "purchases": purchases}
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("GlobalManager: no fue posible guardar %s (error %d)." % [save_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(datos, "\t"))
	file.close()

func load_coupons() -> void:
	coupons = []
	purchases = []
	if not FileAccess.file_exists(save_path):
		print("GlobalManager: no existe %s; colección de cupones vacía." % save_path)
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("GlobalManager: no fue posible leer %s (error %d)." % [save_path, FileAccess.get_open_error()])
		return
	var contenido: String = file.get_as_text()
	file.close()

	var datos: Variant = JSON.parse_string(contenido)
	if typeof(datos) != TYPE_DICTIONARY:
		push_warning("GlobalManager: %s corrupto o con formato inesperado; se ignora." % save_path)
		return
	for c in (datos as Dictionary).get("coupons", []):
		if typeof(c) == TYPE_DICTIONARY:
			var normalizado: Dictionary = _normalizar_cupon(c)
			if not normalizado.is_empty():
				coupons.append(normalizado)
	var compras: Variant = (datos as Dictionary).get("purchases", [])
	if typeof(compras) == TYPE_ARRAY:
		purchases = compras

## JSON no distingue enteros de flotantes: al leer, 2000 vuelve como 2000.0.
## Se normalizan los campos numéricos a int para que las comparaciones,
## los formatos "%d" y las pruebas de igualdad sean consistentes.
func _normalizar_cupon(coupon: Dictionary) -> Dictionary:
	if not coupon.has("value"):
		return {}
	var c: Dictionary = coupon.duplicate(true)
	c["value"] = int(c.get("value", 0))
	c["minimum_purchase"] = int(c.get("minimum_purchase", 0))
	if int(c["value"]) <= 0:
		return {}
	return c

# ---------------------------------------------------------------------------
# Tienda de planes (BuyPanel -> PurchaseInvoice)
# ---------------------------------------------------------------------------

func _on_plan_selected(plan_id: String) -> void:
	if not PLANES_DESCANSO.has(plan_id):
		push_warning("GlobalManager: plan desconocido -> %s" % plan_id)
		return
	compra_actual = {"plan_id": plan_id, "subtotal": int(PLANES_DESCANSO[plan_id]["precio"])}
	EventBus.purchase_updated.emit(compra_actual)

func clear_purchase() -> void:
	compra_actual = {"plan_id": "", "subtotal": 0}
	EventBus.purchase_updated.emit(compra_actual)
