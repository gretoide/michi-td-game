extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(20260916)
	assert(errors.is_empty())
	var gameplay: Node = (load("res://src/gameplay/gameplay_view.gd") as GDScript).new() as Node
	gameplay.size = Vector2(1280, 720)
	root.add_child(gameplay)
	gameplay.setup(runtime)
	await process_frame
	gameplay.size = Vector2(1280, 720)
	await process_frame
	var xp_bar := gameplay.get("xp_bar") as ProgressBar
	var probability_panel := gameplay.get("xp_probability_panel") as PanelContainer
	var probability_label := gameplay.get("xp_probability_label") as Label
	var enemy_count_separator := gameplay.get("enemy_count_separator") as Label
	assert(xp_bar != null and probability_panel != null and probability_label != null and enemy_count_separator != null)
	assert(enemy_count_separator.text == "│")
	assert("100%" in xp_bar.tooltip_text)
	assert("0%" in probability_label.text and probability_label.text.count("0%") >= 4)
	runtime.progression.add_xp(2400)
	gameplay._refresh_ui()
	assert("70%" in xp_bar.tooltip_text and "30%" in probability_label.text)
	var map_view: Variant = gameplay.get("map_view")
	var world_sort := map_view.authored_map.get_node("WorldYSort") as Node2D
	assert(world_sort.y_sort_enabled)
	assert(map_view.authored_map.z_index == 0)
	assert((map_view.authored_map.get_node("Ground") as TileMapLayer).visible)
	assert((map_view.authored_map.get_node("Decorations/FlatDetails") as TileMapLayer).visible)
	var probe_cell := Vector2i(12, 12)
	var probe_position: Vector2 = map_view._cell_view_position(probe_cell, Vector2.ONE * 0.5)
	assert(map_view._cell_at(probe_position) == probe_cell)
	for mapping_cell in [Vector2i(14, 22), Vector2i(30, 35)]:
		var mapping_position: Vector2 = map_view._cell_view_position(mapping_cell, Vector2.ONE * 0.5)
		assert(map_view._cell_at(mapping_position) == mapping_cell)
		var authored_position: Vector2 = map_view.authored_map.to_global((map_view.authored_map as MapEditorRoot).logical_cell_base_to_authored(mapping_cell, 0.5))
		assert(authored_position.is_equal_approx(map_view.global_position + mapping_position))
	for route_cell in [Vector2i(5, 19), Vector2i(19, 5), Vector2i(33, 32)]:
		assert(map_view._cell_at(map_view._cell_view_position(route_cell, Vector2.ONE * 0.5)) == route_cell)
	var zoom_focus: Vector2 = map_view._cell_view_position(Vector2i(20, 15), Vector2.ONE * 0.5)
	var focus_before: Vector2i = map_view._cell_at(zoom_focus)
	map_view._zoom_at(zoom_focus, 0.4)
	map_view._clamp_pan()
	map_view.sync_gem_sprites()
	assert(map_view._cell_at(zoom_focus) == focus_before)
	map_view._zoom_at(zoom_focus, -0.4)
	map_view._clamp_pan()
	map_view.sync_gem_sprites()
	assert(map_view._cell_at(zoom_focus) == focus_before)

	var gem := runtime.construction.place_existing(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), Vector2i(12, 12))
	assert(gem != null)
	map_view.sync_gem_sprites()
	var gem_visual := gameplay._gem_nodes[str(gem.get_instance_id())] as Node2D
	assert(gem_visual.get_parent() == world_sort)
	assert(gem_visual.z_index == 0)
	assert(gem_visual.position.is_equal_approx(map_view.authored_map.logical_cell_base_to_authored(gem.cell, 0.5)))
	assert(map_view.authored_map.to_global(gem_visual.position).is_equal_approx(map_view.global_position + map_view._cell_view_position(gem.cell, Vector2.ONE * 0.5)))
	assert(gameplay._recipe_reference_state(gem.id, gem.level) == 1)
	runtime.phases.resolve_construction()
	assert(gameplay._recipe_reference_state(gem.id, gem.level) == 2)
	runtime._sync_combat_towers()
	assert(runtime.combat.towers.size() == 1)
	assert(map_view._tower_at_cell(probe_cell) == runtime.combat.towers[0])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = probe_position
	map_view._gui_input(click)
	assert(gameplay.selection.kind == SelectionState.Kind.TOWER)

	var profile: Resource = runtime.foundation.catalog.enemy_profiles[0]
	var enemy := runtime.combat.spawn_enemy(profile, Vector2i(12, 11))
	assert(enemy != null)
	map_view.queue_enemy_redraw()
	var enemy_visual := map_view.enemy_nodes[str(enemy.get_instance_id())] as Node2D
	assert(enemy_visual.get_parent() == world_sort)
	assert(enemy_visual.z_index == 0)
	assert(enemy_visual.position.y < gem_visual.position.y)

	map_view.map_zoom = 1.6
	map_view.map_pan = Vector2(-90, -50)
	map_view.sync_gem_sprites()
	assert(gem_visual.position.is_equal_approx(map_view.authored_map.logical_cell_base_to_authored(gem.cell, GemAssetLibrary.TOWER_BASE_CELL_Y)))
	assert(is_equal_approx(map_view.authored_map.scale.x, map_view.authored_map.scale.y))
	print("Top-down runtime Y-sort tests passed")
	gameplay.free()
	quit(0)
