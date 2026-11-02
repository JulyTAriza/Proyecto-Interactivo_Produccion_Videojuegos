# res://src/scenes/coupon/coupon_event.gd
# ---------------------------------------------------------------------------
# COUPON EVENT — Cupón obtenido / Mis cupones
# ---------------------------------------------------------------------------
# Pantalla que se muestra al ganar "Enfoque Rush" (destaca el último cupón
# con una animación Tween) y que también sirve como "Mis cupones": lista
# toda la colección persistente. La lista se reconstruye cada vez que
# GlobalManager emite EventBus.coupons_changed.
# ---------------------------------------------------------------------------
extends Control

@onready var tarjeta: PanelContainer = $Margin/Scroll/VBox/Tarjeta
@onready var lbl_valor: Label = $Margin/Scroll/VBox/Tarjeta/Margin/VBox/LblValor
@onready var lbl_condicion: Label = $Margin/Scroll/VBox/Tarjeta/Margin/VBox/LblCondicion
@onready var lbl_codigo: Label = $Margin/Scroll/VBox/Tarjeta/Margin/VBox/LblCodigo
@onready var lbl_titulo: Label = $Margin/Scroll/VBox/LblTitulo
@onready var lbl_resumen: Label = $Margin/Scroll/VBox/LblResumen
@onready var lista: VBoxContainer = $Margin/Scroll/VBox/Lista
@onready var btn_tienda: Button = $Margin/Scroll/VBox/HBoxBotones/BtnTienda

func _ready() -> void:
	EventBus.coupons_changed.connect(_on_coupons_changed)
	var ultimo: Dictionary = GlobalManager.last_coupon
	if ultimo.is_empty():
		lbl_titulo.text = "Mis cupones"
		tarjeta.visible = false
	else:
		lbl_titulo.text = "¡Cupón obtenido!"
		lbl_valor.text = "$%s de descuento" % FormatUtil.pesos(int(ultimo.get("value", 0)))
		lbl_condicion.text = "Válido en compras desde $%s" % FormatUtil.pesos(int(ultimo.get("minimum_purchase", 0)))
		lbl_codigo.text = "Código %s  ·  %s" % [ultimo.get("code", ""), ultimo.get("origin", "")]
		_animar_tarjeta()
		# Se muestra una sola vez como "nuevo"; en visitas posteriores esta
		# pantalla funciona como "Mis cupones".
		GlobalManager.last_coupon = {}
	EventBus.coupons_requested.emit()
	btn_tienda.grab_focus.call_deferred()

func _on_coupons_changed(coupons: Array) -> void:
	for hijo in lista.get_children():
		hijo.queue_free()
	lbl_resumen.text = "Tienes %d cupón(es) disponible(s). Se conservan aunque cierres la aplicación." % coupons.size() if not coupons.is_empty() else "No tienes cupones disponibles. Gana uno en Enfoque Rush."
	for c in coupons:
		var cupon: Dictionary = c
		var fila: Label = Label.new()
		fila.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.text = "- %s: $%s de descuento, compra mínima $%s (obtenido %s)" % [
			cupon.get("code", "CUPON"), FormatUtil.pesos(int(cupon.get("value", 0))),
			FormatUtil.pesos(int(cupon.get("minimum_purchase", 0))), str(cupon.get("obtained_at", "")).replace("T", " ")]
		lista.add_child(fila)

## Entrada animada de la tarjeta: aparece desde una escala pequeña con
## rebote y un destello de color.
func _animar_tarjeta() -> void:
	tarjeta.modulate = Color(1, 1, 1, 0)
	tarjeta.scale = Vector2(0.6, 0.6)
	await get_tree().process_frame
	tarjeta.pivot_offset = tarjeta.size / 2.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tarjeta, "scale", Vector2.ONE, 0.5)
	tween.parallel().tween_property(tarjeta, "modulate", Color(1.4, 1.3, 0.8, 1), 0.25)
	tween.tween_property(tarjeta, "modulate", Color.WHITE, 0.35)
