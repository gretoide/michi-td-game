class_name GroundPathfinder
extends RefCounted

var grid: GridModel

func _init(value: GridModel) -> void:
	grid = value

func find_route(layout: MapLayout) -> Array[Vector2i]:
	if layout.has_valid_route():
		if _authored_route_is_clear(layout):
			return layout.route_cells.duplicate()
		var authored_detour := _find_authored_detour(layout)
		if not authored_detour.is_empty(): return authored_detour
	var full: Array[Vector2i] = []
	var points := layout.ordered_waypoints()
	for index in range(points.size() - 1):
		var segment := _find_segment(points[index], points[index + 1])
		if segment.is_empty(): return []
		if not full.is_empty(): segment.pop_front()
		full.append_array(segment)
	return full

func _authored_route_is_clear(layout: MapLayout) -> bool:
	for cell: Vector2i in layout.route_cells:
		if not grid.is_walkable(cell): return false
	return true

func _find_authored_detour(layout: MapLayout) -> Array[Vector2i]:
	var route := layout.route_cells
	if route.is_empty() or not grid.is_walkable(route[0]): return []
	var full: Array[Vector2i] = [route[0]]
	var index := 1
	while index < route.size():
		if grid.is_walkable(route[index]):
			full.append(route[index])
			index += 1
			continue
		var previous_clear_index := index - 1
		var next_clear_index := index
		while next_clear_index < route.size() and not grid.is_walkable(route[next_clear_index]):
			next_clear_index += 1
		if next_clear_index >= route.size(): return []
		var detour := _find_segment(route[previous_clear_index], route[next_clear_index])
		if detour.is_empty(): return []
		detour.pop_front()
		full.append_array(detour)
		index = next_clear_index + 1
	return full

func can_occupy_without_blocking(cell: Vector2i, layout: MapLayout) -> bool:
	if not grid.occupy(cell): return false
	var previous_revision := grid.revision - 1
	var valid := not find_route(layout).is_empty()
	grid.release(cell)
	grid.revision = previous_revision
	return valid

func _find_segment(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not grid.is_walkable(start) or not grid.is_walkable(goal): return []
	var frontier: Array[Vector2i] = [start]
	var came_from := {start: start}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal: break
		for next: Vector2i in grid.neighbors(current):
			if grid.is_walkable(next) and not came_from.has(next):
				came_from[next] = current; frontier.append(next)
	if not came_from.has(goal): return []
	var result: Array[Vector2i] = [goal]
	var cursor: Vector2i = goal
	while cursor != start:
		cursor = came_from[cursor] as Vector2i; result.push_front(cursor)
	return result
