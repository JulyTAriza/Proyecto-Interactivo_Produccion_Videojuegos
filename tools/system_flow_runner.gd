# res://tools/system_flow_runner.gd
# ---------------------------------------------------------------------------
# SYSTEM FLOW RUNNER — Prueba de sistema automatizada (SIS-01)
# ---------------------------------------------------------------------------
# Ejecuta el proyecto REAL (main_app.tscn) y lo recorre como lo haría un
# jugador, presionando los mismos botones y usando las mismas acciones de
# entrada (move_left / move_right) que el teclado:
#   Fase "jugar"   : Menú -> Enfoque Rush -> partida completa con un
#                    "bot" que mueve la lente -> Victoria -> cupón guardado
#                    -> Ver cupón -> Tienda -> Plan -> Factura -> Confirmar
#                    (consume el cupón) .
#   Fase "verificar": nueva ejecución del proceso; comprueba que
#                    user://save_data.json se cargó con el estado esperado
#                    (los cupones obtenidos persisten y el consumido no
#                    reaparece).
# Uso:
#   godot --headless --fixed-fps 60 --path . res://tools/system_flow_runner.tscn -- --fase=jugar
#   (opcional: --comprar=false para ganar el cupón y salir sin gastarlo)
#   godot --headless --path . res://tools/system_flow_runner.tscn -- --fase=verificar --esperados=N
# ---------------------------------------------------------------------------
extends Node

const MAIN_APP: PackedScene = preload("res://src/core/main_app.tscn")
const State = FocusRushRules.GameState
const Kind = FocusRushRules.StimulusKind

var app: Node
var errores: Array[String] = []
var args_tienda: String = "planes"

func _ready() -> void:
	var args: Dictionary = _args()
	var fase: String = args.get("fase", "jugar")
	args_tienda = args.get("tienda", "planes")
	app = MAIN_APP.instantiate()
	add_child(app)
	await _frames(5)
	if fase == "verificar":
		_verificar(int(args.get("esperados", "-1")))
	else:
		await _jugar(args.get("comprar", "true") == "true")
	_terminar()

func _jugar(comprar: bool) -> void:
	var cupones_iniciales: int = GlobalManager.coupons.size()
	_log("Cupones al iniciar: %d" % cupones_iniciales)

	# 1) Menú -> Enfoque Rush
	_presionar(_buscar("BtnJugar"))
	await _frames(5)
	var juego: Node = _escena_actual()
	_check(juego.name == "FocusRush", "Se abrió el minijuego (escena actual: %s)" % juego.name)

	# 2) Jugar hasta ganar (máx. 5 intentos)
	var ganado: bool = false
	for intento in 5:
		_presionar(juego.btn_primario)  # Comenzar / Reintentar
		await _frames(2)
		_check(juego.current_state == State.CUENTA_REGRESIVA, "Inicia la cuenta regresiva")
		var frames: int = 0
		while juego.current_state in [State.CUENTA_REGRESIVA, State.JUGANDO] and frames < 60 * 60:
			_bot(juego)
			await get_tree().process_frame
			frames += 1
		Input.action_release("move_left")
		Input.action_release("move_right")
		_log("Intento %d terminó en %s con %d puntos, %d vidas, %.1f s (frames=%d)" % [intento + 1, State.keys()[juego.current_state], juego.score, juego.lives, juego.elapsed, frames])
		if juego.current_state == State.VICTORIA:
			ganado = true
			break
	_check(ganado, "El bot logró ganar una partida")
	if not ganado:
		return

	_check(GlobalManager.coupons.size() == cupones_iniciales + 1, "El cupón ganado entró a la colección")
	_check(_cupones_en_disco() == cupones_iniciales + 1, "El cupón ganado quedó en user://save_data.json")
	var cupon: Dictionary = juego.last_coupon
	_log("Cupón ganado: %s" % cupon)
	if not comprar:
		_log("RESULTADO_CUPONES=%d" % GlobalManager.coupons.size())
		return

	if args_tienda == "kit":
		_presionar(juego.btn_primario)
		await _frames(5)
		await _comprar_kit(cupones_iniciales)
		return

	# 3) Victoria -> Ver mi cupón -> Tienda
	_presionar(juego.btn_primario)
	await _frames(5)
	_check(_escena_actual().name == "CouponEvent", "Se muestra la pantalla del cupón")
	_presionar(_buscar("BtnTienda"))
	await _frames(5)
	_check(_escena_actual().name == "BuyPanel", "Se abrió la tienda")

	# 4) Elegir el plan más caro (25.000) para que cualquier cupón aplique
	_presionar(_buscar("BtnBienestarTotal"))
	await _frames(2)
	_check(GlobalManager.compra_actual.get("subtotal", 0) == 25000, "Subtotal del plan = 25.000")
	var btn_factura: Button = _buscar("BtnFactura")
	_check(not btn_factura.disabled, "El botón de factura se habilitó")
	_presionar(btn_factura)
	await _frames(5)
	var factura: Node = _escena_actual()
	_check(factura.name == "PurchaseInvoice", "Se abrió la factura")
	var esperado: int = 25000 - int(GlobalManager.get_best_coupon(25000).get("value", 0))
	_check(factura.lbl_total.text == "$" + FormatUtil.pesos(esperado), "Total mostrado %s == esperado $%s" % [factura.lbl_total.text, FormatUtil.pesos(esperado)])

	# 5) Confirmar -> el cupón se consume y el archivo se actualiza
	_presionar(factura.btn_confirmar)
	await _frames(5)
	_check(GlobalManager.coupons.size() == cupones_iniciales, "El cupón aplicado se consumió")
	_check(_cupones_en_disco() == cupones_iniciales, "save_data.json refleja el consumo")
	_check(GlobalManager.purchases.size() > 0, "La compra quedó registrada")
	if "pop_up_confirm" in factura:
		_check(factura.pop_up_confirm.visible, "Se muestra PurchaseSuccessPopup tras confirmar")
		_presionar(factura.btn_continuar)
		await _frames(5)
		_check(_escena_actual().name == "MenuPanel", "Continuar regresa al menú principal")
	_log("RESULTADO_CUPONES=%d" % GlobalManager.coupons.size())

## Lab 9: Cupón -> Menú -> Kit Anti-Fatiga (UI auto-poblada) -> factura interactiva.
func _comprar_kit(cupones_iniciales: int) -> void:
	_presionar(_buscar("BtnVolver"))
	await _frames(5)
	_presionar(_buscar("BtnKit"))
	await _frames(5)
	var panel: Node = _escena_actual()
	_check(panel.name == "BuyPanelInteractive", "Se abrió el armador de kit")
	_check(panel.tarjetas.size() == GlobalManager.wellness_items.size(), "Se generó una tarjeta por recurso del catálogo (%d)" % panel.tarjetas.size())
	for id in ["jugo", "frutos_secos", "mindfulness"]:
		_presionar(panel.tarjetas[id])
		await _frames(3)
	var esperado: int = 5500 + 6000 + 12000
	_check(GlobalManager.calculate_kit_subtotal(GlobalManager.kit_selection) == esperado, "Subtotal del kit = $23.500")
	_presionar(panel.tarjetas["te"])  # reemplaza la bebida
	await _frames(3)
	esperado = 4500 + 6000 + 12000
	_check(GlobalManager.kit_selection["bebida"] == "te", "Elegir otra bebida reemplaza la sección")
	await _frames(30)
	_check(panel.lbl_subtotal.text == "Subtotal: $" + FormatUtil.pesos(esperado), "La UI muestra el subtotal recalculado (%s)" % panel.lbl_subtotal.text)
	var slot_snack: Dictionary = panel.composicion.slots["snack"]
	_presionar(slot_snack["quitar"])
	await _frames(3)
	_check(GlobalManager.kit_selection["snack"] == "", "Quitar vacía la sección snack")
	_presionar(panel.tarjetas["frutos_secos"])
	await _frames(3)
	_presionar(panel.btn_factura)
	await _frames(5)
	var factura: Node = _escena_actual()
	_check(factura.name == "PurchaseInvoiceInteractive", "Se abrió la factura interactiva")
	_check(factura.items_factura.size() == 3, "La factura tiene 3 líneas generadas desde recursos")
	var cupon: Dictionary = GlobalManager.get_best_coupon(esperado)
	var total: int = esperado - int(cupon.get("value", 0))
	_check(factura.lbl_total.text == "$" + FormatUtil.pesos(total), "Total de la factura %s == $%s" % [factura.lbl_total.text, FormatUtil.pesos(total)])
	_presionar(factura.btn_confirmar)
	await _frames(5)
	_check(factura.pop_up_confirm.visible, "PurchaseSuccessPopup visible tras confirmar el kit")
	_check(GlobalManager.coupons.size() == cupones_iniciales + 1 - (0 if cupon.is_empty() else 1), "El cupón aplicado al kit se consumió")
	_check(GlobalManager.calculate_kit_subtotal(GlobalManager.kit_selection) == 0, "El kit se vació después de comprar")
	_log("RESULTADO_CUPONES=%d" % GlobalManager.coupons.size())

func _verificar(esperados: int) -> void:
	_log("Cupones cargados al reiniciar: %d (esperados: %d)" % [GlobalManager.coupons.size(), esperados])
	_check(GlobalManager.coupons.size() == esperados, "La colección persistida se restauró al iniciar")

## Bot sencillo: persigue la idea o pausa más baja y se aparta de los
## distractores que están por caer sobre la lente.
func _bot(juego: Node) -> void:
	if juego.current_state != State.JUGANDO:
		return
	var area: Control = juego.play_area
	var px: float = area.player_x
	var y_lente: float = area.player_rect().position.y
	var objetivo: float = area.size.x / 2.0
	var mejor_y: float = -INF
	for s in area.stimuli:
		var p: Vector2 = s["pos"]
		if int(s["kind"]) != Kind.DISTRACTOR and p.y > mejor_y and p.y < y_lente:
			mejor_y = p.y
			objetivo = p.x
	for s in area.stimuli:
		var p: Vector2 = s["pos"]
		if int(s["kind"]) == Kind.DISTRACTOR and p.y > y_lente - 170 and p.y < y_lente + 10:
			if absf(p.x - objetivo) < area.ANCHO_JUGADOR * 0.75:
				objetivo = p.x + (area.ANCHO_JUGADOR if px >= p.x else -area.ANCHO_JUGADOR)
	Input.action_release("move_left")
	Input.action_release("move_right")
	if objetivo < px - 6:
		Input.action_press("move_left")
	elif objetivo > px + 6:
		Input.action_press("move_right")

# ---------------------------------------------------------------------------
func _escena_actual() -> Node:
	return app.current_scene

func _buscar(nombre: String) -> Node:
	var n: Node = _escena_actual().find_child(nombre, true, false)
	if n == null:
		errores.append("No se encontró el nodo %s" % nombre)
	return n

func _presionar(b: BaseButton) -> void:
	if b == null:
		return
	b.pressed.emit()
	if b.toggle_mode:
		b.button_pressed = true

func _cupones_en_disco() -> int:
	var f: FileAccess = FileAccess.open(GlobalManager.save_path, FileAccess.READ)
	if f == null:
		return -1
	var d: Variant = JSON.parse_string(f.get_as_text())
	return (d as Dictionary).get("coupons", []).size() if typeof(d) == TYPE_DICTIONARY else -1

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _check(cond: bool, msg: String) -> void:
	_log(("[OK]   " if cond else "[FALLA] ") + msg)
	if not cond:
		errores.append(msg)

func _log(msg: String) -> void:
	print("SIS> ", msg)

func _args() -> Dictionary:
	var d: Dictionary = {}
	var crudos: Array = Array(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		# En la versión Web los argumentos llegan por la URL: ?fase=jugar&comprar=false
		var query: String = str(JavaScriptBridge.eval("window.location.search", true)).trim_prefix("?")
		for par in query.split("&", false):
			crudos.append("--" + par)
	for a in crudos:
		var partes: PackedStringArray = a.trim_prefix("--").split("=")
		d[partes[0]] = partes[1] if partes.size() > 1 else "true"
	return d

func _terminar() -> void:
	print("SIS> ==== %s (%d falla(s)) ====" % ["PASA" if errores.is_empty() else "FALLA", errores.size()])
	get_tree().quit(0 if errores.is_empty() else 1)
