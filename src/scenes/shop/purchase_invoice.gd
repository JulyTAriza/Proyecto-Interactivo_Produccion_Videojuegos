# res://src/scenes/shop/purchase_invoice.gd
# ---------------------------------------------------------------------------
# PURCHASE INVOICE — Factura de la compra de planes (Laboratorio 7)
# ---------------------------------------------------------------------------
# Muestra el plan elegido, el subtotal, el mejor cupón aplicable (elegido
# por GlobalManager.get_best_coupon) y el total. Al confirmar, la compra se
# registra en GlobalManager, que consume el cupón y actualiza
# user://save_data.json para que no reaparezca en la siguiente ejecución.
#
# Laboratorio 8: tras confirmar se muestra PurchaseSuccessPopup (feedback
# visual claro de la acción crítica) con un botón "Continuar" (ButtonNav)
# que regresa al menú y una X para cerrarlo y revisar la factura.
# ---------------------------------------------------------------------------
extends Control

@onready var lbl_plan: Label = $Margin/Scroll/VBox/LblPlan
@onready var lbl_subtotal: Label = $Margin/Scroll/VBox/Grid/LblSubtotalValor
@onready var lbl_descuento: Label = $Margin/Scroll/VBox/Grid/LblDescuentoValor
@onready var lbl_total: Label = $Margin/Scroll/VBox/Grid/LblTotalValor
@onready var lbl_coupon: Label = $Margin/Scroll/VBox/LblCoupon
@onready var chk_usar_cupon: CheckButton = $Margin/Scroll/VBox/ChkUsarCupon
@onready var btn_confirmar: Button = $Margin/Scroll/VBox/HBoxBotones/BtnConfirmar
@onready var pop_up_confirm: Panel = $PurchaseSuccessPopup
@onready var lbl_mensaje_popup: Label = $PurchaseSuccessPopup/VBoxContainer/LblMensaje
@onready var btn_continuar: Button = $PurchaseSuccessPopup/VBoxContainer/BtnContinuar
@onready var btn_cerrar_popup: Button = $PurchaseSuccessPopup/BtnCerrar
@onready var velo: ColorRect = $Velo

var subtotal: int = 0
var applied_coupon: Dictionary = {}
var best_coupon: Dictionary = {}

func _ready() -> void:
	chk_usar_cupon.toggled.connect(_on_usar_cupon_toggled)
	btn_confirmar.pressed.connect(_on_confirm)
	btn_cerrar_popup.pressed.connect(_cerrar_popup)
	_cargar_compra()
	btn_confirmar.grab_focus.call_deferred()

func _cargar_compra() -> void:
	var compra: Dictionary = GlobalManager.compra_actual
	var plan_id: String = str(compra.get("plan_id", ""))
	if plan_id.is_empty():
		lbl_plan.text = "No hay ningún plan en la compra. Vuelve a la tienda."
		btn_confirmar.disabled = true
		chk_usar_cupon.disabled = true
		return
	var plan: Dictionary = GlobalManager.PLANES_DESCANSO[plan_id]
	subtotal = int(compra.get("subtotal", 0))
	lbl_plan.text = "%s\n%s" % [plan["nombre"], plan["detalle"]]
	best_coupon = GlobalManager.get_best_coupon(subtotal)
	chk_usar_cupon.disabled = best_coupon.is_empty()
	chk_usar_cupon.button_pressed = not best_coupon.is_empty()
	_recalcular()

func _on_usar_cupon_toggled(_activo: bool) -> void:
	_recalcular()

func _recalcular() -> void:
	applied_coupon = best_coupon if chk_usar_cupon.button_pressed else {}
	var total: int = GlobalManager.apply_coupon(subtotal, applied_coupon)
	lbl_subtotal.text = "$%s" % FormatUtil.pesos(subtotal)
	lbl_descuento.text = "-$%s" % FormatUtil.pesos(subtotal - total)
	lbl_total.text = "$%s" % FormatUtil.pesos(total)
	if best_coupon.is_empty():
		lbl_coupon.text = "Sin cupón aplicable: ningún cupón disponible cumple la compra mínima."
	elif applied_coupon.is_empty():
		lbl_coupon.text = "Cupón disponible sin usar: %s (-$%s)." % [best_coupon.get("code", ""), FormatUtil.pesos(int(best_coupon["value"]))]
	else:
		lbl_coupon.text = "Cupón aplicado: %s (-$%s). Se consumirá al confirmar." % [applied_coupon.get("code", ""), FormatUtil.pesos(int(applied_coupon["value"]))]

func _on_confirm() -> void:
	var plan_id: String = str(GlobalManager.compra_actual.get("plan_id", ""))
	# register_purchase() llama a GlobalManager.remove_coupon(applied_coupon)
	# cuando hay cupón aplicado, y guarda la compra en save_data.json.
	var resumen: Dictionary = GlobalManager.register_purchase([plan_id], subtotal, applied_coupon)
	GlobalManager.clear_purchase()
	btn_confirmar.disabled = true
	chk_usar_cupon.disabled = true
	lbl_coupon.text = "Compra confirmada"
	_mostrar_popup(resumen)

func _mostrar_popup(resumen: Dictionary) -> void:
	var detalle: String = "Tu pedido está en proceso.\nPagaste $%s" % FormatUtil.pesos(int(resumen["total"]))
	if int(resumen["discount"]) > 0:
		detalle += " (ahorraste $%s con tu cupón)." % FormatUtil.pesos(int(resumen["discount"]))
	else:
		detalle += "."
	lbl_mensaje_popup.text = detalle
	velo.visible = true
	pop_up_confirm.show()
	pop_up_confirm.pivot_offset = pop_up_confirm.size / 2.0
	pop_up_confirm.scale = Vector2(0.8, 0.8)
	pop_up_confirm.modulate.a = 0.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pop_up_confirm, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(pop_up_confirm, "modulate:a", 1.0, 0.2)
	btn_continuar.grab_focus()

func _cerrar_popup() -> void:
	pop_up_confirm.hide()
	velo.visible = false
