# ADR-002: Uso de un Event Bus (Autoload) para la navegación entre escenas

## Estado
Aceptado

## Contexto
En el Laboratorio 1, la navegación entre pantallas se implementó mediante
llamadas directas y acopladas a `get_tree().change_scene_to_file()`, ejecutadas
desde un script `change_scene.gd` que conocía explícitamente las rutas
absolutas de las escenas de destino.

Este enfoque introduce varios problemas de ingeniería a medida que el
proyecto crece:

- **Acoplamiento fuerte por texto**: cualquier renombramiento o
  reubicación de un archivo `.tscn` rompe en cadena todas las escenas que
  referencian esa ruta de forma literal ("efecto dominó").
- **Baja escalabilidad**: al añadir nuevas pantallas (configuración,
  créditos), cada escena existente tendría que conocer y referenciar
  directamente a las nuevas, aumentando las dependencias cruzadas.
- **Gestión de memoria implícita**: `change_scene_to_file()` no ofrece
  control explícito sobre la liberación de instancias previas cuando se
  requiere una orquestación más fina (por ejemplo, mantener un contenedor
  persistente de UI).
- **Dificultad de prueba y mantenimiento**: la lógica de navegación queda
  dispersa en scripts adjuntos a nodos de cada escena en lugar de
  centralizarse en un único punto de control.

## Decisión
Se implementa un **Event Bus global** (`res://src/core/event_bus.gd`),
registrado como **Autoload** bajo el identificador `EventBus`, que expone
señales tipadas:

```gdscript
signal navigation_requested(target_scene_path: String)
signal parameter_changed(param_name: String, value: Variant)
```

Las escenas visuales (`menu_panel`, `step_1_base`, `config_panel`,
`credits_panel`) **no conocen la existencia de otras escenas ni de
MainApp**: únicamente emiten señales hacia el bus cuando el usuario
interactúa con la interfaz.

`MainApp` (`res://src/core/main_app.tscn`), configurado como escena
principal del proyecto, es el **único suscriptor** de
`navigation_requested`. Al recibir la señal, libera de forma segura la
escena activa (`queue_free()` + referencia a `null`) y luego instancia la
nueva escena solicitada dentro de `SceneContainer`.

Este diseño combina los patrones **Observer** (las escenas "publican"
eventos, el bus los distribuye) y **Singleton** (una única instancia
global y accesible del canal de comunicación).

## Consecuencias

### Positivas
- **Desacoplamiento total**: ninguna escena de interfaz depende de otra;
  todas dependen únicamente del contrato de señales del `EventBus`.
- **Escalabilidad**: agregar un nuevo panel solo requiere que emita
  `navigation_requested` con su propia ruta; no exige modificar las
  escenas existentes.
- **Gestión de memoria centralizada y explícita**: `MainApp` es el único
  responsable del ciclo de vida de las escenas, evitando fugas de memoria
  por instancias huérfanas.
- **Mayor testabilidad**: la lógica de orquestación vive en un solo
  archivo (`main_app.gd`), facilitando su revisión y mantenimiento.

### Negativas / Trade-offs
- **Indirección adicional**: seguir el flujo de un evento requiere
  revisar tanto el emisor como el suscriptor, lo cual añade una curva de
  aprendizaje comparada con una llamada directa.
- **Riesgo de un bus "todopoderoso"**: si no se disciplina su uso, el
  `EventBus` podría convertirse en un punto único de acoplamiento
  implícito entre módulos que deberían permanecer independientes; se
  mitigará manteniendo señales específicas y bien tipadas en lugar de
  canales genéricos.
- **Dependencia de un Autoload global**: introduce un singleton en tiempo
  de ejecución, lo que exige disciplina para no abusar de variables de
  estado compartidas dentro del propio bus.
