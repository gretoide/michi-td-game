# M2 — Gems & Construction

M2 agrega el runtime de gemas y construcción sobre los contratos de M0/M1. La lógica vive en `src/gameplay` y no depende de UI, HTTP ni autenticación.

## Flujo

```text
GameplayCatalog + RandomSource
             ↓
GemGenerator / RecipeMatcher / MvpState
             ↓
ConstructionRuntime
             ↓
GameRuntime
             ↓
ConstructionHarness (provisional) / GameplayView
```

`GemInstance` representa una gema colocada o candidata. Usa IDs estables, nivel 1–7, calidad, celda, ronda y MVP. `StoneInstance` conserva la celda ocupada por una gema descartada.

`GemGenerator` produce los ocho tipos básicos y aplica la tabla de calidad de FR-005. El límite de cinco resultados se mantiene por ronda y la secuencia es reproducible con `SeededRandomSource`.

`ConstructionRuntime` es el owner de la construcción actual. Valida placement y path antes de mutar la grilla, mantiene las cinco gemas de la ronda, convierte descartes en stones y coordina las transiciones de fase. Las operaciones inválidas no alteran estado.

`RecipeMatcher` exige IDs y niveles exactos. El mismo matcher opera sobre el conjunto de cinco gemas para One Shot o sobre todo el tablero durante Combat. Las recetas secretas se pueden ejecutar contextualmente, pero nunca aparecen en el listado normal.

`MvpState` es un contrato aislado: administra niveles 0–10, multiplicadores, graduación, selección por daño inyectado y transferencia limitada a 10. La integración con eventos reales de daño y las auras espaciales quedan para M3/M6.

## Datos bootstrap

`data/gameplay/catalog.tres` contiene los ocho IDs básicos y fixtures mínimos para recetas normales, secretas y resultados especiales. El dataset completo de 38 recetas normales + 8 secretas y las estadísticas definitivas permanece en M5.

## Harness

`ConstructionHarness` es una herramienta provisional dentro de la vista de gameplay. Permite seleccionar coordenadas, colocar gemas, conservar, combinar, degradar y remover stones, mostrando contador, fase y estado. No sustituye el HUD final de M6.

## Pruebas

```powershell
godot --headless --path michi-td-game --script res://test/gameplay/m2/run.gd
```

La suite cubre generación reproducible, ocho IDs, calidad, límite 5, placement, Keep/Stone, Remove Stone, Degrade, combinaciones, One Shot, recetas secretas y MVP.
