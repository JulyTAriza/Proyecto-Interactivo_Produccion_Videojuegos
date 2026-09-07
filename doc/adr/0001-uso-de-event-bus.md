# ADR 0001 — Adopción de un Event Bus para la navegación desacoplada entre escenas

**Fecha:** 2026-09-03
**Autor:** July Tatiana Ariza
**Estado:** Aceptada

## Contexto

Durante el Laboratorio 1, la navegación entre pantallas se implementó
mediante llamadas directas a `get_tree().change_scene_to_file()`, invocadas
desde cada script de interfaz con la ruta absoluta del archivo de destino
escrita como texto plano.

Este enfoque generaba un acoplamiento fuerte entre las escenas: cada panel
necesitaba conocer de antemano la ubicación exacta de las demás escenas del
proyecto. Como consecuencia, cualquier cambio de nombre de archivo o
reorganización de carpetas obligaba a modificar manualmente múltiples
scripts dispersos, con alto riesgo de introducir errores en cadena y sin
ningún punto único de control sobre el flujo de navegación.

A medida que el proyecto crece hacia un sistema de varios entornos (menú,
simulación, configuración, créditos), este patrón se vuelve insostenible
desde el punto de vista de mantenibilidad y escalabilidad.

## Decisión

Se decide reemplazar las llamadas directas de cambio de escena por un
**Event Bus global**, implementado como Autoload bajo el identificador
`EventBus` y basado en la combinación de los patrones **Observer** y
**Singleton**.

El `EventBus` declara señales tipadas de forma estricta:

```gdscript
signal navigation_requested(target_scene_path: String)
signal parameter_changed(param_name: String, value: Variant)
```

Cada panel de interfaz **emite** estas señales cuando el usuario interactúa
con un control, sin tener conocimiento alguno de qué otra escena existe o
cómo se instancia. La responsabilidad de escuchar estas señales, cargar la
escena correspondiente y liberar la escena activa recae exclusivamente en
`MainApp`, el orquestador central del sistema:

```gdscript
if current_scene:
	current_scene.queue_free()
	current_scene = null
```

## Consecuencias

**Positivas**
- Las escenas quedan completamente desacopladas entre sí: ningún panel
  conoce la ruta ni la existencia de otro panel.
- Renombrar o mover un archivo de escena solo requiere actualizar la
  referencia en `MainApp`, eliminando el efecto dominó del enfoque anterior.
- El uso de `queue_free()` y la limpieza explícita de `current_scene`
  previenen fugas de memoria al cambiar de pantalla.
- El tipado estricto de las señales facilita la detección temprana de
  errores y mejora la legibilidad del flujo de eventos.
- La arquitectura resultante es fácilmente extensible: agregar una nueva
  pantalla no exige tocar el código de las pantallas existentes.

**Negativas / trade-offs**
- Se introduce una capa de indirección adicional: seguir el flujo completo
  de una acción requiere revisar tanto el panel emisor como el
  `EventBus` y `MainApp`, lo cual añade una curva de aprendizaje inicial.
- El uso de `Variant` en `parameter_changed` relaja parcialmente el tipado
  estricto del valor transportado, ya que distintos parámetros pueden tener
  naturalezas distintas. Se acepta este costo a cambio de mantener una
  única señal genérica en lugar de múltiples señales específicas por tipo
  de parámetro.

## Alternativas consideradas

- **Mantener `get_tree().change_scene_to_file()` con rutas centralizadas
  en constantes:** reduce parcialmente el acoplamiento textual, pero no
  elimina la dependencia directa entre paneles y el árbol de escenas.
- **Grupos de nodos (`add_to_group`) para comunicación:** viable para casos
  simples, pero menos explícito y más difícil de tipar que un conjunto de
  señales declaradas formalmente en un Autoload.
