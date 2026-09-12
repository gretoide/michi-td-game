class_name EmailVerificationView
extends PanelContainer

signal verify_requested(code: String)
signal resend_requested

var code_input: LineEdit
var message: Label
var message_box: PanelContainer
var verify_button: Button
var resend_button: Button

func setup(email: String) -> void:
    add_theme_stylebox_override("panel", StyleBoxEmpty.new())
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 64); margin.add_theme_constant_override("margin_right", 64); margin.add_theme_constant_override("margin_top", 68); margin.add_theme_constant_override("margin_bottom", 28)
    add_child(margin)
    var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 11); margin.add_child(column)
    var title := Label.new(); title.text = "Confirmá tu email"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 28); _style_readable_label(title, Color("321c12")); column.add_child(title)
    var hint := Label.new(); hint.text = "Enviamos un código a " + email + "\nTiene una validez de 15 minutos."; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hint.add_theme_font_size_override("font_size", 18); _style_readable_label(hint, Color("4a2817")); column.add_child(hint)
    var code_label := Label.new(); code_label.text = "Código de verificación"; code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; code_label.add_theme_font_size_override("font_size", 17); _style_readable_label(code_label, Color("321c12")); column.add_child(code_label)
    code_input = LineEdit.new(); code_input.placeholder_text = "Ingresá los 6 dígitos"; code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER; code_input.max_length = 6; code_input.custom_minimum_size = Vector2(0,48); code_input.add_theme_font_size_override("font_size", 22)
    var style := StyleBoxFlat.new(); style.bg_color = Color("21150f"); style.border_color = Color("8b4c29"); style.set_border_width_all(2); style.set_corner_radius_all(6); style.content_margin_left = 14; style.content_margin_right = 14; style.content_margin_top = 8; style.content_margin_bottom = 8
    var focus := style.duplicate() as StyleBoxFlat; focus.bg_color = Color("2a1a12"); focus.border_color = Color("d18a3b"); focus.set_border_width_all(3); code_input.add_theme_stylebox_override("normal",style); code_input.add_theme_stylebox_override("focus",focus); code_input.add_theme_color_override("font_color",Color("fff8e5")); code_input.add_theme_color_override("caret_color",Color("f0b45c")); code_input.add_theme_color_override("font_placeholder_color",Color("e8cfac")); column.add_child(code_input)
    verify_button = Button.new(); verify_button.text = "Confirmar código"; verify_button.custom_minimum_size = Vector2(0,50); _style_button(verify_button,true); verify_button.pressed.connect(func(): verify_requested.emit(code_input.text.strip_edges())); column.add_child(verify_button)
    resend_button = Button.new(); resend_button.text = "Reenviar código"; resend_button.custom_minimum_size = Vector2(0,42); _style_button(resend_button,false); resend_button.pressed.connect(func(): resend_requested.emit()); column.add_child(resend_button)
    message_box = PanelContainer.new(); message_box.visible = false; message_box.custom_minimum_size = Vector2(0, 58)
    var message_style := StyleBoxFlat.new(); message_style.bg_color = Color("5a321f"); message_style.border_color = Color("c87a35"); message_style.set_border_width_all(2); message_style.set_corner_radius_all(8); message_style.content_margin_left = 16; message_style.content_margin_right = 16; message_style.content_margin_top = 8; message_style.content_margin_bottom = 8; message_box.add_theme_stylebox_override("panel", message_style)
    message = Label.new(); message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.add_theme_font_size_override("font_size", 16); message.add_theme_color_override("font_outline_color", Color("3b2619")); message.add_theme_constant_override("outline_size", 1); message_box.add_child(message); column.add_child(message_box)

func _style_button(button: Button, primary: bool) -> void:
    var normal := "res://assets/ui/rustic-pack/UI-Singles/UI - 44.png"
    var hover := "res://assets/ui/rustic-pack/UI-Singles/UI - 45.png"
    button.add_theme_stylebox_override("normal", _wood_style(normal))
    button.add_theme_stylebox_override("hover", _wood_style(hover))
    button.add_theme_stylebox_override("pressed", _wood_style(hover,Color(0.88,0.88,0.88,1.0)))
    button.add_theme_stylebox_override("focus", _wood_style(normal))
    button.add_theme_color_override("font_color",Color("fff3d6"))
    button.add_theme_color_override("font_hover_color",Color("ffd56a"))
    button.add_theme_color_override("font_pressed_color",Color("fff3d6"))
    button.add_theme_color_override("font_outline_color", Color("3a2116"))
    button.add_theme_constant_override("outline_size", 2)

func _style_readable_label(label: Label, color: Color) -> void:
    label.add_theme_color_override("font_color", color)

func _wood_style(path: String, tint := Color.WHITE) -> StyleBoxTexture:
    var style := StyleBoxTexture.new(); style.texture = load(path); style.texture_margin_left = 7; style.texture_margin_right = 7; style.texture_margin_top = 7; style.texture_margin_bottom = 7; style.modulate_color = tint; return style

func set_busy(busy: bool) -> void:
    verify_button.disabled = busy; resend_button.disabled = busy
func show_message(text: String, is_error := true) -> void:
    message.text = text; message.add_theme_color_override("font_color", Color("fff3d6") if is_error else Color("d8f3dc")); message_box.visible = not text.is_empty()
