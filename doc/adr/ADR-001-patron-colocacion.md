# ADR-001: Adopción del patrón de Co-localización para escenas y scripts

## Estado
Aceptado

## Contexto
En el Laboratorio 1, el proyecto se organizaba de forma plana: las escenas
(`.tscn`) y sus scripts (`.gd`) vivían en la raíz de `res://` sin una
convención de carpetas clara, junto con recursos de distinta naturaleza
(assets, escenas auxiliares, scripts sueltos como `change_scene.gd`).

Este enfoque generó varios problemas a medida que el proyecto creció:

- **Dificultad para localizar archivos relacionados**: encontrar el script
  asociado a una escena requería revisar manualmente el `Script` adjunto en
  el editor.
- **Nomenclatura inconsistente**: mezcla de `PascalCase`, espacios y
  mayúsculas en nombres de archivos y carpetas.
- **Bajo aislamiento de responsabilidades**: no existía una separación
  clara entre lógica global (`core`), pantallas (`scenes`) y componentes
  reutilizables (`components`).

## Decisión
Se adopta el patrón de **Co-localización** (*co-location*): cada escena
visual reside en el mismo subdirectorio que su script controlador,
agrupados por dominio dentro de `res://src/`:

```
src/
├── core/            <- Lógica global (Autoloads, orquestador principal)
├── scenes/
│   ├── menu/        <- menu_panel.tscn + menu_panel.gd
│   ├── simulation/  <- step_1_base.tscn + step_1_base.gd
│   ├── config/      <- config_panel.tscn
│   └── credits/     <- credits_panel.tscn
├── components/       <- Nodos/escenas reutilizables (ej. ButtonNav)
└── assets/           <- Recursos multimedia
```

Se establece además la convención estricta **snake_case en minúsculas**
para todos los archivos, carpetas, nodos raíz de escena y recursos físicos
del proyecto.

## Consecuencias

### Positivas
- **Localización inmediata**: cualquier desarrollador nuevo encuentra el
  script de una escena en la misma carpeta, sin depender del editor.
- **Cohesión alta, acoplamiento bajo**: cada carpeta de `scenes/` es una
  unidad autocontenida y fácil de mover o eliminar.
- **Consistencia de nomenclatura**: reduce errores de referencia por rutas
  mal escritas o inconsistentes entre mayúsculas/minúsculas.

### Negativas / Trade-offs
- Introduce más carpetas que un proyecto plano, lo cual exige disciplina
  para no romper la convención al añadir nuevas pantallas.
- Los paneles que dejan de requerir script propio (ver ADR-003) deben
  eliminar explícitamente el archivo `.gd` huérfano para no ensuciar la
  co-localización.
