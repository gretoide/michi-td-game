extends RefCounted

const EnemyRuntimeScript = preload("res://src/gameplay/combat/enemy_runtime.gd")
const WaveRuntimeScript = preload("res://src/gameplay/waves/wave_runtime.gd")
const GameRuntimeScript = preload("res://src/gameplay/game_runtime.gd")

func run(suite: FoundationTestSuite) -> void:
	var game := GameRuntimeScript.new()
	var init_errors: PackedStringArray = game.initialize(42)
	suite.expect(init_errors.is_empty(), "game runtime initializes for M4")
	suite.expect_equal(game.wave_definitions.size(), 50, "wave catalog contains exactly 50 waves")
	suite.expect_equal(game.wave_definitions[0].spawn_count, 10, "wave one has ten regular enemies")
	game.progress.future_count_modifier = 2; suite.expect(game.start_first_wave(), "first wave starts with adaptive count"); suite.expect_equal(game.wave.pending, 12, "regular wave applies future count modifier")
	suite.expect_equal(game.enemy_count_for_display(), 12, "HUD count matches the authoritative active wave total")
	suite.expect_equal(game.enemy_count_for_wave(1), game.wave.total_count(), "preview and active HUD use the same authoritative regular-wave count")
	suite.expect_equal(game.wave_definitions[0].spawn_count, game.enemy_count_for_wave(1), "WaveRuntime receives the same count that the HUD exposes")
	_test_ground_spawn_uses_precomputed_detour(suite)
	var preview := GameRuntimeScript.new(); suite.expect(preview.initialize(43).is_empty(), "preview runtime initializes")
	suite.expect_equal(preview.enemy_count_for_display(), 10, "construction previews the next regular wave count")
	preview.phases.wave_number = 10
	suite.expect_equal(preview.enemy_count_for_display(), 1, "construction previews one enemy for a boss wave")
	suite.expect_equal(preview.enemy_count_for_wave(10), 1, "boss preview uses one enemy even when the adaptive modifier is present")
	for index in range(50):
		var wave_definition: WaveDefinition = game.wave_definitions[index]
		suite.expect_equal(wave_definition.number, index + 1, "waves remain ordered")
		suite.expect(wave_definition.boss == ((index + 1) in [10, 20, 30, 40, 50]), "boss cadence is canonical")
		suite.expect_equal(wave_definition.spawn_interval, 1.0, "spawn cadence is one enemy per second")
	var profile := EnemyProfileDefinition.new(); profile.id = &"ground"; profile.hp = 10.0; profile.base_speed = 250.0; profile.attack = 3.0
	var enemy = EnemyRuntimeScript.new(); enemy.setup(1, profile); enemy.set_path([Vector2i.ZERO, Vector2i(1, 0)]); enemy.mark_escaped(); suite.expect(not enemy.is_alive(), "enemy escape ends lifecycle"); suite.expect_equal(enemy.apply_damage(DamagePipeline.resolve(_physical(20.0), enemy)), 0.0, "escaped enemy cannot receive damage")
	var wave = WaveRuntimeScript.new(); var definition := WaveDefinition.new(); definition.spawn_count = 10; definition.spawn_interval = 1.0; wave.start(definition, profile); wave.tick(0.0); suite.expect_equal(wave.pending, 9, "wave spawns first enemy immediately"); wave.tick(9.0); suite.expect_equal(wave.pending, 0, "wave spawns ten regular enemies")
	var flying := EnemyProfileDefinition.new(); flying.id = &"flying"; flying.movement_type = "Flying"; var flying_enemy = EnemyRuntimeScript.new(); flying_enemy.setup(2, flying); suite.expect(flying_enemy.is_alive(), "flying profile shares enemy lifecycle")

func _test_ground_spawn_uses_precomputed_detour(suite: FoundationTestSuite) -> void:
	var blocked_runtime := GameRuntimeScript.new()
	suite.expect(blocked_runtime.initialize(4242).is_empty(), "runtime initializes with a pre-existing construction block")
	if blocked_runtime.pathfinder == null or blocked_runtime.map == null: return
	var blocked_cell := Vector2i(5, 10)
	suite.expect(blocked_runtime.grid.occupy(blocked_cell), "pre-existing block occupies the route cell")
	var direct_route := blocked_runtime.pathfinder.find_route(blocked_runtime.map)
	suite.expect(not direct_route.is_empty() and not direct_route.has(blocked_cell), "route snapshot detours around the occupied cell")
	suite.expect(blocked_runtime.start_first_wave(), "wave starts only after the detour is prepared")
	blocked_runtime.tick(0.0)
	suite.expect_equal(blocked_runtime.combat.enemies.size(), 1, "first Ground enemy spawns with the navigation snapshot")
	if blocked_runtime.combat.enemies.size() == 1:
		var enemy: EnemyRuntime = blocked_runtime.combat.enemies[0]
		suite.expect(enemy.path.size() == direct_route.size(), "spawned Ground enemy receives the complete precomputed route")
		suite.expect(not enemy.path.has(Vector2(blocked_cell) * 100.0 + Vector2.ONE * 50.0), "spawned Ground enemy never receives the occupied cell")
		suite.expect(enemy.path.size() > 2 and enemy.path[1] != Vector2(5, 4) * 100.0 + Vector2.ONE * 50.0, "enemy takes the detour before moving toward the checkpoint")

func _physical(amount: float) -> DamagePipeline.DamageContext:
	var context := DamagePipeline.DamageContext.new(); context.base_damage = amount; context.damage_type = DamagePipeline.DamageType.PHYSICAL; return context
