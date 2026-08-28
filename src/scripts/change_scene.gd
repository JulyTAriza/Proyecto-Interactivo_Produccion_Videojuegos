# res://src/scripts/change_scene.gd
extends Node

# Método acoplado para navegar hacia el nivel 1 de simulación
func cambiar_de_escena_nivel() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_level_1.tscn")

# Método acoplado para retornar al menú principal
func cambiar_de_escena_menu() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main.tscn")

func _on_btn_simular_pressed_navigation() -> void:
	cambiar_de_escena_nivel()

	pass # Replace with function body.


func _on_btn_volver_pressed_navigation() -> void:
	cambiar_de_escena_menu()
	pass # Replace with function body.
