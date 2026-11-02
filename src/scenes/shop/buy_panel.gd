# res://src/scenes/shop/buy_panel.gd
# ---------------------------------------------------------------------------
# BUY PANEL — Tienda de Bienestar: planes de descanso (Laboratorio 7)
# ---------------------------------------------------------------------------
# El usuario elige uno de los planes de descanso (botones colocados en el
# editor). La elección se emite por EventBus.plan_selected; GlobalManager
# fija la compra en curso y responde con EventBus.purchase_updated, a la
# que esta pantalla reacciona para mostrar el subtotal, el cupón que se
# aplicaría y habilitar el paso a la factura.
# ---------------------------------------------------------------------------
extends Control

@onready var botones_plan: Dictionary = {
	"pausa_activa": $Margin/Scroll/VBox/Planes/BtnPausaActiva,
	"descanso_profundo": $Margin/Scroll/VBox/Planes/BtnDescansoProfundo,
	"bienestar_total": $Margin/Scroll/VBox/Planes/BtnBienestarTotal,
}
@onready var lbl_seleccion: Label = $Margin/Scroll/VBox/LblSeleccion
@onready var lbl_cupones: Label = $Margin/Scroll/VBox/LblCupones
@onready var btn_factura: Button = $Margin/Scroll/VBox/HBoxBotones/BtnFactura
@onready var btn_vaciar: Button = $Margin/Scroll/VBox/HBoxBotones/BtnVaciar

func _ready() -> void:
	for plan_id: String in botones_plan.keys():
		var boton: Button = botones_plan[plan_id]
		boton.text = _texto_plan(plan_id, false)
		boton.pressed.connect(_on_plan_pressed.bind(plan_id))
	btn_vaciar.pressed.connect(GlobalManager.clear_purchase)

	EventBus.purchase_updated.connect(_on_purchase_updated)
	EventBus.coupons_changed.connect(_on_coupons_changed)
	_on_purchase_updated(GlobalManager.compra_actual)
	EventBus.coupons_requested.emit()
	(botones_plan["pausa_activa"] as Button).grab_focus.call_deferred()

func _texto_plan(plan_id: String, elegido: bool) -> String:
	var plan: Dictionary = GlobalManager.PLANES_DESCANSO[plan_id]
	var marca: String = "[ELEGIDO]  " if elegido else ""
	return "%s%s  -  $%s\n%s" % [marca, plan["nombre"], FormatUtil.pesos(int(plan["precio"])), plan["detalle"]]

func _on_plan_pressed(plan_id: String) -> void:
	EventBus.plan_selected.emit(plan_id)

func _on_purchase_updated(compra: Dictionary) -> void:
	var plan_id: String = str(compra.get("plan_id", ""))
	for id: String in botones_plan.keys():
		var boton: Button = botones_plan[id]
		boton.set_pressed_no_signal(id == plan_id)
		# Accesibilidad: la selección se indica también con TEXTO (no solo
		# con el color del estado Pressed del Theme).
		boton.text = _texto_plan(id, id == plan_id)
	btn_vaciar.disabled = plan_id.is_empty()
	if plan_id.is_empty():
		lbl_seleccion.text = "Aún no has elegido un plan."
		btn_factura.disabled = true
		_actualizar_cupon(0)
		return
	var subtotal: int = int(compra.get("subtotal", 0))
	lbl_seleccion.text = "Plan elegido: %s  ·  Subtotal: $%s" % [GlobalManager.PLANES_DESCANSO[plan_id]["nombre"], FormatUtil.pesos(subtotal)]
	btn_factura.disabled = false
	_actualizar_cupon(subtotal)

func _on_coupons_changed(_coupons: Array) -> void:
	_actualizar_cupon(int(GlobalManager.compra_actual.get("subtotal", 0)))

func _actualizar_cupon(subtotal: int) -> void:
	var total_cupones: int = GlobalManager.coupons.size()
	if total_cupones == 0:
		lbl_cupones.text = "No tienes cupones. Gana uno jugando Enfoque Rush."
		return
	var mejor: Dictionary = GlobalManager.get_best_coupon(subtotal)
	if subtotal == 0:
		lbl_cupones.text = "Tienes %d cupón(es). Elige un plan para ver cuál aplica." % total_cupones
	elif mejor.is_empty():
		lbl_cupones.text = "Tienes %d cupón(es), pero ninguno aplica: no se alcanza la compra mínima." % total_cupones
	else:
		lbl_cupones.text = "Se aplicará tu mejor cupón: -$%s (compra mínima $%s)." % [FormatUtil.pesos(int(mejor["value"])), FormatUtil.pesos(int(mejor["minimum_purchase"]))]
