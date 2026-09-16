extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var object_scene := load("res://assets/art/gameplay/environment/tilesets/map_decoration_object.tscn") as PackedScene
	var object := object_scene.instantiate() as MapDecorationObject
	object.cell = Vector2i(8, 9)
	object.footprint_offset = Vector2i(-1, -2)
	object.footprint_size = Vector2i(3, 4)
	suite.expect_equal(object.authored_footprint(), Rect2i(7, 7, 3, 4), "editable decoration exposes its authored footprint")
	suite.expect(not object.blocks_path, "decoration objects never block construction or navigation")
	object.free()

	var map_scene := load("res://src/gameplay/map/map.tscn") as PackedScene
	var authored := map_scene.instantiate()
	var decorations := authored.get_node("Decorations") as Node2D
	var index := DecorationFootprintIndex.new()
	index.rebuild(decorations)
	var authored_root := authored as MapEditorRoot
	var target := authored_root.logical_cell_to_authored_rect(Vector2i(7, 12))
	var hits := index.groups_for_placement(target)
	var complete_tree: Dictionary = {}
	for group: Dictionary in hits:
		if group["entries"].size() == 20:
			complete_tree = group
			break
	suite.expect(not complete_tree.is_empty(), "decoration index finds a complete multi-cell tree")
	var foreground := decorations.get_node("DecorationForeground") as TileMapLayer
	var before := foreground.get_used_cells().size()
	if not complete_tree.is_empty():
		index.erase_group(complete_tree)
		suite.expect_equal(foreground.get_used_cells().size(), before - 20, "placing a gem removes every tile of the tree asset")
	suite.expect_equal(foreground.get_used_cells().size(), 172, "unrelated foreground decoration tiles remain")
	authored.free()
