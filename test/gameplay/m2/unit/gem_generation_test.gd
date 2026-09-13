extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var first := GemGenerator.new(SeededRandomSource.new(77)); var second := GemGenerator.new(SeededRandomSource.new(77))
	var first_ids: Array = []; var second_ids: Array = []
	for _i in 5: first_ids.append(first.generate(1).id); second_ids.append(second.generate(1).id)
	suite.expect_equal(first_ids, second_ids, "seeded gem type generation is reproducible")
	suite.expect_equal(first.generate(1), null, "construction generation is capped at five gems")
	suite.expect_equal(GemGenerator.quality_probabilities(1), [100.0, 0.0, 0.0, 0.0, 0.0], "level one quality table is exact")
	suite.expect_equal(GemGenerator.quality_probabilities(5), [10.0, 30.0, 30.0, 20.0, 10.0], "level five quality table is exact")
	var all_ids := {}
	var sample := GemGenerator.new(SeededRandomSource.new(1))
	for index in 400:
		if index % 5 == 0: sample.reset_round(index / 5)
		all_ids[sample.generate(5).id] = true
	suite.expect_equal(all_ids.size(), 8, "bootstrap generator supports all eight gem IDs")
