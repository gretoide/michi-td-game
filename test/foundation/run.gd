extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const RandomTest = preload("res://test/foundation/unit/random_test.gd")
const LocalizationTest = preload("res://test/foundation/unit/localization_test.gd")
const DataTest = preload("res://test/foundation/unit/data_test.gd")
const LoaderAnimationTest = preload("res://test/foundation/unit/loader_animation_test.gd")
const IntegrationTest = preload("res://test/foundation/integration/foundation_test.gd")

func _init() -> void:
	var suite := Suite.new()
	RandomTest.new().run(suite)
	LocalizationTest.new().run(suite)
	DataTest.new().run(suite)
	LoaderAnimationTest.new().run(suite)
	IntegrationTest.new().run(suite)
	if suite.failures.is_empty():
		print("Foundation tests passed")
		quit(0)
	else:
		for failure in suite.failures:
			push_error(failure)
		quit(1)
