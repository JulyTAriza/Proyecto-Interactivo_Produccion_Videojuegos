#!/usr/bin/env bash
# Publica en GitHub Issues las 5 incidencias de doc/qa/ISSUES.md y las cierra con su solución.
# Requisitos: gh CLI autenticado (gh auth login) y ejecutar dentro del repositorio clonado.
set -e
for l in "bug:d73a4a" "testing:0e8a16" "qa:5319e7" "ui:1d76db"; do
  gh label create "${l%%:*}" --color "${l##*:}" --force >/dev/null
done
crear() { # titulo etiquetas cuerpo comentario_cierre
  url=$(gh issue create --title "$1" --label "$2" --body "$3")
  echo "Creado: $url"
  gh issue close "$url" --comment "$4"
}
crear "[BUG] Los emoji se ven como cuadros con código hexadecimal en la versión Web" "bug,ui" \
"**Pasos:** exportar a Web la versión del Lab 6 y abrir el menú.
**Obtenido:** el título muestra una caja con '1F9E0' en lugar del emoji.
**Esperado:** icono legible. Evidencia: doc/qa/evidencias/issue-01-emoji-web-antes.png" \
"Solucionado: se retiraron los emoji y se usan iconos SVG + Atkinson Hyperlegible (ui_theme.tres). Commits de lab-7 y lab-8."
crear "[BUG] Los cupones recargados desde save_data.json tienen valores flotantes (2000.0)" "bug,qa" \
"**Pasos:** ganar cupón, reiniciar, breakpoint en global_manager.gd:372 y ejecutar lv.
**Obtenido:** value 2000.0. Fallan las igualdades y los formatos %d." \
"Solucionado con _normalizar_cupon(). Prueba de regresión: test_save_and_load_round_trip_keeps_int_values."
crear "[BUG] El indicador de foco se recorta dentro de las listas con desplazamiento" "bug,ui" \
"**Pasos:** abrir la Tienda con teclado. **Obtenido:** el borde superior de foco queda cortado por el ScrollContainer." \
"Solucionado: el StyleBoxFlat de foco ya no usa expand_margin."
crear "[BUG] 'Abandonar partida' desde la pausa muestra 'Perdiste las 3 vidas'" "bug,testing" \
"**Pasos:** jugar, pausar con Esc y elegir 'Abandonar partida'. **Obtenido:** mensaje de derrota por vidas." \
"Solucionado con la bandera 'abandonada'. Prueba: test_focus_rush_scene.gd::test_abandon_from_pause_shows_abandon_message."
crear "[BUG] Las compras persistidas conservan montos flotantes" "bug,qa" \
"**Pasos:** comprar, reiniciar e inspeccionar 'datos' en load_coupons(). **Obtenido:** subtotal 25000.0 en purchases." \
"Solucionado con _normalizar_compra(). Prueba: test_load_normalizes_purchase_numbers."
