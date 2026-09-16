@tool
class_name MapDecorationObject
extends MapEditableSprite

## A complete visual decoration with an authored-cell footprint.
##
## Decoration objects are intentionally visual only. `blocks_path` is exposed
## for inspection/backwards compatibility, but is always false so placing one
## never changes construction or navigation rules.
@export var asset_id: StringName = &"decoration"
@export var footprint_offset := Vector2i.ZERO
@export var footprint_size := Vector2i.ONE
@export var render_layer := 0
@export var blocks_path := false:
	set(_value):
		blocks_path = false

func _ready() -> void:
	blocks_path = false
	z_as_relative = false
	z_index = render_layer
	super._ready()

func authored_footprint() -> Rect2i:
	return Rect2i(cell + footprint_offset, footprint_size.max(Vector2i.ONE))
