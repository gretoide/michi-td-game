@tool
class_name MapLayout
extends Resource

@export var spawn := Vector2i.ZERO
@export var checkpoints: Array[Vector2i] = []
@export var endpoint := Vector2i.ZERO
@export var obstacles: Array[Vector2i] = []

func ordered_waypoints() -> Array[Vector2i]:
	var result: Array[Vector2i] = [spawn]
	result.append_array(checkpoints)
	result.append(endpoint)
	return result

func validate_for(grid: GridModel) -> PackedStringArray:
	var errors := PackedStringArray()
	if checkpoints.size() != 5: errors.append("Map must define exactly 5 checkpoints")
	var seen := {}
	for cell in ordered_waypoints():
		if not grid.is_in_bounds(cell): errors.append("Waypoint %s is outside the 36x36 grid" % cell)
		elif seen.has(cell): errors.append("Waypoint %s is duplicated" % cell)
		seen[cell] = true
	for cell: Vector2i in obstacles:
		if not grid.is_in_bounds(cell): errors.append("Obstacle %s is outside the 36x36 grid" % cell)
		elif seen.has(cell): errors.append("Obstacle %s overlaps a waypoint" % cell)
	return errors
