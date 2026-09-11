# Producción de Videojuegos - Sistemas Interactivos 2026
**Universidad Antonio Nariño (UAN)**  
**Facultad de Ingeniería de Sistemas y Computación**  

## 📝 Descripción del Proyecto
Este repositorio aloja **Detector de Fatiga Cognitiva**, una aplicación interactiva de autoevaluación psicológica desarrollada durante el semestre académico 2026-2. El usuario responde un breve cuestionario de varias preguntas (escala 0-10) sobre concentración, cansancio mental y errores por falta de atención; la aplicación calcula un índice total y lo clasifica en un nivel de alerta (Bajo, Moderado, Alto o Crítico). El sistema está configurado bajo buenas prácticas de ingeniería de software en Godot Engine, con navegación completamente desacoplada mediante un Event Bus global.

## 📂 Estructura de Directorios del Repositorio
A partir del Laboratorio 2, el proyecto sigue una arquitectura modular con
co-localización estricta (cada escena vive junto a su script controlador):

```
src/
├── core/                     <- Lógica global del sistema
│   ├── event_bus.gd          <- Autoload "EventBus" (Observer/Singleton)
│   ├── global_manager.gd     <- Autoload "GlobalManager" (estado global)
│   ├── main_app.tscn         <- Escena principal (orquestador)
│   └── main_app.gd
├── scenes/
│   ├── menu/                 <- Panel de menú principal
│   ├── simulation/           <- Panel de simulación / evaluación (Paso 1)
│   ├── config/                <- Panel de configuración (sin script propio)
│   ├── credits/               <- Panel de créditos (sin script propio)
│   └── history/                <- (Extra) Historial persistente de evaluaciones
├── components/
│   └── navigation/
│       └── button_nav.tscn    <- Componente reutilizable de navegación
└── assets/                    <- Recursos multimedia (audio, UI, texturas)
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
* **Engine:** Godot Engine 4.x (Renderizador: *Compatibility* para portabilidad web)
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
