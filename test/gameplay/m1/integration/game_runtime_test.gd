extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(123)
	suite.expect(errors.is_empty(), "new game initializes without errors")
	suite.expect_equal(runtime.player_state.wave, 1, "new game starts at wave one")
	suite.expect_equal(runtime.player_state.score, 0, "new game starts with clean score")
	suite.expect_equal(runtime.player_state.lives, 1000, "new game starts with canonical life")
	suite.expect_equal(runtime.player_state.gold, 0, "new game starts with zero gold")
	suite.expect_equal(runtime.player_state.player_level, 1, "new game starts at player level one")
	suite.expect_equal(runtime.player_state.xp, 0, "new game starts with zero XP")
	suite.expect_equal(runtime.player_state.progress, 50.0, "new game starts at fifty percent progress")
	suite.expect_equal(runtime.player_state.support_skills.size(), 0, "new game starts without support skills")
	suite.expect_equal(runtime.phases.phase, GamePhaseMachine.Phase.CONSTRUCTION, "new game starts in Construction")
	suite.expect_equal(runtime.map.checkpoints.size(), 5, "new game initializes canonical map")
	suite.expect(not runtime.pathfinder.find_route(runtime.map).is_empty(), "path exists before gameplay input")
	var spawn_state := {"profile": StringName()}
	runtime.wave.enemy_spawned.connect(func(_enemy_id: int, profile: EnemyProfileDefinition): spawn_state.profile = profile.id)
	suite.expect(runtime.start_first_wave(), "first wave can start after resolving Construction")
	runtime.wave.tick(9.0)
	for enemy_id in range(1, 11):
		runtime.wave.resolve_enemy(enemy_id, &"death")
	suite.expect_equal(spawn_state.profile, &"frenzied_pig", "wave instantiates the configured enemy profile")
	suite.expect_equal(runtime.phases.phase, GamePhaseMachine.Phase.CONSTRUCTION, "completed wave returns to Construction")
	suite.expect_equal(runtime.phases.wave_number, 2, "completed wave advances runtime")
	var second := GameRuntime.new(); second.initialize(123)
	suite.expect_equal(second.player_state.score, 0, "new runtime does not reuse previous state")
