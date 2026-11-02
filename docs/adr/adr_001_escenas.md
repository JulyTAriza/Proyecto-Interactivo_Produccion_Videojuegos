# ADR 001 — Arquitectura basada en escenas (Actividad 3: Arquitectura Profesional)

* **Estado:** Aprobado
* **Fecha:** 2026-11-02
* **Autor:** July Tatiana Ariza Peña

> Este archivo responde a la ruta pedida por la Actividad 3 (`docs/adr/adr_001_escenas.md`).
> Los ADR completos del proyecto están en `doc/adr/` (ADR-001 a ADR-008).

## Contexto
El proyecto crece cada laboratorio (evaluación, tres minijuegos, tienda, kit, cupones,
pruebas). Si todo viviera en una sola escena o en un solo script, cada cambio afectaría a
todo el sistema.

## Decisión
Se adopta una arquitectura **basada en escenas** de Godot:
* Cada pantalla o componente es una escena (`.tscn`) con su script co-localizado
  (`src/scenes/<modulo>/`).
* Las piezas reutilizables son escenas instanciables: `ButtonNav`, `KitComposition`, `Spawner`,
  `FallingItem`, `Cup`, `Station`, `CupSpawn`.
* `MainApp` es la única escena raíz; carga las demás dentro de `SceneContainer`.
* La comunicación entre escenas pasa por el Autoload `EventBus`; el estado compartido vive en
  el Autoload `GlobalManager`.

## Consecuencias
* **Positivas:** responsabilidades separadas, componentes reutilizables, escenas probables por
  separado (GdUnit4 `scene_runner`) y cambios localizados.
* **Negativas:** más archivos y un flujo indirecto (señales) que hay que documentar.
