# res://src/core/event_bus.gd
# ---------------------------------------------------------------------------
# EVENT BUS (Autoload / Singleton)
# ---------------------------------------------------------------------------
# Canal intermediario global que implementa el patrón Observer para
# desacoplar por completo las escenas visuales de la lógica de navegación.
# Ninguna escena conoce a otra directamente: solo emiten y escuchan señales
# a través de este nodo, registrado como Autoload bajo el identificador
# "EventBus".
# ---------------------------------------------------------------------------
extends Node

## Se emite cuando cualquier panel solicita navegar hacia otra escena.
## MainApp es el único suscriptor responsable de instanciar/liberar escenas.
signal navigation_requested(target_scene_path: String)

## Se emite cuando un panel modifica un parámetro de simulación
## (por ejemplo, la selección de un ingrediente y su costo asociado).
signal parameter_changed(param_name: String, value: Variant)
