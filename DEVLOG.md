# DEVLOG — Bitácora de Desarrollo

## [2026-08-21] - Laboratorios 0 y 1: Configuración inicial e interacción local (acoplada)

**Autor:** July Tatiana Ariza

### Resumen
Se configuró el entorno de desarrollo con Godot Engine 4.7.1 (renderizador
Compatibility) y se estructuró el repositorio bajo la convención snake_case
dentro de la carpeta `src/`.

### Cambios realizados
- Creación de `main.tscn`: menú de inicio con `VBoxContainer` y botones
  `BtnSimular` / `BtnSalir`.
- Creación de `main_level_1.tscn`: pantalla de simulación con `GridContainer`
  y botones de selección de ingredientes.
- Implementación de `main.gd` y `main_level_1.gd` con tipado estático estricto,
  captura de nodos con `@onready`, y conexión de señales por código.
- Uso de `.bind()` para parametrizar dinámicamente el callback
  `_on_ingrediente_selected(nombre: String, costo: int)`.
- Configuración de navegación entre escenas mediante el nodo `SceneChanger`.
- Personalización de nombre, descripción e ícono del proyecto.

### Problemas encontrados y solución
- El script `main_level_1.gd` no quedó adjuntado al nodo raíz tras crearlo,
  por lo que los botones de ingredientes no reaccionaban. Se resolvió
  adjuntando el script existente al nodo `MainLevel1`.
- El botón `BtnVolver` quedó con dos conexiones de señal simultáneas
  (una hacia `SceneChanger` y otra dentro de `main_level_1.gd`), causando
  un error de referencia nula tras el cambio de escena. Se eliminó la
  conexión redundante dentro de `main_level_1.gd`.

### Próximos pasos
- Refactorizar la navegación para centralizarla completamente en `SceneChanger`.
- Preparar la grabación del video de sustentación.

## [2026-09-02] - Laboratorios 2 y 3: Co-localización y navegación desacoplada (Event Bus)

**Autor:** July Tatiana Ariza

### Resumen
Se refactorizó por completo la arquitectura plana del Laboratorio 1 hacia
un modelo modular con co-localización de escenas y scripts. Se eliminó la
dependencia directa a `get_tree().change_scene_to_file()` y se reemplazó
por un `EventBus` global (Autoload) que centraliza la comunicación entre
pantallas mediante el patrón Observer.

### Cambios realizados
- Creación de `src/core/event_bus.gd` registrado como Autoload `EventBus`,
  con las señales tipadas `navigation_requested` y `parameter_changed`.
- Creación de `src/core/main_app.gd` / `main_app.tscn` como orquestador
  central: se suscribe al bus, libera con `queue_free()` la escena previa
  y limpia la referencia (`current_scene = null`) antes de instanciar la
  siguiente, previniendo fugas de memoria.
- Reubicación y renombramiento de `main.tscn`/`main.gd` a
  `src/scenes/menu/menu_panel.tscn` / `.gd`, ahora con botones adicionales
  de Configuración y Créditos.
- Reubicación de `main_level_1.tscn`/`main_level_1.gd` a
  `src/scenes/simulation/step_1_base.tscn` / `.gd`.
- Creación de dos paneles nuevos: `src/scenes/config/config_panel.tscn` y
  `src/scenes/credits/credits_panel.tscn`, ambos co-localizados con su
  script y navegando exclusivamente vía `EventBus`.
- Eliminación del script huérfano `change_scene.gd` y de la carpeta vacía
  `src/scripts/`.
- Actualización de `project.godot`: nombre del proyecto a "Laboratorio 2",
  escena principal `src/core/main_app.tscn` y registro del Autoload.
- Redacción del ADR `doc/adr/0001-uso-de-event-bus.md` justificando la
  decisión arquitectónica.

### Problemas encontrados y solución
- Al desacoplar la navegación, inicialmente cada panel intentaba cargar
  directamente la siguiente escena, replicando el problema del Lab 1. Se
  corrigió delegando esa responsabilidad exclusivamente a `MainApp`,
  manteniendo a los paneles ciegos entre sí.
- Fue necesario decidir cómo tipar la señal `parameter_changed` dado que
  el valor puede ser de distinta naturaleza según el parámetro; se usó
  `Variant` de forma explícita para mantener tipado estricto sin perder
  flexibilidad.

### Próximos pasos
- Persistir el estado de selección de ingredientes entre paneles usando
  un recurso o Autoload de estado compartido.
- Añadir transiciones visuales (fade/tween) al cambiar de escena en
  `MainApp`.

## [2026-09-04] - Laboratorio 3 (continuación): Transformación de dominio a Detector de Fatiga Cognitiva

**Autor:** July Tatiana Ariza

### Resumen
Manteniendo intacta la arquitectura de navegación desacoplada (EventBus +
MainApp) del refactor anterior, se reemplazó el contenido de cada panel
para convertir el proyecto en una aplicación real: un test breve de
autoevaluación psicológica de fatiga cognitiva.

### Cambios realizados
- `step_1_base.gd`/`.tscn`: se reemplazó el selector de ingredientes por
  un cuestionario de 5 preguntas navegables (Anterior/Siguiente), cada una
  respondida con un `HSlider` de 0 a 10. Al finalizar, se calcula el
  índice total, el porcentaje y una categoría de alerta (Bajo/Moderado/
  Alto/Crítico), notificada vía `EventBus.parameter_changed`.
- `config_panel.gd`/`.tscn`: ahora permite ajustar el umbral de alerta
  crítica (50%-100%) mediante un `HSlider`, emitido también por el
  EventBus para que otros paneles puedan reaccionar sin acoplarse.
- `menu_panel.tscn`: se agregó título y subtítulo describiendo la app, y
  se renombraron los botones al nuevo dominio ("Iniciar Evaluación").
- `credits_panel.tscn`: se agregó el nombre de la aplicación.
- `project.godot`: nombre y descripción actualizados a "Detector de
  Fatiga Cognitiva".
- `README.md`: descripción del proyecto actualizada.

### Próximos pasos
- Guardar el historial de resultados de evaluaciones anteriores.
- Usar el umbral configurado en `ConfigPanel` para resaltar visualmente
  el resultado cuando se supere (actualmente solo se emite el evento).

## [2026-09-11] - Laboratorio 4 (Sprint Review 1): GlobalManager, ButtonNav y cierre integrador

**Autor:** July Tatiana Ariza

### Resumen
Entrega integradora del Sprint 1 (Laboratorio 4). Se centralizó por
completo el estado de la simulación en un nuevo Autoload
(`GlobalManager`) y se extrajo la navegación repetida en cada panel hacia
un componente reutilizable (`ButtonNav`), configurable 100% desde el
Inspector. `MainApp` ahora también gestiona una pila física de historial
de navegación.

### Cambios realizados
- Creación de `src/core/global_manager.gd`, registrado como Autoload
  `GlobalManager` (cargado después de `EventBus`). Centraliza
  `estado_simulacion: Dictionary` (perfil base + síntomas marcados) y
  recalcula el índice total de fatiga de forma centralizada.
- Actualización de `event_bus.gd`: se reemplazó la señal genérica
  `parameter_changed` por cuatro señales tipadas de forma estricta:
  `navigation_requested(target_scene, discard_previous)`,
  `base_selected(base_name)`, `item_added(item_id)` y
  `total_changed(new_total)`.
- Creación del componente reutilizable
  `src/components/navigation/button_nav.tscn` / `.gd`, con propiedades
  exportadas `target_scene` (`@export_file`) y `discard_previous`
  (`@export`). Se instanció en `menu_panel`, `config_panel`,
  `credits_panel` y `step_1_base`, eliminando toda navegación programada
  a mano en esos cuatro paneles.
- Eliminación completa de `config_panel.gd` y `credits_panel.gd`: ambos
  paneles resuelven su navegación de regreso de forma puramente
  declarativa mediante una instancia de `ButtonNav`.
- Rediseño de `step_1_base.tscn` / `.gd`: los controles pasaron de un
  cuestionario por `HSlider` a botones de "perfil base" (Estudiante /
  Profesional / Deportista) y botones de "síntomas" que emiten
  `base_selected` / `item_added` al `EventBus` mediante `.connect()` y
  `.bind()`. El `Label` de total ya no calcula nada: solo escucha
  `total_changed` de forma pasiva.
- Actualización de `main_app.gd`: se agregó `navigation_history:
  Array[String]`, con `.append()` para navegación hacia adelante y
  `.pop_back()` para regresos (`discard_previous = true`), imprimiendo el
  estado de la pila en consola tras cada navegación.
- Reorganización de la documentación de arquitectura: se renombró el ADR
  original a `ADR-002-uso-de-event-bus.md`, se creó
  `ADR-001-patron-colocacion.md` (documentando retroactivamente la
  decisión del Laboratorio 2) y se redactó
  `ADR-003-global-manager-button-nav.md` para esta entrega.
- Creación de `CHANGELOG.md` con el resumen de la versión 1.0.0 (cierre
  del Sprint 1).

### Problemas encontrados y solución
- Al eliminar `config_panel.gd`, se perdió el control interactivo de
  umbral de alerta agregado en el Laboratorio 3 (un `HSlider` requiere un
  script que reaccione a `value_changed`). Se decidió retirarlo
  temporalmente del panel de Configuración en lugar de dejar un script
  "casi vacío" solo para ese control, ya que el requisito de la rúbrica es
  explícito: Configuración y Créditos no deben tener script propio. Queda
  registrado como trabajo futuro (ver ADR-003).
- El orden de los Autoloads importaba: si `GlobalManager` se registraba
  antes que `EventBus` en `project.godot`, su `_ready()` fallaba al
  intentar conectarse a una señal que aún no existía. Se corrigió
  garantizando que `EventBus` se declare primero en la sección
  `[autoload]`.
- Al migrar `Step1Base` de sliders a botones de síntomas, se evaluó dejar
  que cada botón reflejara visualmente cuántas veces fue presionado; se
  decidió posponerlo para no romper el principio de que la GUI solo
  escucha `total_changed` y no consulta el estado interno de
  `GlobalManager` directamente.

### Próximos pasos
- Reintroducir la configuración de umbral de alerta mediante un nuevo
  Autoload dedicado (`SettingsManager`) que no dependa de un script local
  en `ConfigPanel`.
- Acotar la cantidad máxima de veces que un mismo síntoma puede sumarse
  al total, para reflejar mejor una escala clínica de frecuencia.
- Agregar transición visual (fade/tween) en `MainApp` al cambiar de panel.

## [2026-09-11] - Corrección de layout responsivo + Persistencia (mejora adicional)

**Autor:** July Tatiana Ariza

### Resumen
Dos frentes de trabajo tras revisar el resultado en ejecución: (1) se
corrigió un bug real de maquetación donde el texto se superponía en
`Step1Base` por usar offsets fijos en píxeles, y (2) se agregó
persistencia real en disco (`user://`) para el estado de la simulación y
un historial de evaluaciones guardadas, cerrando una deuda pendiente
anotada desde el Laboratorio 2.

### Cambios realizados
- **Fix de layout**: se reescribieron `menu_panel.tscn`, `step_1_base.tscn`,
  `config_panel.tscn` y `credits_panel.tscn` reemplazando offsets fijos
  por `MarginContainer` + `VBoxContainer`/`HBoxContainer` (y
  `ScrollContainer` en `Step1Base`), para que cada `Label`/`Button` reserve
  automáticamente el espacio que su contenido necesita. Se actualizaron
  las rutas `@onready` en `menu_panel.gd` y `step_1_base.gd` acorde a la
  nueva jerarquía de nodos.
- **Persistencia de estado** (`global_manager.gd`): `estado_simulacion` se
  serializa como JSON en `user://fatiga_estado.json` en cada recálculo, y
  se restaura al iniciar la aplicación. Se agregó la señal
  `EventBus.total_requested` para que `Step1Base` pida el total vigente
  (potencialmente restaurado) en lugar de asumir que siempre arranca en 0.
- **Historial de evaluaciones**: nuevo botón "Finalizar y Guardar
  Evaluación" en `Step1Base` que emite `EventBus.evaluation_finalized`.
  `GlobalManager` guarda el registro en `user://fatiga_historial.json` y
  reinicia el estado para una nueva evaluación.
- **Nueva pantalla `HistoryPanel`**
  (`src/scenes/history/history_panel.tscn` / `.gd`): quinta pantalla,
  adicional a las 4 exigidas por la rúbrica, accesible desde un nuevo
  botón en `MenuPanel`. Renderiza dinámicamente el historial recibido vía
  `EventBus.history_updated`, sin leer `GlobalManager` directamente.
- Documentación: `doc/adr/ADR-004-persistencia-historial.md` (marcado
  explícitamente como mejora fuera del alcance mínimo del Sprint 1).

### Problemas encontrados y solución
- Las señales de Godot no "recuerdan" emisiones pasadas: si `Step1Base` se
  conectaba a `total_changed` después de que `GlobalManager` ya había
  restaurado el estado al arrancar la app, el `Label` mostraba `0` aunque
  hubiera un total persistido. Se resolvió agregando un patrón de
  petición/respuesta explícito (`total_requested` → `total_changed`) en
  vez de depender de una emisión que ya había ocurrido.
- Se consideró que `HistoryPanel` leyera `GlobalManager.historial_evaluaciones`
  directamente al ser un panel de solo lectura, pero se descartó para no
  romper la consistencia arquitectónica del resto del proyecto: se aplicó
  el mismo patrón `*_requested` / `*_updated` ya usado para el total.

### Próximos pasos
- Evaluar guardado diferido (debounce) si en el futuro se agregan más
  campos de estado que se actualicen con alta frecuencia.
- Permitir borrar registros individuales del historial desde la propia
  pantalla `HistoryPanel`.

## [2026-10-15] - Laboratorio 6: Máquina de Estado Finito y Animación Tween

**Autor:** July Tatiana Ariza

### Resumen
Se modeló el flujo real de evaluación de `Step1Base` como una FSM de tres
estados, en vez de dejarlo como una única acción de "guardar" sin
distinción de momentos. Se agregó una animación Tween de confirmación
asociada a la transición hacia el estado final.

### Cambios realizados
- `step_1_base.gd`: nuevo `enum EvaluationState { EN_EVALUACION, GUARDANDO, GUARDADA }`, con `change_state()` como única función que modifica `current_state`, validada contra `_is_transition_allowed()`.
- Los botones de perfil base y de síntomas ahora verifican `current_state == EN_EVALUACION` antes de emitir cualquier señal al EventBus; quedan deshabilitados automáticamente mientras se guarda.
- Nuevos nodos en `step_1_base.tscn`: `LblConfirmacion` (mensaje animado) y `BtnNuevaEvaluacion` (regresa a `EN_EVALUACION`).
- Animación Tween (escala + opacidad, `TRANS_BACK`/`EASE_OUT`) sobre `LblConfirmacion`, disparada al entrar a `GUARDANDO` y que al terminar transiciona automáticamente a `GUARDADA`.
- Diagrama de estados en `doc/diagrams/fsm-evaluacion.md` y justificación en `doc/adr/ADR-005-fsm-flujo-evaluacion.md`.

### Problemas encontrados y solución
- Decidir si el guardado real (`EventBus.evaluation_finalized.emit()`) debía dispararse al *entrar* a `GUARDANDO` o al *terminar* la animación. Se optó por dispararlo al entrar, para que el historial se actualice de inmediato y la animación sea puramente una confirmación visual, no una condición de la que dependa el guardado.
- Evitar que el usuario pudiera presionar "Finalizar" dos veces seguidas antes de que la UI reaccionara: se resolvió deshabilitando los botones como parte de `_enter_guardando()`, antes incluso de iniciar la animación.

### Próximos pasos
- Evaluar una FSM similar para `HistoryPanel` si se agrega edición/borrado de registros individuales.
- Considerar persistir también el estado de la FSM (por si el usuario cierra la app a mitad de la animación de confirmación — caso extremadamente improbable dada la duración de 0.4s, pero documentado como hipótesis).

## [2026-10-22] - Laboratorio 7: Sprint Review 2 — Vertical Slice, Persistencia y Publicación Web

**Autor:** July Tatiana Ariza

### Resumen
El proyecto ya persistía la evaluación y su historial (ADR-004), pero no
tenía los sistemas que pide el Vertical Slice: minijuego, cupones y
compras. Se construyeron adaptados al dominio de fatiga cognitiva y se
integraron al flujo existente sin retirar nada de lo anterior:
**Enfoque Rush** (minijuego de atención), **cupones persistentes** en
`GlobalManager` y una **Tienda de Bienestar** con factura.

### Actividades realizadas
- **Minijuego Enfoque Rush** (`src/scenes/minigame/`): caen ideas
  (círculo amarillo), distractores (rombo rojo) y pausas activas
  (hexágono verde). El jugador mueve la "lente de enfoque" con flechas,
  A/D o el mouse. Meta: 200 puntos en 45 s con 3 vidas; racha x2/x3,
  dificultad progresiva, pausa (Esc/P), cuenta regresiva y pantallas de
  victoria/derrota. FSM de 6 estados (`FocusRushRules.TRANSICIONES`).
  Las reglas puras viven en `focus_rush_rules.gd` para poder probarlas.
- **Cupones persistentes** en `GlobalManager`: `SAVE_PATH =
  "user://save_data.json"`, `save_coupons()` / `load_coupons()` con
  `FileAccess` + `JSON`, carga en `_ready()`, guardado al obtener
  (`EventBus.coupon_obtained`) y actualización al consumir
  (`remove_coupon()`), `get_best_coupon(subtotal)` y `apply_coupon()`.
  El cupón depende del desempeño: 1 estrella $2.000 (mín. $10.000),
  2 estrellas $3.000 (mín. $15.000), 3 estrellas $5.000 (mín. $20.000).
- **Tienda de Bienestar** (`src/scenes/shop/buy_panel.tscn`) con tres
  planes de descanso y **factura** (`purchase_invoice.tscn`) que aplica
  automáticamente el mejor cupón, permite no usarlo y lo consume al
  confirmar.
- **Pantalla de cupón** (`src/scenes/coupon/coupon_event.tscn`): tarjeta
  animada del cupón ganado y lista "Mis cupones".
- **Refinamiento visual**: menú reorganizado en tres secciones
  (Evaluación / Minijuego y tienda / Aplicación); se quitaron los emoji
  de títulos y botones porque en la versión Web se veían como cuadros
  vacíos (la fuente por defecto no los incluye); color de fondo oscuro
  común (`default_clear_color`); transición de fundido entre pantallas;
  foco inicial de teclado en cada pantalla; "Cerrar aplicación" oculto
  en Web (allí `quit()` no hace nada).
- **Navegación**: volver al menú reinicia `navigation_history` para no
  acumular entradas de flujos ya terminados (menú → tienda → factura →
  menú).
- **Exportación Web**: preset "Web" (`export_presets.cfg`), sin hilos,
  sin cabeceras de aislamiento de origen (`ensure_cross_origin_isolation_headers=false`)
  y exportado en modo release (sin depuración) a `build/web/index.html`.
- **Pruebas del flujo completo**: `tools/system_flow_runner.tscn`
  recorre el proyecto real (menú → minijuego jugado por un bot que usa
  las mismas acciones de teclado → victoria → cupón → tienda → factura →
  confirmación). `tools/run_system_test.sh` lo ejecuta en 4 procesos
  distintos para validar el cierre y la reapertura.

### Validación de persistencia
| Prueba | Escritorio (Godot 4.7.1) | Web (Chromium, IndexedDB) |
|---|---|---|
| Ganar cupón, cerrar y reabrir: el cupón sigue disponible | PASA | PASA |
| Consumir el mejor cupón ($5.000 sobre $25.000 → total $20.000), cerrar y reabrir: no reaparece | PASA | PASA |
| `save_data.json` existe en la carpeta de datos del usuario (Proyecto → Abrir carpeta de datos del usuario) | PASA | n/a (IndexedDB) |

### Desafíos encontrados y soluciones
- **JSON devuelve flotantes**: al recargar, `2000` volvía como `2000.0`,
  así que las igualdades entre cupones y el formato `%d` fallaban. Se
  normalizan `value` y `minimum_purchase` a `int` en `_normalizar_cupon()`.
- **Emoji en la versión Web**: se veían como cuadros vacíos. Se
  reemplazaron por texto (y por iconos en el Lab 8).
- **Consumir el cupón correcto**: se identifica cada cupón con un `id`
  único (`CUP-<tiempo>-<aleatorio>`), y `remove_coupon()` busca por id;
  sin id, compara por contenido.
- **Probar un minijuego de 45 s de forma repetible**: se agregó un runner
  con un bot que pulsa `move_left`/`move_right` (`Input.action_press`), y
  en headless se usa `--fixed-fps 60` para que la partida corra rápido.

### URL secreta de la publicación
- itch.io (draft, HTML): _pendiente de pegar tras subir_
  `build/DetectorFatigaCognitiva-web.zip` (ver `doc/PUBLICACION_ITCH.md`).

### Estado final del Vertical Slice
Flujo completo funcional desde `main_app.tscn`: Menú → Enfoque Rush →
Cupón → Tienda → Factura → Confirmación, más la evaluación de fatiga y su
historial de entregas anteriores. Persistencia validada en escritorio y
en navegador.

### Retrospectiva (Sprint 2)
1. **Cambio técnico más importante:** separar las reglas del minijuego
   (`FocusRushRules`) y los cupones (`GlobalManager`) de las escenas: el
   minijuego solo emite `coupon_obtained` y las pantallas solo leen el
   estado, así se integraron cuatro pantallas nuevas sin acoplarlas.
2. **Problema de persistencia:** la conversión int→float de JSON; se
   resolvió normalizando al cargar.
3. **Mejora visual de mayor impacto:** reorganizar el menú por secciones
   y eliminar los emoji que se rompían en Web.
4. **Godot vs. Web:** en Web no hay `quit()`, `user://` vive en IndexedDB
   del navegador, y sin fuentes del sistema los glifos especiales no se
   ven. Además el renderizado por software es más lento, aunque el juego
   usa `delta` y se comporta igual.
5. **Para el siguiente sprint:** Theme centralizado, iconografía,
   accesibilidad y retroalimentación al comprar.

## [2026-10-29] - Laboratorio 8: Diseño de Interfaces y Experiencia de Usuario

**Autor:** July Tatiana Ariza

### Actividades Realizadas
- Se preparó `USER_FEEDBACK.md` con la plantilla y el protocolo de la prueba con usuario real, y se
  registró una evaluación heurística previa cuyos hallazgos ya se corrigieron.
- Se creó e integró `src/assets/ui/ui_theme.tres` con `StyleBoxFlat` para los estados Normal, Hover,
  Pressed y Disabled de `Button` (más Focus), paneles, barra de progreso y variaciones
  `TituloLabel`, `SeccionLabel` y `SecundarioLabel`; se asignó al nodo raíz de `main_app`,
  `menu_panel`, `buy_panel`, `purchase_invoice`, `coupon_event` y del resto de pantallas.
- Se incorporó en el menú un `TextureRect` de fondo (Ignore Size, Keep Aspect Centered, Z Index -1,
  Mouse Filter Ignore) y un set de iconos SVG propios para acciones comunes.
- Se diseñó `PurchaseSuccessPopup` en la factura (título, mensaje con monto y ahorro, botón Continuar
  con `ButtonNav` hacia el menú y X para cerrar).
- Se implementaron 4 mejoras de accesibilidad: contraste AA verificado, Atkinson Hyperlegible con
  tamaños ≥ 16 px, navegación por teclado (`focus_neighbor` + foco inicial) e información
  independiente del color (ver `doc/ACCESIBILIDAD.md`).

### Desafíos y Soluciones
* Desafío: el `TextureRect` de fondo podía bloquear los clics de los botones del menú.
  Solución: Mouse Filter en Ignore y Z Index negativo.
* Desafío: el anillo de foco con `expand_margin` se recortaba dentro de los `ScrollContainer`.
  Solución: el borde de foco se dibuja dentro del botón.
* Desafío: Configuración y Créditos no tienen script, así que no podían dar el foco inicial.
  Solución: nueva propiedad exportada `grab_initial_focus` en `ButtonNav`.

### Estado Final
La interfaz quedó refinada con criterios de UX/UI y accesibilidad hacia la Versión Beta. Flujo
completo verificado de nuevo con `tools/run_system_test.sh` (PASA) y recorrido con teclado en la
versión Web.

### Retrospectiva (Sprint 3 — UI/UX)
- **Cambio que más mejoró la experiencia:** el popup de compra realizada y los estados Hover/Focus:
  ahora cada acción tiene respuesta visible.
- **Dificultad con el Theme:** decidir qué se define en el Theme y qué queda como override local;
  se resolvió con variaciones de tipo para títulos, secciones y textos secundarios.
- **Aporte de la prueba con usuario:** pendiente de la sesión real; la evaluación heurística ya
  detectó que la compra terminaba sin confirmación visible.
- **Por qué esas mejoras de accesibilidad:** el minijuego depende de distinguir estímulos rápidos
  (forma + símbolo, no solo color) y la app se usa con fatiga mental (contraste alto y fuente de
  alta legibilidad reducen el esfuerzo).
- **Qué entendería un usuario nuevo de inmediato:** el menú por secciones y la tienda; lo que más
  claridad requiere es la regla de compra mínima de los cupones.

## [2026-11-01] - Laboratorio 9: Interfaz Dinámica y Representación de Datos mediante Recursos

**Autor:** July Tatiana Ariza

### Actividades Realizadas
- Se creó la clase `WellnessItemData` (`Resource`, `@export` de id, nombre, descripción, categoría,
  textura, precio y alivio) y 9 recursos `.tres` con ilustraciones SVG propias.
- Se creó `WellnessDatabase` y su instancia `wellness_catalog.tres`, precargada en `GlobalManager`
  (`GlobalManager.wellness_items`).
- Nueva pantalla **Arma tu Kit Anti-Fatiga** (`buy_panel_interactive.tscn`): catálogo auto-poblado en
  un `ScrollContainer`, tarjetas creadas por código y conectadas con `bind()`.
- Componente `KitComposition` (bebida, snack, actividad) con secciones generadas por código, botón
  "Quitar" por sección y sección activa seleccionable.
- Señales nuevas `kit_item_selected`, `kit_slot_cleared`, `kit_changed` y `kit_requested`;
  `GlobalManager` recalcula subtotal y alivio a partir de los recursos.
- Tweens: pulsación de la tarjeta, rebote/destello de la sección, conteo del subtotal y
  desplazamiento animado a la categoría.
- `purchase_invoice_interactive.tscn`: líneas generadas desde los recursos, mejor cupón persistente,
  consumo al confirmar y `PurchaseSuccessPopup`.
- `ADR-006.md` documenta la decisión de arquitectura. La prueba de sistema ahora también compra un kit
  (ejecuciones 5 y 6 de `tools/run_system_test.sh`: PASA).

### Desafíos y Soluciones
* Desafío: los `.tres` con arreglos tipados (`Array[WellnessItemData]`) son fáciles de romper a mano.
  Solución: se generaron con `ResourceSaver` (`tools/build_catalog.gd`), igual que al guardarlos desde el Inspector.
* Desafío: el `Button` no calcula su tamaño mínimo a partir de los hijos que contiene.
  Solución: tamaño mínimo explícito en las secciones del kit e iconos limitados con `icon_max_width`.

### Estado Final
El kit se compone desde datos, la UI se genera sola y la compra consume cupones persistentes.

### Retrospectiva
- **Ventaja de separar datos e interfaz:** el mismo recurso alimenta tarjeta, sección del kit, línea
  de factura y cálculo del subtotal sin duplicar información.
- **Por qué generar UI por código:** 9 tarjetas idénticas en estructura se mantienen en una sola
  función; un cambio de diseño se aplica a todas.
- **Crecimiento sin tocar código:** un nuevo `.tres` en el catálogo aparece en la tienda y la factura.
- **Aporte del EventBus:** la factura del kit usa la misma API de cupones (`get_best_coupon`,
  `register_purchase`) que la tienda de planes: el sistema de cupones no tuvo que cambiar.

## [2026-11-02] - Laboratorio 10: Depuración, Pruebas Unitarias y Aseguramiento de Calidad

**Autor:** July Tatiana Ariza

### Actividades Realizadas
- Sesión de depuración con breakpoints en `GlobalManager.load_coupons()` (línea 372) y
  `get_best_coupon()` (línea 312): pila de llamadas, variables locales y paso a paso
  (`registro_depuracion.md`).
- Instalación y activación de **GdUnit4 6.2.3** (`addons/gdUnit4`, habilitado en `project.godot`).
- `tests/test_global_manager.gd` (`GdUnitTestSuite`) con los 3 casos de la guía (`assert_object`,
  `assert_bool`) y 8 casos límite adicionales (`assert_int`).
- Reto autónomo: `test_kit_subtotal.gd` (subtotal del kit desde Resources), `test_focus_rush_rules.gd`
  (FSM, combos, estrellas, cupón) y `test_focus_rush_scene.gd` (escena real con `scene_runner`).
- Integración INT-01: `test_coupon_event_bus_integration.gd` con los Autoloads reales.
- `TEST_REPORT.md` con UNI-01, INT-01 y SIS-01; resultado: **29/29 PASA** y SIS-01 PASA.
- 5 incidencias documentadas en `doc/qa/ISSUES.md` y script `tools/create_github_issues.sh` para
  publicarlas y cerrarlas en GitHub Issues con su solución.
- Preparación de la Release `v0.9.0-beta` (`doc/RELEASE_v0.9.0-beta.md`, `tools/publicar_github.sh`).

### Desafíos y Soluciones
* Desafío: GdUnit4 se niega a correr en modo headless. Solución: `--ignoreHeadlessMode`; las pruebas
  no dependen de eventos de entrada reales (la escena se maneja por su API/FSM).
* Desafío: las pruebas de integración podían borrar los cupones reales. Solución: `save_path` es una
  variable que las pruebas redirigen a un archivo temporal y restauran en `after_test()`.
* Desafío: un defecto (abandono con mensaje de "sin vidas") no se veía jugando normalmente.
  Solución: se escribió primero la prueba de escena, falló, se corrigió y pasó.

### Estado Final
Versión Beta estable: 29 pruebas automatizadas en verde, flujo completo validado en escritorio y Web,
5 defectos corregidos con trazabilidad.

### Retrospectiva
1. **Error más difícil de detectar con breakpoints:** los números flotantes de JSON en `purchases`;
   con `print()` pasa inadvertido y solo al inspeccionar `datos` en `lv` se vio `25000.0`.
2. **Ventaja de GdUnit4 frente a probar a mano:** 29 casos en ~0.3 s cada vez que se cambia el código;
   probar a mano el caso "subtotal igual al mínimo" o "abandonar desde pausa" exige preparar el estado
   cada vez y es fácil olvidarlo.
3. **Unitaria vs. integración vía EventBus:** la unitaria instancia `GlobalManager` aislado y llama sus
   métodos; la de integración emite la señal real y verifica que el Autoload reaccione, persista y
   notifique a otros suscriptores.
4. **Aporte de GitHub Issues:** cada defecto quedó con pasos, causa, solución y prueba de regresión, lo
   que permitió cerrar la Beta sabiendo qué se corrigió y qué queda pendiente.

## [2026-11-02] - Laboratorios 5 y 6 (completados en la entrega final): físicas, FSM por instancia y Tweens

### Actividades Realizadas
* Revisión de cobertura guía por guía antes de la entrega final: los conceptos de físicas 2D del
  Laboratorio 5 y la FSM por objeto con arrastre del Laboratorio 6 no estaban implementados como
  pedían las guías (Enfoque Rush se dibuja con `_draw()` y la FSM existente era la de la evaluación).
* **Lab 5 — Atrapa la Energía** (`src/scenes/gamification/catch_energy/`): `CharacterBody2D` con
  acciones del Input Map, `RigidBody2D` con `PhysicsMaterial` y `contact_monitor`, `StaticBody2D`
  (suelo y embudo), `Area2D` de recolección, `Spawner` con `Timer` y grupos, HUD en `CanvasLayer`,
  cupón por `EventBus.coupon_obtained` y límite de 3 intentos por sesión (reto 1).
* **Lab 6 — Infusión Rush** (`src/scenes/gamification/infusion_rush/`): FSM por taza
  (`FRIA → DISPONIBLE → ARRASTRANDO → INFUSIONANDO → LISTA → ENTREGADA`), acción `interact`,
  estaciones y zona de entrega en grupos, temporizador general, panel de resultado, Tween por
  transición y cupón al ganar.
* Nueva pantalla `game_hub.tscn` ("Participa y gana cupones") y botón "Más minijuegos" en el menú.
* `MainApp` con `mouse_filter = IGNORE` y `SceneContainer` con `PASS` para el *picking* de físicas.
* ADR-007, ADR-008 y `docs/adr/adr_001_escenas.md`.
* 9 pruebas nuevas en GdUnit4 (`test_catch_energy_scene.gd`, `test_cup_fsm.gd`).

### Desafíos y Soluciones
* *Desafío:* las tazas no recibían `mouse_entered` dentro de la aplicación.
* *Solución:* el `Control` raíz de `MainApp` consumía el clic; se cambió su `mouse_filter` y se
  verificó con eventos de mouse reales que una taza pasa de `FRIA` a `INFUSIONANDO`.
* *Desafío:* en modo sin pantalla no hay puntero, y la taza en `ARRASTRANDO` sigue al mouse.
* *Solución:* en las pruebas se pausa su `_physics_process` (`bloqueada`) mientras el motor
  actualiza los solapamientos, y luego se llama a `release_cup()`.

### Decisiones de diseño
* Los minijuegos solo emiten `coupon_obtained`; ninguno conoce la tienda (ADR-007).
* Los intentos de la sesión viven en `GlobalManager`; la factura no conoce esa regla.

### Estado Final
Las 10 guías quedan implementadas en la rama `main`; 38 pruebas automatizadas en verde.
