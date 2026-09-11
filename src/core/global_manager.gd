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

func _ready() -> void:
	print("GlobalManager iniciado. Cargando persistencia local (user://)...")
	_cargar_estado()
	_cargar_historial()

	EventBus.base_selected.connect(_on_base_selected)
	EventBus.item_added.connect(_on_item_added)
	EventBus.total_requested.connect(_on_total_requested)
	EventBus.evaluation_finalized.connect(_on_evaluation_finalized)
	EventBus.history_requested.connect(_on_history_requested)

	# Notifica de inmediato el total restaurado (si lo había) para que la
	# UI, cuando se conecte, pueda pedirlo explícitamente vía
	# "total_requested" y reflejar la persistencia sin necesidad de que el
	# usuario toque nada.
	print("GlobalManager: estado restaurado -> ", estado_simulacion)
	print("GlobalManager: %d evaluación(es) previas cargadas del historial." % historial_evaluaciones.size())

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
