extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var runtime := GameRuntime.new(); suite.expect(runtime.initialize(12).is_empty(), "M2 runtime initializes from bootstrap catalog")
	var c := runtime.construction
	suite.expect(c.place_existing(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), Vector2i(5, 3)) == null, "reserved waypoint placement is rejected")
	suite.expect_equal(c.placed_count(), 0, "rejected reserved placement does not mutate construction")
	var first := c.place_existing(GemInstance.new(&"amethyst", 1, GemInstance.Quality.CHIPPED), Vector2i(8, 8))
	suite.expect(first != null, "valid placement is accepted")
	suite.expect(c.place_existing(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), Vector2i(8, 8)) == null, "duplicate placement is rejected")
	suite.expect(c.place_existing(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), Vector2i(-1, 8)) == null, "out of bounds placement is rejected")
	for cell in [Vector2i(9,8), Vector2i(10,8), Vector2i(11,8), Vector2i(12,8)]:
		suite.expect(c.place_existing(GemInstance.new(&"amethyst", 1, GemInstance.Quality.CHIPPED), cell) != null, "additional valid placements are accepted")
	suite.expect_equal(c.placed_count(), 5, "construction reaches five placements")
	var selected_cell := Vector2i(10, 8)
	suite.expect(c.select_board_gem(selected_cell) != null and c.selected_board_gem.cell == selected_cell, "Construction selects an existing gem without placing another")
	var contextual := c.contextual_combinations(c.selected_board_gem)
	suite.expect(not contextual.is_empty(), "contextual combinations use the selected gem")
	if not contextual.is_empty():
		suite.expect_equal(contextual[0].pool, &"construction_current", "construction options use only the current five-gem pool")
		suite.expect(c.execute_contextual_combination(c.selected_board_gem, {"kind": &"invalid"}) == null, "an option not returned by the matcher cannot execute")
	var options := c.basic_combinations(); suite.expect(not options.is_empty(), "basic combination is detected among current five")
	var result := c.execute_contextual_combination(c.selected_board_gem)
	suite.expect(result != null, "basic combination executes")
	suite.expect_equal(runtime.phases.phase, GamePhaseMachine.Phase.COMBAT, "successful combination enters combat")

	var cross_round := GameRuntime.new(); cross_round.initialize(17)
	var retained := GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED)
	retained.cell = Vector2i(7, 7); cross_round.grid.occupy(retained.cell); cross_round.construction.board_gems.append(retained)
	for index in 5:
		var fresh := GemInstance.new(&"ruby" if index == 0 else &"topaz", 1, GemInstance.Quality.CHIPPED)
		cross_round.construction.place_existing(fresh, Vector2i(8 + index, 8))
	var cross_options := cross_round.construction.find_construction_options(retained)
	suite.expect(cross_options.is_empty(), "One Shot does not mix retained board gems into the current construction pool")

	var keep_runtime := GameRuntime.new(); keep_runtime.initialize(13)
	var keep_cells := [Vector2i(8,8), Vector2i(9,8), Vector2i(10,8), Vector2i(11,8), Vector2i(12,8)]
	for cell in keep_cells:
		keep_runtime.construction.place_existing(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), cell)
	var kept := keep_runtime.construction.current_gems[0]
	suite.expect(keep_runtime.construction.keep(kept), "Keep finalizes a full construction")
	suite.expect_equal(keep_runtime.construction.stones.size(), 4, "Keep converts four unselected gems to stones")
	suite.expect(not keep_runtime.construction.select_stone(keep_cells[1]), "Combat cannot select a stone for construction actions")
	suite.expect(not keep_runtime.construction.remove_stone(keep_cells[1]), "Combat cannot remove a stone")
	keep_runtime.phases.resolve_combat()
	suite.expect(keep_runtime.construction.select_stone(keep_cells[1]), "Construction can select an existing stone without placing a gem")
	suite.expect(keep_runtime.construction.remove_stone(keep_cells[1]), "Remove Stone releases a stone cell during construction")

	var degrade_runtime := GameRuntime.new(); degrade_runtime.initialize(14)
	for index in 5:
		var degraded_gem := GemInstance.new(&"sapphire", 2, GemInstance.Quality.FLAWED)
		degrade_runtime.construction.place_existing(degraded_gem, Vector2i(8 + index, 8))
	var degraded := degrade_runtime.construction.degrade(degrade_runtime.construction.current_gems[0])
	suite.expect(degraded != null and degraded.quality == GemInstance.Quality.CHIPPED, "Degrade lowers quality exactly one step")
	suite.expect_equal(degrade_runtime.construction.stones.size(), 4, "Degrade converts remaining gems to stones")

	var one_shot_runtime := GameRuntime.new(); one_shot_runtime.initialize(15)
	var one_shot_ids: Array[StringName] = [&"sapphire", &"topaz", &"diamond", &"ruby", &"opal"]
	for index in one_shot_ids.size():
		one_shot_runtime.construction.place_existing(GemInstance.new(one_shot_ids[index], 1, GemInstance.Quality.CHIPPED), Vector2i(8 + index, 10))
	var one_shot_options := one_shot_runtime.construction.find_one_shot_matches()
	suite.expect(not one_shot_options.is_empty(), "One Shot detects a fixture recipe using current five gems")
	if not one_shot_options.is_empty():
		var one_shot_result := one_shot_runtime.construction.execute_recipe(one_shot_options[0].recipe, one_shot_options[0].gems[0], true)
		suite.expect(one_shot_result != null and one_shot_result.mvp_level == 0, "One Shot does not transfer MVP")

	var combat_recipe_runtime := GameRuntime.new(); combat_recipe_runtime.initialize(18)
	var combat_recipe_gems: Array[GemInstance] = [
		GemInstance.new(&"opal", 1, GemInstance.Quality.CHIPPED),
		GemInstance.new(&"emerald", 1, GemInstance.Quality.CHIPPED),
		GemInstance.new(&"aquamarine", 1, GemInstance.Quality.CHIPPED),
		GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED),
	]
	for index in combat_recipe_gems.size():
		var board_gem: GemInstance = combat_recipe_gems[index]
		board_gem.cell = Vector2i(8 + index, 18)
		combat_recipe_runtime.grid.occupy(board_gem.cell)
		combat_recipe_runtime.construction.board_gems.append(board_gem)
	combat_recipe_runtime.phases.resolve_construction()
	var combat_options := combat_recipe_runtime.construction.contextual_combinations(combat_recipe_gems[0])
	suite.expect(not combat_options.is_empty(), "combat exposes exact recipe options for a selected tower")
	if not combat_options.is_empty():
		var combat_result := combat_recipe_runtime.construction.execute_contextual_combination(combat_recipe_gems[0], combat_options[0])
		suite.expect(combat_result != null and combat_result.id == &"malachite", "combat executes the selected recipe option")

	var reset_runtime := GameRuntime.new(); reset_runtime.initialize(16)
	var previous_gem := GemInstance.new(&"emerald", 2, GemInstance.Quality.FLAWED)
	previous_gem.cell = Vector2i(7, 7); previous_gem.round_id = 0
	reset_runtime.grid.occupy(previous_gem.cell); reset_runtime.construction.board_gems.append(previous_gem)
	var previous_stone := StoneInstance.new(&"ruby", Vector2i(7, 8), 0)
	reset_runtime.grid.occupy(previous_stone.cell); reset_runtime.construction.stones[previous_stone.cell] = previous_stone
	var active_cell := Vector2i(8, 8)
	reset_runtime.construction.place_existing(GemInstance.new(&"topaz", 1, GemInstance.Quality.CHIPPED), active_cell)
	reset_runtime.construction.reset_current_round()
	suite.expect(reset_runtime.construction.board_gems.has(previous_gem), "Restart preserves gems from previous rounds")
	suite.expect(reset_runtime.construction.stones.has(previous_stone.cell), "Restart preserves stones from previous rounds")
	suite.expect_equal(reset_runtime.grid.state_at(previous_stone.cell), GridModel.CellState.OCCUPIED, "Restart keeps previous stone cells occupied")
	suite.expect_equal(reset_runtime.construction.placed_count(), 0, "Restart clears active round placements")
	suite.expect(reset_runtime.grid.is_walkable(active_cell), "Restart releases active round cells")

	# Reopen regressions: recipe matching is exact by id, level and
	# multiplicity.  A higher-level ingredient must not satisfy a level-one
	# recipe, and basic combinations must never mix levels.
	var exact_runtime := GameRuntime.new(); exact_runtime.initialize(19)
	var exact_gems: Array[GemInstance] = [
		GemInstance.new(&"sapphire", 1, GemInstance.Quality.CHIPPED),
		GemInstance.new(&"diamond", 1, GemInstance.Quality.CHIPPED),
		GemInstance.new(&"topaz", 2, GemInstance.Quality.FLAWED),
	]
	for index in exact_gems.size():
		exact_runtime.construction.place_existing(exact_gems[index], Vector2i(8 + index, 12))
	var silver := exact_runtime.foundation.catalog.recipe_by_id(&"silver") as RecipeDefinition
	suite.expect(exact_runtime.construction.matcher.match_recipe(silver, exact_runtime.construction.current_gems).is_empty(), "Silver rejects a higher-level Topaz instead of downgrading it")
	exact_gems[2].level = 1
	suite.expect_equal(exact_runtime.construction.matcher.match_recipe(silver, exact_runtime.construction.current_gems).size(), 3, "Silver matches the exact Sapphire, Diamond and Topaz levels")

	var basic_runtime := GameRuntime.new(); basic_runtime.initialize(20)
	for index in 4:
		basic_runtime.construction.place_existing(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), Vector2i(8 + index, 14))
	basic_runtime.construction.place_existing(GemInstance.new(&"ruby", 2, GemInstance.Quality.FLAWED), Vector2i(13, 14))
	var basic_options := basic_runtime.construction.basic_combinations()
	suite.expect_equal(basic_options.size(), 1, "basic recipes expose one same-level group when four gems match")
	if not basic_options.is_empty():
		suite.expect(basic_options[0].gems.all(func(gem: GemInstance): return gem.level == 1), "basic recipes never mix different gem levels")
