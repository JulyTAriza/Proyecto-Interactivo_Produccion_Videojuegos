# Registro de Decisión de Arquitectura (ADR)

## ADR-007: Integración de Gamificación con Físicas y Sistema de Recompensas Desacoplado (Laboratorio 5)

* **Estado:** Aprobado
* **Fecha:** 2026-11-02
* **Autor:** July Tatiana Ariza Peña

### Contexto
El sistema utiliza un Event Bus para desacoplar la comunicación entre componentes y un
`GlobalManager` para administrar el estado compartido. El Laboratorio 5 pide incorporar una
mecánica interactiva basada en entrada del usuario y físicas 2D que genere recompensas
(cupones) para el proceso de compra, sin crear dependencias directas entre el minijuego y la
tienda. En el proyecto ya existía "Enfoque Rush" (dibujado con `_draw()`), que no ejercitaba
los cuerpos físicos de Godot.

### Decisión
* Se crea el minijuego **Atrapa la Energía** en `src/scenes/gamification/catch_energy/`:
  * `Player` es un `CharacterBody2D` que se mueve con `Input.get_axis("move_left", "move_right")`
    y `move_and_slide()`; recolecta con un `Area2D` (`AreaRecolect`) independiente de su colisión.
  * Los recursos que caen son `RigidBody2D` (`falling_item.tscn`) con `PhysicsMaterial` de rebote,
    `contact_monitor` y grupo `collectable`; se destruyen al tocar el suelo (grupo `floor`).
  * El suelo y el embudo son `StaticBody2D`.
  * Los `Spawner` (Node2D + Timer, grupo `spawner`) separan *cuándo* generar (Timer) de *si* se
    puede generar (`max_active_items`); algunos lanzan en parábola.
  * El HUD y el panel de resultado viven en un `CanvasLayer`.
* El minijuego publica el cupón con `EventBus.coupon_obtained`. `GlobalManager` lo agrega, lo
  guarda y la factura consulta `get_best_coupon(subtotal)`.
* Reto 1: el límite de **3 intentos por sesión** vive en `GlobalManager` (`intentos_restantes`,
  `registrar_intento`). Ni la factura ni la tienda conocen esa regla.
* `GlobalManager.crear_cupon()` da el mismo formato a los cupones de las tres fuentes.

### Consecuencias
* **Positivas:**
  * El minijuego puede reemplazarse (Reto 2: por una ruleta, por ejemplo) sin tocar la compra:
    basta con emitir `coupon_obtained` con el mismo diccionario.
  * Se agregó un nuevo tipo de cupón (Reto 3) sin modificar la interfaz: la regla del mejor
    cupón válido sigue en `get_best_coupon()`.
  * La dificultad se ajusta desde el Inspector (`@export`) sin modificar código.
* **Negativas / Costos:**
  * Seguir el flujo de una recompensa exige recorrer varios componentes.
  * `GlobalManager` asume la responsabilidad adicional de los intentos de la sesión.
