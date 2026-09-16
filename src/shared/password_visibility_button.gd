class_name PasswordVisibilityButton
extends Button

var revealed := false
var eye_visible_texture: Texture2D
var eye_hidden_texture: Texture2D

func configure_icons(visible_texture: Texture2D, hidden_texture: Texture2D) -> void:
    eye_visible_texture = visible_texture
    eye_hidden_texture = hidden_texture
    if is_inside_tree():
        _update_icon()

func _ready() -> void:
    text = ""
    focus_mode = Control.FOCUS_ALL
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    toggle_mode = true
    expand_icon = false
    alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_theme_constant_override("icon_max_width", 24)
    var empty := StyleBoxEmpty.new()
    add_theme_stylebox_override("normal", empty)
    add_theme_stylebox_override("hover", empty)
    add_theme_stylebox_override("pressed", empty)
    add_theme_stylebox_override("focus", empty)
    toggled.connect(_on_toggled)
    set_revealed(false)

func _on_toggled(value: bool) -> void:
    revealed = value
    _update_icon()

func set_revealed(value: bool) -> void:
    revealed = value
    button_pressed = value
    _update_icon()

func _update_icon() -> void:
    icon = eye_visible_texture if revealed else eye_hidden_texture
    tooltip_text = LocalizationService.tr_key("password.hide" if revealed else "password.show")
