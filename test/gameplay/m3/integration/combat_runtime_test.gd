extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	_test_select_final_gem(suite)
	_test_selection_before_placement(suite)
	_test_game_runtime_starts_wave_after_keep(suite)
	_test_refresh_enemy_paths_preserves_progress(suite)
	_test_movement_type_uses_correct_route(suite)
	_test_clear_projectiles_on_phase_end(suite)
	_test_magic_gem_damages_physical_immune_enemy(suite)
	_test_cleave_hits_nearby_enemy(suite)
	_test_split_hits_additional_target(suite)
	var profile := EnemyProfileDefinition.new(); profile.id = &"test"; profile.hp = 25.0; profile.base_speed = 20.0
	var definition := GemDefinition.new(); definition.id = &"diamond"; definition.levels = [{"level": 1, "damage": 50.0, "range": 1000.0, "base_attack_speed": 100.0, "bat": 1.0}]
	var gem := GemInstance.new(&"diamond", 1, GemInstance.Quality.CHIPPED)
	var tower := TowerRuntime.new(); tower.setup(gem, definition, Vector2.ZERO)
	var combat := CombatRuntime.new(); combat.setup(1000.0, [Vector2i.ZERO, Vector2i(1, 0)]); combat.add_tower(tower)
	var enemy := combat.spawn_enemy(profile, Vector2i(1, 0))
	var damage_events := {"count": 0}
	combat.damage_applied.connect(func(_damaged_enemy: EnemyRuntime, _amount: float): damage_events.count += 1)
	var started := {"value": false, "gem_id": StringName()}; combat.projectile_created.connect(func(projectile: HomingProjectile): started.value = true; started.gem_id = projectile.source_gem_id)
	combat.tick(1.0); suite.expect(started.value, "gem creates a homing projectile in combat")
	suite.expect_equal(started.gem_id, &"diamond", "projectile preserves the source gem color")
	combat.tick(0.1); suite.expect(not enemy.is_alive(), "projectile impact applies damage and kills enemy")
	suite.expect(damage_events.count > 0, "combat emits a damage event for impact feedback")
	suite.expect_equal(combat.enemies.size(), 0, "dead enemies are removed from combat runtime")

func _test_refresh_enemy_paths_preserves_progress(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"path_refresh"; profile.hp = 25.0; profile.base_speed = 20.0
	var combat := CombatRuntime.new()
	combat.setup(1000.0, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var enemy := combat.spawn_enemy(profile, Vector2i(0, 0))
	combat.tick(1.0)
	var position_before := enemy.position
	combat.refresh_enemy_paths([Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)])
	suite.expect(enemy.position.is_equal_approx(position_before), "path refresh preserves the enemy position")
	suite.expect_equal(combat.path_cells.size(), 4, "combat stores the latest global route")
	combat.tick(1.0)
	suite.expect(enemy.position != position_before, "enemy continues moving on the refreshed route")

func _test_movement_type_uses_correct_route(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"flying_path"; profile.movement_type = "Flying"; profile.base_speed = 100.0
	var ground_route: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var waypoints: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0)]
	var combat := CombatRuntime.new(); combat.setup(1000.0, ground_route, waypoints)
	var enemy := combat.spawn_enemy(profile, Vector2i(0, 0))
	suite.expect_equal(enemy.path.size(), waypoints.size(), "flying enemies use ordered waypoints instead of ground cells")
	var before := enemy.position
	combat.tick(0.5)
	suite.expect(enemy.position != before, "flying enemy advances along its waypoint route")

func _test_clear_projectiles_on_phase_end(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"projectile_cleanup"; profile.hp = 100.0; profile.base_speed = 20.0
	var definition := GemDefinition.new(); definition.id = &"diamond"; definition.levels = [{"level": 1, "damage": 1.0, "range": 1000.0, "base_attack_speed": 1000.0, "bat": 1.0}]
	var gem := GemInstance.new(&"diamond", 1, GemInstance.Quality.CHIPPED)
	var tower := TowerRuntime.new(); tower.setup(gem, definition, Vector2.ZERO)
	var combat := CombatRuntime.new(); combat.setup(1000.0, [Vector2i.ZERO, Vector2i(1, 0)]); combat.add_tower(tower); combat.spawn_enemy(profile, Vector2i(1, 0))
	combat.tick(0.01)
	suite.expect(combat.projectiles.size() > 0, "combat creates a projectile before phase cleanup")
	combat.clear_projectiles()
	suite.expect_equal(combat.projectiles.size(), 0, "phase cleanup removes all active projectiles")

func _test_magic_gem_damages_physical_immune_enemy(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"physical_immune"; profile.hp = 100.0; profile.base_speed = 20.0; profile.ability_ids = PackedStringArray(["physical_immune"])
	var definition := GemDefinition.new(); definition.id = &"emerald"; definition.levels = [{"level": 1, "damage": 25.0, "range": 1000.0, "base_attack_speed": 1000.0, "ability": "Poison 1"}]
	var gem := GemInstance.new(&"emerald", 1, GemInstance.Quality.CHIPPED)
	var tower := TowerRuntime.new(); tower.setup(gem, definition, Vector2.ZERO)
	var combat := CombatRuntime.new(); combat.setup(1000.0, [Vector2i.ZERO, Vector2i(1, 0)]); combat.add_tower(tower)
	var enemy := combat.spawn_enemy(profile, Vector2i(1, 0))
	combat.tick(0.01); combat.tick(0.2)
	suite.expect(enemy.hp < enemy.max_hp, "magic gem damages a physically immune enemy")

func _test_cleave_hits_nearby_enemy(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"cleave_target"; profile.hp = 100.0; profile.base_speed = 20.0
	var definition := GemDefinition.new(); definition.id = &"ruby"; definition.levels = [{"level": 1, "damage": 20.0, "range": 1000.0, "base_attack_speed": 1000.0, "ability": "Cleave 1"}]
	var tower := TowerRuntime.new(); tower.setup(GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED), definition, Vector2.ZERO)
	var combat := CombatRuntime.new(); combat.effect_system = EffectSystem.new(); combat.setup(1000.0, [Vector2i.ZERO, Vector2i(1, 0)]); combat.add_tower(tower)
	var primary := combat.spawn_enemy(profile, Vector2i(1, 0)); var secondary := combat.spawn_enemy(profile, Vector2i(1, 0)); secondary.position = primary.position + Vector2(70, 0)
	combat.tick(0.01); combat.tick(0.2)
	suite.expect(primary.hp < primary.max_hp and secondary.hp < secondary.max_hp, "Cleave damages the primary and a nearby secondary target")

func _test_split_hits_additional_target(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"split_target"; profile.hp = 100.0; profile.base_speed = 20.0
	var definition := GemDefinition.new(); definition.id = &"topaz"; definition.levels = [{"level": 1, "damage": 20.0, "range": 1000.0, "base_attack_speed": 1000.0, "ability": "Split 1"}]
	var tower := TowerRuntime.new(); tower.setup(GemInstance.new(&"topaz", 1, GemInstance.Quality.CHIPPED), definition, Vector2.ZERO)
	var combat := CombatRuntime.new(); combat.effect_system = EffectSystem.new(); combat.setup(1000.0, [Vector2i.ZERO, Vector2i(1, 0)]); combat.add_tower(tower)
	var primary := combat.spawn_enemy(profile, Vector2i(1, 0)); var secondary := combat.spawn_enemy(profile, Vector2i(1, 0)); secondary.position = primary.position + Vector2(90, 0)
	combat.tick(0.01); combat.tick(0.2)
	suite.expect(primary.hp < primary.max_hp and secondary.hp < secondary.max_hp, "Split damages the primary and its additional target")

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
