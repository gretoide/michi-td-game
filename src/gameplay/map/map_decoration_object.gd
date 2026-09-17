@tool
class_name MapDecorationObject
extends Node2D

## Complete top-down decoration. The root position is the contact point with
## the ground; visual children extend upwards from that point and therefore do
## not influence Y-sort ordering.
@export var asset_id: StringName = &"decoration"
@export_enum("tree", "bush", "stone", "prop", "structure", "landmark") var category := "prop"
@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		_sync_cell_position()
@export var footprint_offset := Vector2i.ZERO
@export var footprint_size := Vector2i.ONE
@export var remove_on_build := true
## Visual objects keep their authored position. Runtime gameplay cells (gems,
## towers and pathfinding) are stored separately and must not move decorations.
@export var snap_to_grid := false
@export var blocks_path := false:
	set(_value):
		blocks_path = false

const CELL_SIZE := 16.0

func _ready() -> void:
	blocks_path = false
	z_index = 0
	z_as_relative = true
	add_to_group(&"map_decoration")
	add_to_group("map_decoration_%s" % category)
	if remove_on_build:
		add_to_group(&"removable_on_build")
	_sync_cell_position()
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not snap_to_grid:
		return
	var resolved := Vector2i(floori(position.x / CELL_SIZE), ceili(position.y / CELL_SIZE) - 1)
	if resolved != cell:
		cell = resolved

func _sync_cell_position() -> void:
	if not is_inside_tree() or not snap_to_grid:
		return
	position = Vector2(float(cell.x) + 0.5, float(cell.y) + 1.0) * CELL_SIZE

func authored_footprint() -> Rect2i:
	return Rect2i(cell + footprint_offset, footprint_size.max(Vector2i.ONE))
