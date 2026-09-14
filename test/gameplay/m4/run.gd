extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const ProgressionTest = preload("res://test/gameplay/m4/unit/progression_test.gd")
const EnemyWaveTest = preload("res://test/gameplay/m4/integration/enemy_wave_test.gd")
const AbilitiesTest = preload("res://test/gameplay/m4/unit/abilities_test.gd")
const SupportRewardTest = preload("res://test/gameplay/m4/unit/support_reward_test.gd")

func _init() -> void:
	var suite := Suite.new()
	ProgressionTest.new().run(suite)
	EnemyWaveTest.new().run(suite)
	AbilitiesTest.new().run(suite)
	SupportRewardTest.new().run(suite)
	if suite.failures.is_empty():
		print("M4 enemies, waves and progression tests passed"); quit(0)
	else:
		for failure in suite.failures: push_error(failure)
		quit(1)
