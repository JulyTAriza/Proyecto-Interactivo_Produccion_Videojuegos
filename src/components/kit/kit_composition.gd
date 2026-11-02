# res://src/components/kit/kit_composition.gd
# ---------------------------------------------------------------------------
# KIT COMPOSITION — Representación visual del Kit Anti-Fatiga (Lab 9)
# ---------------------------------------------------------------------------
# Equivalente a "PizzaComposition" de la guía: muestra las secciones del
# kit (bebida, snack, actividad) con la textura del recurso elegido en
# cada una. Las secciones se generan por código a partir de
# WellnessItemData.CATEGORIAS, no se colocan a mano.
#
# - Clic en una sección  -> la marca como "activa" (el catálogo se
#                           desplaza a esa categoría).
# - Botón papelera       -> emite EventBus.kit_slot_cleared(sección).
# - update_from(selección) se llama cuando GlobalManager emite
#   EventBus.kit_changed; anima con Tween solo las secciones que cambiaron.
# ---------------------------------------------------------------------------
extends PanelContainer

## Señal local al panel que contiene el componente (no es global: solo le
## interesa a la pantalla que lo usa).
signal slot_activated(slot: String)

const TEXTURA_VACIA: Texture2D = preload("res://src/assets/items/item_vacio.svg")
const ICONO_QUITAR: Texture2D = preload("res://src/assets/icons/icon_trash.svg")
const NOMBRES_SECCION: Dictionary = {"bebida": "Bebida", "snack": "Snack", "actividad": "Actividad"}

@onready var bandeja: HBoxContainer = $Margin/VBox/Bandeja
@onready var lbl_activa: Label = $Margin/VBox/LblActiva

## slot -> { "card": Button, "tex": TextureRect, "nombre": Label, "precio": Label, "quitar": Button }
var slots: Dictionary = {}
var seleccion_actual: Dictionary = {}
var slot_activo: String = ""

func _ready() -> void:
	for slot in WellnessItemData.CATEGORIAS:
		_crear_slot(slot)
	set_active_slot(WellnessItemData.CATEGORIAS[0])

func _crear_slot(slot: String) -> void:
	var card: Button = Button.new()
	card.name = "Slot_" + slot
	card.toggle_mode = true
	card.custom_minimum_size = Vector2(150, 250)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.tooltip_text = "Elegir la sección %s" % NOMBRES_SECCION[slot]
	card.pressed.connect(set_active_slot.bind(slot))
	bandeja.add_child(card)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	var titulo: Label = _label(NOMBRES_SECCION[slot].to_upper(), 16, Color("#CBD5E1"))
	vbox.add_child(titulo)
	var tex: TextureRect = TextureRect.new()
	tex.texture = TEXTURA_VACIA
	tex.custom_minimum_size = Vector2(80, 80)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tex)
	var nombre: Label = _label("Vacía", 17, Color("#F1F5F9"))
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(nombre)
	var precio: Label = _label("$0", 17, Color("#FFD166"))
	vbox.add_child(precio)

	var quitar: Button = Button.new()
	quitar.text = "Quitar"
	quitar.icon = ICONO_QUITAR
	quitar.disabled = true
	quitar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quitar.tooltip_text = "Quitar el elemento de la sección %s" % NOMBRES_SECCION[slot]
	quitar.pressed.connect(func() -> void: EventBus.kit_slot_cleared.emit(slot))
	vbox.add_child(quitar)

	slots[slot] = {"card": card, "tex": tex, "nombre": nombre, "precio": precio, "quitar": quitar}

func _label(texto: String, tam: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func set_active_slot(slot: String) -> void:
	slot_activo = slot
	for s in slots.keys():
		(slots[s]["card"] as Button).set_pressed_no_signal(s == slot)
	# Independiente del color: se indica también con texto.
	lbl_activa.text = "Sección activa: %s (elige un elemento del catálogo)" % NOMBRES_SECCION[slot]
	slot_activated.emit(slot)

## Refresca las secciones a partir de la selección global y anima las que
## cambiaron respecto a la vez anterior.
func update_from(selection: Dictionary) -> void:
	for slot in slots.keys():
		var item_id: String = str(selection.get(slot, ""))
		var cambio: bool = item_id != str(seleccion_actual.get(slot, ""))
		var item: WellnessItemData = GlobalManager.get_wellness_item(item_id)
		var refs: Dictionary = slots[slot]
		(refs["tex"] as TextureRect).texture = item.texture if item else TEXTURA_VACIA
		(refs["nombre"] as Label).text = item.display_name if item else "Vacía"
		(refs["precio"] as Label).text = "$%s" % FormatUtil.pesos(item.price) if item else "$0"
		(refs["quitar"] as Button).disabled = item == null
		if cambio and not seleccion_actual.is_empty():
			_animar_slot(refs, item != null)
	seleccion_actual = selection.duplicate()

## Tween: la textura "rebota" (escala) y la tarjeta destella en verde al
## agregar, o se atenúa brevemente al quitar.
func _animar_slot(refs: Dictionary, agregado: bool) -> void:
	var tex: TextureRect = refs["tex"]
	var card: Button = refs["card"]
	tex.pivot_offset = tex.size / 2.0
	tex.scale = Vector2(0.4, 0.4) if agregado else Vector2(1.2, 1.2)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(tex, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	card.modulate = Color(0.75, 1.6, 1.2) if agregado else Color(1, 1, 1, 0.5)
	tween.tween_property(card, "modulate", Color.WHITE, 0.45)
