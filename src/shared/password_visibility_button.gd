class_name PasswordVisibilityButton
extends Button

var revealed := false

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
    icon = load("res://assets/ui/cursors/password_eye_visible.png" if revealed else "res://assets/ui/cursors/password_eye_hidden.png") as Texture2D
    tooltip_text = "Ocultar contraseña" if revealed else "Mostrar contraseña"
