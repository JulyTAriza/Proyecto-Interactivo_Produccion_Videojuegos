# res://src/core/event_bus.gd
# ---------------------------------------------------------------------------
# EVENT BUS (Autoload / Singleton)
# ---------------------------------------------------------------------------
# Canal intermediario global que implementa el patrón Observer para
# desacoplar por completo las escenas visuales de la lógica de navegación
# y de la lógica de estado de la simulación. Ninguna escena conoce a otra
# directamente ni conoce a GlobalManager: solo emiten y escuchan señales
# tipadas a través de este nodo, registrado como Autoload bajo el
# identificador "EventBus".
# ---------------------------------------------------------------------------
extends Node

## Se emite cuando cualquier panel (o instancia de ButtonNav) solicita
## navegar hacia otra escena. MainApp es el único suscriptor responsable
## de instanciar/liberar escenas y de mantener la pila de historial.
## Si "discard_previous" es true, MainApp interpreta la navegación como un
## "regreso" y retira el último elemento del historial (.pop_back()).
signal navigation_requested(target_scene: String, discard_previous: bool)

## Se emite cuando el usuario selecciona un perfil/base de evaluación en
## Step1Base (por ejemplo: "estudiante", "profesional", "deportista").
## Único suscriptor: GlobalManager.
signal base_selected(base_name: String)

## Se emite cuando el usuario marca un síntoma/ítem adicional en Step1Base.
## Único suscriptor: GlobalManager.
signal item_added(item_id: String)

## Se emite cada vez que GlobalManager recalcula el índice total de fatiga.
## Cualquier interfaz interesada (ej. el Label de Step1Base) se suscribe
## de forma pasiva para refrescar su visualización.
signal total_changed(new_total: int)

## Se emite cuando una interfaz necesita conocer el total ACTUAL sin haber
## provocado ningún cambio (por ejemplo, al cargar Step1Base y querer
## mostrar de inmediato el valor persistido de una sesión anterior).
## GlobalManager responde re-emitiendo "total_changed" con el valor vigente.
signal total_requested

## Se emite desde Step1Base cuando el usuario confirma que terminó de
## responder y quiere guardar el resultado en el historial persistente.
## GlobalManager registra el intento, lo guarda en disco y reinicia el
## estado de la simulación para permitir una nueva evaluación.
signal evaluation_finalized

## Se emite cuando una interfaz (ej. HistoryPanel) necesita el historial
## completo de evaluaciones guardadas. GlobalManager responde emitiendo
## "history_updated" con el arreglo cargado desde disco.
signal history_requested

## Se emite con el arreglo actualizado de evaluaciones guardadas, cada vez
## que se solicita (history_requested) o que se agrega un nuevo registro
## (evaluation_finalized).
signal history_updated(historial: Array)
