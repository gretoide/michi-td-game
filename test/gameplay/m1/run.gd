extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const GridTest = preload("res://test/gameplay/m1/unit/grid_test.gd")
const NavigationTest = preload("res://test/gameplay/m1/unit/navigation_test.gd")
const PhaseWaveTest = preload("res://test/gameplay/m1/unit/phase_wave_test.gd")
const RuntimeTest = preload("res://test/gameplay/m1/integration/game_runtime_test.gd")

func _init() -> void:
	var suite := Suite.new()
	GridTest.new().run(suite)
	NavigationTest.new().run(suite)
	PhaseWaveTest.new().run(suite)
	RuntimeTest.new().run(suite)
	if suite.failures.is_empty():
		print("M1 core loop tests passed"); quit(0)
	else:
		for failure in suite.failures: push_error(failure)
		quit(1)
