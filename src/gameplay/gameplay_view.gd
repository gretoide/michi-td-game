class_name GameplayView
extends Control

signal main_menu_requested
signal logout_requested
signal exit_requested

const SelectionStateScript = preload("res://src/gameplay/ui/selection_state.gd")
const CommandCardModelScript = preload("res://src/gameplay/ui/command_card_model.gd")
const SettingsStoreScript = preload("res://src/gameplay/ui/settings_store.gd")

var runtime: GameRuntime
var selection: SelectionState
var command_model: CommandCardModel
var settings: SettingsStore
var map_view: MapDebugView
var wave_label: Label
var life_bar: ProgressBar
var life_value_label: Label
var _life_fill_style: StyleBoxFlat
var _life_tween: Tween
var _life_target_value := -1.0
var gold_value_label: Label
var feedback_label: Label
var feedback_key := "game.feedback.help"
var help_button: Button
var inspector_label: Label
var inspector_icon: TextureRect
var inspector_name_label: RichTextLabel
var inspector_stats_label: Label
var inspector_panel: PanelContainer
var inspector_title_label: Label
var command_panel: PanelContainer
var reward_overlay: PanelContainer
var recipes_overlay: PanelContainer
var settings_overlay: PanelContainer
var end_overlay: PanelContainer
var debug_overlay: PanelContainer
var pause_overlay: PanelContainer
var exit_confirm_overlay: PanelContainer
var music_slider: HSlider
var command_buttons: Array[Button] = []
var LocalizationService: Node
var recipe_rows: Control
var recipe_query := ""
var recipe_filter := 0
var recipe_color_filter := ""
var _missing_gem_texture_diagnostics := {}
var _gem_nodes: Dictionary = {}
var _help_overlay: PanelContainer
var place_gem_mode := false

func setup(value: GameRuntime, shared_settings: SettingsStore = null) -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    runtime = value
    LocalizationService = get_node("/root/LocalizationService")
    selection = SelectionStateScript.new()
    command_model = CommandCardModelScript.new()
    settings = shared_settings if shared_settings != null else SettingsStoreScript.new()
    if shared_settings == null: settings.load_settings()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)
    process_mode = Node.PROCESS_MODE_ALWAYS
    var background := ColorRect.new()
    background.color = Color("152238")
    var gameplay_theme := Theme.new()
    gameplay_theme.default_font = load("res://assets/fonts/comic_neue_sans_id.ttf")
    gameplay_theme.default_font_size = 16
    gameplay_theme.set_color("font_color", "Label", Color("fff3d6"))
    gameplay_theme.set_color("font_color", "Button", Color("fff3d6"))
    gameplay_theme.set_color("font_hover_color", "Button", Color("ffd56a"))
    theme = gameplay_theme
    background.theme = gameplay_theme
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 12)
    background.add_child(margin)
    var shell := VBoxContainer.new()
    shell.add_theme_constant_override("separation", 10)
    margin.add_child(shell)
    _build_top_bar(shell)
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    shell.add_child(body)
    var play_column := VBoxContainer.new()
    play_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    play_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    play_column.add_theme_constant_override("separation", 8)
    body.add_child(play_column)
    _build_map(play_column)
    _build_command_card(body)
    _build_inspector(command_panel)
    runtime.construction.gem_placed.connect(func(_gem): UiSoundManager.play_place(); map_view.sync_gem_sprites(); map_view.queue_redraw(); _refresh_ui())
    runtime.construction.stone_created.connect(func(_stone): map_view.sync_gem_sprites(); map_view.queue_redraw(); _refresh_ui())
    runtime.construction.construction_changed.connect(func(_count, _total): map_view.sync_gem_sprites(); map_view.queue_redraw(); _refresh_ui())
    runtime.combat.combat_changed.connect(func(): map_view.queue_redraw(); _refresh_ui())
    if not runtime.combat.projectile_created.is_connected(_on_projectile_created):
        runtime.combat.projectile_created.connect(_on_projectile_created)
    if not runtime.outcome.life_changed.is_connected(_on_life_changed):
        runtime.outcome.life_changed.connect(_on_life_changed)
    runtime.phases.phase_entered.connect(func(_phase): place_gem_mode = false; map_view.sync_gem_sprites(); _refresh_ui())
    runtime.outcome.victorious.connect(func(): _show_end(true))
    runtime.outcome.defeated.connect(func(): _show_end(false))
    runtime.support_rewards.reward_available.connect(_show_reward)
    LocalizationService.locale_changed.connect(func(_locale): _refresh_ui(); _rebuild_command_card(); _refresh_open_overlays())
    selection.changed.connect(func(): _refresh_ui(); _rebuild_command_card(); map_view.queue_redraw())
    _refresh_ui()
    _rebuild_command_card()
    map_view.sync_gem_sprites()
    _apply_text_scale()

func _process(delta: float) -> void:
    if runtime != null and not get_tree().paused:
        runtime.tick(delta)
        _refresh_ui()
        map_view.sync_gem_sprites()
        map_view.queue_redraw()

func _build_top_bar(parent: Control) -> void:
    var bar := PanelContainer.new()
    bar.custom_minimum_size = Vector2(0, 52)
    bar.add_theme_stylebox_override("panel", _hud_panel())
    parent.add_child(bar)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    bar.add_child(row)
    wave_label = Label.new(); wave_label.add_theme_font_size_override("font_size", 18); row.add_child(wave_label)
    row.add_child(_hud_separator())
    var life_group := HBoxContainer.new(); life_group.add_theme_constant_override("separation", 6); life_group.custom_minimum_size = Vector2(178, 0); row.add_child(life_group)
    life_group.add_child(_hud_icon("life", LocalizationService.tr_key("game.resources.life")))
    life_bar = ProgressBar.new(); life_bar.custom_minimum_size = Vector2(110, 20); life_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; life_bar.show_percentage = false; life_bar.add_theme_stylebox_override("background", _resource_bar_style(Color("4b3428"))); _life_fill_style = _resource_bar_style(Color("63c174")); life_bar.add_theme_stylebox_override("fill", _life_fill_style); life_group.add_child(life_bar)
    life_value_label = Label.new(); life_value_label.custom_minimum_size = Vector2(86, 0); life_value_label.add_theme_font_size_override("font_size", 17); life_group.add_child(life_value_label)
    row.add_child(_hud_separator())
    var gold_group := HBoxContainer.new(); gold_group.add_theme_constant_override("separation", 6); gold_group.custom_minimum_size = Vector2(84, 0); row.add_child(gold_group)
    gold_group.add_child(_hud_icon("gold", LocalizationService.tr_key("game.resources.gold")))
    gold_value_label = Label.new(); gold_value_label.add_theme_font_size_override("font_size", 17); gold_group.add_child(gold_value_label)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    var pause := Button.new(); pause.text = "Ⅱ"; pause.custom_minimum_size = Vector2(42, 38); pause.tooltip_text = LocalizationService.tr_key("game.pause"); pause.process_mode = Node.PROCESS_MODE_ALWAYS; pause.pressed.connect(_toggle_pause); row.add_child(pause)
    var settings_button := Button.new(); settings_button.icon = load("res://assets/ui/icons/gameplay/settings.png"); settings_button.expand_icon = true; settings_button.custom_minimum_size = Vector2(42, 38); settings_button.tooltip_text = LocalizationService.tr_key("game.settings.title"); settings_button.process_mode = Node.PROCESS_MODE_ALWAYS; settings_button.pressed.connect(_on_settings_pressed); row.add_child(settings_button)
    var recipes_button := Button.new(); recipes_button.icon = load("res://assets/ui/icons/gameplay/recipes.png"); recipes_button.expand_icon = true; recipes_button.custom_minimum_size = Vector2(42, 38); recipes_button.tooltip_text = LocalizationService.tr_key("game.recipes.title"); recipes_button.process_mode = Node.PROCESS_MODE_ALWAYS; recipes_button.pressed.connect(_toggle_recipes); row.add_child(recipes_button)
    var guide_button := Button.new(); guide_button.icon = load("res://assets/ui/icons/gameplay/help.png"); guide_button.expand_icon = true; guide_button.custom_minimum_size = Vector2(42, 38); guide_button.tooltip_text = LocalizationService.tr_key("game.help.title"); guide_button.process_mode = Node.PROCESS_MODE_ALWAYS; guide_button.pressed.connect(_toggle_help); row.add_child(guide_button)

func _hud_separator() -> Label:
    var separator := Label.new()
    separator.text = "│"
    separator.add_theme_font_size_override("font_size", 20)
    separator.add_theme_color_override("font_color", Color("d9b27b"))
    separator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return separator

func _on_settings_pressed() -> void:
    _toggle_settings()

func _on_projectile_created(_projectile: HomingProjectile) -> void:
    UiSoundManager.play_tower_shot()

func _on_life_changed(value: int) -> void:
    if runtime == null or not is_instance_valid(life_bar): return
    var maximum := maxf(1.0, float(runtime.player_state.max_lives))
    var target := clampf(float(value), 0.0, maximum)
    var first_update := _life_target_value < 0.0
    _life_target_value = target
    life_bar.max_value = maximum
    if is_instance_valid(_life_tween) and _life_tween.is_running(): _life_tween.kill()
    if first_update:
        life_bar.value = target
    else:
        _life_tween = create_tween()
        _life_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        _life_tween.tween_property(life_bar, "value", target, 0.2)
    if is_instance_valid(life_value_label): life_value_label.text = "%d/%d" % [value, int(maximum)]
    if is_instance_valid(_life_fill_style):
        _life_fill_style.bg_color = _life_bar_color(target / maximum)

func _life_bar_color(ratio: float) -> Color:
    if ratio <= 0.25: return Color("d9535f")
    if ratio <= 0.5: return Color("d9894e")
    return Color("63c174")

func _hud_icon(name: String, tooltip: String) -> TextureRect:
    var icon := TextureRect.new()
    icon.texture = load("res://assets/ui/icons/gameplay/%s.png" % name)
    icon.custom_minimum_size = Vector2(28, 28)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    icon.tooltip_text = tooltip
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func _resource_bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(5)
    style.content_margin_left = 3
    style.content_margin_right = 3
    style.content_margin_top = 3
    style.content_margin_bottom = 3
    return style

func _build_map(parent: Control) -> void:
    var frame := PanelContainer.new()
    frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.add_theme_stylebox_override("panel", _map_frame())
    parent.add_child(frame)
    map_view = MapDebugView.new()
    map_view.runtime = runtime
    map_view.view = self
    map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_view.clip_contents = true
    frame.add_child(map_view)

func _build_command_card(parent: Control) -> void:
    command_panel = PanelContainer.new()
    command_panel.custom_minimum_size = Vector2(280, 0)
    command_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    command_panel.add_theme_stylebox_override("panel", _hud_panel())
    parent.add_child(command_panel)
    var column := VBoxContainer.new(); column.name = "VBoxContainer"; column.add_theme_constant_override("separation", 8); command_panel.add_child(column)
    var title := Label.new(); title.name = "Title"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 18); column.add_child(title)
    var title_separator := HSeparator.new(); title_separator.add_theme_stylebox_override("separator", _strong_section_separator()); column.add_child(title_separator)
    var grid := VBoxContainer.new(); grid.name = "Grid"; grid.add_theme_constant_override("separation", 5); column.add_child(grid)
    for _i in CommandCardModelScript.HOTKEYS.size():
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 42)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 16)
        _style_game_button(button)
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.process_mode = Node.PROCESS_MODE_ALWAYS
        grid.add_child(button)
        command_buttons.append(button)
    for i in command_buttons.size():
        command_buttons[i].pressed.connect(func(): _execute_command(i))
    var feedback_panel := PanelContainer.new()
    feedback_panel.custom_minimum_size = Vector2(0, 76)
    feedback_panel.add_theme_stylebox_override("panel", _inner_panel())
    column.add_child(feedback_panel)
    feedback_label = Label.new()
    feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    feedback_label.custom_minimum_size = Vector2(0, 92)
    feedback_label.text = LocalizationService.tr_key("game.feedback.help")
    feedback_panel.add_child(feedback_label)
    var actions_separator := HSeparator.new()
    actions_separator.add_theme_stylebox_override("separator", _strong_section_separator())
    column.add_child(actions_separator)
    help_button = Button.new(); help_button.text = LocalizationService.tr_key("game.help.title"); help_button.icon = load("res://assets/ui/icons/gameplay/help.png"); help_button.expand_icon = true; help_button.custom_minimum_size = Vector2(0, 38); _style_game_button(help_button); help_button.pressed.connect(_toggle_help); help_button.visible = false; column.add_child(help_button)
    # Keep the command card clean; the decorative smoke competed with the
    # contextual selection and action sections.

func _build_inspector(parent: Control) -> void:
    var inspector := PanelContainer.new()
    inspector_panel = inspector
    inspector.custom_minimum_size = Vector2(0, 150)
    inspector.add_theme_stylebox_override("panel", _hud_panel())
    var target_parent: Node = parent
    if parent == command_panel and command_panel.get_child_count() > 0:
        target_parent = command_panel.get_child(0)
    target_parent.add_child(inspector)
    var inspector_column := VBoxContainer.new()
    inspector_column.add_theme_constant_override("separation", 6)
    inspector.add_child(inspector_column)
    inspector_title_label = Label.new()
    inspector_title_label.text = "Torre seleccionada" if LocalizationService.locale == "es" else "Selected tower"
    inspector_title_label.add_theme_font_size_override("font_size", 14)
    inspector_title_label.add_theme_color_override("font_color", Color("fff3d6"))
    inspector_column.add_child(inspector_title_label)
    var inspector_row := VBoxContainer.new()
    inspector_row.add_theme_constant_override("separation", 10)
    inspector_column.add_child(inspector_row)
    var inspector_header := HBoxContainer.new()
    inspector_header.add_theme_constant_override("separation", 6)
    inspector_header.custom_minimum_size = Vector2(0, 36)
    inspector_row.add_child(inspector_header)
    var icon_frame := PanelContainer.new()
    icon_frame.custom_minimum_size = Vector2(32, 32)
    icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    icon_frame.add_theme_stylebox_override("panel", _inner_panel())
    inspector_header.add_child(icon_frame)
    inspector_icon = TextureRect.new()
    inspector_icon.custom_minimum_size = Vector2(26, 26)
    inspector_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    inspector_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    inspector_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    inspector_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    inspector_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_frame.add_child(inspector_icon)
    inspector_name_label = RichTextLabel.new()
    inspector_name_label.bbcode_enabled = true
    inspector_name_label.fit_content = false
    inspector_name_label.scroll_active = false
    inspector_name_label.custom_minimum_size = Vector2(0, 32)
    inspector_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inspector_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    inspector_name_label.add_theme_font_size_override("normal_font_size", 17)
    inspector_name_label.add_theme_color_override("default_color", Color("fff3d6"))
    inspector_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inspector_header.add_child(inspector_name_label)
    inspector_stats_label = Label.new()
    inspector_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inspector_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inspector_stats_label.add_theme_font_size_override("font_size", 14)
    inspector_row.add_child(inspector_stats_label)
    inspector_label = inspector_stats_label

func _rebuild_command_card() -> void:
    if command_model == null or runtime == null: return
    command_model.rebuild(runtime, selection)
    var title := command_panel.get_node_or_null("VBoxContainer/Title") as Label
    if title != null: title.text = "Acciones" if LocalizationService.locale == "es" else "Actions"
    for i in command_buttons.size():
        var action: Dictionary = command_model.actions[i]
        command_buttons[i].text = _command_label(action.id)
        var icon_path := _command_icon_path(action.id)
        command_buttons[i].icon = load(icon_path) if not icon_path.is_empty() else null
        command_buttons[i].expand_icon = not icon_path.is_empty()
        command_buttons[i].disabled = not action.enabled
        command_buttons[i].visible = action.get("visible", true)

func _command_label(id: String) -> String:
    return LocalizationService.tr_key("game.command." + id)

func _command_icon_path(id: String) -> String:
    if id == "recipes": return "res://assets/ui/icons/gameplay/recipes.png"
    if id == "settings": return "res://assets/ui/icons/gameplay/settings.png"
    if id == "debug": return "res://assets/ui/icons/gameplay/help.png"
    return ""

func _execute_command(index: int) -> void:
    if index < 0 or index >= command_model.actions.size(): return
    var id: String = command_model.actions[index].id
    match id:
        "place_gem": map_view.place_gem_at_hover()
        "select_gem": _set_feedback("game.feedback.select_hint")
        "combine": _combine_selected()
        "degrade": _degrade_selected()
        "remove_stone": _remove_selected_stone()
        "attack": _attack_selected()
        "stop": _stop_selected()
        "keep_gem": _keep_selected()
        "recipes": _toggle_recipes()
        "restart": _restart()
    _refresh_ui()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed(): return
    if reward_overlay != null and event.keycode >= KEY_1 and event.keycode <= KEY_3:
        var reward_index: int = event.keycode - KEY_1
        if reward_index < runtime.support_rewards.candidates.size():
            var picked: StringName = runtime.support_rewards.candidates[reward_index]
            runtime.support_rewards.choose(picked)
            _close_overlay(reward_overlay); reward_overlay = null; get_tree().paused = false
        return
    if event.keycode == KEY_P: _toggle_recipes(); return
    if event.keycode == KEY_ESCAPE:
        if reward_overlay != null: return
        if exit_confirm_overlay != null: _close_exit_confirmation(); return
        if pause_overlay != null: _toggle_pause(); return
        if recipes_overlay != null: _close_overlay(recipes_overlay); recipes_overlay = null; return
        if settings_overlay != null: _close_settings(); return
        selection.clear(); return
    if event.keycode == KEY_F10: _toggle_debug(); return
    if event.keycode == KEY_R and event.ctrl_pressed: _restart(); return
    var key := OS.get_keycode_string(event.keycode)
    var index := CommandCardModelScript.HOTKEYS.find(key)
    if index >= 0: _execute_command(index)

func _combine_selected() -> void:
    if selection.kind != SelectionState.Kind.GEM: return
    for option in runtime.construction.basic_combinations():
        if selection.value in option.gems:
            runtime.construction.combine_basic(selection.value, int(option.count)); return
    _set_feedback("game.feedback.no_combination")

func _degrade_selected() -> void:
    if selection.kind == SelectionState.Kind.GEM and runtime.construction.degrade(selection.value) == null: _set_feedback("game.feedback.invalid_action")

func _set_feedback(key: String) -> void:
    feedback_key = key
    if is_instance_valid(feedback_label): feedback_label.text = LocalizationService.tr_key(feedback_key)

func _attack_selected() -> void:
    if selection.kind != SelectionState.Kind.TOWER: return
    var tower := selection.value as TowerRuntime
    if tower == null: return
    for enemy: EnemyRuntime in runtime.combat.enemies:
        if enemy.is_alive() and tower.attack(enemy): return
    _set_feedback("game.feedback.invalid_action")

func _stop_selected() -> void:
    if selection.kind != SelectionState.Kind.TOWER: return
    var tower := selection.value as TowerRuntime
    if tower != null: tower.toggle_stop()

func _keep_selected() -> void:
    if selection.kind == SelectionState.Kind.GEM: runtime.construction.keep(selection.value)

func _remove_selected_stone() -> void:
    if selection.kind == SelectionState.Kind.STONE: runtime.construction.remove_stone(selection.value); selection.clear()

func _toggle_recipes() -> void:
    if recipes_overlay != null: _close_overlay(recipes_overlay); recipes_overlay = null; return
    recipes_overlay = _make_parchment_overlay(LocalizationService.tr_key("game.recipes.title"), Vector2(780, 0), func(): _close_overlay(recipes_overlay); recipes_overlay = null)
    var column := _parchment_overlay_column(recipes_overlay)
    column.add_theme_constant_override("separation", 12)
    var search := LineEdit.new()
    search.placeholder_text = LocalizationService.tr_key("game.help.search")
    search.custom_minimum_size = Vector2(0, 42)
    _style_modal_input(search)
    CursorManager.set_text_cursor(search)
    search.text_changed.connect(func(value): recipe_query = value; _populate_recipes())
    column.add_child(search)
    var filter_row := HBoxContainer.new(); filter_row.add_theme_constant_override("separation", 10); column.add_child(filter_row)
    var filter := OptionButton.new(); filter.custom_minimum_size = Vector2(0, 40); filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL; filter.add_item(LocalizationService.tr_key("game.recipes.filter.all")); filter.add_item(LocalizationService.tr_key("game.recipes.filter.base")); filter.add_item(LocalizationService.tr_key("game.recipes.filter.advanced")); filter.item_selected.connect(func(value): recipe_filter = value; _populate_recipes()); _style_modal_select(filter); filter_row.add_child(filter)
    var color_filter := OptionButton.new(); color_filter.custom_minimum_size = Vector2(0, 40); color_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var color_keys := ["blue", "dark_blue", "gold", "light_green", "lilac", "purple", "red", "turquoise"]
    color_filter.add_item(LocalizationService.tr_key("game.recipes.color.all"))
    for color_key in color_keys: color_filter.add_item(LocalizationService.tr_key("game.recipes.color." + color_key))
    color_filter.item_selected.connect(func(value): recipe_color_filter = "" if value == 0 else color_keys[value - 1]; _populate_recipes())
    _style_modal_select(color_filter)
    filter_row.add_child(color_filter)
    var list_panel := PanelContainer.new()
    list_panel.add_theme_stylebox_override("panel", _parchment_inset_style())
    list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(list_panel)
    var list_margin := MarginContainer.new()
    list_margin.add_theme_constant_override("margin_left", 8)
    list_margin.add_theme_constant_override("margin_top", 8)
    list_margin.add_theme_constant_override("margin_right", 8)
    list_margin.add_theme_constant_override("margin_bottom", 8)
    list_panel.add_child(list_margin)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(680, 430)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    list_margin.add_child(scroll)
    _style_modal_scrollbar(scroll.get_v_scroll_bar())
    recipe_rows = GridContainer.new(); recipe_rows.columns = 3; recipe_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL; recipe_rows.add_theme_constant_override("h_separation", 8); recipe_rows.add_theme_constant_override("v_separation", 8); scroll.add_child(recipe_rows)
    _populate_recipes()
    add_child(recipes_overlay)

func _show_reward(wave_number: int, candidates: Array) -> void:
    reward_overlay = _make_overlay(LocalizationService.tr_key("game.reward.title", {"wave": wave_number}))
    var column := _overlay_column(reward_overlay)
    for i in candidates.size():
        var id: StringName = candidates[i]
        var picked_id := id
        var reward_name: String = LocalizationService.tr_key("game.reward.skill.%s" % str(picked_id))
        var button := Button.new(); button.text = "%d. %s" % [i + 1, reward_name]; button.custom_minimum_size = Vector2(320, 42); button.pressed.connect(func(): runtime.support_rewards.choose(picked_id); _close_overlay(reward_overlay); reward_overlay = null; get_tree().paused = false); column.add_child(button)
    var close := _close_icon_button(func(): _close_overlay(reward_overlay); reward_overlay = null; get_tree().paused = false); column.add_child(close); column.move_child(close, 0)
    add_child(reward_overlay)
    get_tree().paused = true

func _show_end(victory: bool) -> void:
    end_overlay = _make_overlay(LocalizationService.tr_key("game.end.victory" if victory else "game.end.defeat"))
    var column := _overlay_column(end_overlay)
    var score := Label.new(); score.text = LocalizationService.tr_key("game.end.score", {"score": runtime.player_state.score}); column.add_child(score)
    var restart := Button.new(); restart.text = LocalizationService.tr_key("game.restart"); restart.pressed.connect(_restart); column.add_child(restart)
    add_child(end_overlay); get_tree().paused = true

func _toggle_settings() -> void:
    if settings_overlay != null: _close_settings(); return
    settings_overlay = _make_parchment_overlay(LocalizationService.tr_key("game.settings.title"), Vector2(660, 0), _close_settings)
    settings_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(settings_overlay)
    var column := _parchment_overlay_column(settings_overlay)
    column.add_theme_constant_override("separation", 10)
    column.add_child(_settings_toggle_row(LocalizationService.tr_key("game.settings.fullscreen"), settings.fullscreen, settings.set_fullscreen))
    column.add_child(_settings_toggle_row(LocalizationService.tr_key("game.settings.music_enabled"), settings.music_enabled, _set_music_enabled))
    column.add_child(_settings_text_size_row())
    var language := LocaleSelector.new(); language.custom_minimum_size = Vector2(170, 40); language.size_flags_horizontal = Control.SIZE_SHRINK_END; language.setup(); _style_modal_select(language); column.add_child(_settings_labeled_control(LocalizationService.tr_key("locale.label"), language))
    var music_group := _settings_slider_row(LocalizationService.tr_key("game.settings.music"), settings.music_volume, func(v): settings.set_music(int(v)), not settings.music_enabled)
    music_slider = music_group.get_node("Margin/Column/Slider") as HSlider
    column.add_child(music_group)
    column.add_child(_settings_slider_row(LocalizationService.tr_key("game.settings.sfx"), settings.sfx_volume, func(v): settings.set_sfx(int(v))))
    _apply_text_scale(); get_tree().paused = true

func _close_settings() -> void:
    _close_overlay(settings_overlay); settings_overlay = null; music_slider = null; get_tree().paused = false

func _set_music_enabled(value: bool) -> void:
    settings.set_music_enabled(value)
    if is_instance_valid(music_slider): music_slider.editable = value

func _settings_text_size_row() -> PanelContainer:
    var panel := _settings_row_panel()
    var row := panel.get_node("Margin/Row") as HBoxContainer
    row.add_theme_constant_override("separation", 12)
    var label := Label.new(); label.text = LocalizationService.tr_key("game.settings.text_size"); label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 16); row.add_child(label)
    var select := OptionButton.new(); select.custom_minimum_size = Vector2(170, 40)
    var values := ["small", "normal", "large"]
    for value in values: select.add_item(LocalizationService.tr_key("game.settings.text_" + value))
    select.selected = values.find(settings.text_size)
    select.item_selected.connect(func(index): settings.set_text_size(values[index]); _apply_text_scale())
    _style_modal_select(select)
    row.add_child(select)
    return panel

func _settings_labeled_control(label_text: String, control: Control) -> PanelContainer:
    var panel := _settings_row_panel()
    var row := panel.get_node("Margin/Row") as HBoxContainer
    row.add_theme_constant_override("separation", 12)
    var label := Label.new(); label.text = label_text; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 16); row.add_child(label)
    row.add_child(control)
    return panel

func _apply_text_scale() -> void:
    var factor: float = float({"small": 0.85, "normal": 1.0, "large": 1.2}.get(settings.text_size, 1.0))
    _scale_control_fonts(self, factor)

func _scale_control_fonts(node: Node, factor: float) -> void:
    for child in node.get_children():
        if child is Control:
            var control := child as Control
            var base: int
            if control.has_meta("base_gameplay_font_size"):
                base = int(control.get_meta("base_gameplay_font_size"))
            else:
                base = control.get_theme_font_size("font_size")
                if base > 0: control.set_meta("base_gameplay_font_size", base)
            if base > 0: control.add_theme_font_size_override("font_size", maxi(10, roundi(base * factor)))
        _scale_control_fonts(child, factor)
func _settings_toggle_row(label_text: String, current_value: bool, callback: Callable) -> PanelContainer:
    var panel := _settings_row_panel()
    var row := panel.get_node("Margin/Row") as HBoxContainer
    row.add_theme_constant_override("separation", 12)
    var label := Label.new()
    label.text = label_text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 16)
    row.add_child(label)
    var toggle := CheckButton.new()
    toggle.custom_minimum_size = Vector2(54, 34)
    toggle.button_pressed = current_value
    toggle.tooltip_text = label_text
    toggle.toggled.connect(callback)
    row.add_child(toggle)
    return panel

func _settings_slider_row(label_text: String, current_value: int, callback: Callable, disabled := false) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _settings_row_style())
    var margin := MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 9)
    panel.add_child(margin)
    var group := VBoxContainer.new()
    group.name = "Column"
    group.add_theme_constant_override("separation", 5)
    margin.add_child(group)
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", 16)
    group.add_child(label)
    var slider := HSlider.new()
    slider.name = "Slider"
    slider.custom_minimum_size = Vector2(0, 24)
    slider.min_value = 0
    slider.max_value = 100
    slider.step = 1
    slider.value = current_value
    slider.editable = not disabled
    slider.tooltip_text = label_text
    slider.add_theme_icon_override("grabber", _settings_grabber())
    slider.add_theme_icon_override("grabber_highlight", _settings_grabber())
    var track := StyleBoxFlat.new()
    track.bg_color = Color("4b3428")
    track.set_corner_radius_all(5)
    track.content_margin_top = 4
    track.content_margin_bottom = 4
    slider.add_theme_stylebox_override("slider", track)
    var filled := StyleBoxFlat.new()
    filled.bg_color = Color("d99b50")
    filled.set_corner_radius_all(5)
    filled.content_margin_top = 4
    filled.content_margin_bottom = 4
    slider.add_theme_stylebox_override("grabber_area", filled)
    slider.add_theme_stylebox_override("grabber_area_highlight", filled)
    slider.value_changed.connect(callback)
    group.add_child(slider)
    return panel

func _settings_grabber() -> Texture2D:
    var image := Image.create(14, 14, false, Image.FORMAT_RGBA8)
    image.fill(Color("fff3d6"))
    return ImageTexture.create_from_image(image)

func _toggle_debug() -> void:
    if debug_overlay != null: _close_overlay(debug_overlay); debug_overlay = null; return
    debug_overlay = _make_overlay(LocalizationService.tr_key("game.debug.title"))
    var column := _overlay_column(debug_overlay)
    var info := Label.new(); info.text = LocalizationService.tr_key("game.debug.info", {"seed": runtime.foundation.random.effective_seed, "gems": runtime.foundation.catalog.gems.size(), "recipes": runtime.foundation.catalog.recipes.size(), "waves": runtime.foundation.catalog.waves.size()}); column.add_child(info)
    var close := _close_icon_button(func(): _close_overlay(debug_overlay); debug_overlay = null); column.add_child(close); column.move_child(close, 0); add_child(debug_overlay)

func _restart() -> void:
    if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.CONSTRUCTION: return
    runtime.construction.reset_current_round()
    selection.clear(); _refresh_ui(); _rebuild_command_card(); map_view.queue_redraw()

func _populate_recipes() -> void:
    if recipe_rows == null: return
    for child in recipe_rows.get_children(): child.queue_free()
    var shown := 0
    for recipe in runtime.foundation.catalog.recipes:
        if recipe.secret: continue
        var localized_input := "%s %s" % [_display_gem_name(recipe.id), _display_gem_name(recipe.result_id)]
        var name := "%s %s %s %s" % [recipe.id, recipe.result_id, localized_input, recipe.id.replace("_", " ")]
        if not recipe_query.strip_edges().is_empty() and recipe_query.to_lower() not in name.to_lower(): continue
        if recipe_filter == 1 and recipe.result_id not in runtime.foundation.catalog.gems.map(func(g): return g.id): continue
        if recipe_filter == 2 and recipe.result_id in runtime.foundation.catalog.gems.map(func(g): return g.id): continue
        if not recipe_color_filter.is_empty() and _gem_color_key(recipe.result_id) != recipe_color_filter: continue
        var row_panel := PanelContainer.new()
        row_panel.custom_minimum_size = Vector2(220, 92)
        row_panel.add_theme_stylebox_override("panel", _recipe_row_style(shown % 2 == 1))
        recipe_rows.add_child(row_panel)
        var row_margin := MarginContainer.new()
        row_margin.add_theme_constant_override("margin_left", 10)
        row_margin.add_theme_constant_override("margin_right", 10)
        row_panel.add_child(row_margin)
        var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); row_margin.add_child(row)
        _add_gem_icon(row, recipe.result_id, 1, 30)
        var label := Label.new()
        var ingredients := []
        for ingredient in recipe.ingredients:
            ingredients.append("%s L%s" % [_display_gem_name(ingredient["id"]), ingredient.get("level", 1)])
        label.text = "%s = %s\n%s" % [_display_gem_name(recipe.result_id), " + ".join(ingredients), _display_gem_name(recipe.id)]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size", 14); label.add_theme_color_override("font_color", Color("3b2418")); row.add_child(label)
        shown += 1
    if shown == 0:
        var empty := Label.new(); empty.text = LocalizationService.tr_key("game.help.empty"); empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty.add_theme_color_override("font_color", Color("6d4a32")); empty.custom_minimum_size = Vector2(0, 72); empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; recipe_rows.add_child(empty)

func _toggle_pause() -> void:
    if pause_overlay != null:
        _close_overlay(pause_overlay); pause_overlay = null; get_tree().paused = false
        return
    pause_overlay = _make_parchment_overlay(LocalizationService.tr_key("game.pause.title"), Vector2(560, 0), _toggle_pause)
    var column := _parchment_overlay_column(pause_overlay)
    column.add_theme_constant_override("separation", 10)
    var message := Label.new(); message.text = LocalizationService.tr_key("game.pause.message"); message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.add_theme_font_size_override("font_size", 18); message.add_theme_color_override("font_color", Color("6d4a32")); message.custom_minimum_size = Vector2(0, 42); message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; column.add_child(message)
    var action_separator := HSeparator.new(); action_separator.add_theme_stylebox_override("separator", _parchment_separator_style()); column.add_child(action_separator)
    var resume := Button.new(); resume.text = LocalizationService.tr_key("game.pause.resume"); resume.custom_minimum_size = Vector2(360, 48); resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; resume.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(resume, true); resume.pressed.connect(_toggle_pause); column.add_child(resume)
    var main_menu := Button.new(); main_menu.text = LocalizationService.tr_key("game.pause.main_menu"); main_menu.icon = load("res://assets/ui/icons/gameplay/main_menu.png"); main_menu.expand_icon = true; main_menu.custom_minimum_size = Vector2(360, 46); main_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; main_menu.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(main_menu); main_menu.pressed.connect(func(): _show_exit_confirmation(false)); column.add_child(main_menu)
    var logout := Button.new(); logout.text = LocalizationService.tr_key("game.pause.logout"); logout.icon = load("res://assets/ui/icons/gameplay/logout.png"); logout.expand_icon = true; logout.custom_minimum_size = Vector2(360, 46); logout.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; logout.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(logout, false, true); logout.pressed.connect(func(): _show_exit_confirmation(true)); column.add_child(logout)
    var exit_game := Button.new(); exit_game.text = LocalizationService.tr_key("game.pause.exit"); exit_game.custom_minimum_size = Vector2(360, 46); exit_game.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; exit_game.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(exit_game, false, true); exit_game.pressed.connect(_show_quit_confirmation); column.add_child(exit_game)
    add_child(pause_overlay)
    get_tree().paused = true

func _return_to_main_menu() -> void:
    get_tree().paused = false
    _close_overlay(pause_overlay)
    pause_overlay = null
    main_menu_requested.emit()

func _show_exit_confirmation(logout: bool) -> void:
    if exit_confirm_overlay != null: return
    exit_confirm_overlay = _make_overlay(LocalizationService.tr_key("game.pause.confirm_logout" if logout else "game.pause.confirm_main_menu"))
    var column := _overlay_column(exit_confirm_overlay)
    column.add_child(_close_icon_button(func(): _close_exit_confirmation()))
    var message := Label.new(); message.text = LocalizationService.tr_key("game.pause.confirm_message"); message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(message)
    var confirm := Button.new(); confirm.text = LocalizationService.tr_key("game.pause.confirm"); confirm.process_mode = Node.PROCESS_MODE_ALWAYS; confirm.pressed.connect(func(): _confirm_exit(logout)); column.add_child(confirm)
    var cancel := Button.new(); cancel.text = LocalizationService.tr_key("game.pause.cancel"); cancel.process_mode = Node.PROCESS_MODE_ALWAYS; cancel.pressed.connect(_close_exit_confirmation); column.add_child(cancel)
    add_child(exit_confirm_overlay)

func _show_quit_confirmation() -> void:
    if exit_confirm_overlay != null: return
    exit_confirm_overlay = _make_overlay(LocalizationService.tr_key("game.pause.confirm_exit"))
    var column := _overlay_column(exit_confirm_overlay)
    column.add_child(_close_icon_button(func(): _close_exit_confirmation()))
    var message := Label.new(); message.text = LocalizationService.tr_key("game.pause.confirm_message"); message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(message)
    var confirm := Button.new(); confirm.text = LocalizationService.tr_key("game.pause.confirm"); confirm.process_mode = Node.PROCESS_MODE_ALWAYS; confirm.pressed.connect(_confirm_quit); column.add_child(confirm)
    var cancel := Button.new(); cancel.text = LocalizationService.tr_key("game.pause.cancel"); cancel.process_mode = Node.PROCESS_MODE_ALWAYS; cancel.pressed.connect(_close_exit_confirmation); column.add_child(cancel)
    add_child(exit_confirm_overlay)

func _close_exit_confirmation() -> void:
    if is_instance_valid(exit_confirm_overlay): exit_confirm_overlay.queue_free()
    exit_confirm_overlay = null

func _confirm_exit(logout: bool) -> void:
    _close_exit_confirmation()
    get_tree().paused = false
    if logout: logout_requested.emit()
    else: main_menu_requested.emit()

func _confirm_quit() -> void:
    _close_exit_confirmation()
    get_tree().paused = false
    exit_requested.emit()

func _add_gem_icon(parent: Control, gem_id: StringName, level: int, size: int) -> void:
    var icon := _make_gem_sprite(gem_id, level, size)
    parent.add_child(icon)

func _make_gem_sprite(gem_id: StringName, level: int, size: float) -> TextureRect:
    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2.ONE * size
    icon.size = Vector2.ONE * size
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    icon.texture = _gem_texture(gem_id, level)
    if icon.texture == null: icon.texture = _fallback_gem_texture(gem_id)
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func _fallback_gem_texture(gem_id: StringName) -> Texture2D:
    var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    var color := _gem_color(gem_id)
    for y in range(8):
        for x in range(8):
            var distance := absf(float(x) - 3.5) + absf(float(y) - 3.5)
            if distance <= 5.0: image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)

func _gem_texture(gem_id: StringName, level: int) -> Texture2D:
    var color := _gem_color_key(gem_id)
    var family := clampi(level, 1, 10)
    var path := "res://assets/art/gameplay/gems/%s/gem_%d_%s.png" % [color, family, color]
    var texture := load(path) as Texture2D
    if texture == null and not _missing_gem_texture_diagnostics.has(path):
        _missing_gem_texture_diagnostics[path] = true
        push_warning("Missing gem texture: %s" % path)
    return texture

func _gem_animation_texture(gem_id: StringName, level: int, frame: int) -> Texture2D:
    var color := _gem_color_key(gem_id)
    var family := clampi(level, 1, 10)
    var frame_path := "res://assets/art/gameplay/gems/%s/gem_%d_%s_%04d.png" % [color, family, color, posmod(frame, 16)]
    var animated := load(frame_path) as Texture2D
    return animated if animated != null else _gem_texture(gem_id, level)

func _gem_color_key(gem_id: StringName) -> String:
    var color := "gold"
    var id := String(gem_id).to_lower()
    if "ruby" in id or "blood" in id or "coral" in id: color = "red"
    elif "amethyst" in id or "purple" in id: color = "purple"
    elif "emerald" in id or "jade" in id: color = "light_green"
    elif "aquamarine" in id or "tourmaline" in id: color = "turquoise"
    elif "sapphire" in id or "lazurite" in id: color = "blue"
    elif "diamond" in id or "quartz" in id: color = "lilac"
    elif "opal" in id or "pearl" in id: color = "dark_blue"
    return color

func _gem_color(gem_id: StringName) -> Color:
    var colors := {"blue": Color("6598ff"), "dark_blue": Color("5667b5"), "gold": Color("f4c95d"), "light_green": Color("55d889"), "lilac": Color("e9a7ff"), "purple": Color("b78cff"), "red": Color("ef6262"), "turquoise": Color("68d8e8")}
    return colors.get(_gem_color_key(gem_id), Color("d99b50"))

func _close_icon_button(callback: Callable) -> Button:
    var close := Button.new()
    close.icon = load("res://assets/ui/cursors/tile_0016.png") as Texture2D
    close.expand_icon = true
    close.custom_minimum_size = Vector2(42, 42)
    close.size_flags_horizontal = Control.SIZE_SHRINK_END
    close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    close.add_theme_constant_override("icon_max_width", 32)
    close.mouse_filter = Control.MOUSE_FILTER_STOP
    close.process_mode = Node.PROCESS_MODE_ALWAYS
    close.tooltip_text = LocalizationService.tr_key("game.close")
    close.pressed.connect(callback)
    return close

func _style_modal_close_button(button: Button) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0, 0, 0, 0)
    normal.set_corner_radius_all(5)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.20, 0.10, 0.06, 0.55)
    var pressed := hover.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(0.12, 0.06, 0.04, 0.78)
    var focus := normal.duplicate() as StyleBoxFlat
    focus.border_color = Color("ffd56a")
    focus.set_border_width_all(2)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("focus", focus)
    CursorManager.set_clickable(button)

func _style_modal_action_button(button: Button, primary := false, danger := false) -> void:
    _style_game_button(button)
    button.add_theme_font_size_override("font_size", 18)
    button.add_theme_constant_override("icon_max_width", 28)
    button.add_theme_color_override("font_pressed_color", Color("fff3d6"))
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color(0, 0, 0, 0)
    focus.border_color = Color("ffd56a")
    focus.set_border_width_all(2)
    focus.set_corner_radius_all(5)
    button.add_theme_stylebox_override("focus", focus)
    if primary:
        button.add_theme_stylebox_override("normal", _texture_style("res://assets/ui/buttons/button_hover.png", 7, Color(1.08, 1.02, 0.88, 1.0)))
    elif danger:
        button.add_theme_color_override("font_hover_color", Color("ffb0a2"))
    CursorManager.set_clickable(button)

func _style_modal_input(field: LineEdit) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("4a3023")
    normal.border_color = Color("765039")
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(5)
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    var focus := normal.duplicate() as StyleBoxFlat
    focus.border_color = Color("d99b50")
    field.add_theme_stylebox_override("normal", normal)
    field.add_theme_stylebox_override("focus", focus)
    field.add_theme_color_override("font_color", Color("fff3d6"))
    field.add_theme_color_override("font_placeholder_color", Color(1.0, 0.95, 0.84, 0.62))
    field.add_theme_color_override("caret_color", Color("ffd56a"))

func _style_modal_select(select: OptionButton) -> void:
    select.add_theme_stylebox_override("normal", _texture_style("res://assets/ui/buttons/button_normal.png", 7))
    select.add_theme_stylebox_override("hover", _texture_style("res://assets/ui/buttons/button_hover.png", 7))
    select.add_theme_stylebox_override("pressed", _texture_style("res://assets/ui/buttons/button_hover.png", 7, Color(0.88, 0.88, 0.88, 1.0)))
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color(0, 0, 0, 0)
    focus.border_color = Color("ffd56a")
    focus.set_border_width_all(2)
    focus.set_corner_radius_all(5)
    select.add_theme_stylebox_override("focus", focus)
    select.add_theme_color_override("font_color", Color("fff3d6"))
    select.add_theme_color_override("font_hover_color", Color("ffd56a"))
    select.add_theme_font_size_override("font_size", 16)
    CursorManager.set_clickable(select)
    var popup := select.get_popup()
    popup.add_theme_color_override("font_color", Color("fff3d6"))
    popup.add_theme_color_override("font_hover_color", Color("ffd56a"))
    var popup_panel := StyleBoxFlat.new()
    popup_panel.bg_color = Color("3a261d")
    popup_panel.border_color = Color("a9794d")
    popup_panel.set_border_width_all(2)
    popup_panel.set_corner_radius_all(4)
    popup.add_theme_stylebox_override("panel", popup_panel)
    var popup_hover := StyleBoxFlat.new()
    popup_hover.bg_color = Color("65442f")
    popup_hover.set_corner_radius_all(3)
    popup.add_theme_stylebox_override("hover", popup_hover)

func _style_modal_scrollbar(scrollbar: VScrollBar) -> void:
    scrollbar.custom_minimum_size.x = 12
    var track := StyleBoxFlat.new()
    track.bg_color = Color(0.25, 0.14, 0.09, 0.20)
    track.set_corner_radius_all(5)
    var grabber := StyleBoxFlat.new()
    grabber.bg_color = Color("9d7049")
    grabber.set_corner_radius_all(5)
    var highlight := grabber.duplicate() as StyleBoxFlat
    highlight.bg_color = Color("c28a4b")
    scrollbar.add_theme_stylebox_override("scroll", track)
    scrollbar.add_theme_stylebox_override("grabber", grabber)
    scrollbar.add_theme_stylebox_override("grabber_highlight", highlight)
    scrollbar.add_theme_stylebox_override("grabber_pressed", highlight)

func _settings_row_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(0, 50)
    panel.add_theme_stylebox_override("panel", _settings_row_style())
    var margin := MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 5)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 5)
    panel.add_child(margin)
    var row := HBoxContainer.new()
    row.name = "Row"
    margin.add_child(row)
    return panel

func _settings_row_style() -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.43, 0.29, 0.19, 0.10)
    panel.border_color = Color(0.43, 0.29, 0.19, 0.24)
    panel.set_border_width_all(1)
    panel.set_corner_radius_all(5)
    return panel

func _parchment_inset_style() -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.49, 0.33, 0.22, 0.11)
    panel.border_color = Color(0.32, 0.19, 0.12, 0.42)
    panel.set_border_width_all(2)
    panel.set_corner_radius_all(5)
    return panel

func _recipe_row_style(alternate: bool) -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.39, 0.25, 0.16, 0.10 if alternate else 0.045)
    panel.border_color = Color(0.43, 0.29, 0.19, 0.18)
    panel.border_width_bottom = 1
    panel.set_corner_radius_all(3)
    return panel

func _parchment_separator_style() -> StyleBoxFlat:
    var separator := StyleBoxFlat.new()
    separator.bg_color = Color(0.39, 0.25, 0.16, 0.32)
    separator.content_margin_top = 1
    separator.content_margin_bottom = 1
    return separator

func _style_help_tabs(tabs: TabContainer) -> void:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.49, 0.33, 0.22, 0.08)
    panel.border_color = Color(0.32, 0.19, 0.12, 0.34)
    panel.set_border_width_all(1)
    panel.set_corner_radius_all(5)
    panel.content_margin_left = 6
    panel.content_margin_top = 8
    panel.content_margin_right = 6
    panel.content_margin_bottom = 6
    tabs.add_theme_stylebox_override("panel", panel)
    var unselected := StyleBoxFlat.new()
    unselected.bg_color = Color("5a3a29")
    unselected.content_margin_left = 14
    unselected.content_margin_right = 14
    unselected.content_margin_top = 8
    unselected.content_margin_bottom = 8
    var selected := unselected.duplicate() as StyleBoxFlat
    selected.bg_color = Color("8a4a29")
    selected.border_color = Color("d99b50")
    selected.border_width_top = 2
    var hovered := unselected.duplicate() as StyleBoxFlat
    hovered.bg_color = Color("74442c")
    tabs.add_theme_stylebox_override("tab_unselected", unselected)
    tabs.add_theme_stylebox_override("tab_selected", selected)
    tabs.add_theme_stylebox_override("tab_hovered", hovered)
    tabs.add_theme_color_override("font_unselected_color", Color("e8d7b8"))
    tabs.add_theme_color_override("font_selected_color", Color("fff3d6"))
    tabs.add_theme_color_override("font_hovered_color", Color("ffd56a"))
    tabs.add_theme_font_size_override("font_size", 16)

func _style_help_action_button(button: Button) -> void:
    _style_modal_action_button(button)
    var selected := _texture_style("res://assets/ui/buttons/button_hover.png", 7, Color(1.08, 0.94, 0.78, 1.0))
    button.add_theme_stylebox_override("pressed", selected)
    button.add_theme_stylebox_override("hover_pressed", selected)
    button.add_theme_color_override("font_pressed_color", Color("ffd56a"))
    button.add_theme_color_override("font_hover_pressed_color", Color("fff3d6"))
    button.add_theme_font_size_override("font_size", 16)

func _help_key_badge_style() -> StyleBoxFlat:
    var badge := StyleBoxFlat.new()
    badge.bg_color = Color("5a3a29")
    badge.border_color = Color("a9794d")
    badge.set_border_width_all(1)
    badge.set_corner_radius_all(4)
    return badge

func _toggle_help() -> void:
    if _help_overlay != null:
        _close_overlay(_help_overlay); _help_overlay = null; return
    _help_overlay = _make_parchment_overlay(LocalizationService.tr_key("game.help.title"), Vector2(880, 0), func(): _close_overlay(_help_overlay); _help_overlay = null)
    var column := _parchment_overlay_column(_help_overlay)
    column.add_theme_constant_override("separation", 12)
    var tabs := TabContainer.new(); tabs.name = "Tabs"; tabs.custom_minimum_size = Vector2(780, 480); tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; _style_help_tabs(tabs); column.add_child(tabs)
    var action_page := HBoxContainer.new(); action_page.name = LocalizationService.tr_key("game.help.actions"); action_page.add_theme_constant_override("separation", 12); tabs.add_child(action_page)
    var action_margin := MarginContainer.new(); action_margin.custom_minimum_size = Vector2(210, 0); action_margin.add_theme_constant_override("margin_left", 8); action_margin.add_theme_constant_override("margin_right", 4); action_margin.add_theme_constant_override("margin_top", 10); action_margin.add_theme_constant_override("margin_bottom", 10); action_page.add_child(action_margin)
    var action_bar := VBoxContainer.new(); action_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL; action_bar.add_theme_constant_override("separation", 8); action_margin.add_child(action_bar)
    var detail_panel := PanelContainer.new(); detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; detail_panel.add_theme_stylebox_override("panel", _parchment_inset_style()); action_page.add_child(detail_panel)
    var detail_scroll := ScrollContainer.new(); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; detail_panel.add_child(detail_scroll)
    _style_modal_scrollbar(detail_scroll.get_v_scroll_bar())
    var detail_margin := MarginContainer.new(); detail_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_margin.add_theme_constant_override("margin_left", 22); detail_margin.add_theme_constant_override("margin_top", 20); detail_margin.add_theme_constant_override("margin_right", 22); detail_margin.add_theme_constant_override("margin_bottom", 20); detail_scroll.add_child(detail_margin)
    var detail_column := VBoxContainer.new(); detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_column.add_theme_constant_override("separation", 10); detail_margin.add_child(detail_column)
    var detail_title := Label.new(); detail_title.add_theme_font_size_override("font_size", 22); detail_title.add_theme_color_override("font_color", Color("3b2418")); detail_column.add_child(detail_title)
    var detail_separator := HSeparator.new(); detail_separator.add_theme_stylebox_override("separator", _parchment_separator_style()); detail_column.add_child(detail_separator)
    var detail_label := Label.new(); detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; detail_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP; detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; detail_label.add_theme_font_size_override("font_size", 17); detail_label.add_theme_color_override("font_color", Color("503522")); detail_column.add_child(detail_label)
    var action_label_keys := ["game.command.place_gem", "game.command.select_gem", "game.command.combine", "game.command.degrade", "game.command.remove_stone", "game.command.keep_gem"]
    var action_detail_keys := ["game.help.place", "game.help.select", "game.help.combine", "game.help.degrade", "game.help.remove_stone", "game.help.keep"]
    var action_group := ButtonGroup.new()
    for index in action_label_keys.size():
        var detail_key: String = action_detail_keys[index]
        var label_key: String = action_label_keys[index]
        var action_button := Button.new(); action_button.text = LocalizationService.tr_key(label_key); action_button.custom_minimum_size = Vector2(0, 42); action_button.toggle_mode = true; action_button.button_group = action_group; _style_help_action_button(action_button); action_button.pressed.connect(func(): detail_title.text = LocalizationService.tr_key(label_key); detail_label.text = LocalizationService.tr_key(detail_key)); action_bar.add_child(action_button)
        if index == 0: action_button.button_pressed = true
    detail_title.text = LocalizationService.tr_key(action_label_keys[0]); detail_label.text = LocalizationService.tr_key(action_detail_keys[0])
    var shortcuts := ScrollContainer.new(); shortcuts.name = LocalizationService.tr_key("game.help.shortcuts"); shortcuts.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; tabs.add_child(shortcuts); _style_modal_scrollbar(shortcuts.get_v_scroll_bar())
    var shortcut_margin := MarginContainer.new(); shortcut_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL; shortcut_margin.add_theme_constant_override("margin_left", 10); shortcut_margin.add_theme_constant_override("margin_top", 10); shortcut_margin.add_theme_constant_override("margin_right", 10); shortcut_margin.add_theme_constant_override("margin_bottom", 10); shortcuts.add_child(shortcut_margin)
    var shortcut_column := VBoxContainer.new(); shortcut_column.add_theme_constant_override("separation", 7); shortcut_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; shortcut_margin.add_child(shortcut_column)
    var shortcut_data := [["Q", "game.command.place_gem"], ["E", "game.command.combine"], ["R", "game.command.degrade"], ["A", "game.command.remove_stone"], ["Z", "game.command.keep_gem"], ["P", "game.command.recipes"], ["Esc", "game.help.shortcut_escape"], ["F10", "game.command.debug"]]
    for entry in shortcut_data:
        var shortcut_panel := PanelContainer.new(); shortcut_panel.add_theme_stylebox_override("panel", _settings_row_style()); shortcut_column.add_child(shortcut_panel)
        var row_margin := MarginContainer.new(); row_margin.add_theme_constant_override("margin_left", 10); row_margin.add_theme_constant_override("margin_top", 5); row_margin.add_theme_constant_override("margin_right", 12); row_margin.add_theme_constant_override("margin_bottom", 5); shortcut_panel.add_child(row_margin)
        var shortcut_row := HBoxContainer.new(); shortcut_row.add_theme_constant_override("separation", 14); row_margin.add_child(shortcut_row)
        var key_badge := PanelContainer.new(); key_badge.custom_minimum_size = Vector2(72, 38); key_badge.add_theme_stylebox_override("panel", _help_key_badge_style()); shortcut_row.add_child(key_badge)
        var key_label := Label.new(); key_label.text = entry[0]; key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; key_label.add_theme_font_size_override("font_size", 17); key_label.add_theme_color_override("font_color", Color("fff3d6")); key_badge.add_child(key_label)
        var action_label := Label.new(); action_label.text = LocalizationService.tr_key(entry[1]); action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; action_label.add_theme_color_override("font_color", Color("3b2418")); action_label.add_theme_font_size_override("font_size", 17); shortcut_row.add_child(action_label)
    add_child(_help_overlay)

func _set_map_cursor(active: bool) -> void:
    var construction_active := active and runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION
    CursorManager.set_map_cursor(construction_active)

func _leave_map_cursor() -> void:
    CursorManager.restore_normal_cursor()

func _update_map_tooltip(cell: Vector2i) -> void:
    if runtime == null or not runtime.grid.is_in_bounds(cell):
        map_view.tooltip_text = ""
        return
    var gem := runtime.construction.gem_at_cell(cell)
    if gem != null:
        map_view.tooltip_text = LocalizationService.tr_key("game.tooltip.gem", {"id": _display_gem_name(gem.id), "level": gem.level, "quality": _quality_label(gem.quality), "cell": gem.cell})
        return
    for tower in runtime.combat.towers:
        if tower.position.distance_to(Vector2(cell) * 100.0 + Vector2.ONE * 50.0) < 80.0:
            map_view.tooltip_text = LocalizationService.tr_key("game.tooltip.tower", {"id": _display_gem_name(tower.id), "damage": snapped(tower.stats.damage, 0.1), "range": snapped(tower.stats.range_units, 0.1), "stopped": LocalizationService.tr_key("game.state.stopped" if tower.stopped else "game.state.active")})
            return
    map_view.tooltip_text = ""

func _display_gem_name(gem_id: StringName) -> String:
    var text := String(gem_id).replace("_", " ").to_lower()
    var names := {
        "sapphire": ["sapphire", "zafiro"], "emerald": ["emerald", "esmeralda"], "ruby": ["ruby", "rubí"],
        "amethyst": ["amethyst", "amatista"], "aquamarine": ["aquamarine", "aguamarina"], "diamond": ["diamond", "diamante"],
        "opal": ["opal", "ópalo"], "topaz": ["topaz", "topacio"], "pearl": ["pearl", "perla"], "tourmaline": ["tourmaline", "turmalina"],
        "gold": ["gold", "oro"], "silver": ["silver", "plata"], "malachite": ["malachite", "malaquita"], "coral": ["coral", "coral"],
        "bloodstone": ["bloodstone", "heliotropo"]
    }
    var locale_index := 1 if LocalizationService.locale == "es" else 0
    for token in names:
        text = text.replace(token, names[token][locale_index])
    return text.capitalize()

func _quality_label(value: int) -> String:
    return LocalizationService.tr_key("game.quality.%d" % value)

func _make_parchment_overlay(title_text: String, minimum_size: Vector2, close_callback: Callable) -> PanelContainer:
    var overlay := PanelContainer.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_theme_stylebox_override("panel", _modal_backdrop())
    overlay.z_index = 100
    overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    var center := CenterContainer.new()
    center.name = "Center"
    overlay.add_child(center)
    var frame := PanelContainer.new()
    frame.name = "Card"
    frame.custom_minimum_size = minimum_size
    frame.add_theme_stylebox_override("panel", _panel_texture_style("res://assets/ui/panels/large_stone.png", 42))
    center.add_child(frame)
    var stone_padding := MarginContainer.new()
    stone_padding.name = "StonePadding"
    stone_padding.add_theme_constant_override("margin_left", 16)
    stone_padding.add_theme_constant_override("margin_top", 16)
    stone_padding.add_theme_constant_override("margin_right", 16)
    stone_padding.add_theme_constant_override("margin_bottom", 16)
    frame.add_child(stone_padding)
    var parchment := PanelContainer.new()
    parchment.name = "Parchment"
    parchment.add_theme_stylebox_override("panel", _panel_texture_style("res://assets/ui/panels/large_parchment.png", 38, Color(1.10, 1.05, 0.96, 1.0)))
    var parchment_theme := Theme.new()
    parchment_theme.default_font = load("res://assets/fonts/comic_neue_sans_id.ttf")
    parchment_theme.default_font_size = 16
    parchment_theme.set_color("font_color", "Label", Color("3b2418"))
    parchment.theme = parchment_theme
    stone_padding.add_child(parchment)
    var margin := MarginContainer.new()
    margin.name = "MarginContainer"
    margin.add_theme_constant_override("margin_left", 40)
    margin.add_theme_constant_override("margin_top", 34)
    margin.add_theme_constant_override("margin_right", 40)
    margin.add_theme_constant_override("margin_bottom", 34)
    parchment.add_child(margin)
    var column := VBoxContainer.new()
    column.name = "VBoxContainer"
    column.add_theme_constant_override("separation", 10)
    margin.add_child(column)
    var header := PanelContainer.new()
    header.custom_minimum_size = Vector2(0, 58)
    header.add_theme_stylebox_override("panel", _hud_panel())
    column.add_child(header)
    var header_row := HBoxContainer.new()
    header_row.add_theme_constant_override("separation", 8)
    header.add_child(header_row)
    var balance := Control.new()
    balance.custom_minimum_size = Vector2(42, 42)
    balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header_row.add_child(balance)
    var title := Label.new()
    title.text = title_text
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("fff3d6"))
    header_row.add_child(title)
    var close := _close_icon_button(close_callback)
    _style_modal_close_button(close)
    header_row.add_child(close)
    return overlay

func _parchment_overlay_column(overlay: PanelContainer) -> VBoxContainer:
    return overlay.get_node("Center/Card/StonePadding/Parchment/MarginContainer/VBoxContainer") as VBoxContainer

func _panel_texture_style(path: String, margin: int, tint := Color.WHITE) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load(path)
    style.texture_margin_left = margin
    style.texture_margin_top = margin
    style.texture_margin_right = margin
    style.texture_margin_bottom = margin
    style.modulate_color = tint
    return style

func _make_overlay(title_text: String) -> PanelContainer:
    var overlay := PanelContainer.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_theme_stylebox_override("panel", _modal_backdrop())
    overlay.z_index = 100
    overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    var center := CenterContainer.new()
    center.name = "Center"
    overlay.add_child(center)
    var card := PanelContainer.new()
    card.name = "Card"
    card.custom_minimum_size = Vector2(660, 0)
    card.add_theme_stylebox_override("panel", _hud_panel())
    center.add_child(card)
    var margin := MarginContainer.new()
    margin.name = "MarginContainer"
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 12)
    card.add_child(margin)
    var column := VBoxContainer.new()
    column.name = "VBoxContainer"
    column.add_theme_constant_override("separation", 8)
    margin.add_child(column)
    var title := Label.new()
    title.text = title_text
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    column.add_child(title)
    return overlay

func _overlay_column(overlay: PanelContainer) -> VBoxContainer:
    return overlay.get_node("Center/Card/MarginContainer/VBoxContainer") as VBoxContainer

func _close_overlay(panel: Control) -> void:
    if is_instance_valid(panel): panel.queue_free()

func _refresh_open_overlays() -> void:
    var reopen_help := _help_overlay != null
    var reopen_recipes := recipes_overlay != null
    var reopen_settings := settings_overlay != null
    var reopen_pause := pause_overlay != null
    if reopen_help:
        _help_overlay.queue_free(); _help_overlay = null
    if reopen_recipes:
        recipes_overlay.queue_free(); recipes_overlay = null
    if reopen_settings:
        settings_overlay.queue_free(); settings_overlay = null
    if reopen_pause:
        pause_overlay.queue_free(); pause_overlay = null
    if reopen_help: call_deferred("_toggle_help")
    if reopen_recipes: call_deferred("_toggle_recipes")
    if reopen_settings: call_deferred("_toggle_settings")
    if reopen_pause: call_deferred("_toggle_pause")

func _refresh_ui() -> void:
    if runtime == null: return
    wave_label.text = LocalizationService.tr_key("game.wave", {"number": runtime.phases.wave_number}) + (" ★" if runtime.current_wave_is_boss else "")
    if is_instance_valid(life_bar):
        life_bar.max_value = maxf(1.0, runtime.player_state.max_lives)
        var target := clampf(float(runtime.player_state.lives), 0.0, life_bar.max_value)
        if is_zero_approx(_life_target_value - target):
            if not is_instance_valid(_life_tween) or not _life_tween.is_running(): life_bar.value = target
        else:
            _on_life_changed(runtime.player_state.lives)
        if is_instance_valid(_life_fill_style): _life_fill_style.bg_color = _life_bar_color(target / life_bar.max_value)
    if is_instance_valid(life_value_label): life_value_label.text = "%d/%d" % [runtime.player_state.lives, runtime.player_state.max_lives]
    if is_instance_valid(gold_value_label): gold_value_label.text = str(runtime.player_state.gold)
    _refresh_inspector_content()
    if is_instance_valid(inspector_panel): inspector_panel.visible = not selection.is_empty()
    if is_instance_valid(inspector_icon):
        inspector_icon.texture = null
        if selection.kind == SelectionState.Kind.GEM:
            var selected_gem: GemInstance = selection.value
            inspector_icon.texture = _gem_texture(selected_gem.id, selected_gem.level)
        elif selection.kind == SelectionState.Kind.TOWER:
            var selected_tower: TowerRuntime = selection.value
            inspector_icon.texture = _gem_texture(selected_tower.id, selected_tower.gem.level if selected_tower.gem != null else 1)
        elif selection.kind == SelectionState.Kind.ENEMY:
            inspector_icon.texture = _enemy_icon_texture()
        elif selection.kind == SelectionState.Kind.STONE:
            inspector_icon.texture = _stone_icon_texture()

func _enemy_icon_texture() -> Texture2D:
    var atlas := AtlasTexture.new()
    atlas.atlas = load("res://assets/art/gameplay/enemies/pipo_nekonin027.png") as Texture2D
    atlas.region = Rect2(0, 0, 32, 32)
    return atlas

func _stone_icon_texture() -> Texture2D:
    return load("res://assets/art/gameplay/environment/stones/stone_01.png") as Texture2D

func _refresh_inspector_content() -> void:
    if not is_instance_valid(inspector_name_label) or not is_instance_valid(inspector_stats_label): return
    inspector_name_label.text = ""
    inspector_stats_label.text = ""
    if selection.is_empty(): return
    if selection.kind == SelectionState.Kind.GEM:
        inspector_title_label.text = "Torre seleccionada" if LocalizationService.locale == "es" else "Selected tower"
        var gem: GemInstance = selection.value
        var definition := runtime.foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
        var stats := TowerCombatStats.from_gem(gem, definition)
        inspector_name_label.text = "[b]%s[/b]" % (_quality_label(gem.quality) + " " + _display_gem_name(gem.id))
        inspector_stats_label.text = "• Nivel: %d\n• Damage: %.1f\n• Range: %.1f\n• Attack Speed: %.1f" % [gem.level, stats.damage, stats.range_units, stats.total_attack_speed()]
    elif selection.kind == SelectionState.Kind.TOWER:
        inspector_title_label.text = "Torre seleccionada" if LocalizationService.locale == "es" else "Selected tower"
        var tower: TowerRuntime = selection.value
        inspector_name_label.text = "[b]%s[/b]" % _display_gem_name(tower.id)
        inspector_stats_label.text = "• Nivel: %d\n• Damage: %.1f\n• Range: %.1f\n• Attack Speed: %.1f" % [tower.gem.level if tower.gem != null else 1, tower.stats.damage, tower.stats.range_units, tower.stats.total_attack_speed()]
    elif selection.kind == SelectionState.Kind.ENEMY:
        inspector_title_label.text = "Enemigo seleccionado" if LocalizationService.locale == "es" else "Selected enemy"
        var enemy: EnemyRuntime = selection.value
        inspector_name_label.text = "[b]%s[/b]" % enemy.profile_id
        inspector_stats_label.text = "• HP: %.1f / %.1f\n• Armor: %.1f\n• Magic: %.1f" % [enemy.hp, enemy.max_hp, enemy.armor, enemy.magic_resistance]
    else:
        inspector_title_label.text = "Piedra seleccionada" if LocalizationService.locale == "es" else "Selected stone"
        inspector_name_label.text = "[b]%s[/b]" % LocalizationService.tr_key("game.selection.stone")
    if is_instance_valid(feedback_label): feedback_label.text = LocalizationService.tr_key(feedback_key)
    if is_instance_valid(help_button): help_button.text = LocalizationService.tr_key("game.help.title")

func _selection_summary() -> String:
    if selection.is_empty(): return LocalizationService.tr_key("game.selection.none")
    if selection.kind == SelectionState.Kind.GEM:
        var gem: GemInstance = selection.value
        var definition := runtime.foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
        var stats := TowerCombatStats.from_gem(gem, definition)
        return "%s %s (Level %d)\nDamage: %.1f\nRange: %.1f\nAttack Speed: %.1f" % [_quality_label(gem.quality), _display_gem_name(gem.id), gem.level, stats.damage, stats.range_units, stats.total_attack_speed()]
    if selection.kind == SelectionState.Kind.ENEMY:
        var enemy: EnemyRuntime = selection.value
        return LocalizationService.tr_key("game.selection.enemy", {"id": enemy.profile_id, "hp": snapped(enemy.hp, 0.1), "max_hp": snapped(enemy.max_hp, 0.1), "armor": enemy.armor, "magic": enemy.magic_resistance})
    if selection.kind == SelectionState.Kind.TOWER:
        var tower: TowerRuntime = selection.value
        return LocalizationService.tr_key("game.selection.tower", {"id": _display_gem_name(tower.id), "damage": snapped(tower.stats.damage, 0.1), "range": snapped(tower.stats.range_units, 0.1), "stopped": LocalizationService.tr_key("game.state.stopped" if tower.stopped else "game.state.active")})
    return LocalizationService.tr_key("game.selection.stone")

func _hud_panel() -> StyleBoxTexture:
    var panel := StyleBoxTexture.new(); panel.texture = load("res://assets/ui/panels/rpg_panel_brown.png"); panel.texture_margin_left = 16; panel.texture_margin_top = 16; panel.texture_margin_right = 16; panel.texture_margin_bottom = 16; panel.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT; panel.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT; return panel

func _style_game_button(button: Button) -> void:
    button.add_theme_stylebox_override("normal", _texture_style("res://assets/ui/buttons/button_normal.png", 7))
    button.add_theme_stylebox_override("hover", _texture_style("res://assets/ui/buttons/button_hover.png", 7))
    button.add_theme_stylebox_override("pressed", _texture_style("res://assets/ui/buttons/button_hover.png", 7, Color(0.88, 0.88, 0.88, 1.0)))
    button.add_theme_color_override("font_color", Color("fff3d6"))
    button.add_theme_color_override("font_hover_color", Color("ffd56a"))

func _texture_style(path: String, margin: int, modulate := Color.WHITE) -> StyleBoxTexture:
    var style := StyleBoxTexture.new(); style.texture = load(path); style.texture_margin_left = margin; style.texture_margin_top = margin; style.texture_margin_right = margin; style.texture_margin_bottom = margin; style.modulate_color = modulate; return style

func _inner_panel() -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color("5a321f")
    panel.border_color = Color("c87a35")
    panel.set_border_width_all(1)
    panel.set_corner_radius_all(4)
    panel.content_margin_left = 10
    panel.content_margin_top = 8
    panel.content_margin_right = 10
    panel.content_margin_bottom = 8
    return panel

func _strong_section_separator() -> StyleBoxFlat:
    var separator := StyleBoxFlat.new()
    separator.bg_color = Color("d9b27b")
    separator.content_margin_top = 2
    separator.content_margin_bottom = 2
    return separator

func _map_frame() -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color("0d1723")
    panel.border_color = Color("a9794d")
    panel.set_border_width_all(3)
    panel.set_corner_radius_all(5)
    panel.content_margin_left = 5
    panel.content_margin_top = 5
    panel.content_margin_right = 5
    panel.content_margin_bottom = 5
    return panel

func _modal_backdrop() -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.025, 0.045, 0.075, 0.82)
    return panel

class MapDebugView extends Control:
    var runtime: GameRuntime
    var view: GameplayView
    var gem_layer: Control
    var terrain_layer: MapTerrainLayer
    var decoration_layer: MapDecorationLayer
    var grid_layer: MapGridLayer
    var stone_layer: Control
    var stone_nodes: Dictionary = {}
    var spawner_layer: Control
    var spawner_decoration: SpawnerDecoration
    var hover_cell := Vector2i(-1, -1)
    var hover_can_place := false
    var map_zoom := 1.0
    var map_pan := Vector2.ZERO
    var board_origin := Vector2.ZERO
    var dragging := false
    var drag_start := Vector2.ZERO
    var pan_start := Vector2.ZERO
    var placement_preview: TextureRect
    const PROJECTILE_TEXTURE := preload("res://assets/art/gameplay/projectiles/fireball_5_colors.png")
    const ENEMY_TEXTURE := preload("res://assets/art/gameplay/enemies/pipo_nekonin027.png")
    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP
        clip_contents = true
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # Keep the terrain/decor layers above the map frame's canvas while
        # preserving their negative order relative to this renderer.
        z_index = 3
        terrain_layer = MapTerrainLayer.new()
        terrain_layer.runtime = runtime
        terrain_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        terrain_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        terrain_layer.z_index = -2
        terrain_layer.show_behind_parent = true
        add_child(terrain_layer)
        decoration_layer = MapDecorationLayer.new()
        decoration_layer.runtime = runtime
        decoration_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        decoration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        decoration_layer.z_index = -1
        decoration_layer.show_behind_parent = true
        add_child(decoration_layer)
        grid_layer = MapGridLayer.new()
        grid_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        grid_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        grid_layer.z_index = 0
        add_child(grid_layer)
        gem_layer = Control.new()
        gem_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        gem_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        gem_layer.z_index = 3
        add_child(gem_layer)
        stone_layer = Control.new()
        stone_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        stone_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        stone_layer.z_index = 2
        add_child(stone_layer)
        spawner_layer = Control.new()
        spawner_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        spawner_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        spawner_layer.z_index = 1
        add_child(spawner_layer)
        spawner_decoration = SpawnerDecoration.new()
        spawner_layer.add_child(spawner_decoration)
        placement_preview = TextureRect.new()
        placement_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        placement_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        placement_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        placement_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
        placement_preview.texture = load("res://assets/art/gameplay/building/slots/PlaceForTower1.png") as Texture2D
        placement_preview.visible = false
        placement_preview.z_index = 4
        add_child(placement_preview)
        var zoom_bar := HBoxContainer.new()
        zoom_bar.position = Vector2(2, 2)
        zoom_bar.add_theme_constant_override("separation", 4)
        for item in [["−", -0.1], ["＋", 0.1], ["⌂", 0.0]]:
            var button := Button.new(); button.text = item[0]; button.custom_minimum_size = Vector2(30, 30); button.tooltip_text = "Zoom"
            button.pressed.connect(func():
                if item[1] == 0.0: map_zoom = 1.0; map_pan = Vector2.ZERO
                else: map_zoom = clampf(map_zoom + float(item[1]), 0.65, 2.5); _center_zoom()
                _clamp_pan(); queue_redraw(); sync_gem_sprites())
            zoom_bar.add_child(button)
        add_child(zoom_bar)
        mouse_entered.connect(func(): view._set_map_cursor(hover_can_place))
        mouse_exited.connect(func(): hover_cell = Vector2i(-1, -1); hover_can_place = false; view._leave_map_cursor(); tooltip_text = ""; sync_gem_sprites(); queue_redraw())
        resized.connect(func(): sync_gem_sprites())
        call_deferred("sync_gem_sprites")

    func sync_gem_sprites() -> void:
        if runtime == null or view == null or gem_layer == null: return
        var live := {}
        var board_size := minf(size.x, size.y)
        if board_size <= 0.0: return
        var scale_value := board_size / 36.0
        board_origin = Vector2((size.x - board_size) * 0.5, (size.y - board_size) * 0.5)
        terrain_layer.size = size
        decoration_layer.size = size
        grid_layer.size = size
        terrain_layer.sync(board_size, map_zoom, map_pan, board_origin)
        decoration_layer.sync(board_size, map_zoom, map_pan, board_origin)
        grid_layer.sync(board_size, map_zoom, map_pan, board_origin)
        _sync_spawner(scale_value)
        _sync_stone_sprites(scale_value)
        _sync_placement_preview(scale_value)
        var sprite_size := maxf(12.0, scale_value * 1.05)
        for gem: GemInstance in runtime.construction.board_gems:
            var key := str(gem.get_instance_id())
            live[key] = true
            var sprite: TextureRect
            if _gem_nodes_has(key):
                sprite = _gem_nodes_get(key)
            else:
                sprite = view._make_gem_sprite(gem.id, gem.level, sprite_size)
                gem_layer.add_child(sprite)
                _gem_nodes_set(key, sprite)
            if gem == runtime.construction.selected_board_gem:
                sprite.texture = view._gem_animation_texture(gem.id, gem.level, int(Time.get_ticks_msec() / 140.0))
            else:
                sprite.texture = view._gem_texture(gem.id, gem.level)
            if sprite.texture == null: sprite.texture = view._fallback_gem_texture(gem.id)
            sprite.position = board_origin + map_pan + ((Vector2(gem.cell) + Vector2.ONE * 0.5) * scale_value - Vector2.ONE * sprite_size * 0.5) * map_zoom
            sprite.size = Vector2.ONE * sprite_size * map_zoom
            sprite.visible = true
        for key in _gem_nodes_keys():
            if not live.has(key):
                var stale := _gem_nodes_get(key)
                if is_instance_valid(stale): stale.queue_free()
                _gem_nodes_erase(key)

    func _gem_nodes_has(key: String) -> bool:
        return _gem_nodes().has(key)

    func _gem_nodes_get(key: String) -> TextureRect:
        return _gem_nodes()[key] as TextureRect

    func _gem_nodes_set(key: String, value: TextureRect) -> void:
        _gem_nodes()[key] = value

    func _gem_nodes_erase(key: String) -> void:
        _gem_nodes().erase(key)

    func _gem_nodes_keys() -> Array:
        return _gem_nodes().keys()

    func _gem_nodes() -> Dictionary:
        return view._gem_nodes

    func _sync_spawner(scale_value: float) -> void:
        if runtime == null or not is_instance_valid(spawner_decoration) or spawner_decoration.texture == null: return
        var source_size := spawner_decoration.texture.get_size()
        if source_size.y <= 0.0: return
        var target_height := scale_value * 1.55 * map_zoom
        var target_size := source_size * (target_height / source_size.y)
        spawner_decoration.size = target_size
        var spawn_center := (Vector2(runtime.map.spawn) + Vector2(0.5, 0.95)) * scale_value * map_zoom + map_pan
        spawner_decoration.position = board_origin + spawn_center - Vector2(target_size.x * 0.5, target_size.y)

    func _sync_stone_sprites(scale_value: float) -> void:
        if runtime == null or not is_instance_valid(stone_layer): return
        var live := {}
        var target_max_size := maxf(8.0, scale_value * 0.72) * map_zoom
        for cell: Vector2i in runtime.construction.stones:
            var key := str(cell)
            live[key] = true
            var sprite := stone_nodes.get(key) as StoneDecoration
            if not is_instance_valid(sprite):
                sprite = StoneDecoration.new()
                stone_layer.add_child(sprite)
                stone_nodes[key] = sprite
            if sprite.texture == null: continue
            var source_size := sprite.texture.get_size()
            var max_dimension := maxf(source_size.x, source_size.y)
            if max_dimension <= 0.0: continue
            var display_size := source_size * (target_max_size / max_dimension)
            sprite.size = display_size
            sprite.position = board_origin + map_pan + ((Vector2(cell) + Vector2.ONE * 0.5) * scale_value * map_zoom) - display_size * 0.5
        for key in stone_nodes.keys():
            if not live.has(key):
                var stale := stone_nodes[key] as StoneDecoration
                if is_instance_valid(stale): stale.queue_free()
                stone_nodes.erase(key)

    func _sync_placement_preview(scale_value: float) -> void:
        if not is_instance_valid(placement_preview): return
        var visible_preview := runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION and hover_cell.x >= 0
        placement_preview.visible = visible_preview
        if not visible_preview: return
        var target_size := maxf(12.0, scale_value * 0.82) * map_zoom
        var slot_name := "PlaceForTower2.png" if (hover_cell.x + hover_cell.y) % 2 == 0 else "PlaceForTower1.png"
        placement_preview.texture = load("res://assets/art/gameplay/building/slots/%s" % slot_name) as Texture2D
        placement_preview.size = Vector2.ONE * target_size
        placement_preview.position = board_origin + map_pan + ((Vector2(hover_cell) + Vector2.ONE * 0.5) * scale_value * map_zoom) - Vector2.ONE * target_size * 0.5
        placement_preview.modulate = Color(1.0, 1.0, 1.0, 0.82) if hover_can_place else Color(1.0, 0.35, 0.35, 0.45)

    func place_gem_at_hover() -> void:
        if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.CONSTRUCTION:
            return
        if hover_cell.x < 0 or not _can_preview_placement(hover_cell):
            view._set_feedback("game.feedback.invalid_action")
            return
        var placed := runtime.construction.place_gem(hover_cell, int(runtime.player_state.player_level))
        if placed == null:
            view._set_feedback("game.feedback.invalid_action")
            return
        view.selection.clear()
        hover_can_place = false
        view._set_map_cursor(false)
    func _gui_input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            map_zoom = clampf(map_zoom + 0.1, 0.65, 2.5); _center_zoom(); _clamp_pan(); queue_redraw(); sync_gem_sprites(); return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            map_zoom = clampf(map_zoom - 0.1, 0.65, 2.5); _center_zoom(); _clamp_pan(); queue_redraw(); sync_gem_sprites(); return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
            dragging = event.pressed; drag_start = event.position; pan_start = map_pan; return
        if event is InputEventMouseMotion and dragging:
            map_pan = pan_start + event.position - drag_start; _clamp_pan(); queue_redraw(); sync_gem_sprites(); return
        if event is InputEventMouseMotion and runtime != null:
            hover_cell = _cell_at(event.position)
            hover_can_place = _can_preview_placement(hover_cell)
            view._update_map_tooltip(hover_cell)
            view._set_map_cursor(hover_can_place)
            sync_gem_sprites()
            queue_redraw()
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and runtime != null:
            var cell := _cell_at(event.position)
            if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
                var gem := runtime.construction.gem_at_cell(cell)
                if gem != null: view.selection.select(SelectionState.Kind.GEM, gem); runtime.construction.select_board_gem(cell)
                elif runtime.construction.stones.has(cell): view.selection.select(SelectionState.Kind.STONE, cell); runtime.construction.select_stone(cell)
                else: view.selection.clear()
                hover_can_place = _can_preview_placement(cell)
                view._set_map_cursor(hover_can_place)
            else:
                var clicked_entity := false
                if runtime.construction.stones.has(cell):
                    view.selection.select(SelectionState.Kind.STONE, cell); runtime.construction.select_stone(cell); clicked_entity = true
                for tower in runtime.combat.towers:
                    if tower.position.distance_to(Vector2(cell) * 100.0 + Vector2.ONE * 50.0) < 80.0:
                        view.selection.select(SelectionState.Kind.TOWER, tower); clicked_entity = true; queue_redraw(); return
                for enemy in runtime.combat.enemies:
                    if enemy.is_alive() and enemy.position.distance_to(Vector2(cell) * 100.0 + Vector2.ONE * 50.0) < 80.0: view.selection.select(SelectionState.Kind.ENEMY, enemy); clicked_entity = true; break
                if not clicked_entity: view.selection.clear()
            queue_redraw()
    func _cell_at(position: Vector2) -> Vector2i:
        var scale_value := minf(size.x, size.y) / 36.0
        var local := (position - board_origin - map_pan) / map_zoom
        return Vector2i(floori(local.x / scale_value), floori(local.y / scale_value))

    func _clamp_pan() -> void:
        var board_size := minf(size.x, size.y)
        var scaled := board_size * map_zoom
        var min_offset := minf(0.0, board_size - scaled)
        var max_offset := maxf(0.0, (board_size - scaled) * 0.5)
        map_pan.x = clampf(map_pan.x, min_offset, max_offset)
        map_pan.y = clampf(map_pan.y, min_offset, max_offset)

    func _center_zoom() -> void:
        var board_size := minf(size.x, size.y)
        map_pan = Vector2((board_size - board_size * map_zoom) * 0.5, (board_size - board_size * map_zoom) * 0.5)
    func _can_preview_placement(cell: Vector2i) -> bool:
        return runtime != null and runtime.construction.can_place_at(cell)
    func _draw() -> void:
        if runtime == null: return
        var board_size := minf(size.x, size.y)
        var scale_value := board_size / 36.0
        draw_set_transform(board_origin + map_pan, 0.0, Vector2.ONE * map_zoom)
        if hover_cell.x >= 0 and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
            var hover_rect := Rect2(Vector2(hover_cell) * scale_value, Vector2.ONE * scale_value)
            var outline_color := Color("ffd477") if hover_can_place else Color("e66b6b")
            draw_rect(hover_rect.grow(-1.0), outline_color, false, 2.0)
        for gem: GemInstance in runtime.construction.board_gems:
            var p := (Vector2(gem.cell)+Vector2.ONE*0.5)*scale_value
        for cell: Vector2i in runtime.construction.stones:
            var stone := stone_nodes.get(str(cell)) as StoneDecoration
            if not is_instance_valid(stone) or stone.texture == null:
                draw_circle((Vector2(cell)+Vector2.ONE*0.5)*scale_value, maxf(4.0, scale_value * 0.3), Color("8b8f9a"))
        if view.selection.kind == SelectionState.Kind.TOWER:
            var selected_combat_gem := view.selection.value as TowerRuntime
            if selected_combat_gem != null:
                draw_circle(selected_combat_gem.position / 100.0 * scale_value, maxf(12.0, scale_value * 0.8), Color("fff1a8"), false, 3.0)
        for enemy: EnemyRuntime in runtime.combat.enemies:
            if enemy.is_alive():
                var p := enemy.position / 100.0 * scale_value
                var enemy_size := maxf(24.0, scale_value * 1.95)
                var frame := int(Time.get_ticks_msec() / 160) % 3
                var direction := Vector2.ZERO
                if enemy.path_index < enemy.path.size() - 1: direction = enemy.path[enemy.path_index + 1] - enemy.position
                var row := 0
                if absf(direction.x) > absf(direction.y): row = 1 if direction.x < 0.0 else 2
                elif direction.y < 0.0: row = 3
                draw_texture_rect_region(ENEMY_TEXTURE, Rect2(p-Vector2.ONE*enemy_size*0.5, Vector2.ONE*enemy_size), Rect2(frame * 32, row * 32, 32, 32))
                draw_rect(Rect2(p+Vector2(-enemy_size*0.42,enemy_size*0.42),Vector2(enemy_size*0.84,4)),Color("3a1820")); draw_rect(Rect2(p+Vector2(-enemy_size*0.42,enemy_size*0.42),Vector2(enemy_size*0.84*enemy.hp/enemy.max_hp,4)),Color("e66b6b"))
        for projectile: HomingProjectile in runtime.combat.projectiles:
            _draw_projectile(projectile, scale_value)
        draw_set_transform(board_origin + map_pan, 0.0, Vector2.ONE * map_zoom)

    func _draw_projectile(projectile: HomingProjectile, scale_value: float) -> void:
        var projectile_point := projectile.position / 100.0 * scale_value
        var projectile_size := maxf(12.0, scale_value * 1.05)
        var frame := int(Time.get_ticks_msec() / 90.0) % 4
        var row := _projectile_color_row(projectile.source_gem_id)
        draw_set_transform(board_origin + map_pan + projectile_point * map_zoom, projectile.direction.angle(), Vector2.ONE * map_zoom)
        draw_texture_rect_region(PROJECTILE_TEXTURE, Rect2(Vector2.ONE * projectile_size * -0.5, Vector2.ONE * projectile_size), Rect2(frame * 32.0, row * 32.0, 32.0, 32.0))

    func _projectile_color_row(gem_id: StringName) -> int:
        match view._gem_color_key(gem_id):
            "purple", "lilac": return 1
            "light_green": return 2
            "red": return 3
            "blue", "turquoise", "dark_blue": return 4
            _: return 0
    func _gem_color(gem: GemInstance) -> Color:
        var colors := {&"amethyst":Color("b78cff"),&"aquamarine":Color("68d8e8"),&"diamond":Color("e9f6ff"),&"emerald":Color("55d889"),&"opal":Color("f3a7d8"),&"ruby":Color("ef6262"),&"sapphire":Color("6598ff"),&"topaz":Color("f4c95d")}; return colors.get(gem.id, Color("d99b50"))

class MapTerrainLayer extends Control:
    const GRID_SIZE := 36
    const BASE_FIELD := 38
    var runtime: GameRuntime
    var tile_nodes: Array[TextureRect] = []
    var field_textures: Dictionary = {}
    var field_edges: Dictionary = {}
    var base_texture: Texture2D
    var route_cells: Dictionary = {}
    var initialized := false
    var last_board_size := -1.0
    var visual_board_size := 0.0
    var visual_zoom := 1.0
    var visual_pan := Vector2.ZERO
    var visual_origin := Vector2.ZERO

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        set_process(false)

    func sync(board_size: float, map_zoom: float, map_pan: Vector2, board_origin: Vector2) -> void:
        if runtime == null or board_size <= 0.0: return
        visual_board_size = board_size
        visual_zoom = map_zoom
        visual_pan = map_pan
        visual_origin = board_origin
        if not initialized:
            _build_field_cache()
            _build_route_cache()
            _build_tile_nodes()
            initialized = true
        if is_equal_approx(last_board_size, board_size) and tile_nodes.is_empty(): return
        last_board_size = board_size
        var cell_size := board_size / float(GRID_SIZE)
        for index in tile_nodes.size():
            var cell := Vector2(index % GRID_SIZE, index / GRID_SIZE)
            var tile := tile_nodes[index]
            tile.position = board_origin + map_pan + cell * cell_size * map_zoom
            tile.size = Vector2.ONE * cell_size * map_zoom
        queue_redraw()

    func _draw() -> void:
        if visual_board_size <= 0.0: return
        var cell_size := visual_board_size / float(GRID_SIZE) * visual_zoom
        if cell_size <= 0.0: return
        var origin := visual_origin + visual_pan
        if base_texture != null:
            var first_x := floori(-origin.x / cell_size) - 1
            var last_x := ceili((size.x - origin.x) / cell_size) + 1
            var first_y := floori(-origin.y / cell_size) - 1
            var last_y := ceili((size.y - origin.y) / cell_size) + 1
            for y in range(first_y, last_y + 1):
                for x in range(first_x, last_x + 1):
                    var grass_rect := Rect2(origin + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
                    draw_texture_rect(base_texture, grass_rect, false, Color.WHITE)
        else:
            draw_rect(Rect2(Vector2.ZERO, size), Color("829544"))

    func _build_field_cache() -> void:
        for tile_id in range(1, 65):
            var path := "res://assets/art/gameplay/terrain/fields/FieldsTile_%02d.png" % tile_id
            var texture := load(path) as Texture2D
            if texture == null:
                push_warning("Terrain tile missing: %s" % path)
                continue
            field_textures[tile_id] = texture
            field_edges[tile_id] = _edge_signature(texture)
        base_texture = field_textures.get(BASE_FIELD, null) as Texture2D

    func _build_route_cache() -> void:
        route_cells.clear()
        if runtime == null or runtime.pathfinder == null or runtime.map == null: return
        for cell: Vector2i in runtime.pathfinder.find_route(runtime.map): route_cells[str(cell)] = true

    func _build_tile_nodes() -> void:
        for y in range(GRID_SIZE):
            for x in range(GRID_SIZE):
                var cell := Vector2i(x, y)
                var tile := TextureRect.new()
                tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
                tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                tile.stretch_mode = TextureRect.STRETCH_SCALE
                tile.texture = field_textures.get(BASE_FIELD, null)
                if route_cells.has(str(cell)):
                    var selected_id := _road_tile(cell)
                    tile.texture = field_textures.get(selected_id, tile.texture)
                if runtime != null and runtime.grid != null and runtime.grid.is_restricted(cell):
                    tile.modulate = Color(0.90, 0.90, 0.84, 1.0)
                add_child(tile)
                tile_nodes.append(tile)

    func _road_tile(cell: Vector2i) -> int:
        var desired := Vector4(
            1.0 if not route_cells.has(str(cell + Vector2i.UP)) else 0.0,
            1.0 if not route_cells.has(str(cell + Vector2i.RIGHT)) else 0.0,
            1.0 if not route_cells.has(str(cell + Vector2i.DOWN)) else 0.0,
            1.0 if not route_cells.has(str(cell + Vector2i.LEFT)) else 0.0
        )
        var best_id := BASE_FIELD
        var best_score := INF
        for tile_id in field_edges.keys():
            if int(tile_id) == BASE_FIELD: continue
            var signature: Vector4 = field_edges[tile_id]
            var score := absf(signature.x - desired.x) + absf(signature.y - desired.y) + absf(signature.z - desired.z) + absf(signature.w - desired.w)
            score += float(int(tile_id)) * 0.0001
            if score < best_score:
                best_score = score
                best_id = int(tile_id)
        return best_id

    func _edge_signature(texture: Texture2D) -> Vector4:
        var image := texture.get_image()
        if image == null or image.is_empty(): return Vector4.ZERO
        var width := image.get_width()
        var height := image.get_height()
        var top := 0.0
        var right := 0.0
        var bottom := 0.0
        var left := 0.0
        var samples := 0.0
        for offset in range(3, max(4, width - 3), 3):
            top += 1.0 if _is_grass(image.get_pixel(offset, 2)) else 0.0
            bottom += 1.0 if _is_grass(image.get_pixel(offset, height - 3)) else 0.0
            samples += 1.0
        for offset in range(3, max(4, height - 3), 3):
            left += 1.0 if _is_grass(image.get_pixel(2, offset)) else 0.0
            right += 1.0 if _is_grass(image.get_pixel(width - 3, offset)) else 0.0
        var vertical_samples := float(max(1, int(ceil(float(height - 6) / 3.0))))
        return Vector4(top / maxf(1.0, samples), right / vertical_samples, bottom / maxf(1.0, samples), left / vertical_samples)

    func _is_grass(color: Color) -> bool:
        return color.a > 0.05 and color.g > color.r * 0.9 and color.g > color.b * 1.25 and color.r < 0.85

class MapGridLayer extends Control:
    const GRID_SIZE := 36
    var visual_board_size := 0.0
    var visual_zoom := 1.0
    var visual_pan := Vector2.ZERO
    var visual_origin := Vector2.ZERO

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    func sync(board_size: float, map_zoom: float, map_pan: Vector2, board_origin: Vector2) -> void:
        visual_board_size = board_size
        visual_zoom = map_zoom
        visual_pan = map_pan
        visual_origin = board_origin
        queue_redraw()

    func _draw() -> void:
        if visual_board_size <= 0.0: return
        var cell_size := visual_board_size / float(GRID_SIZE) * visual_zoom
        if cell_size <= 0.0: return
        var origin := visual_origin + visual_pan
        var line_color := Color(1.0, 1.0, 1.0, 0.10)
        # Keep the grid tied to the same 36x36 board as the terrain. Drawing
        # only these boundaries prevents extra lines outside the board from
        # making the cells look inconsistent while panning or zooming.
        var board_end := origin + Vector2.ONE * visual_board_size * visual_zoom
        for x in range(GRID_SIZE + 1):
            var x_pos := origin.x + float(x) * cell_size
            draw_line(Vector2(x_pos, origin.y), Vector2(x_pos, board_end.y), line_color, 1.0)
        for y in range(GRID_SIZE + 1):
            var y_pos := origin.y + float(y) * cell_size
            draw_line(Vector2(origin.x, y_pos), Vector2(board_end.x, y_pos), line_color, 1.0)

class MapDecorationLayer extends Control:
    const GRID_SIZE := 36
    var runtime: GameRuntime
    var generated := false
    var decorations: Array[TextureRect] = []
    var border_fences: Array[TextureRect] = []
    var border_trees: Array[TextureRect] = []
    var field_tree_cells: Array[Vector2i] = []
    var background_decorations: Array[TextureRect] = []
    var small_nature_cells: Array[Vector2i] = []
    var waypoint_flags: Dictionary = {}
    var rng := RandomNumberGenerator.new()
    var decoration_catalog: Array[Dictionary] = []
    var decoration_cursor := 0

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        rng.seed = 8129
        decoration_catalog = _build_decoration_catalog()

    func sync(board_size: float, map_zoom: float, map_pan: Vector2, board_origin: Vector2) -> void:
        if runtime == null or board_size <= 0.0: return
        if not generated:
            _generate_decorations()
            _generate_border_fences()
            _generate_border_trees()
            _generate_field_trees()
            _generate_background_decorations()
        var cell_size := board_size / float(GRID_SIZE)
        for decoration: TextureRect in decorations:
            var cell := decoration.get_meta("cell", Vector2i.ZERO) as Vector2i
            var category := str(decoration.get_meta("category", "props"))
            var occupancy := 0.44 if category in ["grass", "flowers"] else (0.68 if category == "dirt" else (0.76 if category == "bushes" else 0.90))
            var target := maxf(8.0, cell_size * occupancy) * map_zoom
            var source_size := decoration.texture.get_size() if decoration.texture != null else Vector2.ONE
            var max_dimension := maxf(1.0, maxf(source_size.x, source_size.y))
            var display_size := source_size * (target / max_dimension)
            decoration.size = display_size
            decoration.position = board_origin + map_pan + (Vector2(cell) + Vector2.ONE * 0.5) * cell_size * map_zoom - display_size * 0.5
        for fence: TextureRect in border_fences:
            var cell := fence.get_meta("cell", Vector2i.ZERO) as Vector2i
            var vertical := bool(fence.get_meta("vertical", false))
            var source_size := fence.texture.get_size() if fence.texture != null else Vector2.ONE
            var target_length := cell_size * 1.18 * map_zoom
            var corner := bool(fence.get_meta("corner", false))
            var source_length := maxf(source_size.x, source_size.y) if corner else (source_size.y if vertical else source_size.x)
            var display_size := source_size * (target_length / maxf(1.0, source_length))
            fence.size = display_size
            fence.pivot_offset = display_size * 0.5
            fence.rotation = float(fence.get_meta("rotation", 0.0))
            var center := board_origin + map_pan + (Vector2(cell) + Vector2.ONE * 0.5) * cell_size * map_zoom
            fence.position = center - display_size * 0.5
        for tree: TextureRect in border_trees:
            var cell := tree.get_meta("cell", Vector2i.ZERO) as Vector2i
            var side := str(tree.get_meta("side", "top"))
            var scale_factor := float(tree.get_meta("scale_factor", 1.0))
            var source_size := tree.texture.get_size() if tree.texture != null else Vector2.ONE
            var base_height := 1.75 if side == "field" else 2.15
            var target_height := cell_size * base_height * scale_factor * map_zoom
            var display_size := source_size * (target_height / maxf(1.0, source_size.y))
            var scaled_cell := cell_size * map_zoom
            var map_top_left := board_origin + map_pan
            match side:
                "top":
                    tree.position = map_top_left + Vector2((cell.x + 0.5) * scaled_cell - display_size.x * 0.5, scaled_cell * 0.05)
                "bottom":
                    tree.position = map_top_left + Vector2((cell.x + 0.5) * scaled_cell - display_size.x * 0.5, GRID_SIZE * scaled_cell - display_size.y - scaled_cell * 0.05)
                "left":
                    tree.position = map_top_left + Vector2(scaled_cell * 0.05, (cell.y + 1.0) * scaled_cell - display_size.y)
                "field":
                    tree.position = map_top_left + Vector2((cell.x + 0.5) * scaled_cell - display_size.x * 0.5, (cell.y + 1.0) * scaled_cell - display_size.y)
                _:
                    tree.position = map_top_left + Vector2(GRID_SIZE * scaled_cell - display_size.x - scaled_cell * 0.05, (cell.y + 1.0) * scaled_cell - display_size.y)
            tree.size = display_size
        for decoration: TextureRect in background_decorations:
            var virtual_cell := decoration.get_meta("virtual_cell", Vector2i.ZERO) as Vector2i
            var category := str(decoration.get_meta("category", "grass"))
            var source_size := decoration.texture.get_size() if decoration.texture != null else Vector2.ONE
            var occupancy := 1.35 if category == "tree" else (0.72 if category == "bush" else (0.42 if category == "flower" else 0.36))
            var target := cell_size * occupancy * map_zoom
            var display_size := source_size * (target / maxf(1.0, maxf(source_size.x, source_size.y)))
            decoration.size = display_size
            decoration.position = board_origin + map_pan + (Vector2(virtual_cell) + Vector2.ONE * 0.5) * cell_size * map_zoom - display_size * 0.5
        var live_flags := {}
        if runtime.map != null:
            for point: Vector2i in runtime.map.ordered_waypoints():
                if point == runtime.map.spawn: continue
                var key := str(point)
                var waypoint_flag := waypoint_flags.get(key) as FlagDecoration
                if not is_instance_valid(waypoint_flag):
                    waypoint_flag = FlagDecoration.new()
                    add_child(waypoint_flag)
                    waypoint_flags[key] = waypoint_flag
                waypoint_flag.sync_cell(point, cell_size, map_zoom, map_pan, board_origin)
                waypoint_flag.visible = waypoint_flag.texture != null
                live_flags[key] = true
        for key in waypoint_flags.keys():
            if live_flags.has(key): continue
            var stale_flag := waypoint_flags[key] as FlagDecoration
            if is_instance_valid(stale_flag): stale_flag.queue_free()
            waypoint_flags.erase(key)

    func _generate_decorations() -> void:
        generated = true
        var route := {}
        if runtime != null and runtime.pathfinder != null and runtime.map != null:
            for cell: Vector2i in runtime.pathfinder.find_route(runtime.map): route[str(cell)] = true
        var points := {}
        if runtime != null and runtime.map != null:
            for point: Vector2i in runtime.map.ordered_waypoints(): points[str(point)] = true
        for y in range(GRID_SIZE):
            for x in range(GRID_SIZE):
                var cell := Vector2i(x, y)
                if x == 0 or y == 0 or x == GRID_SIZE - 1 or y == GRID_SIZE - 1: continue
                if route.has(str(cell)) or points.has(str(cell)) or _near_route(cell, route): continue
                if decoration_catalog.is_empty(): continue
                var entry: Dictionary = decoration_catalog[decoration_cursor % decoration_catalog.size()]
                decoration_cursor += 1
                var category: String = entry["category"]
                var chance := 0.24 if category in ["grass", "flowers"] else 0.10
                if rng.randf() > chance: continue
                if category in ["grass", "flowers"] and _near_small_nature(cell): continue
                var path: String = entry["path"]
                var texture := load(path) as Texture2D
                if texture == null:
                    push_warning("Map decoration missing: %s" % path)
                    continue
                var decoration := TextureRect.new()
                decoration.texture = texture
                decoration.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                decoration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                decoration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
                decoration.set_meta("cell", cell)
                decoration.set_meta("category", entry["category"])
                add_child(decoration)
                decorations.append(decoration)
                if category in ["grass", "flowers"]: small_nature_cells.append(cell)

    func _generate_border_fences() -> void:
        if runtime == null or runtime.grid == null: return
        for x in range(1, GRID_SIZE - 1):
            _add_border_fence(Vector2i(x, 0), false, x)
            _add_border_fence(Vector2i(x, GRID_SIZE - 1), false, x + 2)
        for y in range(1, GRID_SIZE - 1):
            _add_border_fence(Vector2i(0, y), true, y)
            _add_border_fence(Vector2i(GRID_SIZE - 1, y), true, y + 2)
        _add_corner_fence(Vector2i(0, 0), 0.0)
        _add_corner_fence(Vector2i(GRID_SIZE - 1, 0), PI * 0.5)
        _add_corner_fence(Vector2i(GRID_SIZE - 1, GRID_SIZE - 1), PI)
        _add_corner_fence(Vector2i(0, GRID_SIZE - 1), -PI * 0.5)

    func _add_border_fence(cell: Vector2i, vertical: bool, variant_seed: int) -> void:
        if runtime.grid.state_at(cell) != GridModel.CellState.BLOCKED: return
        var variant := posmod(variant_seed, 4) + 1
        var path := "res://assets/art/gameplay/environment/props/fences/%d.png" % variant
        if vertical:
            path = "res://assets/art/gameplay/environment/props/fences/7.png"
        var texture := load(path) as Texture2D
        if texture == null:
            push_warning("Map fence missing: %s" % path)
            return
        var fence := TextureRect.new()
        fence.texture = texture
        fence.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        fence.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        fence.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        fence.mouse_filter = Control.MOUSE_FILTER_IGNORE
        fence.set_meta("cell", cell)
        fence.set_meta("vertical", vertical)
        add_child(fence)
        border_fences.append(fence)

    func _add_corner_fence(cell: Vector2i, rotation: float) -> void:
        if runtime.grid.state_at(cell) != GridModel.CellState.BLOCKED: return
        var texture := load("res://assets/art/gameplay/environment/props/fences/6.png") as Texture2D
        if texture == null:
            push_warning("Map corner fence missing: res://assets/art/gameplay/environment/props/fences/6.png")
            return
        var fence := TextureRect.new()
        fence.texture = texture
        fence.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        fence.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        fence.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        fence.mouse_filter = Control.MOUSE_FILTER_IGNORE
        fence.set_meta("cell", cell)
        fence.set_meta("vertical", false)
        fence.set_meta("corner", true)
        fence.set_meta("rotation", rotation)
        add_child(fence)
        border_fences.append(fence)

    func _generate_border_trees() -> void:
        var top_positions := _random_border_positions(1701)
        var bottom_positions := _random_border_positions(2837)
        for x in top_positions:
            _add_border_tree(Vector2i(x, 0), "top", x)
        for x in bottom_positions:
            _add_border_tree(Vector2i(x, GRID_SIZE - 1), "bottom", x + 2)
        var left_positions := _random_border_positions(3919)
        var right_positions := _random_border_positions(4721)
        for y in left_positions:
            _add_border_tree(Vector2i(0, y), "left", y)
        for y in right_positions:
            _add_border_tree(Vector2i(GRID_SIZE - 1, y), "right", y + 2)

    func _random_border_positions(seed_value: int) -> Array[int]:
        var local_rng := RandomNumberGenerator.new()
        local_rng.seed = seed_value
        var result: Array[int] = []
        var target_count := local_rng.randi_range(2, 3)
        var attempts := 0
        while result.size() < target_count and attempts < 80:
            attempts += 1
            var position := local_rng.randi_range(3, GRID_SIZE - 4)
            var valid := true
            for other: int in result:
                if absi(position - other) < 6:
                    valid = false
                    break
            if valid: result.append(position)
        result.sort()
        return result

    func _generate_field_trees() -> void:
        if runtime == null or runtime.grid == null or runtime.pathfinder == null or runtime.map == null: return
        var route := {}
        for cell: Vector2i in runtime.pathfinder.find_route(runtime.map): route[str(cell)] = true
        var points := {}
        for point: Vector2i in runtime.map.ordered_waypoints(): points[str(point)] = true
        var candidates: Array[Vector2i] = []
        for y in range(1, GRID_SIZE - 1):
            for x in range(1, GRID_SIZE - 1):
                var cell := Vector2i(x, y)
                if route.has(str(cell)) or points.has(str(cell)) or _near_route(cell, route): continue
                if runtime.grid.state_at(cell) == GridModel.CellState.BLOCKED: continue
                candidates.append(cell)
        # Add a few asymmetric trees just inside the fence.
        var inner_candidates: Array[Vector2i] = []
        for cell: Vector2i in candidates:
            var edge_distance := mini(cell.x, mini(cell.y, mini(GRID_SIZE - 1 - cell.x, GRID_SIZE - 1 - cell.y)))
            if edge_distance <= 2: inner_candidates.append(cell)
        var inner_attempts := 0
        while field_tree_cells.size() < 3 and not inner_candidates.is_empty() and inner_attempts < 40:
            inner_attempts += 1
            var inner_index := rng.randi_range(0, inner_candidates.size() - 1)
            var inner_cell: Vector2i = inner_candidates[inner_index]
            inner_candidates.remove_at(inner_index)
            if _near_field_tree(inner_cell) or _near_small_nature(inner_cell): continue
            if _add_field_tree(inner_cell, inner_attempts): field_tree_cells.append(inner_cell)
        var attempts := 0
        while field_tree_cells.size() < 10 and not candidates.is_empty() and attempts < 120:
            attempts += 1
            var candidate_index := rng.randi_range(0, candidates.size() - 1)
            var cell: Vector2i = candidates[candidate_index]
            candidates.remove_at(candidate_index)
            if _near_field_tree(cell) or _near_small_nature(cell): continue
            if _add_field_tree(cell, attempts): field_tree_cells.append(cell)

    func _generate_background_decorations() -> void:
        if runtime == null: return
        var candidates: Array[Vector2i] = []
        var cell_size := maxf(1.0, minf(size.x, size.y) / float(GRID_SIZE))
        var margin_cells := maxi(4, ceili(maxf(size.x, size.y) / cell_size) + 2)
        for y in range(-margin_cells, GRID_SIZE + margin_cells):
            for x in range(-margin_cells, GRID_SIZE + margin_cells):
                var outside := x < 0 or y < 0 or x >= GRID_SIZE or y >= GRID_SIZE
                if not outside: continue
                # Keep clear spots so the outer field feels scattered.
                if posmod(x * 13 + y * 7, 7) > 1: continue
                candidates.append(Vector2i(x, y))
        var catalog := _background_decoration_catalog()
        var accepted_cells: Array[Vector2i] = []
        var exterior_tree_count := 0
        for cell: Vector2i in candidates:
            if rng.randf() > 0.30: continue
            if _near_background_cell(cell, accepted_cells, 2.0): continue
            var entry: Dictionary = catalog[rng.randi_range(0, catalog.size() - 1)]
            if entry["category"] == "tree":
                if exterior_tree_count >= 6 or rng.randf() > 0.35: continue
                exterior_tree_count += 1
            var path: String = entry["path"]
            var texture := load(path) as Texture2D
            if texture == null: continue
            var decoration := TextureRect.new()
            decoration.texture = texture
            decoration.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            decoration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            decoration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
            decoration.set_meta("virtual_cell", cell)
            decoration.set_meta("category", entry["category"])
            add_child(decoration)
            background_decorations.append(decoration)
            accepted_cells.append(cell)

    func _near_background_cell(cell: Vector2i, accepted: Array[Vector2i], distance: float) -> bool:
        for other: Vector2i in accepted:
            if cell.distance_to(other) < distance: return true
        return false

    func _add_border_tree(cell: Vector2i, side: String, variant_seed: int) -> void:
        _add_tree(cell, side, variant_seed, true)

    func _add_field_tree(cell: Vector2i, variant_seed: int) -> bool:
        return _add_tree(cell, "field", variant_seed, false)

    func _add_tree(cell: Vector2i, side: String, variant_seed: int, blocked_only: bool) -> bool:
        if runtime == null or runtime.grid == null: return false
        if blocked_only and runtime.grid.state_at(cell) != GridModel.CellState.BLOCKED: return false
        var path := "res://assets/art/gameplay/environment/props/trees/Tree1.png"
        var texture := load(path) as Texture2D
        if texture == null:
            push_warning("Map tree missing: %s" % path)
            return false
        var tree := TextureRect.new()
        tree.texture = texture
        tree.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        tree.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tree.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
        tree.set_meta("cell", cell)
        tree.set_meta("side", side)
        tree.set_meta("scale_factor", 0.92 + float(posmod(variant_seed, 3)) * 0.08)
        add_child(tree)
        border_trees.append(tree)
        return true

    func _near_field_tree(cell: Vector2i) -> bool:
        for other: Vector2i in field_tree_cells:
            if cell.distance_to(other) < 6.0: return true
        return false

    func _build_decoration_catalog() -> Array[Dictionary]:
        var result: Array[Dictionary] = []
        for index in range(1, 7):
            result.append({"path": "res://assets/art/gameplay/environment/vegetation/grass/%d.png" % index, "category": "grass"})
        for index in range(1, 13):
            result.append({"path": "res://assets/art/gameplay/environment/vegetation/flowers/%d.png" % index, "category": "flowers"})
        for index in range(1, 7):
            result.append({"path": "res://assets/art/gameplay/environment/vegetation/bushes/%d.png" % index, "category": "bushes"})
        for index in range(1, 7):
            result.append({"path": "res://assets/art/gameplay/environment/props/dirt/Dirt%d.png" % index, "category": "dirt"})
        for index in range(1, 5):
            result.append({"path": "res://assets/art/gameplay/environment/props/logs/Log%d.png" % index, "category": "props"})
        for index in range(1, 5):
            result.append({"path": "res://assets/art/gameplay/environment/props/boxes/Box%d.png" % index, "category": "props"})
        for index in range(1, 7):
            result.append({"path": "res://assets/art/gameplay/environment/props/lamps/Lamp%d.png" % index, "category": "props"})
        result.append({"path": "res://assets/art/gameplay/environment/props/trees/Tree2.png", "category": "props"})
        return result

    func _background_decoration_catalog() -> Array[Dictionary]:
        var result: Array[Dictionary] = []
        for index in range(1, 7):
            result.append({"path": "res://assets/art/gameplay/environment/vegetation/grass/%d.png" % index, "category": "grass"})
        for index in range(1, 13):
            result.append({"path": "res://assets/art/gameplay/environment/vegetation/flowers/%d.png" % index, "category": "flower"})
        for index in range(1, 7):
            result.append({"path": "res://assets/art/gameplay/environment/vegetation/bushes/%d.png" % index, "category": "bush"})
        for index in range(1, 3):
            result.append({"path": "res://assets/art/gameplay/environment/props/trees/Tree%d.png" % index, "category": "tree"})
        return result

    func _near_small_nature(cell: Vector2i) -> bool:
        for other: Vector2i in small_nature_cells:
            if cell.distance_to(other) < 2.5: return true
        return false

    func _near_route(cell: Vector2i, route: Dictionary) -> bool:
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if route.has(str(cell + Vector2i(dx, dy))): return true
        return false

class FlagDecoration extends TextureRect:
    const FRAME_PATH := "res://assets/art/gameplay/environment/landmarks/flag/1.png"
    var atlas := AtlasTexture.new()
    var current_frame := -1
    var cell := Vector2i.ZERO
    var cell_size := 1.0
    var map_zoom := 1.0
    var map_pan := Vector2.ZERO

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var source := load(FRAME_PATH) as Texture2D
        if source == null:
            push_warning("Waypoint flag texture missing: %s" % FRAME_PATH)
            texture = null
        else:
            atlas.atlas = source
            texture = atlas
        set_process(true)

    func sync_cell(value: Vector2i, value_cell_size: float, value_zoom: float, value_pan: Vector2, value_origin: Vector2) -> void:
        cell = value; cell_size = value_cell_size; map_zoom = value_zoom; map_pan = value_pan
        var target_height := cell_size * 1.45 * map_zoom
        var source_size := Vector2(32, 64)
        size = source_size * (target_height / source_size.y)
        position = value_origin + map_pan + (Vector2(cell) + Vector2(0.5, 0.95)) * cell_size * map_zoom - Vector2(size.x * 0.5, size.y)

    func _process(_delta: float) -> void:
        if atlas.atlas == null: return
        var next_frame := int(Time.get_ticks_msec() / 160) % 6
        if next_frame == current_frame: return
        current_frame = next_frame
        atlas.region = Rect2(current_frame * 32, 0, 32, 64)

class SpawnerDecoration extends TextureRect:
    const FRAME_PATHS := [
        "res://assets/art/gameplay/environment/spawner/spawner_01.png",
        "res://assets/art/gameplay/environment/spawner/spawner_02.png",
        "res://assets/art/gameplay/environment/spawner/spawner_03.png",
        "res://assets/art/gameplay/environment/spawner/spawner_04.png",
    ]

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var frame_index := randi_range(0, FRAME_PATHS.size() - 1)
        texture = load(FRAME_PATHS[frame_index]) as Texture2D
        if texture == null: push_warning("Spawner texture missing: %s" % FRAME_PATHS[frame_index])

class StoneDecoration extends TextureRect:
    const FRAME_PATHS := [
        "res://assets/art/gameplay/environment/stones/stone_06.png",
        "res://assets/art/gameplay/environment/stones/stone_05.png",
        "res://assets/art/gameplay/environment/stones/stone_04.png",
        "res://assets/art/gameplay/environment/stones/stone_03.png",
        "res://assets/art/gameplay/environment/stones/stone_02.png",
        "res://assets/art/gameplay/environment/stones/stone_01.png",
    ]

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var frame_index := randi_range(0, FRAME_PATHS.size() - 1)
        texture = load(FRAME_PATHS[frame_index]) as Texture2D
        if texture == null: push_warning("Stone texture missing: %s" % FRAME_PATHS[frame_index])

class CampfireDecoration extends TextureRect:
    const SHEET := preload("res://assets/art/gameplay/environment/campfire.png")
    var atlas := AtlasTexture.new()
    var current_frame := -1
    func _ready() -> void:
        custom_minimum_size = Vector2(96, 52)
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        atlas.atlas = SHEET
        texture = atlas
        set_process(true)
    func _process(_delta: float) -> void:
        var next_frame := int(Time.get_ticks_msec() / 140) % 6
        if next_frame == current_frame: return
        current_frame = next_frame
        atlas.region = Rect2(current_frame * 32, 0, 32, 64)
