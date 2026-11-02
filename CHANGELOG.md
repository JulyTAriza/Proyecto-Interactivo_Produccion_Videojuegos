# CHANGELOG

Todas las novedades notables de este proyecto se documentan en este
archivo. El formato está inspirado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [1.5.0] - 2026-11-02 — Laboratorio 10: QA · publicada como Release `v0.9.0-beta`

### Added
- GdUnit4 6.2.3 (`addons/gdUnit4`) y 5 suites en `tests/` (29 casos).
- `registro_depuracion.md`, `TEST_REPORT.md`, `doc/qa/ISSUES.md`, evidencias en `doc/qa/evidencias/`.
- `tools/debug_session.tscn`, `tools/create_github_issues.sh`, `tools/publicar_github.sh`.

### Fixed
- #4 Mensaje incorrecto al abandonar una partida desde la pausa.
- #5 Montos flotantes en las compras persistidas.

## [1.4.0] - 2026-11-01 — Laboratorio 9: datos con Resources y UI dinámica

### Added
- `WellnessItemData`, `WellnessDatabase`, `src/data/items/*.tres`, `wellness_catalog.tres`.
- `buy_panel_interactive` (UI auto-poblada), `KitComposition`, `purchase_invoice_interactive`.
- Señales `kit_item_selected`, `kit_slot_cleared`, `kit_changed`, `kit_requested`.
- `ADR-006.md`; botón "Arma tu Kit Anti-Fatiga" en el menú.

## [1.3.0] - 2026-10-29 — Laboratorio 8: UI/UX y accesibilidad

### Added
- `src/assets/ui/ui_theme.tres` (Button Normal/Hover/Pressed/Disabled/Focus, paneles, variaciones).
- Fuente Atkinson Hyperlegible, iconos SVG y fondo del menú.
- `PurchaseSuccessPopup` en la factura; botón "Quitar plan" en la tienda.
- `ButtonNav.grab_initial_focus`; `focus_neighbor` en el menú.
- `USER_FEEDBACK.md`, `BACKLOG.md`, `doc/ACCESIBILIDAD.md`, `tools/contrast_check.py`.

## [1.2.0] - 2026-10-22 — Laboratorio 7: Vertical Slice y publicación Web

### Added
- Minijuego **Enfoque Rush** (`src/scenes/minigame/`) con FSM, dificultad
  progresiva, pausa, victoria/derrota y cupones según desempeño.
- Cupones persistentes en `GlobalManager` (`user://save_data.json`):
  `save_coupons()`, `load_coupons()`, `add_coupon()`, `remove_coupon()`,
  `get_best_coupon()`, `apply_coupon()`, `register_purchase()`.
- Tienda de Bienestar (`buy_panel`), factura (`purchase_invoice`) y
  pantalla de cupón (`coupon_event`).
- Acciones de entrada `move_left`, `move_right`, `pause`.
- Preset de exportación Web y guía `doc/PUBLICACION_ITCH.md`.
- Prueba de sistema automatizada `tools/system_flow_runner.tscn` y
  `tools/run_system_test.sh`.

### Changed
- Menú reorganizado por secciones; transición de fundido en `MainApp`;
  volver al menú reinicia `navigation_history`.

### Fixed
- Emoji que en la versión Web se veían como cuadros vacíos.

## [1.1.0] - 2026-09-11 — Persistencia en disco y fix de layout (mejora adicional)

> Esta versión va **más allá** del mínimo exigido por la rúbrica del
> Sprint 1 (ver `1.0.0` abajo para el alcance oficial evaluado).

### Added (Añadido)
- Persistencia del estado de la simulación en `user://fatiga_estado.json`,
  restaurado automáticamente al abrir la aplicación.
- Historial de evaluaciones guardado en `user://fatiga_historial.json`,
  con botón "Finalizar y Guardar Evaluación" en `Step1Base`.
- Nueva pantalla `HistoryPanel` (quinta pantalla) para consultar el
  historial persistido, enlazada desde `MenuPanel`.
- Señales `total_requested`, `evaluation_finalized`, `history_requested` y
  `history_updated` en `EventBus`.
- `doc/adr/ADR-004-persistencia-historial.md`.

### Fixed (Corregido)
- Se corrigió la superposición visual de `Label`/`Button` en
  `step_1_base.tscn` (y se robusteció el resto de paneles) migrando de
  offsets fijos en píxeles a `MarginContainer` + `VBoxContainer` /
  `HBoxContainer` + `ScrollContainer`, logrando un layout verdaderamente
  responsivo que se ajusta al contenido real en lugar de coordenadas
  calculadas a mano.

## [1.0.0] - 2026-09-11 — Cierre Sprint 1 (Sprint Review 1)

Entrega integradora que consolida los Laboratorios 1 a 4 en un sistema
navegable, desacoplado y con estado global persistente.

### Added (Añadido)
- `GlobalManager` (Autoload): estado global centralizado de la simulación
  de fatiga cognitiva mediante `Dictionary` (perfil base + síntomas).
- Componente reutilizable `ButtonNav` (`src/components/navigation/`),
  parametrizable desde el Inspector (`target_scene`, `discard_previous`).
- Señales tipadas en `EventBus`: `base_selected`, `item_added`,
  `total_changed`, y ampliación de `navigation_requested` con el
  parámetro `discard_previous`.
- Pila de historial de navegación (`navigation_history`) gestionada por
  `MainApp`, con impresión en consola tras cada transición.
- Nuevos controles en `Step1Base`: selección de perfil base y marcado de
  síntomas, que reemplazan el cuestionario por `HSlider` del Sprint
  anterior.
- `doc/adr/ADR-001-patron-colocacion.md` y
  `doc/adr/ADR-003-global-manager-button-nav.md`.
- Este mismo `CHANGELOG.md`.

### Changed (Modificado)
- `menu_panel`, `config_panel` y `credits_panel` ahora resuelven su
  navegación de forma 100% declarativa mediante instancias de
  `ButtonNav`, en lugar de código de navegación propio.
- `main_app.gd` amplía su responsabilidad de orquestador para incluir la
  gestión de `navigation_history`.
- `doc/adr/0001-uso-de-event-bus.md` renombrado a
  `doc/adr/ADR-002-uso-de-event-bus.md` para unificar la convención de
  nomenclatura de ADRs del proyecto.
- `DEVLOG.md` actualizado con la bitácora completa de los Laboratorios 1
  a 4.

### Removed (Eliminado)
- `config_panel.gd` y `credits_panel.gd`: ya no requieren script propio.
- Señal genérica `EventBus.parameter_changed`, reemplazada por señales
  específicas y tipadas (`base_selected`, `item_added`, `total_changed`).
- Control interactivo de umbral de alerta crítica en `ConfigPanel`
  (temporalmente retirado; ver "Próximos pasos" en `DEVLOG.md`).

### Fixed (Corregido)
- Se elimina la duplicación de la constante `MENU_SCENE_PATH` que existía
  repetida en cuatro scripts distintos.

## [0.2.0] - 2026-09-04 — Transformación de dominio

### Added
- Cuestionario de autoevaluación de 5 preguntas en `Step1Base` (escala
  0-10 por `HSlider`), con cálculo de índice y categoría de alerta.
- Control de umbral de alerta crítica en `ConfigPanel`.

### Changed
- Rebranding completo del proyecto a "Detector de Fatiga Cognitiva".

## [0.1.0] - 2026-09-02 — Navegación desacoplada (Event Bus)

### Added
- `EventBus` (Autoload) con las señales `navigation_requested` y
  `parameter_changed`.
- `MainApp` como orquestador central con liberación segura de escenas
  (`queue_free()`).
- Paneles `ConfigPanel` y `CreditsPanel`.
- `doc/adr/0001-uso-de-event-bus.md` (renombrado en 1.0.0).

### Changed
- Migración a arquitectura de co-localización (`src/core`,
  `src/scenes/*`).

## [0.0.1] - 2026-08-21 — Prototipo inicial

### Added
- Menú principal y pantalla de simulación con navegación acoplada
  (`get_tree().change_scene_to_file()`).
