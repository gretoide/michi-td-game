@tool
class_name MapEditorRoot
extends Node2D

const MapLayoutScript = preload("res://src/gameplay/map/map_layout.gd")
const GRID_WIDTH := 64
const GRID_HEIGHT := 40
const CELL_SIZE := 16.0

@export var map_layout_resource: MapLayout
@export var show_editor_grid := true
@export var show_editor_route := true
@export var grid_color := Color(0.55, 0.82, 0.92, 0.20)

func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false
		set_process(false)
	else:
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func authored_layout() -> MapLayout:
	var layout := MapLayoutScript.new() as MapLayout
	if map_layout_resource != null:
		layout.spawn = map_layout_resource.spawn
		layout.endpoint = map_layout_resource.endpoint
		var source_checkpoints: Array[Vector2i] = []
		for point: Vector2i in map_layout_resource.checkpoints: source_checkpoints.append(point)
		layout.checkpoints = source_checkpoints
		var source_obstacles: Array[Vector2i] = []
		for obstacle: Vector2i in map_layout_resource.obstacles: source_obstacles.append(obstacle)
		layout.obstacles = source_obstacles
		var source_route: Array[Vector2i] = []
		for cell: Vector2i in map_layout_resource.route_cells: source_route.append(cell)
		layout.route_cells = source_route
	var path := get_node_or_null("Path")
	if path != null:
		var spawn := path.get_node_or_null("Spawn") as MapEditablePoint
		var endpoint := path.get_node_or_null("Endpoint") as MapEditablePoint
		if spawn != null: layout.spawn = spawn.cell
		if endpoint != null: layout.endpoint = endpoint.cell
		var checkpoints_node := path.get_node_or_null("Checkpoints")
		if checkpoints_node != null:
			var points: Array[MapEditablePoint] = []
			for child in checkpoints_node.get_children():
				if child is MapEditablePoint: points.append(child as MapEditablePoint)
			points.sort_custom(func(a: MapEditablePoint, b: MapEditablePoint) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
			layout.checkpoints.clear()
			for point in points: layout.checkpoints.append(point.cell)
	layout.obstacles.clear()
	var obstacles_node := get_node_or_null("Obstacles")
	if obstacles_node != null:
		for child in obstacles_node.get_children():
			if child is MapObstacle and (child as MapObstacle).blocks_path:
				layout.obstacles.append((child as MapObstacle).cell)
	return layout

func authored_obstacles() -> Array[Vector2i]:
	return authored_layout().obstacles

func prepare_for_runtime() -> void:
	visible = true
	set_process(false)

func prepare_for_editor() -> void:
	visible = Engine.is_editor_hint()
	set_process(Engine.is_editor_hint())
	queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if show_editor_grid:
		for index in range(GRID_WIDTH + 1):
			var offset := float(index) * CELL_SIZE
			draw_line(Vector2(offset, 0), Vector2(offset, GRID_HEIGHT * CELL_SIZE), grid_color, 1.0)
		for index in range(GRID_HEIGHT + 1):
			var offset := float(index) * CELL_SIZE
			draw_line(Vector2(0, offset), Vector2(GRID_WIDTH * CELL_SIZE, offset), grid_color, 1.0)
	var layout := authored_layout()
	if show_editor_route:
		if not layout.route_cells.is_empty():
			# route_cells uses the runtime 36x36 grid. Convert its cell centers
			# to the authored 64x40 canvas before drawing the editor guide.
			for index in range(layout.route_cells.size() - 1):
				var start := _logical_to_authored_cell(layout.route_cells[index])
				var end := _logical_to_authored_cell(layout.route_cells[index + 1])
				draw_line((Vector2(start) + Vector2.ONE * 0.5) * CELL_SIZE, (Vector2(end) + Vector2.ONE * 0.5) * CELL_SIZE, Color(0.98, 0.78, 0.25, 0.82), 5.0)
		else:
			var route := layout.ordered_waypoints()
			for index in range(route.size() - 1):
				draw_line((Vector2(route[index]) + Vector2.ONE * 0.5) * CELL_SIZE, (Vector2(route[index + 1]) + Vector2.ONE * 0.5) * CELL_SIZE, Color(0.98, 0.78, 0.25, 0.75), 8.0)

func _logical_to_authored_cell(cell: Vector2i) -> Vector2i:
	var x := roundi((float(cell.x) + 0.5) * float(GRID_WIDTH) / 36.0 - 0.5)
	var y := roundi(3.0 + float(cell.y - 3) * 32.0 / 29.0)
	return Vector2i(clampi(x, 0, GRID_WIDTH - 1), clampi(y, 0, GRID_HEIGHT - 1))

func logical_cell_to_authored_rect(cell: Vector2i) -> Rect2:
	var x_scale := float(GRID_WIDTH) / 36.0
	var y_scale := 32.0 / 29.0
	var center := Vector2((float(cell.x) + 0.5) * x_scale - 0.5, 3.0 + float(cell.y - 3) * y_scale)
	var authored_size := Vector2(x_scale, y_scale)
	var rect := Rect2((center - authored_size * 0.5) * CELL_SIZE, authored_size * CELL_SIZE)
	return rect.intersection(Rect2(Vector2.ZERO, Vector2(GRID_WIDTH, GRID_HEIGHT) * CELL_SIZE))

func logical_cell_to_runtime_authored_rect(cell: Vector2i) -> Rect2:
	# Runtime actors use the continuous logical-cell center. This rectangle is
	# for hover/selection only; authored decoration footprint conversion keeps
	# using logical_cell_to_authored_rect above.
	var authored_size := Vector2(float(GRID_WIDTH) / 36.0, 32.0 / 29.0)
	var center := logical_world_to_authored((Vector2(cell) + Vector2.ONE * 0.5) * 100.0) / CELL_SIZE
	var rect := Rect2((center - authored_size * 0.5) * CELL_SIZE, authored_size * CELL_SIZE)
	return rect.intersection(Rect2(Vector2.ZERO, Vector2(GRID_WIDTH, GRID_HEIGHT) * CELL_SIZE))

func logical_world_to_authored(world_position: Vector2) -> Vector2:
	var logical := world_position / 100.0
	return Vector2(
		logical.x * float(GRID_WIDTH) / 36.0,
		3.5 + (logical.y - 3.5) * 32.0 / 29.0
	) * CELL_SIZE

func logical_cell_base_to_authored(cell: Vector2i, base_y: float = 0.75) -> Vector2:
	return logical_world_to_authored((Vector2(cell) + Vector2(0.5, base_y)) * 100.0)
