# USER_FEEDBACK — Pruebas de usabilidad

Proyecto: **Detector de Fatiga Cognitiva** (versión Web y escritorio).

## Evaluación de Usabilidad 1 (usuario real)

> **Esta tabla la completa la autora después de la sesión real con una persona externa (5–10 min).**
> El protocolo de abajo indica exactamente qué pedirle y qué observar. No se debe explicar el
> funcionamiento antes de empezar.

| Campo | Detalle de la Evaluación |
|---|---|
| Evaluación | Evaluación de Usabilidad 1 |
| Fecha | __/__/2026 |
| Perfil del evaluador | _(p. ej. estudiante universitario de otra carrera, sin experiencia en el juego)_ |
| Tareas realizadas | Navegación por el menú, partida completa de Enfoque Rush, obtención de cupón, compra de un plan con el cupón y confirmación |
| Aspectos comprendidos | _(qué hizo sin dudar)_ |
| Dificultades encontradas | _(dónde dudó, qué intentó presionar, qué instrucción pidió)_ |
| Sugerencias recibidas | _(lo que la persona propuso con sus palabras)_ |
| Mejoras a implementar | _(cambios concretos que se derivan; pasarlos a BACKLOG.md)_ |

### Protocolo de la sesión
1. Abrir la versión Web (URL de itch.io) en el computador del evaluador.
2. Consigna única: *"Gana un cupón en el minijuego y úsalo para comprar un plan en la tienda.
   Piensa en voz alta mientras lo haces."*
3. Cronometrar y anotar sin intervenir:
   - ¿Encuentra el minijuego desde el menú sin ayuda?
   - ¿Lee las instrucciones del overlay o empieza de inmediato?
   - ¿Distingue idea / distractor / pausa por la forma o solo por el color?
   - ¿Usa teclado o mouse para mover la lente?
   - ¿Entiende por qué un cupón "no aplica" (compra mínima)?
   - ¿Reconoce que la compra terminó (PurchaseSuccessPopup)?
4. Al final, dos preguntas: *¿Qué fue lo más confuso?* y *¿Qué cambiarías primero?*

## Evaluación heurística previa (realizada por la desarrolladora)

Antes de la prueba con usuario real se recorrió todo el flujo en la versión Web (Chromium, 1152×648)
aplicando las heurísticas de Nielsen. **No sustituye la prueba con usuario real**; sirvió para
preparar la versión que se le entrega al evaluador.

| Hallazgo | Heurística | Cambio aplicado (Lab 8) |
|---|---|---|
| Los emoji de títulos y botones se veían como cuadros vacíos en Web | Consistencia / estándares | Se reemplazaron por iconos SVG propios (`src/assets/icons/`) |
| Al confirmar la compra la pantalla no cambiaba: no era claro si se había pagado | Visibilidad del estado del sistema | `PurchaseSuccessPopup` con título, monto pagado, ahorro y botón Continuar |
| Los botones no mostraban cambio al pasar el mouse ni al enfocarlos con teclado | Visibilidad del estado | `ui_theme.tres` con estilos Normal / Hover / Pressed / Disabled y anillo de foco amarillo |
| El plan elegido solo se distinguía por el color | Reconocer antes que recordar / accesibilidad | Texto explícito "[ELEGIDO]" en el botón del plan |
| Sin forma de deshacer la selección de plan | Control y libertad del usuario | Botón "Quitar plan" (icono de papelera) |
| El anillo de foco se recortaba en listas con desplazamiento | Visibilidad | Se dibuja dentro del botón (sin `expand_margin`) |
| Textos secundarios de 13 px | Legibilidad | Base de 18 px, secundarios 16–17 px y títulos 32 px con Atkinson Hyperlegible |
