extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const Loader = preload("res://src/core/data/gameplay_data_loader.gd")

func _init() -> void:
	var suite := Suite.new()
	var loaded := Loader.new().load_catalog("res://data/gameplay/catalog.tres")
	suite.expect(loaded.is_valid(), "M5 catalog is valid: %s" % str(loaded.errors))
	if loaded.catalog != null:
		suite.expect_equal(loaded.catalog.gems.size(), 8, "M5 contains eight basic gem types")
		var levels := 0
		for gem in loaded.catalog.gems: levels += gem.levels.size()
		suite.expect_equal(levels, 56, "M5 contains levels 1-7 for every basic gem")
		suite.expect_equal(loaded.catalog.recipes.size(), 46, "M5 contains 38 normal and 8 secret recipes")
		var secrets := 0
		for recipe in loaded.catalog.recipes: if recipe.secret: secrets += 1
		suite.expect_equal(secrets, 8, "Secret recipes are present and marked hidden")
		suite.expect_equal(loaded.catalog.enemy_profiles.size(), 50, "M5 contains one playable profile per wave")
		suite.expect_equal(loaded.catalog.waves.size(), 50, "M5 contains waves 1 through 50")
		suite.expect(loaded.catalog.waves[49].boss and loaded.catalog.waves[49].number == 50, "Wave 50 is the final boss")
		suite.expect(loaded.catalog.waves[0].enemy_profile_id == &"frenzied_pig", "Wave 1 keeps the baseline profile id")
		var wave_5_profile: Resource = loaded.catalog.enemy_profile_by_id(loaded.catalog.waves[4].enemy_profile_id)
		suite.expect(wave_5_profile != null and wave_5_profile.movement_type == "Flying", "Wave 5 uses the first Flying variant")
		var result_definition: Resource = loaded.catalog.gem_definition_for_id(&"natural_zumurud")
		suite.expect(result_definition != null and result_definition.levels[0].damage == 8, "Natural Zumurud result exposes its runtime stats")
	for wave in loaded.catalog.waves:
		suite.expect(wave.spawn_interval == 1.0, "Wave %d uses canonical one-second spawn" % wave.number)
		if wave.boss: suite.expect_equal(wave.spawn_count, 1, "Boss wave %d has one boss" % wave.number)
	if suite.failures.is_empty(): print("M5 content integration tests passed")
	else:
		for failure in suite.failures: push_error(failure)
	quit(0 if suite.failures.is_empty() else 1)
