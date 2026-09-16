@tool
extends Sprite2D

const FRAME_SIZE := Vector2(32.0, 64.0)
const FRAME_COUNT := 6
const FRAME_TIME := 0.16

var _elapsed := 0.0
var _frame := -1

func _ready() -> void:
	if texture is AtlasTexture:
		texture = (texture as AtlasTexture).duplicate()
	set_process(true)
	_apply_frame(0)

func _process(delta: float) -> void:
	_elapsed += delta
	_apply_frame(int(_elapsed / FRAME_TIME) % FRAME_COUNT)

func _apply_frame(value: int) -> void:
	if _frame == value or not texture is AtlasTexture:
		return
	_frame = value
	(texture as AtlasTexture).region = Rect2(FRAME_SIZE.x * value, 0.0, FRAME_SIZE.x, FRAME_SIZE.y)
