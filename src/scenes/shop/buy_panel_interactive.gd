# res://src/scenes/shop/buy_panel_interactive.gd
# ---------------------------------------------------------------------------
# BUY PANEL INTERACTIVE — "Arma tu Kit Anti-Fatiga" (Laboratorio 9)
# ---------------------------------------------------------------------------
# Interfaz AUTO-POBLADA: no hay ni un botón de producto colocado a mano en
# el editor. En _ready() se recorre GlobalManager.wellness_items (el
# catálogo .tres de recursos WellnessItemData) y se crean por código los
# encabezados de categoría y las tarjetas de cada elemento, conectando su
# señal pressed con bind(categoría, id).
#
# Flujo de datos:
#   tarjeta.pressed -> EventBus.kit_item_selected(sección, id)
#   GlobalManager actualiza kit_selection y recalcula el subtotal desde los
#   recursos -> EventBus.kit_changed(selección, subtotal)
#   esta pantalla y KitComposition se actualizan (con Tweens).
# ---------------------------------------------------------------------------
extends Control

const NOMBRES_CATEGORIA: Dictionary = {"bebida": "Bebidas", "snack": "Snacks", "actividad": "Actividades"}

@onready var scroll_catalogo: ScrollContainer = $Margin/VBox/HBox/ScrollCatalogo
@onready var catalogo: VBoxContainer = $Margin/VBox/HBox/ScrollCatalogo/Catalogo
@onready var composicion: PanelContainer = $Margin/VBox/HBox/VBoxDerecha/KitComposition
@onready var lbl_subtotal: Label = $Margin/VBox/HBox/VBoxDerecha/LblSubtotal
@onready var lbl_alivio: Label = $Margin/VBox/HBox/VBoxDerecha/LblAlivio
@onready var lbl_cupon: Label = $Margin/VBox/HBox/VBoxDerecha/LblCupon
@onready var btn_factura: Button = $Margin/VBox/HBox/VBoxDerecha/HBoxBotones/BtnFactura
@onready var btn_vaciar: Button = $Margin/VBox/HBox/VBoxDerecha/HBoxBotones/BtnVaciar

## id -> Button (tarjeta generada) para poder marcar/animar la seleccionada.
var tarjetas: Dictionary = {}
## categoría -> Label (encabezado generado) para desplazarse hasta él.
var encabezados: Dictionary = {}
var subtotal_mostrado: int = 0

func _ready() -> void:
	_poblar_catalogo()
	composicion.slot_activated.connect(_on_slot_activated)
	btn_vaciar.pressed.connect(func() -> void: EventBus.kit_slot_cleared.emit(""))
	EventBus.kit_changed.connect(_on_kit_changed)
	EventBus.coupons_changed.connect(func(_c: Array) -> void: _actualizar_cupon(subtotal_mostrado))
	EventBus.kit_requested.emit()
	if not tarjetas.is_empty():
		(tarjetas.values()[0] as Button).grab_focus.call_deferred()

# ---------------------------------------------------------------------------
# UI dinámica: generación de controles a partir del catálogo de recursos
# ---------------------------------------------------------------------------

func _poblar_catalogo() -> void:
	for hijo in catalogo.get_children():
		hijo.queue_free()
	var por_categoria: Dictionary = {}
	for item: WellnessItemData in GlobalManager.wellness_items:
		if item == null or not item.is_valid():
			push_warning("BuyPanelInteractive: recurso inválido en el catálogo, se omite.")
			continue
		if not por_categoria.has(item.category):
			por_categoria[item.category] = []
		por_categoria[item.category].append(item)

	for categoria in WellnessItemData.CATEGORIAS:
		if not por_categoria.has(categoria):
			continue
		var encabezado: Label = Label.new()
		encabezado.text = NOMBRES_CATEGORIA.get(categoria, categoria.capitalize())
		encabezado.theme_type_variation = &"SeccionLabel"
		catalogo.add_child(encabezado)
		encabezados[categoria] = encabezado
		for item: WellnessItemData in por_categoria[categoria]:
			catalogo.add_child(_crear_tarjeta(item))

func _crear_tarjeta(item: WellnessItemData) -> Button:
	var tarjeta: Button = Button.new()
	tarjeta.name = "Item_" + item.id
	tarjeta.toggle_mode = true
	tarjeta.icon = item.texture
	tarjeta.expand_icon = false
	tarjeta.add_theme_constant_override("icon_max_width", 48)
	tarjeta.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tarjeta.custom_minimum_size = Vector2(0, 64)
	tarjeta.text = _texto_tarjeta(item, false)
	tarjeta.tooltip_text = item.description
	tarjeta.pressed.connect(_on_item_pressed.bind(item.category, item.id))
	tarjetas[item.id] = tarjeta
	return tarjeta

func _texto_tarjeta(item: WellnessItemData, en_kit: bool) -> String:
	var marca: String = "[EN TU KIT]  " if en_kit else ""
	return "%s%s  -  $%s\nAlivio estimado: -%d puntos de fatiga" % [marca, item.display_name, FormatUtil.pesos(item.price), item.relief]

# ---------------------------------------------------------------------------
# Interacción
# ---------------------------------------------------------------------------

func _on_item_pressed(categoria: String, item_id: String) -> void:
	_pulso(tarjetas[item_id])
	composicion.set_active_slot(categoria)
	EventBus.kit_item_selected.emit(categoria, item_id)

func _on_slot_activated(slot: String) -> void:
	if encabezados.has(slot):
		var destino: int = int(encabezados[slot].position.y)
		create_tween().tween_property(scroll_catalogo, "scroll_vertical", destino, 0.3).set_trans(Tween.TRANS_SINE)
		_destello(encabezados[slot])

func _on_kit_changed(selection: Dictionary, subtotal: int) -> void:
	composicion.update_from(selection)
	var elegidos: Array = selection.values()
	for id: String in tarjetas.keys():
		var tarjeta: Button = tarjetas[id]
		var en_kit: bool = elegidos.has(id)
		tarjeta.set_pressed_no_signal(en_kit)
		tarjeta.text = _texto_tarjeta(GlobalManager.get_wellness_item(id), en_kit)
	_animar_subtotal(subtotal)
	lbl_alivio.text = "Alivio estimado del kit: -%d puntos de fatiga" % GlobalManager.calculate_kit_relief(selection)
	btn_factura.disabled = subtotal <= 0
	btn_vaciar.disabled = subtotal <= 0
	_actualizar_cupon(subtotal)

func _actualizar_cupon(subtotal: int) -> void:
	if GlobalManager.coupons.is_empty():
		lbl_cupon.text = "Sin cupones disponibles (gánalos en Enfoque Rush)."
		return
	var mejor: Dictionary = GlobalManager.get_best_coupon(subtotal)
	if mejor.is_empty():
		var minimo: int = 1 << 30
		for c in GlobalManager.coupons:
			minimo = mini(minimo, int(c.get("minimum_purchase", 0)))
		lbl_cupon.text = "Te faltan $%s para poder usar un cupón." % FormatUtil.pesos(maxi(minimo - subtotal, 0))
	else:
		lbl_cupon.text = "Cupón aplicable en la factura: -$%s" % FormatUtil.pesos(int(mejor["value"]))

# ---------------------------------------------------------------------------
# Retroalimentación visual con Tween
# ---------------------------------------------------------------------------

## Escala de "pulsación" sobre la tarjeta elegida.
func _pulso(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(control, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

## Destello de color (modulate) sobre un encabezado de categoría.
func _destello(control: CanvasItem) -> void:
	control.modulate = Color(1.0, 0.85, 0.3)
	create_tween().tween_property(control, "modulate", Color.WHITE, 0.6)

## El subtotal "cuenta" hasta el nuevo valor y hace un pequeño rebote.
func _animar_subtotal(nuevo: int) -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_pintar_subtotal, subtotal_mostrado, nuevo, 0.35)
	subtotal_mostrado = nuevo
	lbl_subtotal.pivot_offset = lbl_subtotal.size / 2.0
	var rebote: Tween = create_tween()
	rebote.tween_property(lbl_subtotal, "scale", Vector2(1.08, 1.08), 0.1)
	rebote.tween_property(lbl_subtotal, "scale", Vector2.ONE, 0.2)

func _pintar_subtotal(valor: int) -> void:
	lbl_subtotal.text = "Subtotal: $%s" % FormatUtil.pesos(valor)
