const LoaderAnimation = preload("res://src/shared/loader_animation.gd")

func run(suite) -> void:
	var loader = LoaderAnimation.new()
	var source := load("res://assets/ui/loaders/login_cats_loader.png") as Texture2D
	suite.expect(source != null, "login loader spritesheet is available")
	suite.expect_equal(LoaderAnimation.FRAME_REGIONS.size(), 8, "loader exposes eight authored frames")
	loader.setup(source)
	suite.expect(loader.texture is AtlasTexture, "loader displays one atlas frame instead of the complete strip")
	var first := loader.texture as AtlasTexture
	suite.expect(first.region == LoaderAnimation.FRAME_REGIONS[0], "loader starts at the first frame")
	loader._process(1.0)
	var second := loader.texture as AtlasTexture
	suite.expect(second.region == LoaderAnimation.FRAME_REGIONS[1], "loader advances to the next frame")
	var hourglass := LoaderAnimation.new()
	var hourglass_frames: Array[Texture2D] = [
		load("res://assets/ui/icons/kenney_basic_double/progress_empty.png"),
		load("res://assets/ui/icons/kenney_basic_double/progress_CW_25.png"),
	]
	hourglass.setup_frames(hourglass_frames)
	suite.expect(hourglass.texture == hourglass_frames[0], "loader accepts independent frame textures")
	hourglass._process(1.0)
	suite.expect(hourglass.texture == hourglass_frames[1], "independent frame loader advances without a spritesheet")
	hourglass.free()
	loader.free()
