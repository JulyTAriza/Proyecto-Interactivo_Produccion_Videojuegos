#!/usr/bin/env python3
"""Laboratorio 8 — Verificación de contraste WCAG 2.1 de la paleta del Theme.

Calcula la relación de contraste (L1 + 0.05) / (L2 + 0.05) entre cada color
de texto y el fondo sobre el que se dibuja en ui_theme.tres. Criterio AA
para texto normal: >= 4.5:1.  Uso: python3 tools/contrast_check.py
"""

def lum(hexcolor: str) -> float:
    h = hexcolor.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    lin = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)

def ratio(a: str, b: str) -> float:
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

PARES = [
    ("Texto principal / fondo de la app", "#F1F5F9", "#0B1020"),
    ("Texto secundario / fondo de la app", "#CBD5E1", "#0B1020"),
    ("Texto principal / panel", "#F1F5F9", "#161E36"),
    ("Texto secundario / panel", "#CBD5E1", "#161E36"),
    ("Acento cian (títulos de sección) / fondo", "#5CDDFF", "#0B1020"),
    ("Acento amarillo (puntos, sección) / fondo", "#FFD166", "#0B1020"),
    ("Botón Normal: texto / fondo", "#F1F5F9", "#1E2A4A"),
    ("Botón Hover: texto / fondo", "#FFFFFF", "#24427E"),
    ("Botón Pressed: texto / fondo", "#FFFFFF", "#0E5E7E"),
    ("Botón Disabled: texto / fondo", "#9AA5BE", "#1A2033"),
    ("Tarjeta de cupón: texto / fondo amarillo", "#0B1020", "#FED166"),
    ("Popup éxito: título verde / panel", "#06D6A0", "#161E36"),
]

if __name__ == "__main__":
    fallas = 0
    print(f"{'Par de colores':48} {'Relación':>9}  AA(4.5:1)")
    for nombre, fg, bg in PARES:
        r = ratio(fg, bg)
        ok = r >= 4.5
        fallas += not ok
        print(f"{nombre:48} {r:8.2f}:1  {'CUMPLE' if ok else 'NO CUMPLE'}")
    print(f"\n{len(PARES) - fallas}/{len(PARES)} pares cumplen AA.")
    raise SystemExit(1 if fallas else 0)
