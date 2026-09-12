class_name WelcomeView
extends PanelContainer

signal logout_requested

func setup() -> void:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 40)
    margin.add_theme_constant_override("margin_right", 40)
    margin.add_theme_constant_override("margin_top", 32)
    margin.add_theme_constant_override("margin_bottom", 32)
    add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    margin.add_child(column)
    var title := Label.new()
    title.text = "Bienvenido, " + str(SessionStore.user.get("alias", "jugador"))
    title.add_theme_font_size_override("font_size", 32)
    column.add_child(title)
    var info := Label.new()
    info.text = "Tu cuenta está conectada. El primer mapa llegará pronto."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(info)
    var logout := Button.new()
    logout.text = "Cerrar sesión"
    logout.custom_minimum_size = Vector2(220, 46)
    logout.pressed.connect(func(): logout_requested.emit())
    column.add_child(logout)
