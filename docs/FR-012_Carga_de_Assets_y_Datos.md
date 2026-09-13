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
- Seeds reproducibles: servicio `RandomSource` de MIC-68 en M0.
