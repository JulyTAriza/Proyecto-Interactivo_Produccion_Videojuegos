# Publicación Web en itch.io (Laboratorio 7, Parte 3 y 4)

## 1. Exportar
1. **Proyecto → Exportar… → Web** (preset ya configurado en `export_presets.cfg`).
2. Si Godot lo pide, **Administrar plantillas de exportación → Descargar** (versión 4.7.1).
3. Opciones del preset que exige la guía:
   - `Variant → Thread Support`: **desactivado** (no requiere SharedArrayBuffer).
   - `Progressive Web App → Ensure Cross Origin Isolation Headers`: **desactivado**.
   - Al exportar, desmarcar **Export With Debug**.
4. Ruta: `build/web/index.html`.

Desde la terminal el resultado es idéntico:
```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

## 2. Probar en el navegador antes de subir
- Desde Godot: botón **Ejecutar en el navegador** (icono HTML5 junto a "Ejecutar").
- O con un servidor local: `python -m http.server 8000 --directory build/web` → `http://localhost:8000`.
- Prueba de persistencia: ganar un cupón en Enfoque Rush → cerrar la pestaña → abrir de nuevo →
  "Mis cupones" lo muestra. Comprar en la Tienda usando el cupón → cerrar → abrir → ya no aparece.

## 3. ZIP para itch.io
`index.html` debe quedar en la **raíz** del ZIP (no dentro de una carpeta):
```bash
cd build/web && zip -r ../DetectorFatigaCognitiva-web.zip . && cd -
```
El ZIP que acompaña la entrega ya cumple esta regla.

## 4. Subir a itch.io
1. itch.io → **Upload new project**.
2. *Kind of project*: **HTML**.
3. Subir `DetectorFatigaCognitiva-web.zip` y marcar **This file will be played in the browser**.
4. *Embed options*: tamaño 1152 × 648, activar **Fullscreen button**.
5. *Visibility & access*: **Draft** → guardar.
6. Copiar la **Secret URL** que muestra itch.io para borradores.
7. Abrirla en una ventana de **incógnito** sin iniciar sesión y jugar una partida.
8. Pegar la URL en la entrada del Laboratorio 7 de `DEVLOG.md`.
