# Producción de Videojuegos - Sistemas Interactivos 2026
**Universidad Antonio Nariño (UAN)**
**Facultad de Ingeniería de Sistemas y Computación**

## 📝 Descripción del Proyecto

Este repositorio aloja el proyecto integrador interactivo desarrollado a lo
largo del semestre académico 2026-2. Se trata de un sistema interactivo
multi-etapa, construido en Godot Engine y estructurado bajo buenas prácticas
de ingeniería de software, con énfasis en modularidad, bajo acoplamiento y
documentación técnica progresiva.

## 📂 Estructura de Directorios del Repositorio

A partir del Laboratorio 2, el proyecto adopta una arquitectura modular
basada en el principio de **co-localización estricta**: cada escena reside
en la misma carpeta que su script controlador, garantizando alta cohesión
y facilitando el mantenimiento a medida que el sistema crece.

```
src/
├── core/                  <- Lógica global del sistema
│   ├── event_bus.gd       <- Autoload "EventBus" (Observer/Singleton)
│   ├── main_app.tscn      <- Escena principal (orquestador)
│   └── main_app.gd
├── scenes/
│   ├── menu/              <- Panel de menú principal
│   ├── simulation/        <- Panel de simulación (Paso 1)
│   ├── config/             <- Panel de configuración
│   └── credits/             <- Panel de créditos
├── components/              <- Nodos y micro-escenas reutilizables
└── assets/                   <- Recursos multimedia (audio, UI, texturas)
```

## 🧩 Arquitectura de Navegación Desacoplada

La navegación entre pantallas ya **no** depende de llamadas directas y
acopladas como `get_tree().change_scene_to_file()`. En su lugar, el
proyecto implementa un **Event Bus global** (Autoload `EventBus`) que
centraliza la comunicación entre paneles mediante el patrón Observer.

Cada panel se limita a emitir la señal `navigation_requested(ruta)`, sin
conocer nada sobre las demás pantallas; es `MainApp` el único componente
responsable de instanciar y liberar escenas de forma segura, evitando
fugas de memoria. El razonamiento completo detrás de esta decisión
arquitectónica está documentado en
[`doc/adr/0001-uso-de-event-bus.md`](doc/adr/0001-uso-de-event-bus.md).

## ⚙️ Tecnologías Utilizadas

* **Motor:** Godot Engine 4.x (renderizador *Compatibility*, orientado a
  portabilidad web)
* **Lenguaje:** GDScript 2.0, con tipado estático estricto
* **Control de versiones:** Git / GitHub

## 🎨 Personalización del Proyecto

El nombre, la descripción y el ícono del proyecto se configuraron desde el
panel interno de Godot Engine, siguiendo la ruta:

**Project > Project Settings > Application > Config**

En esa sección se definieron los siguientes campos:

* **Name:** nombre visible del proyecto.
* **Description:** breve descripción del propósito del sistema interactivo.
* **Icon:** imagen personalizada, ubicada en `src/assets/ui/`.

## 👨‍💻 Autor

* **Nombre:** [July Tatiana Ariza Peña]
* **Código Estudiantil:** [12242612877]
* **Programa:** [Ingeniería de Software]
