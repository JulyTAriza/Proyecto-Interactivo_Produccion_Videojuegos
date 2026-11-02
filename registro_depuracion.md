# Registro de depuración — Laboratorio 10

**Herramienta:** depurador integrado de Godot 4.7.1 (mismo motor que el panel *Depurador* del
editor, usado aquí en su modo de línea de comandos `-d --breakpoints` para dejar la sesión
transcrita). Comandos usados: `bt` (pila de llamadas / Stack Trace), `lv` (variables locales),
`p <expr>` (evaluar expresión), `n` (Step Over, F10 en el editor), `s` (Step Into, F11) y `c`
(Continue, F12). En el editor se reproduce igual: clic en el margen de la línea, **F6** para ejecutar
la escena y los botones Step Into / Step Over / Continue del panel Depurador.

**Función clave depurada:** `GlobalManager.get_best_coupon(subtotal)` y la carga
`GlobalManager.load_coupons()`.

**Escena de apoyo:** `res://tools/debug_session.tscn` — escribe en un archivo temporal tres cupones
(D1 $2.000 / mín. $10.000, D2 $3.000 / mín. $15.000, D3 $5.000 / mín. $20.000), fuerza
`load_coupons()` y consulta `get_best_coupon(15000)` (caso límite: el subtotal es **igual** al
mínimo de D2).

```bash
godot --path . -d \
  --breakpoints res://src/core/global_manager.gd:372,res://src/core/global_manager.gd:312 \
  res://tools/debug_session.tscn
```

## Breakpoint 1 — `global_manager.gd:372` (justo después de `JSON.parse_string`)
- **Stack Trace (`bt`):** `Frame 0 load_coupons (global_manager.gd:372)` ← `Frame 1 _ready (debug_session.gd:18)`.
- **Variables (`lv`):** `contenido` contiene `"value":2000`, pero `datos` muestra
  `"value": 2000.0`, `"minimum_purchase": 10000.0`. `p datos["coupons"][0]["value"]` → `2000.0`.
- **Hallazgo:** el parser JSON de Godot convierte todo número a `float`. Confirma por qué el
  proyecto necesita `_normalizar_cupon()` (Issue #2) antes de comparar o formatear con `%d`.

## Breakpoint 2 — `global_manager.gd:312` (`if subtotal < int(cupon.get("minimum_purchase", 0))`)
Se recorrieron las tres iteraciones con `n` (Step Over):

| Iteración | `cupon` | `mejor` antes | Flujo observado | `mejor` después |
|---|---|---|---|---|
| 1 | D1 ($2.000 / mín. $10.000) | `{}` | 312 → 314 → 315 (aplica) | D1 |
| 2 | D2 ($3.000 / mín. $15.000) | D1 | 312 → 314 → 315 (aplica: 15000 **no** es < 15000) | D2 |
| 3 | D3 ($5.000 / mín. $20.000) | D2 | 312 → **313 `continue`** (no alcanza el mínimo) | D2 |

Resultado impreso: `DEBUG> mejor cupón para $15.000 -> ENFOQUE-3000`.

- **Qué se descubrió sobre el flujo:** las variables ya llegan como `int` a `get_best_coupon`
  (la normalización ocurre al cargar), el límite exacto se acepta (`<` estricto en la condición de
  descarte) y un cupón de mayor valor pero inalcanzable se descarta en la línea 313 sin tocar
  `mejor`. Estos tres hechos se convirtieron en pruebas GdUnit4
  (`test_coupon_applies_when_subtotal_equals_minimum`, `test_ignores_higher_coupon_that_is_not_reachable`).

## Sesión previa — datos reales de `user://save_data.json`
En la primera sesión el breakpoint 1 se disparó también desde el `_ready()` del Autoload con el
archivo real del usuario. En `lv` se vio que el arreglo **`purchases`** conservaba montos flotantes
(`"subtotal": 25000.0`, `"total": 20000.0`) y cupones internos sin normalizar.
- **Hallazgo nuevo (Issue #5):** `load_coupons()` solo normalizaba `coupons`. Se agregó
  `_normalizar_compra()` y la prueba de regresión `test_load_normalizes_purchase_numbers`.

## Cómo ayudó la herramienta
Ver los valores **dentro** de la ejecución (`2000.0` frente a `2000`) explicó un defecto que con
`print()` pasa desapercibido, porque `print` muestra ambos casi igual dentro de un diccionario. La
pila de llamadas confirmó que `load_coupons()` se ejecuta tanto desde el Autoload como bajo demanda,
y el paso a paso permitió verificar la regla de compra mínima en el caso límite exacto.

Transcripciones completas: `doc/qa/evidencias/depuracion-sesion-1-hallazgo-floats.txt` y
`doc/qa/evidencias/depuracion-sesion-2-get-best-coupon.txt`.
