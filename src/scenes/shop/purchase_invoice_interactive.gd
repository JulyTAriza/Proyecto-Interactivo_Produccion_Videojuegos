# res://src/scenes/shop/purchase_invoice_interactive.gd
# ---------------------------------------------------------------------------
# PURCHASE INVOICE INTERACTIVE — Factura del Kit Anti-Fatiga (Laboratorio 9)
# ---------------------------------------------------------------------------
# Consulta la selección activa en GlobalManager (kit_selection) y obtiene
# nombre, icono y precio DIRECTAMENTE de los recursos WellnessItemData,
# generando una línea de factura por cada elemento. Calcula el subtotal con
# GlobalManager.calculate_kit_subtotal(), obtiene el mejor cupón
# persistente con get_best_coupon() y, al confirmar, lo consume (se borra
# de save_data.json) y muestra PurchaseSuccessPopup.
# ---------------------------------------------------------------------------
extends Control

const NOMBRES_SECCION: Dictionary = {"bebida": "Bebida", "snack": "Snack", "actividad": "Actividad"}

@onready var lineas: VBoxContainer = $Margin/Scroll/VBox/Lineas
@onready var lbl_subtotal: Label = $Margin/Scroll/VBox/Grid/LblSubtotalValor
@onready var lbl_descuento: Label = $Margin/Scroll/VBox/Grid/LblDescuentoValor
@onready var lbl_total: Label = $Margin/Scroll/VBox/Grid/LblTotalValor
@onready var lbl_alivio: Label = $Margin/Scroll/VBox/LblAlivio
@onready var lbl_coupon: Label = $Margin/Scroll/VBox/LblCoupon
@onready var chk_usar_cupon: CheckButton = $Margin/Scroll/VBox/ChkUsarCupon
@onready var btn_confirmar: Button = $Margin/Scroll/VBox/HBoxBotones/BtnConfirmar
@onready var pop_up_confirm: Panel = $PurchaseSuccessPopup
@onready var lbl_mensaje_popup: Label = $PurchaseSuccessPopup/VBoxContainer/LblMensaje
@onready var btn_continuar: Button = $PurchaseSuccessPopup/VBoxContainer/BtnContinuar
@onready var btn_cerrar_popup: Button = $PurchaseSuccessPopup/BtnCerrar
@onready var velo: ColorRect = $Velo

var subtotal: int = 0
var best_coupon: Dictionary = {}
var applied_coupon: Dictionary = {}
var items_factura: Array[WellnessItemData] = []

func _ready() -> void:
	chk_usar_cupon.toggled.connect(func(_on: bool) -> void: _recalcular())
	btn_confirmar.pressed.connect(_on_confirm)
	btn_cerrar_popup.pressed.connect(_cerrar_popup)
	_cargar_desde_recursos()
	btn_confirmar.grab_focus.call_deferred()

func _cargar_desde_recursos() -> void:
	items_factura = GlobalManager.get_kit_items()
	for hijo in lineas.get_children():
		hijo.queue_free()
	for item in items_factura:
		lineas.add_child(_crear_linea(item))
	subtotal = GlobalManager.calculate_kit_subtotal(GlobalManager.kit_selection)
	lbl_alivio.text = "Alivio estimado: -%d puntos en tu índice de fatiga" % GlobalManager.calculate_kit_relief(GlobalManager.kit_selection)
	if items_factura.is_empty():
		lbl_coupon.text = "Tu kit está vacío. Vuelve y elige al menos un elemento."
		btn_confirmar.disabled = true
		chk_usar_cupon.disabled = true
	best_coupon = GlobalManager.get_best_coupon(subtotal)
	chk_usar_cupon.disabled = best_coupon.is_empty()
	chk_usar_cupon.set_pressed_no_signal(not best_coupon.is_empty())
	_recalcular()

func _crear_linea(item: WellnessItemData) -> HBoxContainer:
	var fila: HBoxContainer = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	var icono: TextureRect = TextureRect.new()
	icono.texture = item.texture
	icono.custom_minimum_size = Vector2(40, 40)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(icono)
	var nombre: Label = Label.new()
	nombre.text = "%s  (%s)" % [item.display_name, NOMBRES_SECCION.get(item.category, item.category)]
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var precio: Label = Label.new()
	precio.text = "$%s" % FormatUtil.pesos(item.price)
	fila.add_child(precio)
	return fila

func _recalcular() -> void:
	applied_coupon = best_coupon if chk_usar_cupon.button_pressed else {}
	var total: int = GlobalManager.apply_coupon(subtotal, applied_coupon)
	lbl_subtotal.text = "$%s" % FormatUtil.pesos(subtotal)
	lbl_descuento.text = "-$%s" % FormatUtil.pesos(subtotal - total)
	lbl_total.text = "$%s" % FormatUtil.pesos(total)
	if items_factura.is_empty():
		return
	if best_coupon.is_empty():
		lbl_coupon.text = "Sin cupón aplicable: ningún cupón disponible cumple la compra mínima."
	elif applied_coupon.is_empty():
		lbl_coupon.text = "Tienes un cupón de -$%s que no estás usando." % FormatUtil.pesos(int(best_coupon["value"]))
	else:
		lbl_coupon.text = "Cupón aplicado: %s (-$%s). Se consumirá al confirmar." % [applied_coupon.get("code", ""), FormatUtil.pesos(int(applied_coupon["value"]))]

func _on_confirm() -> void:
	var ids: Array = []
	for item in items_factura:
		ids.append(item.id)
	var resumen: Dictionary = GlobalManager.register_purchase(ids, subtotal, applied_coupon)
	GlobalManager.clear_kit()
	btn_confirmar.disabled = true
	chk_usar_cupon.disabled = true
	lbl_coupon.text = "Compra confirmada"
	lbl_mensaje_popup.text = "Tu kit está en preparación.\nPagaste $%s%s" % [
		FormatUtil.pesos(int(resumen["total"])),
		" (ahorraste $%s con tu cupón)." % FormatUtil.pesos(int(resumen["discount"])) if int(resumen["discount"]) > 0 else "."]
	velo.visible = true
	pop_up_confirm.show()
	pop_up_confirm.pivot_offset = pop_up_confirm.size / 2.0
	pop_up_confirm.scale = Vector2(0.8, 0.8)
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pop_up_confirm, "scale", Vector2.ONE, 0.3)
	btn_continuar.grab_focus()

func _cerrar_popup() -> void:
	pop_up_confirm.hide()
	velo.visible = false
