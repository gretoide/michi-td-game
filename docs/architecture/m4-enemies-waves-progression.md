# M4 — Enemies, Waves & Progression

M4 conecta Construction con un ciclo de Combat completo: spawn data-driven,
muerte o escape, recompensas, progreso, experiencia, vida y transición a la
siguiente wave.

## Runtime

`GameRuntime` compone `WaveRuntime`, `EnemyRuntime`, `ProgressRuntime`,
`EconomyRuntime`, `PlayerProgressionRuntime` y `GameOutcomeRuntime`. Los eventos
de muerte y escape resuelven una sola vez cada enemigo; muerte y escape son
estados mutuamente excluyentes.

El catálogo contiene 50 waves, spawn regular de un enemigo por segundo y bosses
únicos en las waves 10, 20, 30, 40 y 50. La selección de perfiles se hace por
ID del `WaveDefinition`, no por posición fija ni por lógica de UI.

## Progresión y rewards

Progress, gold, XP, quality level y player life son módulos independientes. La
recompensa de support skills aparece cada cinco waves elegibles, ofrece tres
candidatos únicos y bloquea el avance hasta que se elige uno. Cuando se ocupan
los cuatro slots sólo se ofrecen mejoras válidas hasta nivel 4.

## Alcance

M4 entrega contratos y fixtures jugables; el catálogo canónico completo se
expande en M5. El overlay visual final de rewards pertenece a M6.

## Validación

```powershell
godot --headless --path . --script res://test/gameplay/m4/run.gd
```
