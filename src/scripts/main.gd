extends Control

@onready var menu_simular: Button = $VBoxMenu/BtnSimular
@onready var menu_salir: Button = $VBoxMenu/BtnSalir
@onready var mensaje_estado: Label = $LblEstado


func _ready() -> void:
	_configurar_menu()
	mensaje_estado.text = "Estado del Sistema: Listo"


func _configurar_menu() -> void:
	menu_simular.pressed.connect(_iniciar_simulacion)
	menu_salir.pressed.connect(_cerrar_aplicacion)


func _iniciar_simulacion() -> void:
	mensaje_estado.text = "Estado del Sistema: Cargando simulación..."
	print("La simulación fue iniciada.")


func _cerrar_aplicacion() -> void:
	print("Cerrando aplicación...")
	get_tree().quit()
