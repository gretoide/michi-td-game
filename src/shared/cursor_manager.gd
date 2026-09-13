extends Node

const NORMAL_CURSOR := "res://assets/ui/cursors/cursor_normal.png"
const CLICK_CURSOR := "res://assets/ui/cursors/cursor_click.png"
const LOADER_FRAMES := [
    "res://assets/ui/cursors/loader_cursor_1.png",
    "res://assets/ui/cursors/loader_cursor_2.png",
]
const CURSOR_SIZE := 20
var _texture_cache: Dictionary = {}

var _busy := false
var _loader_index := 0
var _loader_timer: Timer

func _ready() -> void:
    _loader_timer = Timer.new()
    _loader_timer.wait_time = 0.22
    _loader_timer.timeout.connect(_advance_loader)
    add_child(_loader_timer)
    _apply_normal()

func set_clickable(control: Control) -> void:
    control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    UiSoundManager.attach_control(control)

func set_busy(busy: bool) -> void:
    if _busy == busy:
        return
    _busy = busy
    if busy:
        _loader_index = 0
        _apply_loader()
        _loader_timer.start()
    else:
        _loader_timer.stop()
        _apply_normal()

func _advance_loader() -> void:
    _loader_index = (_loader_index + 1) % LOADER_FRAMES.size()
    _apply_loader()

func _apply_normal() -> void:
    var normal_texture := _scaled_texture(NORMAL_CURSOR)
    var click_texture := _scaled_texture(CLICK_CURSOR)
    if normal_texture == null or click_texture == null:
        return
    Input.set_custom_mouse_cursor(normal_texture, Input.CURSOR_ARROW, Vector2(2, 2))
    Input.set_custom_mouse_cursor(click_texture, Input.CURSOR_POINTING_HAND, Vector2(2, 2))
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _apply_loader() -> void:
    var texture := _scaled_texture(LOADER_FRAMES[_loader_index])
    if texture == null:
        return
    Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, Vector2(10, 10))
    Input.set_custom_mouse_cursor(texture, Input.CURSOR_POINTING_HAND, Vector2(10, 10))
    Input.set_default_cursor_shape(Input.CURSOR_BUSY)

func _scaled_texture(path: String) -> Texture2D:
    if _texture_cache.has(path):
        return _texture_cache[path]
    var source := load(path) as Texture2D
    if source == null:
        return null
    var image := source.get_image()
    image.resize(CURSOR_SIZE, CURSOR_SIZE, Image.INTERPOLATE_NEAREST)
    var texture := ImageTexture.create_from_image(image)
    _texture_cache[path] = texture
    return texture
