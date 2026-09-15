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

La regresión M6 también valida los sprites de enemigos: cada hoja debe conservar un
atlas 3×4 con transparencia, y cada icono debe ser cuadrado y conservar transparencia.

El mapeo visual actual es explícito: `frenzied_pig` usa `gatos_nigromantes/`,
`invisible_spider_w8` usa `invisibles/`, las waves boss usan `boss/` y el resto de
perfiles normales usa `normal_enemies/` como fallback. Cada hoja tiene su icono
correspondiente para el inspector. Si una textura nueva no está disponible durante
un checkout o exportación, el runtime conserva el sprite histórico como fallback.

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

## Selección y acciones contextuales

Durante Construction el mapa tiene dos modos explícitos: selección (por defecto) y
placement (activado por `Place Gem`/Q). Un click sobre una gema o piedra existente
siempre selecciona la entidad y no consume una colocación; un click sobre una celda
vacía sólo coloca cuando placement está activo. La previsualización se oculta fuera
de ese modo.

`ConstructionRuntime.contextual_combinations()` es la única fuente de elegibilidad
para el inspector, el command card y la ejecución. Combina las reglas básicas con
`RecipeMatcher` para One Shot en Construction y recetas avanzadas en Combat, respetando
IDs, niveles, multiplicidad, alcance y secretos. Las recetas secretas siguen siendo
ejecutables por contexto, pero no aparecen en el panel normal de recetas. Cuando no
hay contexto, el command card oculta la acción y no muestra el placeholder genérico
“This action is not available”. Las opciones contextuales se presentan ahora en un
popup anclado sobre la gema: `construction_current` contiene sólo las cinco gemas
recién colocadas y `board` contiene las combinaciones avanzadas de Combat. La primera
selección del popup no muta estado; la confirmación ejecuta exactamente esa opción.
El popup se posiciona a la derecha de la gema con una flecha de conexión, muestra el
icono, nombre, nivel, daño, rango y velocidad de la entidad seleccionada. Cuando hay
una sola opción se muestra como texto estático; con dos o más se usa un dropdown sin
prefijos de pool. `Combine` ejecuta directamente la opción seleccionada. No hay una
segunda confirmación ni un botón de descarte: `Esc`, click fuera o seleccionar otra
entidad cierra el popup sin mutar ingredientes. También contiene las acciones contextuales
(`Keep`, `Degrade`, `Remove Stone`, `Attack` y `Stop`). El panel derecho ya no muestra información ni la carta de acciones;
conserva únicamente el feedback general y los indicadores de estado no disponibles.
Las piedras abren el mismo popup contextual, con su identidad y la acción `Remove
Stone`; esta acción elimina la piedra mediante `ConstructionRuntime`, libera la celda
y cierra la selección.
El popup es transitorio: cualquier transformación de cámara (zoom, paneo o resize)
lo cierra y limpia la selección, sin mutar entidades, ingredientes ni ocupación de la
grilla. Para volver a operar se selecciona nuevamente la entidad en su nueva posición.

## Presentación de torres y footprint

Las gemas que sobreviven a una construcción anterior conservan su representación de
torre al comenzar la siguiente wave; durante Combat las gemas activas también usan
esa representación. El sprite puede ocupar visualmente varias celdas para mantener
la lectura de una torre, pero su anclaje lógico, selección y colisión continúan siendo
el centro de una única celda de la grilla. El tamaño visual se calcula en la vista y
no altera pathfinding, reservas ni reglas de placement.
El atlas conserva celdas uniformes, pero cada torre se posiciona usando el centro
horizontal del cuarto inferior opaco, correspondiente al pedestal, e ignora partículas
laterales para el centrado. La base visible se apoya al `75%` vertical de la celda.
Estas métricas se calculan una sola vez y se cachean por tipo y nivel, de modo que el
contenido visible queda centrado aunque el PNG tenga márgenes asimétricos.
Las torres usan una dimensión visible máxima de `1.4175` celdas y las piedras usan
`0.9` celdas. Todas las piedras muestran el mismo sprite petrificado, recortado por sus
límites alfa y centrado en la celda; su capa visual permanece por encima de las torres
sin cambiar el hitbox. Las gemas aún no finalizadas usan un contenedor visual de `3.05`
celdas, aproximadamente un 10% menor que el anterior.
Los sprites que viven en el mapa no conservan un tamaño mínimo de interfaz: su rectángulo
escala junto con la cámara, por lo que el punto de anclaje permanece sobre la misma celda
al acercar o alejar el zoom.
Las vallas del borde se dibujan delante del castillo, mientras que todos los árboles
usan la capa inmediatamente superior a las vallas para que troncos y copas no queden
cortados por el cercado. El punto de spawn usa una capa superior a los árboles para
que el portal permanezca visible incluso si la decoración aleatoria coincide con él.
Las piedras conservan su capa frontal salvo cuando están exactamente una celda encima
de una torre; en ese caso se dibujan detrás de la torre para respetar la profundidad
vertical del escenario, sin alterar ninguna de las dos celdas lógicas.
