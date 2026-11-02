# TEST_REPORT — Detector de Fatiga Cognitiva (Versión Beta v0.9.0-beta)

**Fecha de ejecución:** 2026-11-02 · **Motor:** Godot 4.7.1 · **Framework:** GdUnit4 6.2.3

## Resumen
| Nivel | Casos | Resultado |
|---|---|---|
| Unitarias (GdUnit4) | 23 | 23 PASA |
| Integración (GdUnit4, Autoloads reales y `scene_runner`) | 6 | 6 PASA |
| Sistema (proyecto completo, 6 ejecuciones del proceso) | 1 escenario (SIS-01) | PASA |
| **Total automatizado GdUnit4 (Beta)** | **29** | **29 PASA, 0 fallas** |
| Entrega final: minijuegos de los Labs 5 y 6 (`test_catch_energy_scene.gd`, `test_cup_fsm.gd`) | 9 | 9 PASA |
| **Total automatizado en la entrega final** | **38** | **38 PASA, 0 fallas** |

Comandos:
```bash
export GODOT_BIN=/ruta/a/godot
addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests   # pruebas GdUnit4
tools/run_system_test.sh                                                    # prueba de sistema SIS-01
```
Evidencias: `doc/qa/evidencias/gdunit4-resultado.txt`, `doc/qa/evidencias/sis-01-resultado.txt`.

## Casos documentados (pirámide de pruebas)

### UNI-01 — Selección del mejor cupón (Unitaria)
| Campo | Detalle |
|---|---|
| Objetivo | Verificar aisladamente que `GlobalManager.get_best_coupon(subtotal)` devuelve el cupón de mayor descuento que cumple la compra mínima |
| Condiciones iniciales | Instancia nueva de `global_manager.gd` sin agregar al árbol (`_ready()` no corre); `coupons` asignado directamente |
| Entradas / Resultado esperado | (a) `[{2000, mín 10000}]`, subtotal 12000 → ese cupón · (b) mismo cupón, subtotal 9999 → `{}` · (c) `[{1000, mín 5000}, {3000, mín 10000}]`, subtotal 12000 → `{3000, mín 10000}` · (d) límite: subtotal 10000 = mínimo → aplica · (e) `[{5000, mín 20000}, {2000, mín 10000}]`, subtotal 15000 → $2.000 |
| Implementación | `tests/test_global_manager.gd` (`test_returns_coupon_when_subtotal_is_sufficient`, `test_returns_empty_when_no_coupon_valid`, `test_selects_highest_value_coupon`, `test_coupon_applies_when_subtotal_equals_minimum`, `test_ignores_higher_coupon_that_is_not_reachable`) |
| Resultado obtenido | PASA |

### INT-01 — Registro de cupón vía EventBus (Integración)
| Campo | Detalle |
|---|---|
| Objetivo | Comprobar que emitir `EventBus.coupon_obtained` persiste el cupón en `GlobalManager`, lo escribe en disco y notifica `coupons_changed` |
| Condiciones iniciales | Autoloads reales en el árbol; `GlobalManager.save_path` redirigido a `user://test_integration_save_data.json`; colección vacía (se restaura al terminar) |
| Entrada | `EventBus.coupon_obtained.emit({"id":"INT-01","value":3000,"minimum_purchase":15000})` |
| Resultado esperado | `GlobalManager.coupons.size() == 1`, id `INT-01`, el archivo contiene 1 cupón y `coupons_changed` se emitió una vez con tamaño 1 |
| Implementación | `tests/test_coupon_event_bus_integration.gd::test_coupon_obtained_signal_persists_coupon` (+ consumo en compra y kit vía EventBus) |
| Resultado obtenido | PASA |

### SIS-01 — Flujo completo y persistencia (Sistema)
| Campo | Detalle |
|---|---|
| Objetivo | Verificar el ciclo completo: minijuego → emisión de cupón → guardado en `save_data.json` → consumo en compra, a través de reinicios reales de la aplicación |
| Condiciones iniciales | Carpeta de datos del usuario vacía |
| Entradas | `tools/system_flow_runner.tscn` carga `main_app.tscn` y pulsa los mismos botones que un jugador; un bot mueve la lente con las acciones `move_left`/`move_right` |
| Pasos y resultado esperado | 1) Ganar Enfoque Rush y cerrar → 1 cupón en disco. 2) Reabrir → se carga 1 cupón. 3) Ganar otro, comprar el Plan Bienestar Total ($25.000) → se aplica el mejor cupón, aparece `PurchaseSuccessPopup` y "Continuar" vuelve al menú. 4) Reabrir → el cupón consumido no reaparece. 5) Ganar y comprar un Kit Anti-Fatiga (UI auto-poblada) → factura con 3 líneas y cupón aplicado. 6) Reabrir → colección consistente |
| Resultado obtenido | PASA (escritorio). En Web (Chromium + IndexedDB) los pasos 1–4 también PASAN con la misma lógica |

## Reto autónomo — funciones propias probadas
| Suite | Función real | Casos normales | Casos límite / negativos |
|---|---|---|---|
| `tests/test_kit_subtotal.gd` | `GlobalManager.calculate_kit_subtotal()` / `calculate_kit_relief()` (Lab 9) | kit completo = suma de `price` de los recursos | kit vacío = 0; ids inexistentes no suman; kit más barato ($14.500) no alcanza cupón de mín. $15.000 |
| `tests/test_focus_rush_rules.gd` | `FocusRushRules` (FSM, combos, estrellas, cupón) | transiciones válidas; cupón de 3 estrellas | transiciones prohibidas (ganar sin jugar, doble victoria); límites de combo 4/5/9/10; 15 s exactos para 2 estrellas |
| `tests/test_focus_rush_scene.gd` | `focus_rush.tscn` con `scene_runner` | meta alcanzada → VICTORIA + 1 cupón | tiempo agotado → DERROTA sin cupón; abandonar desde pausa (Issue #4) |

## Defectos encontrados
Ver `doc/qa/ISSUES.md` (5 incidencias, todas corregidas y con prueba o evidencia).
