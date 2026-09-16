extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var phases := GamePhaseMachine.new(); var observed: Array[int] = []
	phases.phase_entered.connect(func(value: int): observed.append(value))
	phases.reset()
	suite.expect_equal(phases.phase, GamePhaseMachine.Phase.CONSTRUCTION, "game starts in Construction")
	suite.expect(phases.is_action_allowed(&"place_gem"), "placement is allowed in Construction")
	suite.expect(phases.is_action_allowed(&"toggle_attack"), "tower attack toggle is allowed in Construction")
	suite.expect(not phases.is_action_allowed(&"attack"), "attack is blocked in Construction")
	suite.expect(phases.resolve_construction(), "resolved Construction enters Combat")
	suite.expect(phases.is_action_allowed(&"attack"), "attack is enabled in Combat")
	suite.expect(phases.is_action_allowed(&"stop"), "tower stop is enabled in Combat")
	suite.expect(not phases.is_action_allowed(&"remove_stone"), "stone removal is blocked in Combat")
	suite.expect(not phases.is_action_allowed(&"combine"), "combination is blocked in Combat")
	suite.expect(phases.resolve_combat(), "resolved Combat returns to Construction")
	suite.expect_equal(phases.wave_number, 2, "resolved Combat advances wave")
	suite.expect_equal(observed.size(), 3, "phase entries are observable")

	var definition := WaveDefinition.new(); definition.spawn_count = 2; definition.spawn_interval = 1.0
	var profile := EnemyProfileDefinition.new(); profile.id = &"test"; profile.movement_type = "Flying"
	var wave := WaveRuntime.new(); var spawned: Array[int] = []; var wave_state := {"completed": false}
	wave.enemy_spawned.connect(func(id: int, _profile: EnemyProfileDefinition): spawned.append(id))
	wave.wave_completed.connect(func(): wave_state.completed = true)
	wave.start(definition, profile)
	wave.tick(0.0); suite.expect_equal(spawned.size(), 1, "first enemy spawns at wave start")
	wave.tick(0.5); suite.expect_equal(spawned.size(), 1, "spawn interval is respected")
	wave.tick(0.5); suite.expect_equal(spawned.size(), 2, "second enemy spawns after one second")
	wave.resolve_enemy(1, &"death"); suite.expect(not wave_state.completed, "wave waits for living enemies")
	suite.expect(not wave.resolve_enemy(1, &"death"), "an enemy cannot resolve twice")
	wave.resolve_enemy(2, &"escaped"); suite.expect(wave_state.completed, "last resolution completes wave")
