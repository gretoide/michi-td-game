# M3 — Combat Engine

M3 agrega el circuito runtime de combate sin acoplarlo a la UI ni al API.

```text
GemDefinition + GlobalConfig
          ↓
TowerRuntime / EnemyRuntime
          ↓
TargetController → Attack cadence
          ↓
HomingProjectile
          ↓
DamagePipeline
          ↓
EffectSystem → MvpState
```

`TowerCombatStats` carga damage, range, Base AS y BAT desde los niveles de la gema. La velocidad se calcula con `ΣAS = Base AS + bonuses`, limitada a `[20, 700]`; el ataque básico es Physical.

`TargetController` expone los modos automático FIFO, manual y detenido. `HomingProjectile` conserva el objetivo hasta impacto a la velocidad de `GlobalConfig`, y se invalida sin retarget si el objetivo muere o escapa.

`DamagePipeline` separa Physical, Magic y Pure y devuelve un resultado no negativo. `EffectRuntime`/`EffectSystem` proveen metadatos de escuela, debuff, duración y stacking para extender debuffs, DoT y auras sin hardcodear efectos en el loop de ataque.

El HUD propio muestra fase, wave, gemas, enemigos y proyectiles. La unidad defensiva visible es siempre la gema; `TowerRuntime` se conserva como nombre técnico interno del emisor de combate. Cada proyectil guarda la gema de origen para elegir la animación de fuego de su color. El catálogo utilizado es bootstrap; el dataset completo de efectos/recetas permanece en M5 y el refinamiento visual final en M6.

## Verificación

```powershell
godot --headless --path michi-td-game --script res://test/gameplay/m3/run.gd
```

La suite cubre stats, targeting, proyectiles, color de gema de origen, daño, inmunidades, efectos y el circuito gema → proyectil → impacto.
