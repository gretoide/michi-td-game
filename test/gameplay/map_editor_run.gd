extends SceneTree

func _init() -> void:
	var map_scene := load("res://src/gameplay/map/map.tscn") as PackedScene
	var authored := map_scene.instantiate()
	root.add_child(authored)
	await process_frame
	var runtime := GameRuntime.new()
	var errors := runtime.initialize(20260915)
	if not errors.is_empty():
		push_error("Map editor runtime test failed: " + "; ".join(errors))
		quit(1)
		return
	var layout := authored.authored_layout() as MapLayout
	assert(layout.checkpoints.size() == 5)
	assert(layout.obstacles.size() == 3)
	assert(not runtime.pathfinder.find_route(runtime.map).is_empty())
	print("Map editor scene/runtime tests passed")
	quit(0)
