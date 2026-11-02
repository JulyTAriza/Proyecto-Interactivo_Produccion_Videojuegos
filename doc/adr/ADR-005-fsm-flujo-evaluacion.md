# ADR-005: Máquina de Estado Finito para el flujo de evaluación

* **Estado:** Aprobado
* **Fecha:** 2026-10-15
* **Autor:** July Tatiana Ariza

## Contexto

`Step1Base` permitía presionar "Finalizar y Guardar Evaluación" en
cualquier momento, incluso varias veces seguidas antes de que terminara
de procesarse el guardado anterior, y no existía ninguna distinción
explícita entre "el usuario está respondiendo" y "la evaluación ya se
guardó". Esto abría la puerta a guardar duplicados en el historial, o a
que el usuario siguiera marcando síntomas de una evaluación que, en la
práctica, ya se había cerrado.

El propio dominio del proyecto (un test de autoevaluación que pasa por
responder, confirmar y guardar) se describe naturalmente como una
secuencia de estados — es, de hecho, muy similar al ejemplo "selección,
personalización y confirmación" de la guía de referencia.

## Decisión

Se modela el flujo de `Step1Base` como una FSM con tres estados
(`enum EvaluationState { EN_EVALUACION, GUARDANDO, GUARDADA }`):

- **`EN_EVALUACION`**: estado inicial. El usuario puede elegir su perfil
  base y marcar síntomas libremente.
- **`GUARDANDO`**: transición disparada al presionar "Finalizar". Se
  deshabilitan todos los controles de evaluación, se emite
  `EventBus.evaluation_finalized` (el guardado real en
  `GlobalManager`), y se reproduce una animación de confirmación.
- **`GUARDADA`**: estado alcanzado automáticamente cuando termina la
  animación. Solo permite volver a `EN_EVALUACION` mediante el botón
  "Iniciar Nueva Evaluación".

Toda transición pasa por `change_state(new_state)`, que consulta
`_is_transition_allowed(from, to)` antes de aplicarse. Las entradas del
usuario (`_on_base_pressed`, `_on_item_pressed`) verifican el estado
actual antes de emitir cualquier señal al EventBus — el estado
determina qué interacciones son válidas, no al revés.

Se distingue el comportamiento propio de un estado (`_enter_guardando()`:
bloquear controles y disparar el guardado real; `_enter_guardada()`:
mostrar el botón de nueva evaluación) de la animación asociada a la
transición (`_reproducir_animacion_confirmacion()`), que anima la
aparición del mensaje de confirmación mediante `Tween` (escala +
opacidad, curva `TRANS_BACK`/`EASE_OUT`).

## Consecuencias

### Positivas
- Es imposible, por diseño, guardar la misma evaluación dos veces: una
  vez en `GUARDANDO`, el botón "Finalizar" queda deshabilitado hasta que
  el ciclo completo termine.
- El usuario recibe una confirmación visual clara (animada) de que su
  evaluación se guardó, en vez de que la pantalla simplemente se
  reinicie sin aviso.
- Las reglas del flujo quedan centralizadas y explícitas en
  `_is_transition_allowed()`, fáciles de auditar.

### Negativas / Costos
- Se agregaron ~40 líneas de código y dos nodos de interfaz nuevos
  (`LblConfirmacion`, `BtnNuevaEvaluacion`) para un flujo que antes se
  resolvía con una sola línea (`EventBus.evaluation_finalized.emit()`).
- Si en el futuro se permite editar una evaluación ya guardada, habrá
  que ampliar cuidadosamente la tabla de transiciones para no introducir
  estados inconsistentes con el historial ya persistido.
