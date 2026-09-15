@tool
class_name MapEditablePoint
extends Node2D

@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		_sync_cell_position()
@export var point_label := ""
@export var snap_to_grid := true
@export_range(8.0, 64.0, 1.0) var marker_radius := 18.0

const CELL_SIZE := 100.0

func _ready() -> void:
	_sync_cell_position()
	set_process(Engine.is_editor_hint())
	queue_redraw()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not snap_to_grid:
		return
	var expected := Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5
	if position.distance_to(expected) > 1.0:
		cell = Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))
	queue_redraw()

func _sync_cell_position() -> void:
	if not is_inside_tree() or not snap_to_grid:
		return
	position = Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5
	queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, marker_radius, Color(0.16, 0.72, 0.95, 0.28))
	draw_arc(Vector2.ZERO, marker_radius, 0.0, TAU, 24, Color(0.65, 0.92, 1.0, 0.95), 3.0)
	draw_line(Vector2(-marker_radius * 0.65, 0), Vector2(marker_radius * 0.65, 0), Color.WHITE, 2.0)
	draw_line(Vector2(0, -marker_radius * 0.65), Vector2(0, marker_radius * 0.65), Color.WHITE, 2.0)
	if not point_label.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(marker_radius + 6.0, 5.0), point_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)

