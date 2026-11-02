# res://src/scenes/minigame/focus_play_area.gd
# ---------------------------------------------------------------------------
# FOCUS PLAY AREA — Campo de juego de "Enfoque Rush" (solo dibujo)
# ---------------------------------------------------------------------------
# Dibuja con _draw() los estímulos que caen, la "lente de enfoque" que
# controla el jugador y los textos flotantes de retroalimentación. No
# contiene reglas: FocusRush (el controlador) le entrega los datos y llama
# a queue_redraw() en cada cuadro.
#
# ACCESIBILIDAD (independencia del color): cada tipo de estímulo se
# distingue por FORMA y SÍMBOLO, no solo por color:
#   IDEA       -> círculo amarillo con una marca de verificación.
#   DISTRACTOR -> rombo rojo con signo de exclamación.
#   PAUSA      -> hexágono verde con signo "+".
# ---------------------------------------------------------------------------
extends Control

const COLOR_IDEA: Color = Color("#ffd166")
const COLOR_DISTRACTOR: Color = Color("#ef476f")
const COLOR_PAUSA: Color = Color("#06d6a0")
const COLOR_JUGADOR: Color = Color("#4cc9f0")
const COLOR_TINTA: Color = Color("#0b1020")
const COLOR_GUIA: Color = Color(1, 1, 1, 0.06)

const RADIO_ESTIMULO: float = 22.0
const ANCHO_JUGADOR: float = 128.0
const ALTO_JUGADOR: float = 22.0
const MARGEN_INFERIOR: float = 28.0

## Estímulos vivos: { "kind": int, "pos": Vector2, "speed": float, "spin": float }
var stimuli: Array = []
## Textos flotantes: { "text": String, "pos": Vector2, "color": Color, "life": float }
var floaters: Array = []
## Posición horizontal (centro) de la lente de enfoque.
var player_x: float = 0.0
## Destello cuando se atrapa un distractor (0..1).
var flash: float = 0.0

func player_rect() -> Rect2:
	var y: float = size.y - MARGEN_INFERIOR - ALTO_JUGADOR
	return Rect2(player_x - ANCHO_JUGADOR / 2.0, y, ANCHO_JUGADOR, ALTO_JUGADOR)

func _draw() -> void:
	# Fondo del campo y carriles guía.
	draw_rect(Rect2(Vector2.ZERO, size), Color("#10172e"))
	for i in range(1, 6):
		var x: float = size.x * i / 6.0
		draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_GUIA, 1.0)

	for s in stimuli:
		_dibujar_estimulo(s)

	_dibujar_jugador()

	var fuente: Font = get_theme_default_font()
	for f in floaters:
		var c: Color = f["color"]
		c.a = clampf(f["life"], 0.0, 1.0)
		draw_string(fuente, f["pos"], f["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 22, c)

	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(COLOR_DISTRACTOR, flash * 0.35))

func _dibujar_jugador() -> void:
	var r: Rect2 = player_rect()
	var radio: float = r.size.y / 2.0
	# Cápsula: rectángulo central + dos semicírculos.
	draw_rect(Rect2(r.position.x + radio, r.position.y, r.size.x - 2 * radio, r.size.y), COLOR_JUGADOR)
	draw_circle(Vector2(r.position.x + radio, r.position.y + radio), radio, COLOR_JUGADOR)
	draw_circle(Vector2(r.end.x - radio, r.position.y + radio), radio, COLOR_JUGADOR)
	# "Lente": arco superior que sugiere un recipiente que recibe ideas.
	draw_arc(Vector2(r.get_center().x, r.position.y + 4), r.size.x * 0.42, PI * 1.08, PI * 1.92, 24, Color(COLOR_JUGADOR, 0.7), 3.0)
	# Ojo central (identidad visual del "enfoque").
	draw_circle(r.get_center(), 7.0, COLOR_TINTA)
	draw_circle(r.get_center(), 3.0, Color.WHITE)

func _dibujar_estimulo(s: Dictionary) -> void:
	var p: Vector2 = s["pos"]
	var R: float = RADIO_ESTIMULO
	match int(s["kind"]):
		FocusRushRules.StimulusKind.IDEA:
			draw_circle(p, R, COLOR_IDEA)
			draw_arc(p, R, 0, TAU, 32, COLOR_TINTA, 2.0)
			var check: PackedVector2Array = [p + Vector2(-10, 0), p + Vector2(-3, 8), p + Vector2(11, -8)]
			draw_polyline(check, COLOR_TINTA, 4.0, true)
		FocusRushRules.StimulusKind.DISTRACTOR:
			var rombo: PackedVector2Array = [p + Vector2(0, -R - 3), p + Vector2(R + 3, 0), p + Vector2(0, R + 3), p + Vector2(-R - 3, 0)]
			draw_colored_polygon(rombo, COLOR_DISTRACTOR)
			rombo.append(rombo[0])
			draw_polyline(rombo, COLOR_TINTA, 2.0, true)
			draw_rect(Rect2(p.x - 2.5, p.y - 12, 5, 14), Color.WHITE)
			draw_circle(p + Vector2(0, 8), 3.0, Color.WHITE)
		FocusRushRules.StimulusKind.PAUSA:
			var hexagono: PackedVector2Array = []
			for i in 6:
				var ang: float = TAU * i / 6.0 + PI / 6.0
				hexagono.append(p + Vector2(cos(ang), sin(ang)) * R)
			draw_colored_polygon(hexagono, COLOR_PAUSA)
			hexagono.append(hexagono[0])
			draw_polyline(hexagono, COLOR_TINTA, 2.0, true)
			draw_rect(Rect2(p.x - 9, p.y - 2.5, 18, 5), COLOR_TINTA)
			draw_rect(Rect2(p.x - 2.5, p.y - 9, 5, 18), COLOR_TINTA)
