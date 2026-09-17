extends SceneTree

const MAP_PATH := "res://src/gameplay/map/map.tscn"
const GENERATED_DIR := "res://assets/art/gameplay/environment/generated/map_objects"
const CATEGORY_FOLDERS := {
	"tree": "Trees",
	"bush": "Bushes",
	"stone": "Stones",
	"prop": "Props",
	"structure": "Structures",
	"landmark": "Landmarks",
}

var generated_count := 0
var consolidated_count := 0

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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GENERATED_DIR))

	var folders := _ensure_category_folders(map, world_sort)
	var used_names: Dictionary = {}
	for object: MapDecorationObject in _collect_objects(world_sort):
		object.name = _unique_name(_descriptive_name(object), used_names)
		object.add_to_group("map_decoration_%s" % object.category, true)
		var folder_name: String = CATEGORY_FOLDERS.get(object.category, "Props")
		var folder := folders[folder_name] as Node2D
		if object.get_parent() != folder:
			object.owner = null
			object.reparent(folder, true)
			object.owner = map
		_consolidate_object(map, object)

	if generated_count > 0:
		print("Generated %d consolidated textures. Import the project and run this tool again." % generated_count)
		quit(2)
		return

	var output := PackedScene.new()
	var pack_error := output.pack(map)
	if pack_error != OK:
		push_error("Cannot pack consolidated map: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(output, MAP_PATH)
	if save_error != OK:
		push_error("Cannot save consolidated map: %s" % error_string(save_error))
		quit(1)
		return
	print("Consolidated %d decoration objects into one Sprite2D each" % consolidated_count)
	quit(0)

func _consolidate_object(map: MapEditorRoot, object: MapDecorationObject) -> void:
	if object.get_child_count() != 1:
		return
	var visual_root := object.get_child(0)
	if visual_root is Sprite2D:
		(visual_root as Sprite2D).name = "Visual"
		return
	if not visual_root is Node2D:
		return
	var fragments: Array[Sprite2D] = []
	for child in visual_root.get_children():
		if child is Sprite2D and (child as Sprite2D).texture != null:
			fragments.append(child as Sprite2D)
	if fragments.is_empty():
		return

	var bounds := _fragment_bounds(fragments[0])
	for index in range(1, fragments.size()):
		bounds = bounds.merge(_fragment_bounds(fragments[index]))
	var image_size := Vector2i(maxi(1, ceili(bounds.size.x)), maxi(1, ceili(bounds.size.y)))
	var image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for fragment in fragments:
		var source := fragment.texture.get_image()
		if source == null:
			push_warning("Cannot read fragment texture for %s" % object.name)
			return
		source.convert(Image.FORMAT_RGBA8)
		var target_size := Vector2i(maxi(1, roundi(source.get_width() * absf(fragment.scale.x))), maxi(1, roundi(source.get_height() * absf(fragment.scale.y))))
		if source.get_size() != target_size:
			source.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		if fragment.flip_h:
			source.flip_x()
		if fragment.flip_v:
			source.flip_y()
		var fragment_bounds := _fragment_bounds(fragment)
		var destination := Vector2i(roundi(fragment_bounds.position.x - bounds.position.x), roundi(fragment_bounds.position.y - bounds.position.y))
		image.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), destination)

	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(image.get_data())
	var hash := hash_context.finish().hex_encode().substr(0, 12)
	var category_dir := "%s/%s" % [GENERATED_DIR, _category_folder(object.category)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(category_dir))
	var texture_path := "%s/%s_%s.png" % [category_dir, str(object.asset_id).to_snake_case(), hash]
	if not FileAccess.file_exists(texture_path):
		var image_error := image.save_png(texture_path)
		if image_error != OK:
			push_error("Cannot save %s: %s" % [texture_path, error_string(image_error)])
			return
		generated_count += 1
		return
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_warning("Waiting for Godot import: %s" % texture_path)
		generated_count += 1
		return

	var center := bounds.get_center()
	visual_root.free()
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = texture
	visual.position = center
	object.add_child(visual)
	visual.owner = map
	consolidated_count += 1

func _ensure_category_folders(map: MapEditorRoot, world_sort: Node2D) -> Dictionary:
	var result: Dictionary = {}
	for folder_name: String in CATEGORY_FOLDERS.values():
		var folder := world_sort.get_node_or_null(folder_name) as Node2D
		if folder == null:
			folder = Node2D.new()
			folder.name = folder_name
			world_sort.add_child(folder)
			folder.owner = map
		folder.y_sort_enabled = true
		folder.z_index = 0
		result[folder_name] = folder
	return result

func _collect_objects(node: Node) -> Array[MapDecorationObject]:
	var result: Array[MapDecorationObject] = []
	for child in node.get_children():
		if child is MapDecorationObject:
			result.append(child as MapDecorationObject)
		else:
			result.append_array(_collect_objects(child))
	return result

func _fragment_bounds(fragment: Sprite2D) -> Rect2:
	var texture_size := fragment.texture.get_size() * fragment.scale.abs()
	return Rect2(fragment.position - texture_size * 0.5, texture_size)

func _descriptive_name(object: MapDecorationObject) -> String:
	var asset := str(object.asset_id).to_pascal_case()
	if object.category == "landmark":
		if str(object.asset_id).begins_with("cp"):
			return "Landmark_Checkpoint_%02d" % int(str(object.asset_id).trim_prefix("cp"))
		if object.asset_id == &"spawn":
			return "Landmark_SpawnPortal"
		if object.asset_id == &"castle":
			return "Landmark_Castle"
	return "%s_%s_C%02d_R%02d" % [object.category.to_pascal_case(), asset, object.cell.x, object.cell.y]

func _category_folder(category: String) -> String:
	match category:
		"tree":
			return "trees"
		"bush":
			return "bushes"
		"stone":
			return "stones"
		"structure":
			return "structures"
		"landmark":
			return "landmarks"
		_:
			return "props"

func _unique_name(base_name: String, used_names: Dictionary) -> String:
	var count := int(used_names.get(base_name, 0)) + 1
	used_names[base_name] = count
	return base_name if count == 1 else "%s_%02d" % [base_name, count]
