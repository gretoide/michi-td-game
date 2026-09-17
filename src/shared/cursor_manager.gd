extends Node

var _texture_cache: Dictionary = {}
var visual_assets: VisualAssetConfig

var _busy := false
var _loader_index := 0
var _loader_timer: Timer

func _ready() -> void:
    if visual_assets == null:
        visual_assets = VisualAssetConfig.new()
    _loader_timer = Timer.new()
    _loader_timer.wait_time = 0.22
    _loader_timer.timeout.connect(_advance_loader)
    add_child(_loader_timer)
    _apply_normal()

func configure(value: VisualAssetConfig) -> void:
    visual_assets = value if value != null else VisualAssetConfig.new()
    _texture_cache.clear()
    if is_inside_tree():
        _apply_normal()

func set_clickable(control: Control) -> void:
    control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    UiSoundManager.attach_control(control)

func set_text_cursor(control: Control) -> void:
    control.mouse_default_cursor_shape = Control.CURSOR_IBEAM

func set_construction_cursor(active: bool) -> void:
    if active:
        var texture := _scaled_texture(visual_assets.cursor_construction, "construction")
        if texture != null:
            Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, visual_assets.cursor_construction_hotspot)
            Input.set_default_cursor_shape(Input.CURSOR_ARROW)
    else:
        _apply_normal()

func set_map_cursor(construction_active: bool) -> void:
    if construction_active:
        set_construction_cursor(true)
        return
    # Keep the selected Kenney cursor everywhere when no construction action
    # is active, including occupied or invalid map cells.
    _apply_normal()

func restore_normal_cursor() -> void:
    _apply_normal()

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
    _loader_index = (_loader_index + 1) % 4
    _apply_loader()

func _apply_normal() -> void:
    var normal_texture := _scaled_texture(visual_assets.cursor_normal, "normal")
    var click_texture := _scaled_texture(visual_assets.cursor_click, "click")
    if normal_texture == null or click_texture == null:
        return
    Input.set_custom_mouse_cursor(normal_texture, Input.CURSOR_ARROW, visual_assets.cursor_normal_hotspot)
    Input.set_custom_mouse_cursor(click_texture, Input.CURSOR_POINTING_HAND, visual_assets.cursor_click_hotspot)
    var text_texture := _scaled_texture(visual_assets.cursor_text, "text")
    if text_texture != null:
        Input.set_custom_mouse_cursor(text_texture, Input.CURSOR_IBEAM, visual_assets.cursor_text_hotspot)
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _apply_loader() -> void:
    var frames: Array[Texture2D] = [visual_assets.cursor_loader_1, visual_assets.cursor_loader_2, visual_assets.cursor_loader_3, visual_assets.cursor_loader_4]
    var source := frames[_loader_index]
    var texture := _scaled_texture(source, "loader_%d" % _loader_index)
    if texture == null:
        return
    Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, visual_assets.cursor_loader_hotspot)
    Input.set_custom_mouse_cursor(texture, Input.CURSOR_POINTING_HAND, visual_assets.cursor_loader_hotspot)
    Input.set_default_cursor_shape(Input.CURSOR_BUSY)

func _scaled_texture(source: Texture2D, cache_key: String) -> Texture2D:
    if source == null:
        return null
    if _texture_cache.has(cache_key):
        return _texture_cache[cache_key]
    var image := source.get_image()
    var target_size := maxi(1, visual_assets.cursor_size)
    image.resize(target_size, target_size, Image.INTERPOLATE_NEAREST)
    var texture := ImageTexture.create_from_image(image)
    _texture_cache[cache_key] = texture
    return texture
