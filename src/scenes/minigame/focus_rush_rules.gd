# res://src/scenes/minigame/focus_rush_rules.gd
# ---------------------------------------------------------------------------
# FOCUS RUSH RULES — Reglas puras del minijuego "Enfoque Rush"
# ---------------------------------------------------------------------------
# Se separan las reglas de negocio del minijuego (puntaje, combos, tabla de
# transiciones de la FSM y cálculo del cupón ganado) de la escena visual.
# Así pueden probarse de forma aislada con GdUnit4 (Laboratorio 10) sin
# instanciar nodos, y la escena solo se ocupa de dibujar y leer la entrada.
# ---------------------------------------------------------------------------
class_name FocusRushRules
extends RefCounted

## Estados del minijuego (FSM).
enum GameState { INSTRUCCIONES, CUENTA_REGRESIVA, JUGANDO, PAUSADO, VICTORIA, DERROTA }

## Tipos de estímulo que caen en el campo de juego.
enum StimulusKind { IDEA, DISTRACTOR, PAUSA }

const DURACION_PARTIDA: float = 45.0
const META_PUNTOS: int = 200
const VIDAS_INICIALES: int = 3
const PUNTOS_IDEA: int = 10

## Umbrales de "estrellas" según el desempeño al ganar.
const SEGUNDOS_PARA_2_ESTRELLAS: float = 15.0

## Tabla de transiciones permitidas de la FSM.
const TRANSICIONES: Dictionary = {
	GameState.INSTRUCCIONES: [GameState.CUENTA_REGRESIVA],
	GameState.CUENTA_REGRESIVA: [GameState.JUGANDO],
	GameState.JUGANDO: [GameState.PAUSADO, GameState.VICTORIA, GameState.DERROTA],
	GameState.PAUSADO: [GameState.JUGANDO, GameState.DERROTA],
	GameState.VICTORIA: [GameState.CUENTA_REGRESIVA],
	GameState.DERROTA: [GameState.CUENTA_REGRESIVA],
}

static func is_transition_allowed(from: GameState, to: GameState) -> bool:
	return TRANSICIONES.get(from, []).has(to)

## Multiplicador según la racha de ideas atrapadas sin fallar:
## 0-4 -> x1, 5-9 -> x2, 10 o más -> x3.
static func combo_multiplier(streak: int) -> int:
	if streak >= 10:
		return 3
	if streak >= 5:
		return 2
	return 1

## Puntos que otorga atrapar una IDEA con la racha indicada (antes de
## sumar la idea actual).
static func points_for_idea(streak: int) -> int:
	return PUNTOS_IDEA * combo_multiplier(streak)

## Probabilidad de que el siguiente estímulo sea un distractor; aumenta con
## el tiempo transcurrido (dificultad progresiva), acotada a [0.25, 0.45].
static func distractor_chance(elapsed: float) -> float:
	return clampf(0.25 + elapsed / DURACION_PARTIDA * 0.20, 0.25, 0.45)

## Intervalo entre apariciones: de 0.85 s al inicio a 0.45 s al final.
static func spawn_interval(elapsed: float) -> float:
	return lerpf(0.85, 0.45, clampf(elapsed / DURACION_PARTIDA, 0.0, 1.0))

## Velocidad de caída en píxeles/segundo, también progresiva.
static func fall_speed(elapsed: float) -> float:
	return lerpf(170.0, 300.0, clampf(elapsed / DURACION_PARTIDA, 0.0, 1.0))

## Estrellas obtenidas al ganar (1 a 3). 0 si no se alcanzó la meta.
static func stars_for(score: int, time_left: float, lives_lost: int) -> int:
	if score < META_PUNTOS:
		return 0
	var estrellas: int = 1
	if time_left >= SEGUNDOS_PARA_2_ESTRELLAS:
		estrellas = 2
		if lives_lost == 0:
			estrellas = 3
	return estrellas

## Cupón que se entrega según las estrellas. Un cupón de mayor valor exige
## un mínimo de compra mayor (regla de negocio de la tienda).
static func coupon_for_stars(stars: int) -> Dictionary:
	match stars:
		1:
			return {"value": 2000, "minimum_purchase": 10000}
		2:
			return {"value": 3000, "minimum_purchase": 15000}
		3:
			return {"value": 5000, "minimum_purchase": 20000}
	return {}

## Construye el cupón completo (con id único, código y metadatos) que se
## emite por EventBus.coupon_obtained.
static func build_coupon(stars: int, score: int) -> Dictionary:
	var base: Dictionary = coupon_for_stars(stars)
	if base.is_empty():
		return {}
	var marca: int = int(Time.get_unix_time_from_system())
	base["id"] = "CUP-%d-%04d" % [marca, randi() % 10000]
	base["code"] = "ENFOQUE-%d" % int(base["value"])
	base["origin"] = "Enfoque Rush (%d estrella%s, %d pts)" % [stars, "" if stars == 1 else "s", score]
	base["obtained_at"] = Time.get_datetime_string_from_system()
	return base
