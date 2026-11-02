# res://tools/debug_session.gd
# Escena auxiliar para la sesión de depuración del Laboratorio 10.
# Precarga cupones de prueba en disco, fuerza la recarga y consulta el mejor
# cupón para un subtotal de $15.000 (caso límite: igual al mínimo del cupón
# de 2 estrellas). Se ejecuta con el depurador de Godot y breakpoints.
extends Node

func _ready() -> void:
	var datos: Dictionary = {"coupons": [
		{"id": "D1", "code": "ENFOQUE-2000", "value": 2000, "minimum_purchase": 10000},
		{"id": "D2", "code": "ENFOQUE-3000", "value": 3000, "minimum_purchase": 15000},
		{"id": "D3", "code": "ENFOQUE-5000", "value": 5000, "minimum_purchase": 20000},
	], "purchases": []}
	GlobalManager.save_path = "user://debug_save_data.json"
	var f: FileAccess = FileAccess.open(GlobalManager.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(datos))
	f.close()
	GlobalManager.load_coupons()
	var mejor: Dictionary = GlobalManager.get_best_coupon(15000)
	print("DEBUG> mejor cupón para $15.000 -> ", mejor.get("code", "ninguno"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GlobalManager.save_path))
	get_tree().quit()
