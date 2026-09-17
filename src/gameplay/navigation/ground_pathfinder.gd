class_name GroundPathfinder
extends RefCounted

var grid: GridModel

func _init(value: GridModel) -> void:
	grid = value

func find_route(layout: MapLayout) -> Array[Vector2i]:
	# Always solve each waypoint segment against the current grid.  The
	# authored route is useful as editor data/debug guidance, but it must not
	# become a runtime shortcut: it can be longer than an available detour and
	# would make enemies discover a blockage only after colliding with it.
	var full: Array[Vector2i] = []
	var points := layout.ordered_waypoints()
	for index in range(points.size() - 1):
		var segment := _find_segment(points[index], points[index + 1])
		if segment.is_empty(): return []
		if not full.is_empty(): segment.pop_front()
		full.append_array(segment)
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
	var frontier_head := 0
	var came_from := {start: start}
	while frontier_head < frontier.size():
		var current: Vector2i = frontier[frontier_head]
		frontier_head += 1
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
