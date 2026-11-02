# res://src/scenes/shop/purchase_invoice.gd
# ---------------------------------------------------------------------------
# PURCHASE INVOICE — Factura de la compra de planes (Laboratorio 7)
# ---------------------------------------------------------------------------
# Muestra el plan elegido, el subtotal, el mejor cupón aplicable (elegido
# por GlobalManager.get_best_coupon) y el total. Al confirmar, la compra se
# registra en GlobalManager, que consume el cupón y actualiza
# user://save_data.json para que no reaparezca en la siguiente ejecución.
# ---------------------------------------------------------------------------
extends Control

@onready var lbl_plan: Label = $Margin/Scroll/VBox/LblPlan
@onready var lbl_subtotal: Label = $Margin/Scroll/VBox/Grid/LblSubtotalValor
@onready var lbl_descuento: Label = $Margin/Scroll/VBox/Grid/LblDescuentoValor
@onready var lbl_total: Label = $Margin/Scroll/VBox/Grid/LblTotalValor
@onready var lbl_coupon: Label = $Margin/Scroll/VBox/LblCoupon
@onready var chk_usar_cupon: CheckButton = $Margin/Scroll/VBox/ChkUsarCupon
@onready var btn_confirmar: Button = $Margin/Scroll/VBox/HBoxBotones/BtnConfirmar

var subtotal: int = 0
var applied_coupon: Dictionary = {}
var best_coupon: Dictionary = {}

func _ready() -> void:
	chk_usar_cupon.toggled.connect(_on_usar_cupon_toggled)
	btn_confirmar.pressed.connect(_on_confirm)
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
	GlobalManager.register_purchase([plan_id], subtotal, applied_coupon)
	GlobalManager.clear_purchase()
	btn_confirmar.disabled = true
	chk_usar_cupon.disabled = true
	lbl_coupon.text = "Compra confirmada"
