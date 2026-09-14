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
	for index in range(50):
		var wave_definition: WaveDefinition = game.wave_definitions[index]
		suite.expect_equal(wave_definition.number, index + 1, "waves remain ordered")
		suite.expect(wave_definition.boss == ((index + 1) in [10, 20, 30, 40, 50]), "boss cadence is canonical")
		suite.expect_equal(wave_definition.spawn_interval, 1.0, "spawn cadence is one enemy per second")
	var profile := EnemyProfileDefinition.new(); profile.id = &"ground"; profile.hp = 10.0; profile.base_speed = 250.0; profile.attack = 3.0
	var enemy = EnemyRuntimeScript.new(); enemy.setup(1, profile); enemy.set_path([Vector2i.ZERO, Vector2i(1, 0)]); enemy.mark_escaped(); suite.expect(not enemy.is_alive(), "enemy escape ends lifecycle"); suite.expect_equal(enemy.apply_damage(DamagePipeline.resolve(_physical(20.0), enemy)), 0.0, "escaped enemy cannot receive damage")
	var wave = WaveRuntimeScript.new(); var definition := WaveDefinition.new(); definition.spawn_count = 10; definition.spawn_interval = 1.0; wave.start(definition, profile); wave.tick(0.0); suite.expect_equal(wave.pending, 9, "wave spawns first enemy immediately"); wave.tick(9.0); suite.expect_equal(wave.pending, 0, "wave spawns ten regular enemies")
	var flying := EnemyProfileDefinition.new(); flying.id = &"flying"; flying.movement_type = "Flying"; var flying_enemy = EnemyRuntimeScript.new(); flying_enemy.setup(2, flying); suite.expect(flying_enemy.is_alive(), "flying profile shares enemy lifecycle")

func _physical(amount: float) -> DamagePipeline.DamageContext:
	var context := DamagePipeline.DamageContext.new(); context.base_damage = amount; context.damage_type = DamagePipeline.DamageType.PHYSICAL; return context
