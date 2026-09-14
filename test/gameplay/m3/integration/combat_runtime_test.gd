extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	_test_select_final_gem(suite)
	_test_selection_before_placement(suite)
	_test_game_runtime_starts_wave_after_keep(suite)
	var profile := EnemyProfileDefinition.new(); profile.id = &"test"; profile.hp = 25.0; profile.base_speed = 20.0
	var definition := GemDefinition.new(); definition.id = &"diamond"; definition.levels = [{"level": 1, "damage": 50.0, "range": 1000.0, "base_attack_speed": 100.0, "bat": 1.0}]
	var gem := GemInstance.new(&"diamond", 1, GemInstance.Quality.CHIPPED)
	var tower := TowerRuntime.new(); tower.setup(gem, definition, Vector2.ZERO)
	var combat := CombatRuntime.new(); combat.setup(1000.0, [Vector2i.ZERO, Vector2i(1, 0)]); combat.add_tower(tower)
	var enemy := combat.spawn_enemy(profile, Vector2i(1, 0))
	var started := {"value": false}; combat.projectile_created.connect(func(_projectile: HomingProjectile): started.value = true)
	combat.tick(1.0); suite.expect(started.value, "tower creates a homing projectile in combat")
	combat.tick(0.1); suite.expect(not enemy.is_alive(), "projectile impact applies damage and kills enemy")
	suite.expect_equal(combat.enemies.size(), 0, "dead enemies are removed from combat runtime")

func _test_selection_before_placement(suite: FoundationTestSuite) -> void:
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(44)
	if not errors.is_empty(): return
	runtime.construction.ensure_gem_pool(1)
	suite.expect_equal(runtime.construction.available_gems.size(), 5, "construction exposes five selectable gems")
	var first := runtime.construction.available_gems[0]
	suite.expect(runtime.construction.selected_gem == first, "first pending gem is selected automatically")
	var first_placed := runtime.construction.place_selected(Vector2i(8, 8))
	suite.expect(first_placed == first, "first pending gem can be placed immediately")
	suite.expect(runtime.construction.selected_gem == runtime.construction.available_gems[0], "next pending gem is selected after placement")
	var selected := runtime.construction.select_available(2)
	suite.expect(selected != null, "a pending gem can be selected")
	var placed := runtime.construction.place_selected(Vector2i(10, 8))
	suite.expect(placed == selected, "the selected gem is the one placed")
	var before_invalid := runtime.construction.selected_gem
	suite.expect(runtime.construction.place_selected(Vector2i(-1, 8)) == null, "invalid placement is rejected")
	suite.expect(runtime.construction.selected_gem == before_invalid, "invalid placement preserves selection")

func _test_game_runtime_starts_wave_after_keep(suite: FoundationTestSuite) -> void:
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(1234)
	suite.expect(errors.is_empty(), "game runtime initializes for combat integration")
	if not errors.is_empty(): return
	var cells := [Vector2i(8, 8), Vector2i(10, 8), Vector2i(12, 8), Vector2i(8, 10), Vector2i(10, 10)]
	for cell in cells:
		runtime.construction.place_gem(cell)
	suite.expect_equal(runtime.construction.placed_count(), 5, "five gems can be placed before combat")
	var first: GemInstance = runtime.construction.current_gems[0]
	suite.expect(runtime.construction.keep(first), "keep finalizes construction")
	suite.expect_equal(runtime.phases.phase, GamePhaseMachine.Phase.COMBAT, "keep enters combat phase")
	suite.expect(runtime.wave.is_active(), "finalizing construction starts the first wave")
	runtime.tick(1.1)
	suite.expect(runtime.combat.enemies.size() > 0, "first wave spawns a visible enemy")

func _test_select_final_gem(suite: FoundationTestSuite) -> void:
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(55)
	if not errors.is_empty(): return
	var cells := [Vector2i(8, 8), Vector2i(10, 8), Vector2i(12, 8), Vector2i(8, 10), Vector2i(10, 10)]
	suite.expect(runtime.construction.select_board_gem(cells[3]) == null, "final gem cannot be selected before five placements")
	for cell in cells: runtime.construction.place_gem(cell)
	var chosen := runtime.construction.select_board_gem(cells[3])
	suite.expect(chosen != null, "a placed gem can be selected as final")
	suite.expect(runtime.construction.keep(chosen), "selected final gem starts combat")
	suite.expect_equal(runtime.construction.selected_result.cell, cells[3], "selected final gem keeps its cell")
