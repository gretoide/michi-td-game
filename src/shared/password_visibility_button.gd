class_name PasswordVisibilityButton
extends Control

signal toggled(visible: bool)
var revealed := false

func _ready() -> void:
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        revealed = not revealed
        toggled.emit(revealed)
        queue_redraw()
        accept_event()

func _draw() -> void:
    var c := Color("fff3d6")
    var center := size * 0.5
    var radius: float = min(size.x, size.y) * 0.22
    draw_arc(center, radius, 0.0, TAU, 24, c, 2.0)
    draw_circle(center, radius * 0.35, c)
    if not revealed:
        draw_line(Vector2(center.x - radius * 1.35, center.y - radius * 1.35), Vector2(center.x + radius * 1.35, center.y + radius * 1.35), c, 2.5)
