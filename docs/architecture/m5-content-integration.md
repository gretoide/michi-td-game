# M5 — Content Integration

M5 expande el catálogo bootstrap sin cambiar los contratos de M0–M4.

## Dataset integrado

`M5ContentCatalog.expand` materializa y valida:

- 8 tipos básicos de gema con niveles 1–7;
- 38 recetas normales y 8 secretas;
- 50 perfiles/waves con cadencia canónica de un segundo;
- Natural Zumurud como receta ejecutable con Spell Steal todavía placeholder.

Los recursos `.tres` siguen siendo el punto de entrada estable. La expansión se
ejecuta antes de la validación final y conserva IDs `StringName` estables. Los
resultados de recetas se resuelven mediante definiciones de gemas, sin duplicar
el catálogo ni convertir recetas en IDs de runtime.

## Contenido diferido

Las cinco abilities enemigas reservadas por diseño (`refraction`, `untouchable`,
`reactive_armor`, `blink` y `global_slow_aura`) no se activan en V1. Spell Steal
se muestra como próximamente y no agrega efectos de combate.

## Validación

```powershell
godot --headless --path . --script res://test/gameplay/m5/run.gd
```
