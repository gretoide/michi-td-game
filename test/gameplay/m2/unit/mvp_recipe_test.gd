extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var mvp := MvpState.new(); mvp.register_tower(&"a"); mvp.register_tower(&"b")
	suite.expect_equal(mvp.award_round({"a": 10.0, "b": 4.0}), &"a", "MVP selects the highest injected damage")
	suite.expect_equal(mvp.level_of(&"a"), 1, "MVP award increments one level")
	for _i in 9: mvp.award(&"a")
	suite.expect(mvp.is_graduated(&"a"), "MVP level ten graduates the tower")
	suite.expect_equal(mvp.multiplier_of(&"a"), 1.9, "MVP levels one to nine add ten percent each")
	suite.expect_equal(mvp.award_round({"a": 100.0, "b": 4.0}), &"b", "graduated towers are excluded from MVP")
	var gem_a := GemInstance.new(&"amethyst", 1, GemInstance.Quality.CHIPPED); gem_a.mvp_level = 8
	var gem_b := GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED); gem_b.mvp_level = 5
	suite.expect_equal(MvpState.transfer_mvp([gem_a, gem_b]), 10, "advanced combination transfer is capped at ten")
	var recipe := RecipeDefinition.new(); recipe.id = &"fixture"; recipe.result_id = &"silver"; recipe.ingredients = [{"id": &"amethyst", "level": 1}, {"id": &"ruby", "level": 1}]
	var matcher := RecipeMatcher.new()
	suite.expect_equal(matcher.match_recipe(recipe, [gem_a, gem_b]).size(), 2, "recipe matching uses exact IDs and levels")
	var wrong := GemInstance.new(&"ruby", 2, GemInstance.Quality.FLAWED)
	suite.expect(matcher.match_recipe(recipe, [gem_a, wrong]).is_empty(), "recipe rejects non-exact levels")
	suite.expect_equal(matcher.visible_recipes([recipe]).size(), 1, "normal recipes remain visible")
	recipe.secret = true
	suite.expect_equal(matcher.visible_recipes([recipe]).size(), 0, "secret recipes are hidden from normal listings")

