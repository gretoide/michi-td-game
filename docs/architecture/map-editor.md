# Editor 2D del mapa

El mapa authored está en `src/gameplay/map/map.tscn` y se abre como escena independiente en el editor 2D. La escena contiene:

- `Ground`, un `TileMapLayer` con un `TileSet` nativo de 16×16 y un mapa pintado de 64×40 celdas (1024×640 px), listo para pintar desde el panel TileMap.
- El `TileSet` de `Ground` contiene atlas de pasto, camino, playa, acantilado, farmland y agua desde `assets/art/gameplay/terrain/cute_fantasy/`.
- `Path/Spawn`, `Path/Checkpoints/CP01..CP05` y `Path/Endpoint` para el camino y sus puntos.
- `Obstacles` con nodos `MapObstacle` editables.
- `Gems` con marcadores `MapGemMarker` que no reemplazan las gemas generadas por las rondas.
- `Decorations` con capas `DecorationTiles`/`DecorationForeground`, un contenedor `Objects` para escenas `MapDecorationObject` y un `Fences` `TileMapLayer` visual para las vallas, sin colisiones.
- `Decorations/Fences` tiene una cerca authored persistida alrededor del rectángulo de juego; sirve como referencia visual del límite construible y no agrega colisiones.
- `Decorations/FarmMapleTree`, `FarmSpringCrop` y `FarmRoadDetail` muestran ejemplos editables de los spritesheets de Farm RPG. Cada marcador conserva la textura completa y permite cambiar `region_rect`, `scale`, `cell` o `sprite` desde el Inspector; se pueden duplicar o borrar sin afectar la navegación.
- `data/gameplay/initial_map.tres` conserva un `route_cells` authored de 112 celdas ortogonalmente conectadas. El juego lo usa como recorrido authored cuando está libre; si una construcción ocupa una de esas celdas, `GroundPathfinder` calcula un desvío dinámico y mantiene la secuencia de los cinco checkpoints.

Las piedras, arbustos, árboles y props del grupo `Decorations` son tiles visuales, no obstáculos de la grilla. `Decorations/DecorationTiles` es la capa `TileMapLayer` pintable (junto con `Fences`) para añadirlos desde el editor; incluye los atlas de Cute Fantasy y Farm RPG incorporados en `assets/art/gameplay/environment/tilesets/`, además de una fuente de escenas para colocarlos como objetos completos cuando el atlas requiere una escena. Los objetos completos usan `MapDecorationObject`, que conserva una huella authored y se puede mover independientemente de los puntos lógicos. El índice de huellas agrupa automáticamente composiciones contiguas del mismo atlas y tiles grandes, de modo que una gema elimina el asset completo sin tocar decoración vecina fuera de la celda. Las únicas celdas reservadas para construcción son los waypoints (spawn, los cinco checkpoints y la llegada). Cada checkpoint se muestra con una única bandera animada tomada del atlas de seis frames.

Los puntos y sprites exponen `cell`, `sprite`, `snap_to_grid`, `blocks_path`, `gem_id`, `level` y las propiedades nativas de `Sprite2D`, como `scale` y `rotation`. Se pueden mover desde la vista 2D, cambiar de escala o reemplazar la textura desde el Inspector. Duplicar o borrar un nodo dentro de `Obstacles` agrega o quita un obstáculo lógico.

La escena authored se muestra como mapa completo, centrado y ajustado al panel de gameplay al iniciar. El panel usa el mismo verde base del tile de pasto para que el espacio exterior también conserve ese color al alejar el zoom. La lógica continúa usando la grilla 36×36 y `data/gameplay/initial_map.tres`; las `GemInstance`, piedras, enemigos y proyectiles siguen gestionados por sus runtimes y no se pisan con los marcadores authored estáticos.

Para guardar cambios en Godot: abrir `src/gameplay/map/map.tscn`, editar desde la vista 2D o el panel TileMap inferior y presionar `Ctrl+S`.

## Atribución de assets

Los recursos de `cute_fantasy` provienen del pack Cute Fantasy Free. Según su `read_me.txt`, se pueden modificar y usar en proyectos no comerciales, pero no se puede redistribuir el pack de forma aislada.
