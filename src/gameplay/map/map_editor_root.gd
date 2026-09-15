@tool
class_name MapEditorRoot
extends Node2D

const MapLayoutScript = preload("res://src/gameplay/map/map_layout.gd")
const GRID_SIZE := 36
const CELL_SIZE := 100.0

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
		for index in range(GRID_SIZE + 1):
			var offset := float(index) * CELL_SIZE
			draw_line(Vector2(offset, 0), Vector2(offset, GRID_SIZE * CELL_SIZE), grid_color, 1.0)
			draw_line(Vector2(0, offset), Vector2(GRID_SIZE * CELL_SIZE, offset), grid_color, 1.0)
	if show_editor_route:
		var layout := authored_layout()
		var route := layout.ordered_waypoints()
		for index in range(route.size() - 1):
			draw_line((Vector2(route[index]) + Vector2.ONE * 0.5) * CELL_SIZE, (Vector2(route[index + 1]) + Vector2.ONE * 0.5) * CELL_SIZE, Color(0.98, 0.78, 0.25, 0.75), 8.0)
