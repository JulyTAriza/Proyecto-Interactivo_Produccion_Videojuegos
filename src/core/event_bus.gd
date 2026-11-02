# res://src/core/event_bus.gd
# ---------------------------------------------------------------------------
# EVENT BUS (Autoload / Singleton)
# ---------------------------------------------------------------------------
# Canal intermediario global que implementa el patrón Observer para
# desacoplar por completo las escenas visuales de la lógica de navegación
# y de la lógica de estado de la simulación. Ninguna escena conoce a otra
# directamente: solo emiten y escuchan señales tipadas a través de este
# nodo, registrado como Autoload bajo el identificador "EventBus".
# ---------------------------------------------------------------------------
extends Node

# ===========================================================================
# NAVEGACIÓN (Laboratorios 3-4)
# ===========================================================================

## Se emite cuando cualquier panel (o instancia de ButtonNav) solicita
## navegar hacia otra escena. MainApp es el único suscriptor responsable
## de instanciar/liberar escenas y de mantener la pila de historial.
## Si "discard_previous" es true, MainApp interpreta la navegación como un
## "regreso" y retira el último elemento del historial (.pop_back()).
signal navigation_requested(target_scene: String, discard_previous: bool)

# ===========================================================================
# EVALUACIÓN DE FATIGA (Laboratorios 4-6)
# ===========================================================================

## Se emite cuando el usuario selecciona un perfil/base de evaluación en
## Step1Base (por ejemplo: "estudiante", "profesional", "deportista").
signal base_selected(base_name: String)

## Se emite cuando el usuario marca un síntoma/ítem adicional en Step1Base.
signal item_added(item_id: String)

## Se emite cada vez que GlobalManager recalcula el índice total de fatiga.
signal total_changed(new_total: int)

## Petición explícita del total vigente (patrón petición/respuesta).
signal total_requested

## El usuario confirma que terminó la evaluación y quiere guardarla.
signal evaluation_finalized

## Petición del historial completo de evaluaciones guardadas.
signal history_requested

## Respuesta con el arreglo actualizado de evaluaciones guardadas.
signal history_updated(historial: Array)

# ===========================================================================
# CUPONES Y COMPRAS (Laboratorio 7)
# ===========================================================================

## El minijuego "Enfoque Rush" emite esta señal cuando el jugador gana.
## Único suscriptor con responsabilidad de estado: GlobalManager, que lo
## agrega a la colección y lo persiste en user://save_data.json.
signal coupon_obtained(coupon: Dictionary)

## Se emite (desde GlobalManager) cada vez que la colección de cupones
## cambia: al cargar, al obtener uno nuevo o al consumir uno en una compra.
signal coupons_changed(coupons: Array)

## Petición explícita de la colección actual de cupones.
signal coupons_requested

## La tienda de planes (BuyPanel) informa el plan elegido por el usuario.
signal plan_selected(plan_id: String)

## GlobalManager confirma la compra en curso (plan + subtotal).
signal purchase_updated(purchase: Dictionary)

## Se emite cuando una compra fue confirmada en cualquier factura.
## summary = { "items": Array, "subtotal": int, "discount": int,
##             "total": int, "coupon": Dictionary, "fecha": String }
signal purchase_completed(summary: Dictionary)

# ===========================================================================
# KIT ANTI-FATIGA BASADO EN RESOURCES (Laboratorio 9)
# ===========================================================================

## El usuario elige un elemento del catálogo para una sección del kit
## (slot = categoría: "bebida", "snack" o "actividad").
signal kit_item_selected(slot: String, item_id: String)

## El usuario vacía una sección del kit ("" = vaciar todo el kit).
signal kit_slot_cleared(slot: String)

## GlobalManager notifica la composición vigente del kit y su subtotal,
## recalculado a partir de los recursos (WellnessItemData.price).
signal kit_changed(selection: Dictionary, subtotal: int)

## Petición explícita de la composición vigente del kit.
signal kit_requested
