# res://src/scenes/gamification/game_hub.gd
# ---------------------------------------------------------------------------
# GAME HUB — Participa en la promoción (Laboratorios 5, 6 y 7)
# ---------------------------------------------------------------------------
# Pantalla de participación voluntaria: reúne las tres fuentes de cupones.
# La navegación la hacen instancias de ButtonNav configuradas en el
# Inspector; este script solo muestra los intentos restantes de la sesión
# (estado que vive en GlobalManager) y desactiva el botón de un juego
# cuando ya no le quedan intentos.
# ---------------------------------------------------------------------------
extends Control

## juego_id -> [botón, etiqueta]
@onready var juegos: Dictionary = {
	"catch_energy": [$Margin/Scroll/VBox/Grid/CardCatch/Margin/VBox/BtnCatch, $Margin/Scroll/VBox/Grid/CardCatch/Margin/VBox/LblIntentos],
	"infusion_rush": [$Margin/Scroll/VBox/Grid/CardInfusion/Margin/VBox/BtnInfusion, $Margin/Scroll/VBox/Grid/CardInfusion/Margin/VBox/LblIntentos],
}
@onready var btn_focus: Button = $Margin/Scroll/VBox/Grid/CardFocus/Margin/VBox/BtnFocus

func _ready() -> void:
	for juego_id in juegos.keys():
		var boton: Button = juegos[juego_id][0]
		var etiqueta: Label = juegos[juego_id][1]
		var restantes: int = GlobalManager.intentos_restantes(juego_id)
		etiqueta.text = "Intentos restantes en esta sesión: %d de %d" % [restantes, GlobalManager.MAX_INTENTOS_SESION]
		boton.disabled = restantes <= 0
	btn_focus.grab_focus.call_deferred()
