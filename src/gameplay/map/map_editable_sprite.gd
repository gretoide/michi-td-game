@tool
class_name MapEditableSprite
extends Sprite2D

## Shared authored-map sprite. Position is represented in cells so the map
## remains easy to edit in the 2D view while the regular Sprite2D transform
## still exposes scale, rotation and texture in the Inspector.
@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		_sync_cell_position()
@export var sprite: Texture2D:
	set(value):
		sprite = value
		texture = value
@export var snap_to_grid := true

const CELL_SIZE := 16.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sprite != null:
		texture = sprite
	_sync_cell_position()
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not snap_to_grid:
		return
	var expected := Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5
	if position.distance_to(expected) > 1.0:
		cell = Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))

func _sync_cell_position() -> void:
	if not is_inside_tree() or not snap_to_grid:
		return
	position = Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5
