# Mejoras de accesibilidad (Laboratorio 8, WCAG adaptado)

Se implementaron **cuatro** mejoras (la guía pide mínimo dos).

## 1. Contraste de color adecuado (WCAG 1.4.3, AA ≥ 4.5:1)
- **Problema que resuelve:** textos grises sobre fondos grises difíciles de leer, sobre todo en
  pantallas con brillo bajo o proyectores.
- **Implementación:** paleta del `ui_theme.tres` diseñada sobre fondo `#0B1020`; todos los pares
  texto/fondo se verifican con `tools/contrast_check.py`:

| Par | Relación |
|---|---|
| Texto principal / fondo | 17.28:1 |
| Texto secundario / fondo | 12.75:1 |
| Botón Normal | 12.91:1 |
| Botón Hover | 9.74:1 |
| Botón Pressed | 7.19:1 |
| Botón Disabled | 6.55:1 |
| Tarjeta de cupón (texto oscuro / amarillo) | 13.10:1 |
| Título del popup (verde / panel) | 8.75:1 |

## 2. Tipografía y tamaño legible
- **Problema:** textos de 13–14 px con la fuente por defecto y emoji que no se veían en Web.
- **Implementación:** fuente **Atkinson Hyperlegible** (diseñada por el Braille Institute para baja
  visión; licencia OFL, `src/assets/fonts/`) como `default_font` del Theme. Tamaños: base 18 px,
  secundarios 16–17 px (`SecundarioLabel`), secciones 22 px (`SeccionLabel`), títulos 32 px
  (`TituloLabel`). Los botones usan la variante Bold.

## 3. Navegación por teclado
- **Problema:** sin mouse no se podía saber qué botón estaba activo ni moverse entre columnas.
- **Implementación:**
  - Estilo `focus` en el Theme (anillo amarillo de 3 px) visible en todos los botones.
  - `focus_neighbor_top/bottom/left/right` configurados en el menú (3 columnas, ciclo vertical).
  - Cada pantalla da el foco inicial a su acción principal (`grab_focus`), incluidas las que no
    tienen script, gracias a la nueva propiedad `grab_initial_focus` de `ButtonNav`.
  - El minijuego se juega completo con teclado (flechas/A-D, Esc/P, Enter en los menús).

## 4. Información independiente del color
- **Problema:** personas con daltonismo no distinguirían ideas (amarillo), distractores (rojo) y
  pausas (verde) si solo cambia el color.
- **Implementación:** cada estímulo tiene forma y símbolo propios (círculo con visto bueno, rombo con
  "!", hexágono con "+"); las vidas se muestran como "Vidas: 2 de 3"; el plan seleccionado lleva el
  texto "[ELEGIDO]"; los botones deshabilitados se acompañan de un mensaje que explica por qué
  (p. ej. "ningún cupón cumple la compra mínima").

## Iconografía de soporte (convenciones)
Flecha = volver, X = cerrar, carrito = compra/factura, papelera = quitar, triángulo = jugar,
ticket = cupones, reloj = historial, engranaje = configuración, "i" = créditos.
