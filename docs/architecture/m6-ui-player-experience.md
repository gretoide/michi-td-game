# M6 — UI y Player Experience

La vista `GameplayView` es el único shell visible de la partida. Consume eventos y
estado de `GameRuntime`; no contiene reglas de combate, recetas, waves ni progresión.

## Capas

- `SelectionState`: selección única de gema, piedra, enemigo o torre.
- `CommandCardModel`: doce acciones derivadas del contexto, con hotkeys fijas
  `Q W E R / A S D F / Z X C V`.
- `GameplayView`: mapa, barra global, carta de comandos, inspector y feedback.
- Overlays: recetas, rewards, configuración, Debug y end screen.
- `SettingsStore`: preferencias de ventana y audio en `user://game_settings.cfg`.

El click y el hotkey usan el mismo handler. `Esc` cierra overlays compatibles o limpia
la selección; un reward pendiente no puede saltearse. El selector EN/ES existente se
mantiene en la barra global y todos los textos nuevos usan `LocalizationService`.

## Flujo

```text
GameRuntime events
        ↓
GameplayView → SelectionState → CommandCardModel
        ↓              ↓
   map feedback     command actions
        ↓
 recipes / rewards / settings / end screen
```

El panel de recetas lista las 38 recetas normales y oculta las secretas. El overlay de
rewards muestra exactamente los candidatos emitidos por `SupportRewardRuntime` y sólo
la elección por click o `1/2/3` reanuda la wave. Victory/Defeat congela la simulación y
expone el score del dominio. `F10` abre Debug usando el catálogo y seed reales.

