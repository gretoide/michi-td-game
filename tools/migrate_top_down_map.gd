extends SceneTree

const MAP_PATH := "res://src/gameplay/map/map.tscn"
const TERRAIN_TILESET_PATH := "res://data/gameplay/terrain_tileset.tres"
const FLAT_TILESET_PATH := "res://data/gameplay/flat_decoration_tileset.tres"
const FENCE_TILESET_PATH := "res://data/gameplay/fence_tileset.tres"
const DecorationObjectScript = preload("res://src/gameplay/map/map_decoration_object.gd")
const CATEGORY_FOLDERS := {
	"tree": "Trees",
	"bush": "Bushes",
	"stone": "Stones",
	"prop": "Props",
	"structure": "Structures",
	"landmark": "Landmarks",
}

const TALL_SOURCES := {
	1: {"id": "bush", "category": "bush"},
	2: {"id": "tree", "category": "tree"},
	3: {"id": "stone", "category": "stone"},
	5: {"id": "oak_small", "category": "tree"},
	6: {"id": "oak", "category": "tree"},
	7: {"id": "maple", "category": "tree"},
	10: {"id": "house", "category": "structure"},
}

func _init() -> void:
	var packed := load(MAP_PATH) as PackedScene
	if packed == null:
		push_error("Cannot load %s" % MAP_PATH)
		quit(1)
		return
	var map := packed.instantiate() as MapEditorRoot
	root.add_child(map)
	var world_sort := map.get_node_or_null("WorldYSort") as Node2D
	if world_sort == null:
		push_error("WorldYSort is missing")
		quit(1)
		return
	_ensure_category_folders(map, world_sort)

	_externalize_tilesets(map)
	var converted := 0
	for layer_path in ["Decorations/FlatDetails", "Decorations/FlatDetailsForeground"]:
		var layer := map.get_node_or_null(layer_path) as TileMapLayer
		if layer != null:
			converted += _convert_tall_components(map, world_sort, layer)

	_move_landmark(map, world_sort, "Path/Spawn/SpawnerVisual", "SpawnVisual", &"spawn", "landmark")
	for checkpoint_index in range(1, 6):
		var label := "CP%02d" % checkpoint_index
		_move_landmark(map, world_sort, "Path/Checkpoints/%s/FlagVisual" % label, "%sVisual" % label, StringName(label.to_lower()), "landmark")
	_move_landmark(map, world_sort, "Path/Endpoint/CastleVisual", "CastleVisual", &"castle", "landmark")
	_anchor_existing_landmarks(world_sort)

	var output := PackedScene.new()
	var pack_error := output.pack(map)
	if pack_error != OK:
		push_error("Cannot pack migrated map: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(output, MAP_PATH)
	if save_error != OK:
		push_error("Cannot save migrated map: %s" % error_string(save_error))
		quit(1)
		return
	print("Top-down map migration complete: %d tall decoration groups converted" % converted)
	quit(0)

func _externalize_tilesets(map: MapEditorRoot) -> void:
	var ground := map.get_node("Ground") as TileMapLayer
	var flat := map.get_node("Decorations/FlatDetails") as TileMapLayer
	var flat_front := map.get_node("Decorations/FlatDetailsForeground") as TileMapLayer
	var fences := map.get_node("Decorations/Fences") as TileMapLayer
	_save_tileset(ground, TERRAIN_TILESET_PATH)
	_remove_unused_scene_sources(flat, flat_front)
	_save_tileset(flat, FLAT_TILESET_PATH)
	flat_front.tile_set = flat.tile_set
	_save_tileset(fences, FENCE_TILESET_PATH)

func _save_tileset(layer: TileMapLayer, path: String) -> void:
	var resource := layer.tile_set.duplicate(true) as TileSet
	var save_error := ResourceSaver.save(resource, path)
	if save_error != OK:
		push_error("Cannot save TileSet %s: %s" % [path, error_string(save_error)])
		return
	layer.tile_set = load(path) as TileSet

func _remove_unused_scene_sources(flat: TileMapLayer, flat_front: TileMapLayer) -> void:
	var removable: Array[int] = []
	for index in flat.tile_set.get_source_count():
		var source_id := flat.tile_set.get_source_id(index)
		if not flat.tile_set.get_source(source_id) is TileSetScenesCollectionSource:
			continue
		var used := flat.get_used_cells_by_id(source_id).size() + flat_front.get_used_cells_by_id(source_id).size()
		if used == 0:
			removable.append(source_id)
		else:
			push_warning("Unrecognized scene-tile group from source %d preserved (%d cells)" % [source_id, used])
	for source_id in removable:
		flat.tile_set.remove_source(source_id)

func _convert_tall_components(map: MapEditorRoot, world_sort: Node2D, layer: TileMapLayer) -> int:
	var buckets: Dictionary = {}
	for cell: Vector2i in layer.get_used_cells():
		var source_id := layer.get_cell_source_id(cell)
		if not TALL_SOURCES.has(source_id):
			continue
		if not buckets.has(source_id):
			buckets[source_id] = []
		buckets[source_id].append(cell)
	var converted := 0
	for source_id: int in buckets:
		var pending: Dictionary = {}
		for cell: Vector2i in buckets[source_id]:
			pending[cell] = true
		while not pending.is_empty():
			var first: Vector2i = pending.keys()[0]
			var queue: Array[Vector2i] = [first]
			var component: Array[Vector2i] = []
			pending.erase(first)
			while not queue.is_empty():
				var current: Vector2i = queue.pop_front() as Vector2i
				component.append(current)
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = current + direction
					if pending.has(neighbor):
						pending.erase(neighbor)
						queue.append(neighbor)
			_create_object_from_component(map, world_sort, layer, source_id, component, converted)
			for cell: Vector2i in component:
				layer.erase_cell(cell)
			converted += 1
	return converted

func _create_object_from_component(map: MapEditorRoot, world_sort: Node2D, layer: TileMapLayer, source_id: int, cells: Array[Vector2i], serial: int) -> void:
	var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null:
		return
	var visual_bounds := Rect2()
	var visual_data: Array[Dictionary] = []
	for cell: Vector2i in cells:
		var atlas_coords := layer.get_cell_atlas_coords(cell)
		var region := source.get_tile_texture_region(atlas_coords)
		var tile_data := layer.get_cell_tile_data(cell)
		var origin := Vector2(tile_data.texture_origin) if tile_data != null else Vector2.ZERO
		var center := layer.map_to_local(cell) + origin
		var rect := Rect2(center - region.size * 0.5, region.size)
		visual_bounds = rect if visual_data.is_empty() else visual_bounds.merge(rect)
		visual_data.append({"center": center, "region": region})
	var meta: Dictionary = TALL_SOURCES[source_id]
	var object := DecorationObjectScript.new() as MapDecorationObject
	object.name = "%s_%03d" % [str(meta["id"]).to_pascal_case(), serial]
	object.asset_id = StringName(meta["id"])
	object.category = str(meta["category"])
	object.snap_to_grid = false
	object.blocks_path = false
	object.remove_on_build = true
	var footprint := Rect2i(
		Vector2i(floori(visual_bounds.position.x / 16.0), floori(visual_bounds.position.y / 16.0)),
		Vector2i(maxi(1, ceili(visual_bounds.size.x / 16.0)), maxi(1, ceili(visual_bounds.size.y / 16.0)))
	)
	object.cell = Vector2i(floori(visual_bounds.get_center().x / 16.0), floori(visual_bounds.end.y / 16.0) - 1)
	object.footprint_offset = footprint.position - object.cell
	object.footprint_size = footprint.size
	object.position = Vector2(visual_bounds.get_center().x, visual_bounds.end.y)
	_decoration_parent(world_sort, object.category).add_child(object)
	object.owner = map
	var visual := Node2D.new()
	visual.name = "Visual"
	object.add_child(visual)
	visual.owner = map
	for item: Dictionary in visual_data:
		var atlas := AtlasTexture.new()
		atlas.atlas = source.texture
		atlas.region = item["region"]
		atlas.filter_clip = true
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = atlas
		sprite.position = item["center"] - object.position
		visual.add_child(sprite)
		sprite.owner = map

func _move_landmark(map: MapEditorRoot, world_sort: Node2D, path: String, object_name: String, asset_id: StringName, category: String) -> void:
	var visual := map.get_node_or_null(path) as CanvasItem
	if visual == null:
		return
	var logical_point := visual.get_parent() as Node2D
	var object := DecorationObjectScript.new() as MapDecorationObject
	object.name = object_name
	object.asset_id = asset_id
	object.category = category
	object.remove_on_build = false
	object.snap_to_grid = false
	object.blocks_path = false
	object.position = logical_point.position
	if logical_point is MapEditablePoint:
		object.cell = (logical_point as MapEditablePoint).cell
	_decoration_parent(world_sort, category).add_child(object)
	object.owner = map
	visual.owner = null
	visual.reparent(object, true)
	visual.owner = map
	visual.z_index = 0
	visual.z_as_relative = true

func _anchor_existing_landmarks(world_sort: Node) -> void:
	for child in world_sort.get_children():
		var object := child as MapDecorationObject
		if object == null:
			_anchor_existing_landmarks(child)
			continue
		if object.category != "landmark" or object.get_child_count() != 1:
			continue
		var sprite := object.get_child(0) as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var scaled_size := sprite.texture.get_size() * sprite.scale.abs()
		var ground_shift := Vector2(sprite.position.x, sprite.position.y + scaled_size.y * 0.5)
		object.position += ground_shift
		sprite.position -= ground_shift

func _ensure_category_folders(map: MapEditorRoot, world_sort: Node2D) -> void:
	for folder_name: String in CATEGORY_FOLDERS.values():
		var folder := world_sort.get_node_or_null(folder_name) as Node2D
		if folder == null:
			folder = Node2D.new()
			folder.name = folder_name
			folder.y_sort_enabled = true
			folder.z_index = 0
			world_sort.add_child(folder)
			folder.owner = map

func _decoration_parent(world_sort: Node2D, category: String) -> Node2D:
	var folder_name: String = CATEGORY_FOLDERS.get(category, "Props")
	return world_sort.get_node(folder_name) as Node2D
