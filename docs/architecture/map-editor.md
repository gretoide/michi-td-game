# Editor 2D del mapa

El mapa authored está en `src/gameplay/map/map.tscn` y se abre como escena independiente en el editor 2D. La escena contiene:

- `Ground`, un `TileMapLayer` en `z=-100` con un mapa pintado de 64×40 celdas (1024×640 px).
- `Decorations/FlatDetails` y `Decorations/FlatDetailsForeground`, `TileMapLayer` reservados para flores, cultivos bajos y detalles sin volumen.
- `Decorations/Fences`, un `TileMapLayer` visual en `z=-40`, sin colisiones.
- `WorldYSort`, un único `Node2D` con `y_sort_enabled=true`. Dentro están las carpetas `Trees`, `Bushes`, `Stones`, `Props`, `Structures` y `Landmarks`; cada una también tiene `y_sort_enabled=true` para conservar un orden Y único entre categorías.
- `Foreground` (`z=50`) y `WorldEffects` (`z=75`) para elementos que siempre deben quedar delante y para efectos, respectivamente.
- Los TileSets compartidos son recursos externos: `data/gameplay/terrain_tileset.tres`, `data/gameplay/flat_decoration_tileset.tres` y `data/gameplay/fence_tileset.tres`. Por eso todos los `TileMapLayer` pintables muestran su biblioteca al seleccionarlos.

La biblioteca de arte está ordenada por función dentro de `assets/art/gameplay/environment`: `vegetation/` (césped, flores y arbustos), `stones/`, `props/` (cajas, lámparas, troncos y vallas), `landmarks/` (castillo, spawn y banderas) y `tilesets/` (fuentes para pintar). Las texturas consolidadas que usa el mapa se guardan además en `generated/map_objects/trees`, `bushes`, `stones`, `props`, `structures` o `landmarks`.
- `Path/Spawn`, `Path/Checkpoints/CP01..CP05` y `Path/Endpoint` para el camino y sus puntos.
- `Obstacles` con nodos `MapObstacle` editables.
- `Gems` con marcadores `MapGemMarker` que no reemplazan las gemas generadas por las rondas.
- `Decorations/Fences` tiene una cerca authored persistida alrededor del rectángulo de juego; sirve como referencia visual del límite construible y no agrega colisiones.
- `data/gameplay/initial_map.tres` conserva un `route_cells` authored de 112 celdas ortogonalmente conectadas. El juego lo usa como recorrido authored cuando está libre; si una construcción ocupa una de esas celdas, `GroundPathfinder` calcula un desvío dinámico y mantiene la secuencia de los cinco checkpoints.

Los objetos altos usan `MapDecorationObject`. Su raíz es el punto de contacto con el suelo —tronco, pies o pedestal— y contiene un único `Sprite2D` llamado `Visual`, que se extiende hacia arriba. La escena no conserva piezas internas ni nombres automáticos como `@Sprite2D@30`: los fragmentos provenientes del TileMap se consolidan en una textura por variante bajo `assets/art/gameplay/environment/generated/map_objects`. Las carpetas de categoría son `Node2D` con Y-sort anidado: sólo organizan el árbol del editor, mientras Godot las ordena en el mismo espacio Y que `WorldYSort`. Todos conservan `z_index=0`: Godot decide el cruce por la coordenada Y de la raíz. No existen bandas especiales para “debajo” o “encima” de enemigos. Para forzar un elemento siempre frontal debe ir en `Foreground`, no alterar el Z de un objeto ordenable.

Los nombres del árbol de escena indican qué es cada objeto y dónde está anclado. Por ejemplo, `Tree_Maple_C13_R03` es un arce cuya base está en la columna 13, fila 3; los puntos visuales protegidos se llaman `Landmark_SpawnPortal`, `Landmark_Checkpoint_01..05` y `Landmark_Castle`. Además, cada nodo tiene un grupo persistente según su tipo (`map_decoration_tree`, `map_decoration_stone`, `map_decoration_landmark`, etc.), que se puede usar como filtro en el panel de grupos de Godot. El nombre, la carpeta y el grupo sirven para encontrar/editar; el orden visual sigue dependiendo de la posición Y y no del texto.

Para agregar una lámpara al mapa, arrastrá `assets/art/gameplay/environment/props/lamps/lamp.tscn` o cualquiera de `lamp_02.tscn`…`lamp_06.tscn` desde el FileSystem a `WorldYSort/Props`. La escena ya trae `MapDecorationObject`, `category="prop"`, huella de una celda y un único `Visual`; ajustá `cell` desde el Inspector o mové el nodo con snap a la grilla. No arrastres `Lamp1.png` directamente, porque eso crea un Sprite2D sin huella y no se eliminaría como objeto completo al construir.

`MapDecorationObject` expone `asset_id`, `category`, `cell`, `footprint_offset`, `footprint_size`, `remove_on_build` y `blocks_path=false`. El índice de huellas consulta estos objetos directamente: al construir una gema se elimina el objeto completo que intersecta la celda, sin tocar vecinos, vallas ni landmarks protegidos. Las decoraciones siguen sin reservar celdas ni participar del pathfinding. Las únicas celdas no construibles por el mapa son spawn, checkpoints y endpoint.

Spawn, las cinco banderas y el castillo son objetos visuales dentro de `WorldYSort`, independientes de los nodos lógicos bajo `Path`. Mover su `Visual` no mueve el waypoint. Gemas/torres, piedras y cada enemigo se agregan en runtime como hijos directos de `WorldYSort`; barras de vida y partículas permanecen como hijos del actor correspondiente. El zoom, paneo y resize transforman `MapWorld` completo, de modo que no se recalcula una posición de pantalla distinta para cada familia de sprites.

Los puntos lógicos exponen `cell`; los objetos visuales exponen su anclaje y huella. Se pueden mover, duplicar o borrar desde `WorldYSort` en la vista 2D. Duplicar o borrar un nodo dentro de `Obstacles` sigue agregando o quitando un obstáculo lógico.

La escena authored se muestra como mapa completo, centrado y ajustado al panel de gameplay al iniciar. La lógica continúa usando la grilla 36×36 y `data/gameplay/initial_map.tres`; el cambio de render no modifica posiciones lógicas, hitboxes, checkpoints ni rutas.

El migrador reproducible está en `tools/migrate_top_down_map.gd`. Convierte únicamente fuentes altas conocidas, quita sus tiles después de crear el objeto completo, externaliza TileSets y conserva con advertencia cualquier fuente de escenas no reconocida que siga en uso. Después de una migración, `tools/consolidate_map_decorations.gd` asigna los nombres descriptivos y combina cada visual en un único `Sprite2D`; si genera PNG nuevos, se ejecuta una vez el editor headless para importarlos y luego se vuelve a ejecutar la herramienta.

Para guardar cambios en Godot: abrir `src/gameplay/map/map.tscn`, editar desde la vista 2D o el panel TileMap inferior y presionar `Ctrl+S`.

## Atribución de assets

Los recursos de `cute_fantasy` provienen del pack Cute Fantasy Free. Según su `read_me.txt`, se pueden modificar y usar en proyectos no comerciales, pero no se puede redistribuir el pack de forma aislada.
