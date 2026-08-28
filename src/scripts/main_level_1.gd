extends Control

@onready var opcion_a: Button = $GridContainer/BtnIngrediente1
@onready var opcion_b: Button = $GridContainer/BtnIngrediente2
@onready var resultado_label: Label = $LblStatusLocal


func _ready() -> void:
	inicializar_opciones()


func inicializar_opciones() -> void:
	opcion_a.pressed.connect(
		registrar_ingrediente.bind("Base Tradicional", 1500)
	)

	opcion_b.pressed.connect(
		registrar_ingrediente.bind("Base Integral", 2000)
	)


func registrar_ingrediente(nombre: String, costo: int) -> void:
	var descripcion: String = "Selección: %s (+$%d)" % [nombre, costo]

	resultado_label.text = descripcion
	print("Opción seleccionada: ", nombre)
	print("Costo asociado: $", costo)
