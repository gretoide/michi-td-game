class_name WelcomeView
extends PanelContainer

signal logout_requested
signal enter_requested

func setup(alias := "jugador", visual_assets: VisualAssetConfig = null) -> void:
    var assets := visual_assets if visual_assets != null else VisualAssetConfig.new()
    custom_minimum_size = Vector2(0, 230)
    add_theme_stylebox_override("panel", StyleBoxEmpty.new())
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 40)
    margin.add_theme_constant_override("margin_right", 40)
    margin.add_theme_constant_override("margin_top", 86)
    margin.add_theme_constant_override("margin_bottom", 28)
    add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    column.add_theme_font_override("font", load("res://assets/fonts/comic_neue_sans_id.ttf"))
    margin.add_child(column)
    var title := Label.new()
    var localization := get_node_or_null("/root/LocalizationService")
    title.text = localization.tr_key("welcome.title", {"alias": alias}) if localization != null else "Bienvenido, " + alias
    title.add_theme_font_size_override("font_size", 32)
    title.add_theme_color_override("font_color", Color("321c12"))
    column.add_child(title)
    var info := Label.new()
    info.text = localization.tr_key("welcome.info") if localization != null else "Tu cuenta está lista. Prepará tus defensas para la próxima batalla."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_color_override("font_color", Color("4a2817"))
    column.add_child(info)
    var enter := Button.new()
    enter.text = (localization.tr_key("welcome.enter") if localization != null else "Ingresar") + "  →"
    enter.icon = assets.main_menu
    enter.expand_icon = true
    enter.custom_minimum_size = Vector2(300, 54)
    enter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    enter.tooltip_text = localization.tr_key("welcome.enter.tooltip") if localization != null else "Ingresar al reino"
    enter.add_theme_stylebox_override("normal", _button_style("res://assets/ui/buttons/button_normal.png"))
    enter.add_theme_stylebox_override("hover", _button_style("res://assets/ui/buttons/button_hover.png"))
    enter.add_theme_stylebox_override("pressed", _button_style("res://assets/ui/buttons/button_hover.png", Color(0.88, 0.88, 0.88, 1.0)))
    enter.add_theme_color_override("font_color", Color("fff3d6"))
    enter.add_theme_color_override("font_hover_color", Color("ffd56a"))
    enter.add_theme_color_override("font_outline_color", Color("3a2116"))
    enter.add_theme_constant_override("outline_size", 2)
    CursorManager.set_clickable(enter)
    enter.pressed.connect(func(): enter_requested.emit())
    column.add_child(enter)
    var logout := Button.new()
    logout.text = localization.tr_key("welcome.logout") if localization != null else "Cerrar sesión"
    logout.icon = assets.logout
    logout.expand_icon = true
    logout.custom_minimum_size = Vector2(240, 44)
    logout.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    logout.add_theme_stylebox_override("normal", _button_style("res://assets/ui/buttons/button_normal.png"))
    logout.add_theme_stylebox_override("hover", _button_style("res://assets/ui/buttons/button_hover.png"))
    logout.add_theme_stylebox_override("pressed", _button_style("res://assets/ui/buttons/button_hover.png", Color(0.88, 0.88, 0.88, 1.0)))
    logout.add_theme_color_override("font_color", Color("fff3d6"))
    logout.add_theme_color_override("font_hover_color", Color("ffd56a"))
    CursorManager.set_clickable(logout)
    logout.pressed.connect(func(): logout_requested.emit())
    column.add_child(logout)

func _button_style(path: String, tint := Color.WHITE) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load(path)
    style.texture_margin_left = 7; style.texture_margin_right = 7
    style.texture_margin_top = 7; style.texture_margin_bottom = 7
    style.modulate_color = tint
    return style
