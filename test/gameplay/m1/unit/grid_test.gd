extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var grid := GridModel.new()
	suite.expect_equal(GridModel.WIDTH * GridModel.HEIGHT, 1296, "grid has 36x36 cells")
	suite.expect(grid.is_in_bounds(Vector2i.ZERO), "origin is valid")
	suite.expect(not grid.is_in_bounds(Vector2i(36, 0)), "right edge is rejected")
	suite.expect(grid.occupy(Vector2i(2, 3)), "free cell can be occupied")
	suite.expect(not grid.occupy(Vector2i(2, 3)), "occupied cell rejects a second occupant")
	suite.expect(grid.release(Vector2i(2, 3)), "occupied cell can be released")
	suite.expect_equal(grid.cell_to_world(Vector2i(1, 1)), Vector2(150,150), "cell uses 100 world units")
	suite.expect_equal(grid.world_to_cell(Vector2(199,101)), Vector2i(1,1), "world converts to cell")
	suite.expect_equal(grid.neighbors(Vector2i.ZERO).size(), 2, "corner exposes two neighbors")
	grid.reserve(Vector2i(4,4)); suite.expect(grid.is_walkable(Vector2i(4,4)), "reserved route remains walkable")
	suite.expect(not grid.occupy(Vector2i(4,4)), "reserved route rejects tower occupation")
