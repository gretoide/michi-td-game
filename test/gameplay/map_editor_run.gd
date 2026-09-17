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
	var decoration_tiles := authored.get_node("Decorations/FlatDetails") as TileMapLayer
	var decoration_foreground := authored.get_node("Decorations/FlatDetailsForeground") as TileMapLayer
	var world_y_sort := authored.get_node("WorldYSort") as Node2D
	assert(ground != null)
	assert(ground.tile_set != null)
	assert(ground.tile_set.tile_size == Vector2i(16, 16))
	assert(ground.tile_set.get_source_count() == 8)
	assert(ground.z_index == -100)
	assert((ground.tile_set.get_source(0) as TileSetAtlasSource).get_texture_region_size() == Vector2i(16, 16))
	assert(ground.get_used_rect() == Rect2i(0, 0, 64, 40))
	assert(fences != null)
	assert(decoration_tiles != null)
	assert(decoration_tiles.z_index == -50)
	assert(fences.z_index == -40)
	assert(decoration_tiles.tile_set != null)
	assert(decoration_foreground.tile_set == decoration_tiles.tile_set)
	assert(decoration_tiles.tile_set.get_source_count() == 11)
	for tall_source_id in [1, 2, 3, 5, 6, 7, 10]:
		assert(decoration_tiles.get_used_cells_by_id(tall_source_id).is_empty())
		assert(decoration_foreground.get_used_cells_by_id(tall_source_id).is_empty())
	assert(decoration_tiles.tile_set.resource_path == "res://data/gameplay/flat_decoration_tileset.tres")
	assert(ground.tile_set.resource_path == "res://data/gameplay/terrain_tileset.tres")
	assert(fences.tile_set.resource_path == "res://data/gameplay/fence_tileset.tres")
	assert(fences.get_used_cells().size() == 218)
	assert(world_y_sort.y_sort_enabled)
	assert(world_y_sort.z_index == 0)
	assert(world_y_sort.get_child_count() == 6)
	for folder_name in ["Trees", "Bushes", "Stones", "Props", "Structures", "Landmarks"]:
		var folder := world_y_sort.get_node(folder_name) as Node2D
		assert(folder.y_sort_enabled)
	var decoration_objects := _collect_decoration_objects(world_y_sort)
	assert(decoration_objects.size() >= 35)
	for object in decoration_objects:
		assert(object is MapDecorationObject)
		assert((object as MapDecorationObject).z_index == 0)
		assert(not str(object.name).begins_with("Maple_"))
		assert(object.get_node_or_null("Visual") is Sprite2D)
		var visual := object.get_node("Visual")
		assert(visual is Sprite2D)
		assert(visual.name == "Visual")
		assert(not str(visual.name).contains("@Sprite2D"))
		var category := (object as MapDecorationObject).category
		assert(object.is_in_group("map_decoration_%s" % category))
	assert(not authored.has_node("Decorations/ObjectsAboveEnemies"))
	assert(not authored.has_node("Decorations/BehindTerrain"))
	assert(authored.get_node("WorldYSort/Landmarks/Landmark_SpawnPortal") is MapDecorationObject)
	assert(authored.get_node("WorldYSort/Landmarks/Landmark_Checkpoint_01") is MapDecorationObject)
	assert(authored.get_node("WorldYSort/Landmarks/Landmark_Castle") is MapDecorationObject)
	for lamp_path in ["lamp.tscn", "lamp_02.tscn", "lamp_03.tscn", "lamp_04.tscn", "lamp_05.tscn", "lamp_06.tscn"]:
		var lamp_scene := load("res://assets/art/gameplay/environment/props/lamps/%s" % lamp_path) as PackedScene
		var lamp := lamp_scene.instantiate() as MapDecorationObject
		assert(lamp != null)
		assert(lamp.category == "prop")
		assert(not lamp.snap_to_grid)
		assert(lamp.get_node("Visual") is Sprite2D)
		lamp.free()
	var props := authored.get_node("WorldYSort/Props")
	var lamp_count := 0
	for prop in props.get_children():
		if prop.name.begins_with("Lamp_"):
			lamp_count += 1
	assert(lamp_count == 10)
	assert(authored.get_node("Foreground").z_index == 50)
	assert(authored.get_node("WorldEffects").z_index == 75)
	for x in range(1, 63):
		assert(fences.get_cell_source_id(Vector2i(x, 0)) >= 0)
		assert(fences.get_cell_source_id(Vector2i(x, 39)) >= 0)
	for y in range(1, 39):
		assert(fences.get_cell_source_id(Vector2i(0, y)) >= 0)
		assert(fences.get_cell_source_id(Vector2i(63, y)) >= 0)
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

func _collect_decoration_objects(node: Node) -> Array[MapDecorationObject]:
	var result: Array[MapDecorationObject] = []
	for child in node.get_children():
		if child is MapDecorationObject:
			result.append(child as MapDecorationObject)
		else:
			result.append_array(_collect_decoration_objects(child))
	return result
