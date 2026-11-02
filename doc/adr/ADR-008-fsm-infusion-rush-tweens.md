# Registro de Decisión de Arquitectura (ADR)

## ADR-008: Máquina de Estado Finito por Instancia y Animaciones Programáticas (Laboratorio 6)

* **Estado:** Aprobado
* **Fecha:** 2026-11-02
* **Autor:** July Tatiana Ariza Peña

### Contexto
El Laboratorio 6 pide modelar con una FSM el ciclo de vida de un objeto interactivo
(en la guía, una pizza) cuyo comportamiento depende de su estado, y representar las
transiciones con Tweens. ADR-005 ya aplicó una FSM al flujo de la evaluación, pero ese flujo
tiene una sola instancia y no usa arrastre ni temporizadores por objeto.

### Decisión
* Se crea **Infusión Rush** en `src/scenes/gamification/infusion_rush/`. Cada taza
  (`cup.tscn`, `CharacterBody2D` con `input_pickable`) tiene su propia FSM en `cup.gd`:
  `FRIA → DISPONIBLE → ARRASTRANDO → INFUSIONANDO → LISTA → ARRASTRANDO → ENTREGADA`.
* `change_state()` es el único punto que cambia el estado y valida la tabla de transiciones
  (`is_transition_allowed`). `previous_state` distingue los dos usos de `ARRASTRANDO`.
* El estado interpreta la entrada `interact` (clic izquierdo del Input Map): en `FRIA` e
  `INFUSIONANDO` acelera el `Timer`; en `DISPONIBLE` y `LISTA` toma la taza.
* Un solo `Timer` por taza mide enfriamiento e infusión, porque solo hay un estado a la vez.
* `play_transition_animation(from, to)` elige un Tween por cada pareja de estados.
* La estación (`station.gd`, grupo `station`) y la zona de entrega (`delivery_area.gd`, grupo
  `delivery`) solo reaccionan; el controlador (`infusion_rush_main.gd`) lleva entregas, tiempo,
  victoria/derrota y emite `coupon_obtained` al ganar.
* `MainApp` ignora el mouse y `SceneContainer` lo deja pasar (`mouse_filter`), para que el
  *picking* de físicas llegue a las tazas.

### Consecuencias
* **Positivas:**
  * Varias tazas conviven en estados distintos sin condicionales globales.
  * Agregar un estado (p. ej. `TERMINANDO`, reto 2 de la guía) implica tocar la enumeración,
    la tabla de transiciones y un `process_*`, sin reescribir el resto.
  * Las animaciones quedan asociadas a transiciones, no a clics sueltos.
* **Negativas / Costos:**
  * Más funciones por objeto; hay que mantener la tabla de transiciones al día.
  * Los Tweens se crean en cada transición: si se encadenan muchos, conviene esperar
    `tween.finished` antes de permitir otra interacción.
