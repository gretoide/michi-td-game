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
	var index := DecorationFootprintIndex.new()
	index.rebuild(authored)
	var complete_tree: Dictionary = {}
	var tree: MapDecorationObject
	var largest_area := 0.0
	for group: Dictionary in index.groups:
		var entries: Array = group.get("entries", [])
		if entries.size() == 1 and entries[0].has("object"):
			var candidate := entries[0]["object"] as MapDecorationObject
			var area := (group.get("bounds", Rect2()) as Rect2).get_area()
			if candidate != null and candidate.category == "tree" and candidate.remove_on_build and area > largest_area:
				complete_tree = group
				tree = candidate
				largest_area = area
			if candidate != null:
				suite.expect(candidate.remove_on_build, "protected landmarks stay outside the decoration removal index")
	suite.expect(not complete_tree.is_empty(), "decoration index finds a complete multi-cell tree object")
	var fences := authored.get_node("Decorations/Fences") as TileMapLayer
	var fence_count := fences.get_used_cells().size()
	if tree != null:
		var target := complete_tree["bounds"] as Rect2
		var hits := index.groups_for_placement(Rect2(target.get_center() - Vector2.ONE, Vector2.ONE * 2.0))
		suite.expect(hits.has(complete_tree), "a cell inside the tree resolves to the complete object footprint")
		index.erase_group(complete_tree)
		suite.expect(tree.is_queued_for_deletion(), "placing a gem queues the complete tree object for removal")
	suite.expect_equal(fences.get_used_cells().size(), fence_count, "removing a decoration never touches fences")
	authored.free()
