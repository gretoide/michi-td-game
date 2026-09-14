extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const CombatTest = preload("res://test/gameplay/m3/unit/combat_test.gd")
const CombatRuntimeTest = preload("res://test/gameplay/m3/integration/combat_runtime_test.gd")
const AuraEffectTest = preload("res://test/gameplay/m3/unit/aura_effect_test.gd")

func _init() -> void:
	var suite := Suite.new()
	CombatTest.new().run(suite)
	CombatRuntimeTest.new().run(suite)
	AuraEffectTest.new().run(suite)
	if suite.failures.is_empty():
		print("M3 combat engine tests passed"); quit(0)
	else:
		for failure in suite.failures: push_error(failure)
		quit(1)
