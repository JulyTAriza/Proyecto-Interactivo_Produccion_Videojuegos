# Guiones de los videos demostrativos (5–7 min cada uno)

Los videos los graba y narra la autora. Cada guion indica qué mostrar y qué explicar, en orden.

## Laboratorio 8 — Interfaz, UX y accesibilidad
| Min | Mostrar | Explicar |
|---|---|---|
| 0:00 | Menú en la versión Web | Objetivo del sprint: pasar de "funciona" a "se entiende y se usa bien" |
| 0:45 | `src/assets/ui/ui_theme.tres` en el editor (Button → Styles) | Un Theme centralizado; 4 estados con StyleBoxFlat + Focus; asignado al nodo raíz de cada escena |
| 2:00 | Pasar el mouse y tabular por el menú | Hover, Pressed, Disabled ("Ir a la factura" deshabilitado) y anillo de foco |
| 2:45 | `menu_panel.tscn` → nodo Fondo | TextureRect: Ignore Size, Keep Aspect Centered, Z Index -1, Mouse Filter Ignore (si no, bloquea los clics) |
| 3:30 | Comprar un plan → PurchaseSuccessPopup | Feedback de acción crítica; X para cerrar, Continuar para volver |
| 4:30 | `doc/ACCESIBILIDAD.md` + `tools/contrast_check.py` | Mejoras elegidas: contraste AA (12/12 pares), fuente legible, teclado, independencia del color (formas del minijuego) y el problema que resuelve cada una |
| 6:00 | USER_FEEDBACK.md | Qué observó la prueba con usuario real y qué se cambió |

## Laboratorio 9 — Resources y UI dinámica
| Min | Mostrar | Explicar |
|---|---|---|
| 0:00 | `wellness_item_data.gd` | `class_name`, `@export` (id, nombre, textura, precio, alivio) |
| 1:00 | `src/data/items/te.tres` en el Inspector y `wellness_catalog.tres` | Catálogo `.tres` y `preload` en GlobalManager |
| 2:00 | `buy_panel_interactive.gd::_poblar_catalogo()` | Recorre `GlobalManager.wellness_items`, crea tarjetas y conecta `pressed.bind()` |
| 3:00 | Ejecutar: elegir bebida/snack/actividad | EventBus `kit_item_selected` → GlobalManager → `kit_changed`; Tweens (pulsación, rebote, conteo del subtotal) |
| 4:30 | Duplicar un `.tres` (p. ej. "Agua con limón") y añadirlo al catálogo | La UI lo muestra sin cambiar código |
| 5:30 | Factura interactiva con cupón | Líneas generadas desde recursos, mejor cupón, consumo persistente |

## Laboratorio 10 — Depuración y QA
| Min | Mostrar | Explicar |
|---|---|---|
| 0:00 | Breakpoint en `global_manager.gd:312`, F6 sobre `tools/debug_session.tscn` | Pila de llamadas, variables (`subtotal`, `cupon`, `mejor`), F10/F11/F12 |
| 1:30 | Breakpoint en la línea 372 | Ver `2000.0` en `datos`: origen de los Issues #2 y #5 |
| 2:30 | Panel GdUnit4 → ejecutar `res://tests` | 29 pruebas en verde; recorrer `test_global_manager.gd` (3 de la guía + límites) |
| 4:00 | `test_focus_rush_scene.gd` | Prueba de escena que detectó el Issue #4 (mostrar el fallo con la línea de la corrección comentada, y el verde después) |
| 5:00 | GitHub → Issues cerrados y Release `v0.9.0-beta` | Etiquetas, pasos, solución y trazabilidad |
| 6:00 | TEST_REPORT.md | UNI-01, INT-01, SIS-01 y reto autónomo |
