# v0.9.0-beta — Versión Beta

Primera versión Beta del **Detector de Fatiga Cognitiva** (Sprints 2 y 3, Laboratorios 7 a 10).

## Novedades
- **Enfoque Rush:** minijuego de atención con victoria/derrota, pausa, rachas y cupones por desempeño.
- **Cupones persistentes** (`user://save_data.json`) que se consumen al comprar.
- **Tienda de Bienestar** (planes) y **Arma tu Kit Anti-Fatiga** (catálogo basado en `Resource` con UI auto-poblada).
- **UI/UX:** Theme centralizado, iconografía, popup de compra realizada y 4 mejoras de accesibilidad.
- **Calidad:** 29 pruebas GdUnit4 en verde, prueba de sistema automatizada y 5 incidencias corregidas.

## Cómo jugar
- Web: abrir la URL de itch.io (o `index.html` de `DetectorFatigaCognitiva-web.zip` con un servidor local).
- Mover la lente: flechas / A-D / mouse. Pausa: Esc o P.

## Problemas conocidos
- La prueba con usuario real (USER_FEEDBACK.md) está pendiente de registrar.
- La versión Web usa el renderizador de compatibilidad; en equipos sin aceleración gráfica puede ir a menos FPS (la lógica usa `delta`, así que la duración de la partida no cambia).
