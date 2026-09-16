extends SceneTree

func _init() -> void:
	var map_scene := load("res://src/gameplay/map/map.tscn") as PackedScene
	var authored := map_scene.instantiate()
	root.add_child(authored)
	await process_frame
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(20260915)
	if not errors.is_empty():
		push_error("Map editor runtime test failed: " + "; ".join(errors))
		quit(1)
		return
	var layout := authored.authored_layout() as MapLayout
	var ground := authored.get_node("Ground") as TileMapLayer
	var fences := authored.get_node("Decorations/Fences") as TileMapLayer
	var decoration_tiles := authored.get_node("Decorations/DecorationTiles") as TileMapLayer
	assert(ground != null)
	assert(ground.tile_set != null)
	assert(ground.tile_set.tile_size == Vector2i(16, 16))
	assert(ground.tile_set.get_source_count() == 8)
	assert((ground.tile_set.get_source(0) as TileSetAtlasSource).get_texture_region_size() == Vector2i(16, 16))
	assert(ground.get_used_rect() == Rect2i(0, 0, 64, 40))
	assert(fences != null)
	assert(decoration_tiles != null)
	assert(decoration_tiles.tile_set != null)
	assert(decoration_tiles.tile_set.get_source_count() == 12)
	assert(fences.get_used_cells().size() == 204)
	assert(authored.get_node("Decorations/FarmMapleTree") is MapDecorationMarker)
	assert(authored.get_node("Decorations/FarmSpringCrop") is MapDecorationMarker)
	assert(authored.get_node("Decorations/FarmRoadDetail") is MapDecorationMarker)
	assert(authored.get_node("Decorations/StoneNorth") is MapDecorationMarker)
	assert(authored.get_node("Decorations/StoneWest") is MapDecorationMarker)
	assert(authored.get_node("Decorations/StoneEast") is MapDecorationMarker)
	for x in range(1, 63):
		assert(fences.get_cell_atlas_coords(Vector2i(x, 39)) == fences.get_cell_atlas_coords(Vector2i(x, 0)))
	for y in range(1, 39):
		assert(fences.get_cell_atlas_coords(Vector2i(63, y)) == fences.get_cell_atlas_coords(Vector2i(0, y)))
	assert(layout.spawn == Vector2i(9, 3))
	assert(layout.endpoint == Vector2i(59, 35))
	assert(layout.checkpoints[4] == Vector2i(34, 35))
	assert(layout.checkpoints.size() == 5)
	assert(layout.obstacles.is_empty())
	assert(runtime.map.route_cells.size() > 7)
	assert(runtime.pathfinder.find_route(runtime.map).size() == runtime.map.route_cells.size())
	assert(runtime.construction.can_place_at(Vector2i(22, 9)), "decorative stone cell remains buildable")
	assert(not runtime.construction.can_place_at(runtime.map.checkpoints[0]), "checkpoint remains reserved")
	print("Map editor scene/runtime tests passed")
	quit(0)
