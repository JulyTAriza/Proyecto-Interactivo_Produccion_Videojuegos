# res://tools/build_catalog.gd
# Genera los .tres del catálogo (equivalente a crearlos a mano en el
# Inspector). Uso: godot --headless --path . -s res://tools/build_catalog.gd
extends SceneTree

const DATOS: Array = [
	["agua", "Botella de agua", "Hidratarse mejora la atención sostenida.", "bebida", 3000, 3],
	["te", "Té de manzanilla", "Bebida caliente que ayuda a bajar la tensión.", "bebida", 4500, 4],
	["jugo", "Jugo natural", "Energía de la fruta sin exceso de azúcar.", "bebida", 5500, 3],
	["frutos_secos", "Mix de frutos secos", "Grasas saludables para el cerebro.", "snack", 6000, 4],
	["fruta", "Fruta picada", "Snack ligero y refrescante.", "snack", 5000, 3],
	["barra", "Barra de avena", "Energía de liberación lenta.", "snack", 3500, 2],
	["pausa_activa", "Pausa activa guiada", "5 minutos de estiramientos dirigidos.", "actividad", 8000, 6],
	["mindfulness", "Sesión de mindfulness", "10 minutos de atención plena guiada.", "actividad", 12000, 8],
	["siesta", "Siesta reparadora", "20 minutos de descanso con alarma suave.", "actividad", 9000, 7],
]

func _init() -> void:
	var db: WellnessDatabase = WellnessDatabase.new()
	for d in DATOS:
		var item: WellnessItemData = WellnessItemData.new()
		item.id = d[0]
		item.display_name = d[1]
		item.description = d[2]
		item.category = d[3]
		item.price = d[4]
		item.relief = d[5]
		item.texture = load("res://src/assets/items/item_%s.svg" % d[0])
		var ruta: String = "res://src/data/items/%s.tres" % d[0]
		ResourceSaver.save(item, ruta)
		db.items.append(load(ruta))
	ResourceSaver.save(db, "res://src/data/wellness_catalog.tres")
	print("Catálogo generado con %d elementos." % db.items.size())
	quit()
