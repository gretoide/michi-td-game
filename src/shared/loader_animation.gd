extends TextureRect

## Displays the login loader spritesheet as one animated cat at a time.
## The source image is authored as eight separate horizontal frames with
## transparent space between them, so a single TextureRect would show all
## cats at once.

@export var frames_per_second := 7.0

const FRAME_REGIONS: Array[Rect2] = [
	Rect2(27, 79, 267, 500),
	Rect2(299, 110, 273, 548),
	Rect2(580, 123, 264, 553),
	Rect2(846, 185, 258, 515),
	Rect2(1102, 223, 242, 492),
	Rect2(1339, 295, 253, 373),
	Rect2(1614, 148, 264, 510),
	Rect2(1886, 77, 259, 528),
]

var _source_texture: Texture2D
var _frame_textures: Array[Texture2D] = []
var _frame_index := 0
var _elapsed := 0.0

func setup(source: Texture2D) -> void:
	_source_texture = source
	_frame_textures.clear()
	_frame_index = 0
	_elapsed = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_frame()
	set_process(_source_texture != null and FRAME_REGIONS.size() > 1)

func setup_frames(frames: Array[Texture2D]) -> void:
	_source_texture = null
	_frame_textures = frames.filter(func(frame: Texture2D) -> bool: return frame != null)
	_frame_index = 0
	_elapsed = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_frame()
	set_process(_frame_textures.size() > 1)

func _process(delta: float) -> void:
	if _source_texture == null and _frame_textures.is_empty() or frames_per_second <= 0.0:
		return
	_elapsed += delta
	var frame_duration := 1.0 / frames_per_second
	if _elapsed < frame_duration:
		return
	_elapsed = fmod(_elapsed, frame_duration)
	var frame_count := _frame_textures.size() if not _frame_textures.is_empty() else FRAME_REGIONS.size()
	_frame_index = (_frame_index + 1) % frame_count
	_apply_frame()

func _apply_frame() -> void:
	if not _frame_textures.is_empty():
		texture = _frame_textures[_frame_index]
		return
	if _source_texture == null:
		texture = null
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = _source_texture
	atlas.region = FRAME_REGIONS[_frame_index]
	texture = atlas
