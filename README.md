# Producción de Videojuegos - Sistemas Interactivos 2026
**Universidad Antonio Nariño (UAN)**  
**Facultad de Ingeniería de Sistemas y Computación**  

## 📝 Descripción del Proyecto
Este repositorio aloja **Detector de Fatiga Cognitiva**, una aplicación interactiva de autoevaluación psicológica desarrollada durante el semestre académico 2026-2. El usuario responde un breve cuestionario de varias preguntas (escala 0-10) sobre concentración, cansancio mental y errores por falta de atención; la aplicación calcula un índice total y lo clasifica en un nivel de alerta (Bajo, Moderado, Alto o Crítico). El sistema está configurado bajo buenas prácticas de ingeniería de software en Godot Engine, con navegación completamente desacoplada mediante un Event Bus global.

## 🎮 Cómo se juega (Sprints 2 y 3)
1. **Enfoque Rush** (minijuego): mueve la lente con flechas / A-D / mouse. Atrapa las ideas (círculo
   amarillo), esquiva los distractores (rombo rojo) y recoge pausas activas (hexágono verde). Llega a
   200 puntos en 45 s para ganar un **cupón** (1 a 3 estrellas según tiempo y vidas). Esc o P pausa.
2. **Tienda de Bienestar**: compra un plan de descanso; la factura aplica tu mejor cupón.
3. **Arma tu Kit Anti-Fatiga**: elige bebida, snack y actividad de un catálogo generado desde
   `Resource`; la factura del kit también acepta cupones.
4. Los cupones y las compras se guardan en `user://save_data.json` (IndexedDB en la versión Web).

## 📂 Estructura de Directorios del Repositorio
```
src/
├── core/            event_bus.gd, global_manager.gd (cupones, compras, kit), main_app, format_util.gd
├── data/            wellness_item_data.gd, wellness_database.gd, items/*.tres, wellness_catalog.tres  (Lab 9)
├── scenes/
│   ├── menu/        Menú principal (fondo TextureRect, 3 secciones)
│   ├── simulation/  Evaluación de fatiga (FSM, Lab 6)
│   ├── history/     Historial persistente de evaluaciones
│   ├── minigame/    Enfoque Rush: focus_rush.tscn, focus_play_area.gd, focus_rush_rules.gd  (Lab 7)
│   ├── coupon/      coupon_event.tscn: cupón obtenido / mis cupones  (Lab 7)
│   ├── shop/        buy_panel, purchase_invoice (Lab 7-8) · *_interactive (Lab 9)
│   ├── config/  credits/
├── components/      navigation/button_nav · kit/kit_composition  (Lab 9)
└── assets/          ui/ui_theme.tres (Lab 8), fonts/, icons/, items/
tests/               Suites GdUnit4 (Lab 10)
tools/               Prueba de sistema, sesión de depuración, contraste WCAG, scripts de GitHub
doc/                 ADR-001..005, ACCESIBILIDAD.md, PUBLICACION_ITCH.md, qa/ (issues y evidencias)
```

## 📚 Entregables por laboratorio
| Lab | Rama / etiqueta | Documentos |
|---|---|---|
| 7 Vertical Slice + Web | `lab-7` | DEVLOG, `doc/PUBLICACION_ITCH.md` |
| 8 UI/UX y accesibilidad | `lab-8` · `lab-8-final` | USER_FEEDBACK.md, BACKLOG.md, `doc/ACCESIBILIDAD.md` |
| 9 Resources y UI dinámica | `lab-9` · `lab-9-final` | ADR-006.md |
| 10 Depuración y QA | `lab-10` · `lab-10-final` · `v0.9.0-beta` | registro_depuracion.md, TEST_REPORT.md, `doc/qa/ISSUES.md` |

## 🧪 Pruebas
```bash
export GODOT_BIN=/ruta/a/godot
addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests   # 29 pruebas GdUnit4
tools/run_system_test.sh                                                    # prueba de sistema SIS-01
python3 tools/contrast_check.py                                             # contraste WCAG del Theme
```

## 🧩 Arquitectura de Navegación Desacoplada
La navegación entre pantallas ya **no** usa llamadas directas y acopladas
(`get_tree().change_scene_to_file()`). En su lugar, se implementa un
**Event Bus global (Autoload `EventBus`)** que centraliza la comunicación
mediante el patrón Observer. Cada panel emite `navigation_requested(ruta,
discard_previous)` a través de una instancia del componente reutilizable
**`ButtonNav`**, y `MainApp` es el único responsable de instanciar/liberar
escenas y de mantener la pila `navigation_history`. Esta decisión está
documentada en
[`doc/adr/ADR-002-uso-de-event-bus.md`](doc/adr/ADR-002-uso-de-event-bus.md).

## 🌐 Estado Global Centralizado (GlobalManager)
El índice de fatiga cognitiva (perfil base + síntomas marcados) se
gestiona en un `Dictionary` dentro del Autoload **`GlobalManager`**,
completamente desacoplado de la GUI. Los paneles solo emiten intenciones
(`base_selected`, `item_added`) al `EventBus`; `GlobalManager` recalcula
el total y notifica `total_changed`, al cual la interfaz se suscribe de
forma pasiva. Detalle completo en
[`doc/adr/ADR-003-global-manager-button-nav.md`](doc/adr/ADR-003-global-manager-button-nav.md).

Los tres Registros de Decisión Arquitectónica (ADR) **exigidos por el
Sprint 1** son:
1. [`ADR-001-patron-colocacion.md`](doc/adr/ADR-001-patron-colocacion.md)
2. [`ADR-002-uso-de-event-bus.md`](doc/adr/ADR-002-uso-de-event-bus.md)
3. [`ADR-003-global-manager-button-nav.md`](doc/adr/ADR-003-global-manager-button-nav.md)

## 💾 Persistencia entre sesiones (mejora adicional, fuera del alcance mínimo)
Más allá de lo pedido en la rúbrica, `GlobalManager` también persiste su
estado en disco (`user://fatiga_estado.json`) y mantiene un historial de
evaluaciones guardadas (`user://fatiga_historial.json`), consultable desde
la pantalla adicional `HistoryPanel`. Esto significa que cerrar y volver a
abrir la aplicación **no** borra el progreso ni los resultados anteriores.
Detalle completo, incluyendo por qué se documenta aparte de los 3 ADR
oficiales, en
[`doc/adr/ADR-004-persistencia-historial.md`](doc/adr/ADR-004-persistencia-historial.md).

Consulta también [`CHANGELOG.md`](CHANGELOG.md) para el historial de
versiones y [`DEVLOG.md`](DEVLOG.md) para la bitácora técnica completa.

## ⚙️ Tecnologías Utilizadas
* **Engine:** Godot Engine 4.7.1 (Renderizador: *Compatibility* para portabilidad web)
* **Pruebas:** GdUnit4 6.2.3
* **Fuente:** Atkinson Hyperlegible (OFL)
* **Lenguaje:** GDScript 2.0 (Tipado estricto)
* **Versionamiento:** Git / GitHub para control de configuraciones
## 🎨 Personalización del Proyecto.

El nombre, la descripción y el ícono del proyecto se configuraron desde el panel interno de Godot Engine, siguiendo la ruta:

**Project > Project Settings > Application > Config**

Dentro de esa sección se editaron los siguientes campos:

* **Name:** Nombre visible del proyecto.
* **Description:** Breve descripción del propósito del sistema interactivo.
* **Icon:** Imagen personalizada (ubicada en `src/assets/ui/`)

## 👨‍💻 Autor
* **Nombre:** [July Tatiana Ariza]
* **Código Estudiantil:** [12242612877]
* **Programa:** Ingeniería de Software
