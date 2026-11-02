# res://src/data/wellness_database.gd
# ---------------------------------------------------------------------------
# WELLNESS DATABASE — Catálogo oficial de elementos de bienestar (Lab 9)
# ---------------------------------------------------------------------------
# Contenedor de recursos WellnessItemData. Su instancia
# res://src/data/wellness_catalog.tres es el catálogo oficial que
# GlobalManager precarga. Para agregar un producto basta con crear un
# nuevo .tres de WellnessItemData y arrastrarlo al arreglo "items" en el
# Inspector: la interfaz se genera sola, sin tocar código.
# ---------------------------------------------------------------------------
class_name WellnessDatabase
extends Resource

@export var items: Array[WellnessItemData] = []

func get_item(item_id: String) -> WellnessItemData:
	for item in items:
		if item != null and item.id == item_id:
			return item
	return null

func get_by_category(category: String) -> Array[WellnessItemData]:
	var out: Array[WellnessItemData] = []
	for item in items:
		if item != null and item.category == category:
			out.append(item)
	return out

## Categorías presentes en el catálogo, en el orden oficial del kit.
func get_categories() -> PackedStringArray:
	var out: PackedStringArray = []
	for c in WellnessItemData.CATEGORIAS:
		if not get_by_category(c).is_empty():
			out.append(c)
	return out
