@tool
class_name MapLayout
extends Resource

@export var spawn := Vector2i.ZERO
@export var checkpoints: Array[Vector2i] = []
@export var endpoint := Vector2i.ZERO
@export var obstacles: Array[Vector2i] = []
## Optional authored route. When present, the runtime follows it while it is clear.
## A blocked cell makes the pathfinder fall back to its dynamic BFS detour.
@export var route_cells: Array[Vector2i] = []

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
	if not route_cells.is_empty():
		var route_errors := validate_route()
		for error: String in route_errors: errors.append(error)
	return errors

func validate_route() -> PackedStringArray:
	var errors := PackedStringArray()
	if route_cells.is_empty(): return errors
	if route_cells[0] != spawn:
		errors.append("Authored route must start at spawn %s" % spawn)
	if route_cells[-1] != endpoint:
		errors.append("Authored route must end at endpoint %s" % endpoint)
	for index in range(route_cells.size()):
		var cell := route_cells[index]
		if not _is_in_runtime_bounds(cell):
			errors.append("Authored route cell %s is outside the 36x36 grid" % cell)
		if index > 0 and route_cells[index - 1].distance_squared_to(cell) != 1:
			errors.append("Authored route has a non-adjacent step at index %d" % index)
	var waypoint_index := 0
	var waypoints := ordered_waypoints()
	for cell in route_cells:
		if waypoint_index < waypoints.size() and cell == waypoints[waypoint_index]:
			waypoint_index += 1
	if waypoint_index != waypoints.size():
		errors.append("Authored route must contain spawn, checkpoints and endpoint in order")
	return errors

func has_valid_route() -> bool:
	return not route_cells.is_empty() and validate_route().is_empty()

func _is_in_runtime_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < 36 and cell.y < 36
