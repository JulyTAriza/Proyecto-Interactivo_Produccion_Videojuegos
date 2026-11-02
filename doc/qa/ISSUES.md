# Incidencias de QA (fuente para GitHub Issues — Laboratorio 10)

Todas se detectaron durante las pruebas y la depuración de este sprint. Están listas para
publicarse en la pestaña **Issues** con `tools/create_github_issues.sh` (usa `gh`), que además las
cierra con la solución aplicada.

---
## #1 [BUG] Los emoji de títulos y botones se ven como cuadros con código hexadecimal en la versión Web
**Etiquetas:** `bug`, `ui`
**Pasos para reproducir:** 1) Exportar la versión del Lab 6 con el preset Web. 2) Abrirla en Chrome.
3) Observar el título "🧠 Detector de Fatiga Cognitiva" y el botón "📖 Historial".
**Resultado obtenido:** el emoji aparece como una caja con "1F9E0". **Esperado:** un icono legible.
**Causa:** en Web no hay fuentes del sistema como respaldo y la fuente por defecto no trae emoji.
**Solución:** se retiraron los emoji (Lab 7) y se reemplazaron por iconos SVG propios + fuente
Atkinson Hyperlegible en `ui_theme.tres` (Lab 8).
**Evidencia:** `doc/qa/evidencias/issue-01-emoji-web-antes.png` / `issue-01-iconos-web-despues.png`.
**Estado:** Cerrado.

## #2 [BUG] Los cupones recargados desde save_data.json tienen valores flotantes (2000.0)
**Etiquetas:** `bug`, `qa`
**Pasos:** 1) Ganar un cupón. 2) Reiniciar. 3) Breakpoint en `global_manager.gd:372`, `lv`.
**Obtenido:** `"value": 2000.0`. Las igualdades de diccionarios y los formatos `%d` fallan.
**Esperado:** enteros.
**Solución:** `_normalizar_cupon()` convierte `value` y `minimum_purchase` a `int` al cargar.
**Prueba:** `test_save_and_load_round_trip_keeps_int_values`.
**Evidencia:** `doc/qa/evidencias/depuracion-sesion-2-get-best-coupon.txt`. **Estado:** Cerrado.

## #3 [BUG] El indicador de foco de teclado se recorta dentro de las listas con desplazamiento
**Etiquetas:** `bug`, `ui`
**Pasos:** 1) Menú → Tienda de Bienestar con teclado. 2) El primer plan recibe el foco.
**Obtenido:** el borde amarillo superior queda cortado por el `ScrollContainer`.
**Solución:** el `StyleBoxFlat` de foco se dibuja dentro del botón (sin `expand_margin`).
**Evidencia:** `doc/qa/evidencias/issue-03-foco-recortado-antes.png`. **Estado:** Cerrado.

## #4 [BUG] "Abandonar partida" desde la pausa muestra "Perdiste las 3 vidas"
**Etiquetas:** `bug`, `testing`
**Pasos:** 1) Jugar Enfoque Rush. 2) Pausar (Esc). 3) "Abandonar partida".
**Obtenido:** "Perdiste las 3 vidas: los distractores ganaron esta vez." **Esperado:** mensaje de abandono.
**Causa:** el abandono se implementó forzando `lives = 0`.
**Solución:** bandera `abandonada` y mensaje propio en `_enter_derrota()`.
**Prueba:** `tests/test_focus_rush_scene.gd::test_abandon_from_pause_shows_abandon_message` (falló antes
de la corrección y pasa después). **Estado:** Cerrado.

## #5 [BUG] Las compras persistidas conservan montos flotantes y cupones sin normalizar
**Etiquetas:** `bug`, `qa`
**Pasos:** 1) Hacer una compra. 2) Reiniciar. 3) Breakpoint en `load_coupons()`, inspeccionar `datos`.
**Obtenido:** `"subtotal": 25000.0`, `"total": 20000.0` dentro de `purchases`.
**Solución:** `_normalizar_compra()` al cargar.
**Prueba:** `test_load_normalizes_purchase_numbers`.
**Evidencia:** `doc/qa/evidencias/depuracion-sesion-1-hallazgo-floats.txt`. **Estado:** Cerrado.
