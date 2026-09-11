# res://src/scenes/history/history_panel.gd
# ---------------------------------------------------------------------------
# HISTORY PANEL — Historial persistente de evaluaciones
# ---------------------------------------------------------------------------
# Pantalla adicional (más allá de las 4 exigidas por el Sprint 1) que
# demuestra la persistencia entre sesiones: lista todas las evaluaciones
# guardadas por GlobalManager en disco (user://fatiga_historial.json).
#
# Al igual que Step1Base, esta pantalla NUNCA lee GlobalManager
# directamente: solicita el historial emitiendo "history_requested" y se
# limita a escuchar pasivamente "history_updated" para renderizar la
# lista, manteniendo el mismo desacoplamiento vía EventBus del resto del
# proyecto.
# ---------------------------------------------------------------------------
extends Control

@onready var lbl_vacio: Label = $Margin/Scroll/VBoxContainer/LblVacio
@onready var lista_registros: VBoxContainer = $Margin/Scroll/VBoxContainer/ListaRegistros

func _ready() -> void:
	print("Panel de historial cargado. Solicitando datos persistidos...")
	EventBus.history_updated.connect(_on_history_updated)
	EventBus.history_requested.emit()

func _on_history_updated(historial: Array) -> void:
	# Limpia la lista renderizada previamente antes de reconstruirla.
	for child in lista_registros.get_children():
		child.queue_free()

	lbl_vacio.visible = historial.is_empty()

	# Se recorre en reversa para mostrar la evaluación más reciente primero.
	for i in range(historial.size() - 1, -1, -1):
		var registro: Dictionary = historial[i]
		var fila: Label = Label.new()
		fila.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.text = "🗓 %s   |   Perfil: %s   |   Índice total: %d" % [
			registro.get("fecha", "sin fecha"),
			registro.get("base", "¿?"),
			registro.get("total", 0),
		]
		lista_registros.add_child(fila)
