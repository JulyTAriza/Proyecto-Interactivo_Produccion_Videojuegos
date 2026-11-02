# BACKLOG — Detector de Fatiga Cognitiva

Prioridades: **P1** imprescindible para la Beta · **P2** deseable para la Beta · **P3** posterior.

## Completado
- [x] Lab 7 — Minijuego Enfoque Rush con victoria/derrota, pausa y dificultad progresiva.
- [x] Lab 7 — Cupones persistentes (`user://save_data.json`), consumo al comprar.
- [x] Lab 7 — Tienda de planes y factura con mejor cupón automático.
- [x] Lab 7 — Exportación Web probada en navegador (incluida persistencia).
- [x] Lab 8 — Theme centralizado `ui_theme.tres` (Button: Normal / Hover / Pressed / Disabled + Focus).
- [x] Lab 8 — Fondo `TextureRect` en el menú (Mouse Filter Ignore, Z Index -1).
- [x] Lab 8 — Iconografía: volver (flecha), cerrar (X), carrito, papelera, jugar, cupón, historial.
- [x] Lab 8 — `PurchaseSuccessPopup` en la factura.
- [x] Lab 8 — Accesibilidad: contraste AA verificado, tipografía legible, navegación por teclado,
      información independiente del color.
- [x] Lab 9 — `WellnessItemData` + `WellnessDatabase` + catálogo `.tres` en `GlobalManager`.
- [x] Lab 9 — Kit Anti-Fatiga con UI auto-poblada, composición por secciones y Tweens.
- [x] Lab 9 — Factura interactiva con cupones persistentes y ADR-006.
- [x] Lab 10 — Sesión de depuración con breakpoints (`registro_depuracion.md`).
- [x] Lab 10 — Suite GdUnit4 (29 casos en verde) y prueba de sistema SIS-01.
- [x] Lab 10 — Issues #1–#5 corregidos (emoji Web, floats de JSON en cupones y compras, foco recortado, mensaje de abandono).

## Pendiente para la Beta (priorizado)
| Prioridad | Tarea | Origen |
|---|---|---|
| P1 | Completar la prueba con usuario real y trasladar sus hallazgos aquí | Lab 8 |
| P1 | Publicar los Issues y la Release `v0.9.0-beta` en GitHub (`tools/create_github_issues.sh`, `tools/publicar_github.sh`) | Lab 10 |
| P2 | Ejecutar la suite GdUnit4 en GitHub Actions en cada push | Lab 10 |
| P2 | Que el alivio del kit comprado reduzca el índice de la evaluación de fatiga | Lab 9 |
| P2 | Opción de "texto grande" en Configuración (escala de fuente del Theme) | Heurística Lab 8 |
| P2 | Sonido de retroalimentación al atrapar ideas / distractores (con opción de silenciar) | Heurística Lab 8 |
| P2 | Mostrar en el minijuego una mini-leyenda permanente de las tres formas | Heurística Lab 8 |
| P3 | Borrar registros individuales del historial | DEVLOG Lab 4 |
| P3 | Reintroducir el umbral de alerta configurable (SettingsManager) | DEVLOG Lab 4 |
