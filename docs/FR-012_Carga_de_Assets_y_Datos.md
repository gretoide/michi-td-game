# FR-012 — Carga de assets y datos

## Estado técnico de M0

El runtime de Godot consume recursos tipados `.tres` bajo `data/gameplay`. La especificación funcional y los valores completos permanecen en Drive; M5 integra el contenido completo.

## Contrato de datos

`GameplayCatalog` referencia `GlobalConfig`, gemas, recetas, perfiles enemigos y waves. Cada entrada tiene un ID estable. El loader valida schema, campos obligatorios, rangos, IDs duplicados y referencias cruzadas antes de habilitar gameplay.

Los errores exponen `code`, `path` y `message`; no se reemplaza un recurso inválido con defaults silenciosos. M0 incluye un catálogo bootstrap representativo para probar la foundation.

## Carga y fallback

La carga usa `ResourceLoader` sobre archivos `.tres`, por lo que los datos quedan incluidos en el PCK y editables desde el Inspector. Si falta el catálogo o falla su schema, `GameplayFoundation` devuelve el resultado inválido y la shell puede mostrar el error sin iniciar gameplay parcial.

## Fuentes y evolución

- Fuente funcional: documentos FR y datasets publicados en Drive.
- Contrato ejecutable: `.tres` versionados en este repositorio.
- Integración completa: MIC-45, MIC-46 y MIC-48 en M5.

## Implementación M5 — 14 sep 2026

El cargador conserva `data/gameplay/catalog.tres` como entry point y expande el contenido canónico mediante `src/core/data/m5_content_catalog.gd` antes de ejecutar la validación. Se integraron 8 gemas con niveles 1–7, 38 recetas normales, 8 secretas y 50 perfiles/waves. Las recetas secretas permanecen disponibles sólo para matching contextual; `Natural Zumurud` mantiene `Spell Steal` como placeholder V1. Las variantes de enemigos se reducen a la primera variante jugable y se filtran las abilities fuera de alcance.
- Seeds reproducibles: servicio `RandomSource` de MIC-68 en M0.
