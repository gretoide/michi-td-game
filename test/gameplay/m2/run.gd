extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const GenerationTest = preload("res://test/gameplay/m2/unit/gem_generation_test.gd")
const MvpRecipeTest = preload("res://test/gameplay/m2/unit/mvp_recipe_test.gd")
const ConstructionTest = preload("res://test/gameplay/m2/integration/construction_test.gd")

func _init() -> void:
	var suite := Suite.new()
	GenerationTest.new().run(suite)
	MvpRecipeTest.new().run(suite)
	ConstructionTest.new().run(suite)
	if suite.failures.is_empty():
		print("M2 gems and construction tests passed"); quit(0)
	else:
		for failure in suite.failures: push_error(failure)
		quit(1)

