# res://src/data/wellness_item_data.gd
# ---------------------------------------------------------------------------
# WELLNESS ITEM DATA — Recurso de datos de un elemento de bienestar (Lab 9)
# ---------------------------------------------------------------------------
# Capa de DATOS pura: describe un elemento que puede formar parte del
# "Kit Anti-Fatiga" (equivalente al ingrediente de la guía). No sabe nada
# de cómo se dibuja: la interfaz lo lee y genera sus controles.
# Cada elemento es un archivo .tres editable desde el Inspector.
# ---------------------------------------------------------------------------
class_name WellnessItemData
extends Resource

## Categorías válidas = secciones del kit.
const CATEGORIAS: PackedStringArray = ["bebida", "snack", "actividad"]

## Identificador único (clave usada por GlobalManager y EventBus).
@export var id: String = ""
## Nombre legible que se muestra en la interfaz.
@export var display_name: String = ""
## Descripción breve del beneficio.
@export_multiline var description: String = ""
## Sección del kit a la que pertenece.
@export_enum("bebida", "snack", "actividad") var category: String = "bebida"
## Icono / ilustración del elemento.
@export var texture: Texture2D
## Precio en pesos colombianos.
@export_range(0, 100000, 500) var price: int = 0
## Puntos de alivio estimado de fatiga (se resta del índice de fatiga).
@export_range(0, 20) var relief: int = 0

func is_valid() -> bool:
	return not id.is_empty() and not display_name.is_empty() and CATEGORIAS.has(category) and price >= 0
