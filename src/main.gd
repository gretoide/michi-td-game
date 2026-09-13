extends Node

enum AccessState { LANDING, REGISTER, LOGIN, VERIFY_EMAIL, AUTHENTICATED_HOME }
var access_state := AccessState.LANDING
var api: ApiClient
var auth: AuthService
var root_ui: VBoxContainer
var glass_panel: Panel
var parchment_panel: Panel
var parchment_brightener: ColorRect
var panel_stack: VBoxContainer
var background_texture: TextureRect
var background_next_texture: TextureRect
var backgrounds: Array[Texture2D] = []
var background_index := 0
var background_timer: Timer
var background_transitioning := false
var message_label: Label
var message_panel: PanelContainer
var alias_input: LineEdit
var email_input: LineEdit
var password_input: LineEdit
var password_row: HBoxContainer
var password_visibility_button: Control
var submit_button: Button
var mode_button: Button
var mode_button_label: RichTextLabel
var auth_title: Label
var welcome_menu: VBoxContainer
var back_button: Button
var welcome: WelcomeView
var verification: EmailVerificationView
var verification_email := ""
var verification_password := ""
var register_mode := true
var home_music: AudioStreamPlayer
var music_toggle_button: Button
var session_loader: Control
var session_loader_tween: Tween

func _ready() -> void:
    api = ApiClient.new(); add_child(api)
    auth = AuthService.new(); add_child(auth); auth.setup(api)
    auth.succeeded.connect(_on_auth_succeeded); auth.failed.connect(_on_auth_failed)
    auth.verification_required.connect(_on_verification_required); auth.verification_succeeded.connect(_on_auth_succeeded); auth.resend_succeeded.connect(_on_resend_succeeded)
    auth.restore_failed.connect(_show_landing)
    _build_ui(); _start_home_music()
    if SessionStore.restore_refresh_token():
        _show_session_loader()
        auth.restore_session()
    else:
        _show_landing()

func _start_home_music() -> void:
    var stream := load("res://assets/audio/home_theme.mp3") as AudioStreamMP3
    if stream == null: return
    stream.loop = true; home_music = AudioStreamPlayer.new(); home_music.stream = stream; home_music.volume_db = -16.0; add_child(home_music); home_music.play(); _update_music_toggle()

func _build_ui() -> void:
    var background := ColorRect.new(); background.color = Color("0e1524"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
    backgrounds = [
        load("res://assets/art/backgrounds/kingdom.png") as Texture2D,
        load("res://assets/art/backgrounds/battlefield.png") as Texture2D,
        load("res://assets/art/backgrounds/forge.png") as Texture2D,
        load("res://assets/art/backgrounds/war_room.png") as Texture2D,
        load("res://assets/art/backgrounds/tavern_feast.png") as Texture2D,
    ]
    background_texture = _create_background_layer(background)
    background_next_texture = _create_background_layer(background)
    background_texture.texture = backgrounds[0]
    background_next_texture.modulate.a = 0.0
    var overlay := ColorRect.new(); overlay.color = Color(0.02,0.04,0.08,0.30); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; background.add_child(overlay)
    background_timer = Timer.new(); background_timer.wait_time = 8.0; background_timer.autostart = true; background_timer.timeout.connect(_rotate_background); add_child(background_timer)
    var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(center)
    panel_stack = VBoxContainer.new(); panel_stack.alignment = BoxContainer.ALIGNMENT_CENTER; panel_stack.add_theme_constant_override("separation", 18); center.add_child(panel_stack)
    glass_panel = Panel.new(); glass_panel.custom_minimum_size = Vector2(640,400); glass_panel.add_theme_stylebox_override("panel", _texture_style("res://assets/ui/panels/large_stone.png",42)); panel_stack.add_child(glass_panel)
    parchment_panel = Panel.new(); parchment_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); parchment_panel.offset_left = 18; parchment_panel.offset_top = 18; parchment_panel.offset_right = -18; parchment_panel.offset_bottom = -18; parchment_panel.add_theme_stylebox_override("panel",_texture_style("res://assets/ui/panels/large_parchment.png",38,Color(1.18,1.10,0.96,1.0))); glass_panel.add_child(parchment_panel)
    parchment_brightener = ColorRect.new(); parchment_brightener.color = Color(1.0,0.95,0.82,0.62); parchment_brightener.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); parchment_brightener.offset_left = 34; parchment_brightener.offset_top = 34; parchment_brightener.offset_right = -34; parchment_brightener.offset_bottom = -34; parchment_brightener.mouse_filter = Control.MOUSE_FILTER_IGNORE; parchment_brightener.visible = false; parchment_panel.add_child(parchment_brightener)
    var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",64); margin.add_theme_constant_override("margin_right",64); margin.add_theme_constant_override("margin_top",90); margin.add_theme_constant_override("margin_bottom",42); parchment_panel.add_child(margin)
    root_ui = VBoxContainer.new(); root_ui.add_theme_constant_override("separation",12); var theme := Theme.new(); theme.default_font = load("res://assets/fonts/comic_neue_sans_id.ttf"); theme.default_font_size = 20; theme.set_color("font_color","Label",Color("321c12")); theme.set_color("font_color","Button",Color("321c12")); parchment_panel.theme = theme; root_ui.theme = theme; margin.add_child(root_ui)
    _create_title_sign()
    welcome_menu = VBoxContainer.new(); welcome_menu.add_theme_constant_override("separation",14)
    var welcome_label := Label.new(); welcome_label.text = "Bienvenido al reino"; welcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; welcome_label.add_theme_font_size_override("font_size",30); welcome_menu.add_child(welcome_label)
    var hint := Label.new(); hint.text = "Elegí cómo querés comenzar tu aventura"; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; welcome_menu.add_child(hint)
    var choices := HBoxContainer.new(); choices.alignment = BoxContainer.ALIGNMENT_CENTER; choices.add_theme_constant_override("separation",14)
    var create_button := Button.new(); create_button.text = "Crear cuenta"; create_button.custom_minimum_size = Vector2(205,58); _style_action_button(create_button,true); create_button.pressed.connect(func(): _open_auth(true)); choices.add_child(create_button)
    var login_button := Button.new(); login_button.text = "Iniciar sesión"; login_button.custom_minimum_size = Vector2(205,58); _style_action_button(login_button,false); login_button.pressed.connect(func(): _open_auth(false)); choices.add_child(login_button)
    welcome_menu.add_child(choices); root_ui.add_child(welcome_menu)
    auth_title = Label.new(); auth_title.add_theme_font_size_override("font_size",25); auth_title.visible = false; root_ui.add_child(auth_title)
    alias_input = _create_input("Alias",false); alias_input.visible = false; root_ui.add_child(alias_input)
    email_input = _create_input("Email",false); email_input.visible = false; root_ui.add_child(email_input)
    password_input = _create_input("Contraseña",true); password_row = HBoxContainer.new(); password_row.add_theme_constant_override("separation",8); password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL; password_row.add_child(password_input)
    password_visibility_button = PasswordVisibilityButton.new(); password_visibility_button.custom_minimum_size = Vector2(48,42); password_visibility_button.toggled.connect(_toggle_password_visibility); password_row.add_child(password_visibility_button); password_row.visible = false; root_ui.add_child(password_row)
    submit_button = Button.new(); submit_button.custom_minimum_size = Vector2(0,54); _style_action_button(submit_button,true); submit_button.pressed.connect(_submit_auth); submit_button.visible = false; root_ui.add_child(submit_button)
    mode_button = Button.new(); mode_button.flat = true; mode_button.custom_minimum_size = Vector2(0,38); mode_button.pressed.connect(_toggle_mode); mode_button.mouse_entered.connect(func(): _set_mode_button_text(true)); mode_button.mouse_exited.connect(func(): _set_mode_button_text(false)); mode_button.visible = false; _style_link_button(mode_button); root_ui.add_child(mode_button)
    mode_button_label = RichTextLabel.new(); mode_button_label.bbcode_enabled = true; mode_button_label.fit_content = true; mode_button_label.scroll_active = false; mode_button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; mode_button_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mode_button_label.offset_top = 3; mode_button_label.offset_bottom = -3; mode_button_label.add_theme_font_size_override("normal_font_size",20); mode_button.add_child(mode_button_label)
    message_panel = PanelContainer.new(); message_panel.visible = false; message_panel.custom_minimum_size = Vector2(520,108); message_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    message_panel.add_theme_stylebox_override("panel",_texture_style("res://assets/ui/panels/small_stone.png",28))
    var alert_margin := MarginContainer.new(); alert_margin.add_theme_constant_override("margin_left",42); alert_margin.add_theme_constant_override("margin_right",42); alert_margin.add_theme_constant_override("margin_top",20); alert_margin.add_theme_constant_override("margin_bottom",20); message_panel.add_child(alert_margin)
    var alert_row := HBoxContainer.new(); alert_row.alignment = BoxContainer.ALIGNMENT_CENTER; alert_row.add_theme_constant_override("separation",14); alert_margin.add_child(alert_row)
    var alert_icon := TextureRect.new(); alert_icon.texture = load("res://assets/ui/icons/alert_error.png"); alert_icon.custom_minimum_size = Vector2(44,44); alert_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; alert_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; alert_row.add_child(alert_icon)
    message_label = Label.new(); message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; message_label.add_theme_color_override("font_color",Color("fff1d0")); message_label.add_theme_font_size_override("font_size",17); alert_row.add_child(message_label); panel_stack.add_child(message_panel)
    back_button = Button.new(); back_button.text = "Volver"; back_button.icon = load("res://assets/ui/icons/back.png"); back_button.expand_icon = true; back_button.custom_minimum_size = Vector2(150,44); back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; _style_action_button(back_button,false); back_button.visible = false; back_button.pressed.connect(_show_landing); panel_stack.add_child(back_button)
    _create_music_toggle()

func _create_title_sign() -> void:
    var sign := PanelContainer.new(); sign.z_index = 10; sign.mouse_filter = Control.MOUSE_FILTER_IGNORE; sign.anchor_left = 0.5; sign.anchor_right = 0.5; sign.offset_left = -190; sign.offset_right = 190; sign.offset_top = -52; sign.offset_bottom = 72; sign.add_theme_stylebox_override("panel",_wood_style("res://assets/ui/decorations/title_sign.png")); glass_panel.add_child(sign)
    var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation",18); sign.add_child(row); row.add_child(_create_sign_stud())
    var title := Label.new(); title.text = "Michi"; title.custom_minimum_size = Vector2(250,0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",72); title.add_theme_font_override("font",load("res://assets/fonts/kelmscott.ttf")); title.add_theme_color_override("font_color",Color("fff3d6")); row.add_child(title); row.add_child(_create_sign_stud())

func _create_sign_stud() -> TextureRect:
    var stud := TextureRect.new(); stud.texture = load("res://assets/ui/icons/decorative_stud.png"); stud.custom_minimum_size = Vector2(26,26); stud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; stud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; stud.mouse_filter = Control.MOUSE_FILTER_IGNORE; return stud

func _wood_style(path: String) -> StyleBoxTexture:
    var style := StyleBoxTexture.new(); style.texture = load(path); style.texture_margin_left = 8; style.texture_margin_right = 8; style.texture_margin_top = 8; style.texture_margin_bottom = 8; style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE; style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE; return style

func _texture_style(path: String, margin: float, tint := Color.WHITE) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load(path)
    style.texture_margin_left = margin; style.texture_margin_right = margin
    style.texture_margin_top = margin; style.texture_margin_bottom = margin
    style.modulate_color = tint
    return style

func _style_action_button(button: Button, primary: bool) -> void:
    var normal := "res://assets/ui/buttons/button_normal.png"
    var hover := "res://assets/ui/buttons/button_hover.png"
    button.add_theme_stylebox_override("normal",_texture_style(normal,7))
    button.add_theme_stylebox_override("hover",_texture_style(hover,7))
    button.add_theme_stylebox_override("pressed",_texture_style(hover,7,Color(0.88,0.88,0.88,1.0)))
    button.add_theme_stylebox_override("focus",_texture_style(normal,7))
    button.add_theme_color_override("font_color",Color("fff3d6"))
    button.add_theme_color_override("font_hover_color",Color("ffd56a"))
    button.add_theme_color_override("font_pressed_color",Color("fff3d6"))

func _style_link_button(button: Button) -> void:
    var empty := StyleBoxEmpty.new()
    button.add_theme_stylebox_override("normal", empty)
    button.add_theme_stylebox_override("hover", empty)
    button.add_theme_stylebox_override("pressed", empty)
    button.add_theme_stylebox_override("focus", empty)

func _create_input(placeholder: String, secret: bool) -> LineEdit:
    var field := LineEdit.new(); field.placeholder_text = placeholder; field.custom_minimum_size = Vector2(0,44); field.secret = secret; var normal := StyleBoxFlat.new(); normal.bg_color = Color("241913"); normal.border_color = Color("5f3826"); normal.set_border_width_all(2); normal.set_corner_radius_all(4); normal.content_margin_left = 14; normal.content_margin_right = 14; normal.content_margin_top = 8; normal.content_margin_bottom = 8; var focus := normal.duplicate() as StyleBoxFlat; focus.border_color = Color("c87a35"); field.add_theme_stylebox_override("normal",normal); field.add_theme_stylebox_override("focus",focus); field.add_theme_color_override("font_color",Color("fff3d6")); field.add_theme_color_override("font_placeholder_color",Color(0.92,0.86,0.76,0.72)); return field

func _create_music_toggle() -> void:
    music_toggle_button = Button.new(); music_toggle_button.z_index = 50; music_toggle_button.flat = true; music_toggle_button.expand_icon = true; music_toggle_button.add_theme_constant_override("icon_max_width",44); music_toggle_button.custom_minimum_size = Vector2(68,68); music_toggle_button.set_anchors_preset(Control.PRESET_TOP_RIGHT); music_toggle_button.offset_left = -92; music_toggle_button.offset_top = 24; music_toggle_button.offset_right = -24; music_toggle_button.offset_bottom = 92; music_toggle_button.pressed.connect(_toggle_home_music); add_child(music_toggle_button)
func _toggle_home_music() -> void:
    if is_instance_valid(home_music): home_music.stream_paused = not home_music.stream_paused
    _update_music_toggle()
func _update_music_toggle() -> void:
    if not is_instance_valid(music_toggle_button): return
    var playing := is_instance_valid(home_music) and not home_music.stream_paused; music_toggle_button.icon = load("res://assets/ui/icons/music_enabled.png" if playing else "res://assets/ui/icons/music_disabled.png"); music_toggle_button.tooltip_text = "Pausar música" if playing else "Reproducir música"

func _toggle_password_visibility(visible: bool) -> void: password_input.secret = not visible
func _toggle_mode() -> void: _open_auth(not register_mode)

func _set_mode_button_text(hover := false) -> void:
    if not is_instance_valid(mode_button_label):
        return
    var prompt := "¿Ya defendiste este reino?"
    var action := "Iniciar sesión"
    if not register_mode:
        prompt = "¿Primera vez en el reino?"
        action = "Crear cuenta"
    var action_color := "8d421d" if not hover else "b85b24"
    mode_button_label.text = "[center][color=#321c12]%s[/color] [b][color=#%s]%s[/color][/b][/center]" % [prompt, action_color, action]

func _open_auth(register: bool) -> void:
    parchment_brightener.visible = false
    access_state = AccessState.REGISTER if register else AccessState.LOGIN
    register_mode = register
    glass_panel.custom_minimum_size = Vector2(640,520 if register else 465)
    welcome_menu.visible = false
    auth_title.visible = true
    alias_input.visible = register
    email_input.visible = true
    password_row.visible = true
    submit_button.visible = true
    mode_button.visible = true
    message_panel.visible = false
    back_button.visible = true
    auth_title.text = "Crear cuenta" if register else "Iniciar sesión"
    submit_button.text = "Registrarme" if register else "Entrar"
    _set_mode_button_text(false)
    message_label.text = ""
    _fade_content()
func _show_landing() -> void:
    _hide_session_loader()
    parchment_brightener.visible = false
    access_state = AccessState.LANDING
    glass_panel.custom_minimum_size = Vector2(640,400)
    if is_instance_valid(verification):
        verification.queue_free()
        verification = null
    if is_instance_valid(welcome):
        welcome.queue_free()
        welcome = null
    root_ui.visible = true
    welcome_menu.visible = true
    auth_title.visible = false
    alias_input.visible = false
    email_input.visible = false
    password_row.visible = false
    submit_button.visible = false
    mode_button.visible = false
    message_panel.visible = false
    back_button.visible = false
    _fade_content()
func _fade_content() -> void: root_ui.modulate.a = 0.0; create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(root_ui,"modulate:a",1.0,0.22)
func _submit_auth() -> void:
    message_panel.visible = false; message_label.text = ""; submit_button.disabled = true
    if register_mode: verification_email = email_input.text.strip_edges(); verification_password = password_input.text; auth.register(alias_input.text,email_input.text,password_input.text)
    else: auth.login(email_input.text,password_input.text)
func _on_auth_succeeded(session: Dictionary) -> void:
    submit_button.disabled = false
    var session_user := session.get("user", {}) as Dictionary
    _show_welcome(str(session_user.get("alias", SessionStore.user.get("alias", "jugador"))))
func _on_verification_required(email: String) -> void: submit_button.disabled = false; verification_email = email if email != "" else email_input.text.strip_edges(); verification_password = password_input.text; _show_verification()
func _show_verification() -> void:
    access_state = AccessState.VERIFY_EMAIL; glass_panel.custom_minimum_size = Vector2(640,520); parchment_brightener.visible = false; root_ui.visible = false; back_button.visible = true; verification = EmailVerificationView.new(); verification.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); verification.setup(verification_email); verification.verify_requested.connect(_verify_code); verification.resend_requested.connect(_resend_code); parchment_panel.add_child(verification)
func _verify_code(code: String) -> void:
    if code.length() != 6 or not code.is_valid_int(): verification.show_message("Ingresá un código válido de 6 dígitos"); return
    verification.set_busy(true); auth.verify_email(verification_email,code)
func _resend_code() -> void: verification.set_busy(true); auth.resend_verification(verification_email,verification_password)
func _on_resend_succeeded() -> void:
    if is_instance_valid(verification): verification.set_busy(false); verification.show_message("Código reenviado. Revisá tu bandeja de entrada.", false)
func _on_auth_failed(error: String) -> void:
    submit_button.disabled = false
    if is_instance_valid(verification): verification.set_busy(false); verification.show_message(_friendly_error(error)); return
    var friendly := _friendly_error(error)
    message_label.text = friendly
    var message_lines := friendly.count("\n") + 1
    message_panel.custom_minimum_size.y = clampf(72.0 + message_lines * 22.0,108.0,174.0)
    message_panel.visible = true
func _show_welcome(alias := "") -> void:
    _hide_session_loader()
    parchment_brightener.visible = false
    var display_alias := alias if not alias.is_empty() else str(SessionStore.user.get("alias", "jugador"))
    access_state = AccessState.AUTHENTICATED_HOME
    root_ui.visible = false
    back_button.visible = false
    if is_instance_valid(verification):
        verification.queue_free()
    verification = null
    if is_instance_valid(welcome):
        welcome.queue_free()
    welcome = WelcomeView.new()
    welcome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    welcome.z_index = 5
    welcome.setup(display_alias)
    parchment_panel.add_child(welcome)

func _show_session_loader() -> void:
    root_ui.visible = false
    back_button.visible = false
    session_loader = CenterContainer.new()
    session_loader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    session_loader.z_index = 6
    var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; column.add_theme_constant_override("separation", 16); session_loader.add_child(column)
    var label := Label.new(); label.text = "Reconociendo tu sesión..."; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 24); label.add_theme_color_override("font_color", Color("321c12")); column.add_child(label)
    var progress := ProgressBar.new(); progress.custom_minimum_size = Vector2(280, 16); progress.show_percentage = false
    var track := StyleBoxFlat.new(); track.bg_color = Color("d6a66d"); track.set_corner_radius_all(8); progress.add_theme_stylebox_override("background", track)
    var fill := StyleBoxFlat.new(); fill.bg_color = Color("9a4e26"); fill.set_corner_radius_all(8); progress.add_theme_stylebox_override("fill", fill); column.add_child(progress)
    parchment_panel.add_child(session_loader)
    session_loader_tween = create_tween().set_loops(); session_loader_tween.tween_property(progress, "value", 100.0, 1.15).from(0.0)

func _hide_session_loader() -> void:
    if is_instance_valid(session_loader_tween): session_loader_tween.kill()
    session_loader_tween = null
    if is_instance_valid(session_loader): session_loader.queue_free()
    session_loader = null

func _create_background_layer(parent: Node) -> TextureRect:
    var layer := TextureRect.new()
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    layer.modulate = Color(1,1,1,0.66)
    layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(layer)
    return layer

func _rotate_background() -> void:
    if background_transitioning or backgrounds.size() < 2:
        return
    background_transitioning = true
    background_index = (background_index + 1) % backgrounds.size()
    background_next_texture.texture = backgrounds[background_index]
    background_next_texture.modulate.a = 0.0
    var fade := create_tween().set_parallel(true)
    fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    fade.tween_property(background_texture,"modulate:a",0.0,1.8)
    fade.tween_property(background_next_texture,"modulate:a",0.66,1.8)
    fade.chain().tween_callback(_finish_background_transition)

func _finish_background_transition() -> void:
    var previous := background_texture
    background_texture = background_next_texture
    background_next_texture = previous
    background_next_texture.modulate.a = 0.0
    background_transitioning = false

func _friendly_error(error: String) -> String:
    var lower := error.to_lower()
    var messages := PackedStringArray()
    if "alias o email ya está registrado" in lower or "already registered" in lower:
        return "Ese alias o email ya está en uso. Probá con otro o iniciá sesión."
    if "alias must match" in lower:
        messages.append("El alias sólo puede contener letras, números, espacios, guiones y guion bajo.")
    if "alias must be longer" in lower or "alias must be at least" in lower:
        messages.append("El alias debe tener al menos 3 caracteres.")
    if "email must be an email" in lower:
        messages.append("Ingresá un email válido.")
    if "password must be longer" in lower or "password must be at least" in lower:
        messages.append("La contraseña debe tener al menos 8 caracteres.")
    if "invalid credentials" in lower or "credenciales" in lower:
        return "El email o la contraseña no son correctos."
    if "código inválido o expirado" in lower:
        return "Ese código ya no es válido. Pedí uno nuevo con «Reenviar código»."
    if "código inválido" in lower:
        return "El código ingresado no coincide. Revisalo e intentá nuevamente."
    if "código expiró" in lower:
        return "El código venció. Pedí uno nuevo con «Reenviar código»."
    if "superaste los intentos" in lower:
        return "Alcanzaste el límite de intentos. Reenviá el código para generar uno nuevo."
    if "esperá un minuto" in lower:
        return "El código se envió hace poco. Esperá un minuto antes de pedir otro."
    if "email no está configurado" in lower or "email_not_configured" in lower:
        return "El servidor todavía no tiene configurado el envío de emails."
    if "no se pudo enviar el email" in lower or "verification_delivery_failed" in lower:
        return "No pudimos enviar el código por email. Intentá nuevamente en unos minutos."
    if "ya hay una solicitud en curso" in lower:
        return "Hay otra operación en curso. Esperá un momento e intentá nuevamente."
    if "no se pudo conectar" in lower or "no se pudo iniciar la solicitud" in lower or "conectar con la api" in lower:
        return "No pudimos conectar con el servidor. Revisá tu conexión e intentá nuevamente."
    if not messages.is_empty():
        return "\n".join(messages)
    var detail := error.strip_edges()
    var separator := detail.find(": ")
    if separator >= 0:
        detail = detail.substr(separator + 2).strip_edges()
    if not detail.is_empty() and detail.length() <= 180 and not "{" in detail and not "[" in detail:
        return detail
    return "Ocurrió un error inesperado. Intentá nuevamente; si continúa, revisá los logs del servidor."
