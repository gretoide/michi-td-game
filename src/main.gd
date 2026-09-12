extends Node

var api: ApiClient
var auth: AuthService
var root_ui: VBoxContainer
var glass_panel: Panel
var background_texture: TextureRect
var background_next_texture: TextureRect
var background_index := 0
var background_timer: Timer
var backgrounds: Array[Texture2D] = []
var message_label: Label
var alias_input: LineEdit
var email_input: LineEdit
var password_input: LineEdit
var submit_button: Button
var mode_button: Button
var auth_title: Label
var welcome: WelcomeView
var register_mode := true

func _ready() -> void:
    backgrounds = [
        load("res://assets/backgrounds/battlefield.png") as Texture2D,
        load("res://assets/backgrounds/forge.png") as Texture2D,
        load("res://assets/backgrounds/war_room.png") as Texture2D,
    ]
    api = ApiClient.new()
    add_child(api)
    auth = AuthService.new()
    add_child(auth)
    auth.setup(api)
    auth.succeeded.connect(_on_auth_succeeded)
    auth.failed.connect(_on_auth_failed)
    _build_ui()
    background_timer = Timer.new()
    background_timer.wait_time = 8.0
    background_timer.autostart = true
    background_timer.timeout.connect(_rotate_background)
    add_child(background_timer)

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("0e1524")
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    background_texture = _create_background_layer(background)
    background_next_texture = _create_background_layer(background)
    background_next_texture.modulate.a = 0.0
    _set_background(0)
    var overlay := ColorRect.new()
    overlay.color = Color(0.02, 0.04, 0.08, 0.28)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.add_child(overlay)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    glass_panel = Panel.new()
    glass_panel.custom_minimum_size = Vector2(620, 540)
    var glass_style := StyleBoxFlat.new()
    glass_style.bg_color = Color(0.05, 0.08, 0.15, 0.34)
    glass_style.border_color = Color(0.75, 0.86, 1.0, 0.45)
    glass_style.set_border_width_all(1)
    glass_style.set_corner_radius_all(22)
    glass_panel.add_theme_stylebox_override("panel", glass_style)
    center.add_child(glass_panel)
    var glass_blur := ColorRect.new()
    glass_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    glass_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shader := load("res://src/shared/glass_blur.gdshader") as Shader
    var shader_material := ShaderMaterial.new()
    shader_material.shader = shader
    glass_blur.material = shader_material
    glass_panel.add_child(glass_blur)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 58)
    margin.add_theme_constant_override("margin_right", 58)
    margin.add_theme_constant_override("margin_top", 46)
    margin.add_theme_constant_override("margin_bottom", 46)
    glass_panel.add_child(margin)
    root_ui = VBoxContainer.new()
    root_ui.custom_minimum_size = Vector2(504, 0)
    root_ui.add_theme_constant_override("separation", 13)
    margin.add_child(root_ui)
    var title := Label.new()
    title.text = "M I C H I   T D"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 46)
    root_ui.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Tower defense 2D"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_ui.add_child(subtitle)
    auth_title = Label.new()
    auth_title.text = "Crear cuenta"
    auth_title.add_theme_font_size_override("font_size", 24)
    root_ui.add_child(auth_title)
    alias_input = _create_input("Alias", false)
    root_ui.add_child(alias_input)
    email_input = _create_input("Email", false)
    root_ui.add_child(email_input)
    password_input = _create_input("Contraseña", true)
    var password_row := HBoxContainer.new()
    password_row.add_theme_constant_override("separation", 8)
    password_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    password_row.add_child(password_input)
    var password_toggle := Button.new()
    password_toggle.text = "◉"
    password_toggle.tooltip_text = "Mostrar u ocultar contraseña"
    password_toggle.custom_minimum_size = Vector2(48, 42)
    password_toggle.focus_mode = Control.FOCUS_NONE
    password_toggle.pressed.connect(_toggle_password_visibility)
    password_row.add_child(password_toggle)
    root_ui.add_child(password_row)
    submit_button = Button.new()
    submit_button.text = "Registrarme"
    submit_button.custom_minimum_size = Vector2(0, 48)
    submit_button.pressed.connect(_submit_auth)
    root_ui.add_child(submit_button)
    mode_button = Button.new()
    mode_button.text = "Ya tengo una cuenta: iniciar sesión"
    mode_button.flat = true
    mode_button.pressed.connect(_toggle_mode)
    root_ui.add_child(mode_button)
    message_label = Label.new()
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.custom_minimum_size = Vector2(0, 34)
    root_ui.add_child(message_label)

func _create_background_layer(parent: Node) -> TextureRect:
    var layer := TextureRect.new()
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    layer.modulate = Color(1, 1, 1, 0.66)
    layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(layer)
    return layer

func _create_input(placeholder: String, secret: bool) -> LineEdit:
    var field := LineEdit.new()
    field.placeholder_text = placeholder
    field.custom_minimum_size = Vector2(0, 42)
    field.secret = secret
    return field

func _toggle_password_visibility() -> void:
    password_input.secret = not password_input.secret

func _toggle_mode() -> void:
    register_mode = not register_mode
    alias_input.visible = register_mode
    auth_title.text = "Crear cuenta" if register_mode else "Iniciar sesión"
    submit_button.text = "Registrarme" if register_mode else "Entrar"
    mode_button.text = "Ya tengo una cuenta: iniciar sesión" if register_mode else "Crear una cuenta nueva"
    message_label.text = ""

func _set_background(index: int) -> void:
    if backgrounds.is_empty() or not is_instance_valid(background_texture):
        return
    var next_index := posmod(index, backgrounds.size())
    if background_texture.texture == null:
        background_index = next_index
        background_texture.texture = backgrounds[background_index]
        return
    background_index = next_index
    background_next_texture.texture = backgrounds[background_index]
    background_next_texture.modulate.a = 0.0
    var transition := create_tween().set_parallel(true)
    transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    transition.tween_property(background_texture, "modulate:a", 0.0, 1.4)
    transition.tween_property(background_next_texture, "modulate:a", 0.66, 1.4)
    transition.chain().tween_callback(_finish_background_transition)

func _finish_background_transition() -> void:
    var old_texture := background_texture
    background_texture = background_next_texture
    background_next_texture = old_texture
    background_next_texture.modulate.a = 0.0

func _rotate_background() -> void:
    _set_background(background_index + 1)

func _submit_auth() -> void:
    message_label.text = "Enviando..."
    submit_button.disabled = true
    if register_mode:
        auth.register(alias_input.text, email_input.text, password_input.text)
    else:
        auth.login(email_input.text, password_input.text)

func _on_auth_succeeded(_session: Dictionary) -> void:
    submit_button.disabled = false
    _show_welcome()

func _on_auth_failed(error: String) -> void:
    submit_button.disabled = false
    message_label.text = error
    message_label.modulate = Color("f59e9e")

func _show_welcome() -> void:
    root_ui.visible = false
    welcome = WelcomeView.new()
    welcome.custom_minimum_size = Vector2(460, 220)
    welcome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    welcome.setup()
    welcome.logout_requested.connect(_logout)
    glass_panel.add_child(welcome)

func _logout() -> void:
    auth.logout()
    if is_instance_valid(welcome): welcome.queue_free()
    root_ui.visible = true
