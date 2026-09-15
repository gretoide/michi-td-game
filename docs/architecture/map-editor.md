# Editor 2D del mapa

El mapa authored está en `src/gameplay/map/map.tscn` y se instancia como `Map` dentro de `src/main.tscn`. La escena contiene:

- `Path/Spawn`, `Path/Checkpoints/CP01..CP05` y `Path/Endpoint` para el camino y sus puntos.
- `Obstacles` con nodos `MapObstacle` editables.
- `Gems` con marcadores `MapGemMarker` que no reemplazan las gemas generadas por las rondas.
- `Decorations` con nodos `MapDecorationMarker`.

Los puntos y sprites exponen `cell`, `sprite`, `snap_to_grid`, `blocks_path`, `gem_id`, `level` y las propiedades nativas de `Sprite2D`, como `scale` y `rotation`. Se pueden mover desde la vista 2D, cambiar de escala o reemplazar la textura desde el Inspector. Duplicar o borrar un nodo dentro de `Obstacles` agrega o quita un obstáculo lógico.

La escena authored queda aislada del runtime de la partida para preservar el mapa visual y la generación existentes. La partida continúa usando `data/gameplay/initial_map.tres`; las `GemInstance` y piedras que nacen durante las rondas siguen gestionadas por `ConstructionRuntime` y no se pisan con los marcadores de esta escena.

Para guardar cambios en Godot: abrir `src/gameplay/map/map.tscn` o expandir el nodo `Map` en `main.tscn`, editar y presionar `Ctrl+S`.
