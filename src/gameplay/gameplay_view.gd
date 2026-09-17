class_name GameplayView
extends Control

const MODAL_TITLE_FONT := preload("res://assets/fonts/anak_bijak.ttf")

signal main_menu_requested
signal logout_requested
signal exit_requested

const SelectionStateScript = preload("res://src/gameplay/ui/selection_state.gd")
const CommandCardModelScript = preload("res://src/gameplay/ui/command_card_model.gd")
const SettingsStoreScript = preload("res://src/gameplay/ui/settings_store.gd")
const GemAssetLibraryScript = preload("res://src/gameplay/assets/gem_asset_library.gd")
const GemAssetGalleryScript = preload("res://src/gameplay/ui/gem_asset_gallery.gd")
const ENEMY_NECROMANCER_SHEET_PATH := "res://assets/art/gameplay/enemies/gatos_nigromantes/necromancer_cat.png"
const ENEMY_NECROMANCER_ICON_PATH := "res://assets/art/gameplay/enemies/gatos_nigromantes/necromancer_cat_icon.png"
const ENEMY_NORMAL_SHEET_PATH := "res://assets/art/gameplay/enemies/normal_enemies/necromancer_cat.png"
const ENEMY_NORMAL_ICON_PATH := "res://assets/art/gameplay/enemies/normal_enemies/necromancer_cat_icon.png"
const ENEMY_BOSS_SHEET_PATH := "res://assets/art/gameplay/enemies/boss/necromancer_cat_boss.png"
const ENEMY_BOSS_ICON_PATH := "res://assets/art/gameplay/enemies/boss/necromancer_cat_boss_icon.png"
const ENEMY_INVISIBLE_SHEET_PATH := "res://assets/art/gameplay/enemies/invisibles/invisible_cat_w8.png"
const ENEMY_INVISIBLE_ICON_PATH := "res://assets/art/gameplay/enemies/invisibles/invisible_cat_w8_icon.png"
const ENEMY_FALLBACK_SHEET_PATH := "res://assets/art/gameplay/enemies/pipo_nekonin027.png"
const ENEMY_FALLBACK_ICON_PATH := "res://assets/art/gameplay/enemies/pipo_nekonin027.png"

var runtime: GameRuntime
var selection: SelectionState
var command_model: CommandCardModel
var settings: SettingsStore
var visual_assets: VisualAssetConfig
var gem_assets: GemAssetLibrary
var map_view: MapDebugView
var _enemy_sheet_cache: Dictionary = {}
var _enemy_icon_cache: Dictionary = {}
var wave_label: Label
var life_bar: ProgressBar
var life_value_label: Label
var _life_fill_style: StyleBoxFlat
var _life_tween: Tween
var _life_target_value := -1.0
var gold_value_label: Label
var player_level_label: Label
var xp_bar: ProgressBar
var xp_value_label: Label
var progress_bar: ProgressBar
var progress_name_label: Label
var progress_value_label: Label
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
var gem_gallery: Control
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
var combination_popup: PanelContainer
var combination_popup_arrow: Label
var combination_options: Array = []

func setup(value: GameRuntime, shared_settings: SettingsStore = null, shared_visual_assets: VisualAssetConfig = null) -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    runtime = value
    gem_assets = GemAssetLibraryScript.new()
    LocalizationService = get_node("/root/LocalizationService")
    selection = SelectionStateScript.new()
    command_model = CommandCardModelScript.new()
    settings = shared_settings if shared_settings != null else SettingsStoreScript.new()
    if shared_settings == null: settings.load_settings()
    visual_assets = shared_visual_assets if shared_visual_assets != null else VisualAssetConfig.new()
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
    if not runtime.combat.damage_applied.is_connected(_on_damage_applied):
        runtime.combat.damage_applied.connect(_on_damage_applied)
    if not runtime.outcome.life_changed.is_connected(_on_life_changed):
        runtime.outcome.life_changed.connect(_on_life_changed)
    runtime.phases.phase_entered.connect(func(_phase): place_gem_mode = false; _close_combination_popup(); map_view.sync_gem_sprites(); _refresh_ui(); _rebuild_command_card())
    runtime.outcome.victorious.connect(func(): _show_end(true))
    runtime.outcome.defeated.connect(func(): _show_end(false))
    runtime.support_rewards.reward_available.connect(_show_reward)
    LocalizationService.locale_changed.connect(_on_gameplay_locale_changed)
    selection.changed.connect(_on_gameplay_selection_changed)
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
        map_view.queue_enemy_redraw()

func _on_gameplay_locale_changed(_locale: String) -> void:
    var popup_gem := _selected_combination_gem() if is_instance_valid(combination_popup) else null
    var popup_stone: Variant = selection.value if is_instance_valid(combination_popup) and selection.kind == SelectionState.Kind.STONE else null
    _refresh_ui()
    if is_instance_valid(progress_name_label): progress_name_label.text = LocalizationService.tr_key("game.player.progress")
    _rebuild_command_card()
    _refresh_open_overlays()
    if popup_gem != null: _open_combination_popup_for(popup_gem)
    elif popup_stone is Vector2i: _open_stone_popup_for(popup_stone)

func _on_gameplay_selection_changed() -> void:
    _refresh_ui()
    _rebuild_command_card()
    map_view.queue_redraw()
    if is_instance_valid(combination_popup) and _selected_combination_gem() == null:
        _close_combination_popup()

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
    row.add_child(_hud_separator())
    var xp_group := HBoxContainer.new(); xp_group.add_theme_constant_override("separation", 6); xp_group.custom_minimum_size = Vector2(230, 0); xp_group.mouse_filter = Control.MOUSE_FILTER_PASS; row.add_child(xp_group)
    player_level_label = Label.new(); player_level_label.add_theme_font_size_override("font_size", 17); xp_group.add_child(player_level_label)
    xp_bar = ProgressBar.new(); xp_bar.custom_minimum_size = Vector2(105, 18); xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; xp_bar.show_percentage = false; xp_bar.add_theme_stylebox_override("background", _resource_bar_style(Color("4b3428"))); xp_bar.add_theme_stylebox_override("fill", _resource_bar_style(Color("9c7cff"))); xp_group.add_child(xp_bar)
    xp_value_label = Label.new(); xp_value_label.custom_minimum_size = Vector2(82, 0); xp_value_label.add_theme_font_size_override("font_size", 14); xp_group.add_child(xp_value_label)
    xp_group.tooltip_text = _player_quality_probability_tooltip()
    player_level_label.tooltip_text = xp_group.tooltip_text
    xp_bar.tooltip_text = xp_group.tooltip_text
    xp_value_label.tooltip_text = xp_group.tooltip_text
    row.add_child(_hud_separator())
    var progress_group := HBoxContainer.new(); progress_group.add_theme_constant_override("separation", 6); progress_group.custom_minimum_size = Vector2(190, 0); row.add_child(progress_group)
    progress_name_label = Label.new(); progress_name_label.text = LocalizationService.tr_key("game.player.progress"); progress_name_label.add_theme_font_size_override("font_size", 15); progress_name_label.tooltip_text = LocalizationService.tr_key("game.player.progress"); progress_group.add_child(progress_name_label)
    progress_bar = ProgressBar.new(); progress_bar.custom_minimum_size = Vector2(88, 18); progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; progress_bar.show_percentage = false; progress_bar.add_theme_stylebox_override("background", _resource_bar_style(Color("4b3428"))); progress_bar.add_theme_stylebox_override("fill", _resource_bar_style(Color("d99b50"))); progress_group.add_child(progress_bar)
    progress_value_label = Label.new(); progress_value_label.custom_minimum_size = Vector2(64, 0); progress_value_label.add_theme_font_size_override("font_size", 14); progress_group.add_child(progress_value_label)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    var pause := Button.new(); pause.text = "Ⅱ"; pause.custom_minimum_size = Vector2(42, 38); pause.tooltip_text = LocalizationService.tr_key("game.pause"); pause.process_mode = Node.PROCESS_MODE_ALWAYS; _style_game_button(pause); pause.pressed.connect(_toggle_pause); row.add_child(pause)
    var settings_button := Button.new(); settings_button.icon = visual_assets.settings; settings_button.expand_icon = true; settings_button.custom_minimum_size = Vector2(42, 38); settings_button.tooltip_text = LocalizationService.tr_key("game.settings.title"); settings_button.process_mode = Node.PROCESS_MODE_ALWAYS; _style_game_button(settings_button); settings_button.pressed.connect(_on_settings_pressed); row.add_child(settings_button)
    var recipes_button := Button.new(); recipes_button.icon = visual_assets.recipes; recipes_button.expand_icon = true; recipes_button.custom_minimum_size = Vector2(42, 38); recipes_button.tooltip_text = LocalizationService.tr_key("game.recipes.title"); recipes_button.process_mode = Node.PROCESS_MODE_ALWAYS; _style_game_button(recipes_button); recipes_button.pressed.connect(_toggle_recipes); row.add_child(recipes_button)
    var guide_button := Button.new(); guide_button.icon = visual_assets.help; guide_button.expand_icon = true; guide_button.custom_minimum_size = Vector2(42, 38); guide_button.tooltip_text = LocalizationService.tr_key("game.help.title"); guide_button.process_mode = Node.PROCESS_MODE_ALWAYS; _style_game_button(guide_button); guide_button.pressed.connect(_toggle_help); row.add_child(guide_button)

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

func _on_damage_applied(enemy: EnemyRuntime, _amount: float) -> void:
    # Keep hit feedback in the visual layer; damage, hitboxes and targeting
    # remain owned by CombatRuntime.
    if map_view != null and enemy != null:
        map_view.show_damage_feedback(enemy.position)

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
    icon.texture = _hud_icon_texture(name)
    icon.custom_minimum_size = Vector2(28, 28)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    icon.tooltip_text = tooltip
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func _hud_icon_texture(name: String) -> Texture2D:
    match name:
        "life": return visual_assets.hud_life
        "gold": return visual_assets.hud_gold
        "progress": return visual_assets.hud_progress
        _: return null

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
    var sidebar_root := Control.new()
    sidebar_root.name = "VBoxContainer"
    sidebar_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sidebar_root.clip_contents = false
    command_panel.add_child(sidebar_root)
    var sidebar_art := TextureRect.new()
    sidebar_art.texture = load("res://assets/art/backgrounds/gameplay_sidebar.png") as Texture2D
    sidebar_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sidebar_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    sidebar_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # PanelContainer reserves its decorative margins for the child. Extend
    # the artwork underneath those margins so no empty strips or seams show.
    sidebar_art.offset_left = -18
    sidebar_art.offset_top = -18
    sidebar_art.offset_right = 18
    sidebar_art.offset_bottom = 18
    # Fade only the artwork; the UI controls retain their normal contrast.
    sidebar_art.self_modulate = Color(1.0, 1.0, 1.0, 0.12)
    sidebar_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    sidebar_root.add_child(sidebar_art)
    var column := VBoxContainer.new(); column.name = "Content"; column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); column.add_theme_constant_override("separation", 8); sidebar_root.add_child(column)
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
    help_button = Button.new(); help_button.text = LocalizationService.tr_key("game.help.title"); help_button.icon = visual_assets.help; help_button.expand_icon = true; help_button.custom_minimum_size = Vector2(0, 38); _style_game_button(help_button); help_button.pressed.connect(_toggle_help); help_button.visible = false; column.add_child(help_button)
    # Keep the command card clean; the decorative smoke competed with the
    # contextual selection and action sections.

func _build_inspector(parent: Control) -> void:
    var inspector := PanelContainer.new()
    inspector_panel = inspector
    inspector.custom_minimum_size = Vector2(0, 150)
    inspector.add_theme_stylebox_override("panel", _hud_panel())
    var target_parent: Node = parent
    if parent == command_panel and command_panel.get_child_count() > 0:
        var sidebar_root := command_panel.get_child(0)
        target_parent = sidebar_root.get_node("Content")
    target_parent.add_child(inspector)
    var inspector_column := VBoxContainer.new()
    inspector_column.add_theme_constant_override("separation", 6)
    inspector.add_child(inspector_column)
    inspector_title_label = Label.new()
    inspector_title_label.text = LocalizationService.tr_key("game.inspector.tower.title")
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
    icon_frame.custom_minimum_size = Vector2(48, 48)
    icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var icon_style := StyleBoxFlat.new()
    icon_style.bg_color = Color("5a321f")
    icon_style.border_color = Color("c87a35")
    icon_style.set_border_width_all(1)
    icon_style.set_corner_radius_all(6)
    icon_style.content_margin_left = 2
    icon_style.content_margin_top = 2
    icon_style.content_margin_right = 2
    icon_style.content_margin_bottom = 2
    icon_frame.add_theme_stylebox_override("panel", icon_style)
    inspector_header.add_child(icon_frame)
    inspector_icon = TextureRect.new()
    inspector_icon.custom_minimum_size = Vector2(40, 40)
    inspector_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    inspector_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    inspector_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    inspector_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    inspector_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_frame.add_child(inspector_icon)
    inspector_name_label = RichTextLabel.new()
    inspector_name_label.bbcode_enabled = true
    inspector_name_label.fit_content = true
    inspector_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inspector_name_label.scroll_active = false
    inspector_name_label.custom_minimum_size = Vector2(0, 0)
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
    var title := command_panel.get_node_or_null("VBoxContainer/Content/Title") as Label
    if title != null: title.text = LocalizationService.tr_key("game.command.title")
    for i in command_buttons.size():
        var action: Dictionary = command_model.actions[i]
        command_buttons[i].text = _command_label(action.id)
        var command_icon := _command_icon_texture(action.id)
        command_buttons[i].icon = command_icon
        command_buttons[i].expand_icon = command_icon != null
        command_buttons[i].disabled = not action.enabled
        command_buttons[i].visible = false
    var sidebar_root := command_panel.get_child(0) as Control
    if sidebar_root != null:
        var content := sidebar_root.get_node_or_null("Content") as Control
        if content != null:
            var sidebar_title := content.get_node_or_null("Title") as Control
            var grid := content.get_node_or_null("Grid") as Control
            if sidebar_title != null: sidebar_title.visible = false
            if grid != null: grid.visible = false

func _command_label(id: String) -> String:
    if id == "attack" and selection != null and selection.kind == SelectionState.Kind.TOWER and runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
        var tower := selection.value as TowerRuntime
        if tower != null:
            return LocalizationService.tr_key("game.command.attack_enabled" if tower.attack_enabled else "game.command.attack_disabled")
    if id == "attack" and selection != null and selection.kind == SelectionState.Kind.TOWER and runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.COMBAT:
        var combat_tower := selection.value as TowerRuntime
        if combat_tower != null and not combat_tower.attack_enabled:
            return LocalizationService.tr_key("game.command.activate")
    if id == "stop" and selection != null and selection.kind == SelectionState.Kind.TOWER and runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.COMBAT:
        var stopped_tower := selection.value as TowerRuntime
        if stopped_tower != null and stopped_tower.stopped:
            return LocalizationService.tr_key("game.command.activate")
    return LocalizationService.tr_key("game.command." + id)

func _command_icon_texture(id: String) -> Texture2D:
    if id == "recipes": return visual_assets.recipes
    if id == "settings": return visual_assets.settings
    if id == "debug": return visual_assets.help
    return null

func _execute_command(index: int) -> void:
    if index < 0 or index >= command_model.actions.size(): return
    var action: Dictionary = command_model.actions[index]
    if not action.get("visible", false) or not action.get("enabled", false): return
    var id: String = action.id
    match id:
        "place_gem":
            # Q arms placement. The following click resolves the cell from
            # the map event itself, so opening the game no longer requires a
            # preliminary click just to initialize hover state.
            if runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION and map_view != null:
                place_gem_mode = not place_gem_mode
                selection.clear()
                _close_combination_popup()
                map_view.hover_can_place = map_view._can_preview_placement(map_view.hover_cell)
                _set_map_cursor(place_gem_mode and map_view.hover_can_place)
        "select_gem": _set_feedback("game.feedback.select_hint")
        "combine": _open_combination_popup_for(_selected_combination_gem())
        "degrade": _degrade_selected()
        "remove_stone": _remove_selected_stone()
        "attack": _toggle_attack_selected() if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION else _attack_selected()
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
        if is_instance_valid(combination_popup):
            _close_combination_popup()
            return
        selection.clear(); return
    if event.keycode == KEY_F10: _toggle_debug(); return
    if event.keycode == KEY_R and event.ctrl_pressed: _restart(); return
    var key := OS.get_keycode_string(event.keycode)
    var index := CommandCardModelScript.HOTKEYS.find(key)
    if index >= 0: _execute_command(index)

func _combine_selected() -> void:
    var gem := _selected_combination_gem()
    if gem != null: _open_combination_popup_for(gem)

func _selected_combination_gem() -> GemInstance:
    if selection.is_empty(): return null
    if selection.kind == SelectionState.Kind.GEM: return selection.value as GemInstance
    if selection.kind == SelectionState.Kind.TOWER:
        var tower := selection.value as TowerRuntime
        return tower.gem if tower != null else null
    return null

func _degrade_selected() -> void:
    if selection.kind == SelectionState.Kind.GEM and runtime.construction.degrade(selection.value) == null: _set_feedback("game.feedback.invalid_action")

func _set_feedback(key: String) -> void:
    feedback_key = key
    if is_instance_valid(feedback_label): feedback_label.text = LocalizationService.tr_key(feedback_key)

func _can_open_gem_context_popup(gem: GemInstance) -> bool:
    return CommandCardModelScript.can_open_gem_context_popup(runtime, gem)

func _open_combination_popup_for(gem: GemInstance) -> void:
    _close_combination_popup()
    var selected_tower := selection.value as TowerRuntime if selection.kind == SelectionState.Kind.TOWER else null
    if selected_tower == null and not _can_open_gem_context_popup(gem): return
    command_model.rebuild(runtime, selection)
    combination_options = [] if selected_tower != null else runtime.construction.contextual_combinations(gem)
    combination_popup = PanelContainer.new()
    combination_popup.name = "CombinationPopup"
    # Context panels must stay above every map layer, including authored
    # foreground objects and the runtime overlay.
    combination_popup.z_index = 300
    combination_popup.mouse_filter = Control.MOUSE_FILTER_STOP
    combination_popup.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    combination_popup.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    combination_popup.custom_minimum_size = Vector2(390, 0)
    combination_popup.add_theme_stylebox_override("panel", _hud_panel())
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    combination_popup.add_child(column)
    var entity_header := HBoxContainer.new()
    entity_header.add_theme_constant_override("separation", 8)
    var entity_icon := TextureRect.new()
    entity_icon.custom_minimum_size = Vector2(42, 42)
    entity_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    entity_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    entity_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    entity_icon.texture = _tower_texture(gem.id, gem.level) if selected_tower != null else _gem_texture(gem.id, gem.level)
    entity_header.add_child(entity_icon)
    var entity_info := VBoxContainer.new()
    var entity_name := Label.new()
    entity_name.text = _quality_label(gem.quality) + " " + _display_gem_name(gem.id)
    entity_name.add_theme_font_override("font", MODAL_TITLE_FONT)
    entity_info.add_child(entity_name)
    entity_header.add_child(entity_info)
    column.add_child(entity_header)
    var entity_stats := Label.new()
    entity_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    entity_stats.text = _combination_entity_stats(gem)
    column.add_child(entity_stats)
    column.add_child(HSeparator.new())
    var title := Label.new()
    title.text = LocalizationService.tr_key("game.combinations.title")
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_font_override("font", MODAL_TITLE_FONT)
    column.add_child(title)
    if combination_options.is_empty():
        var empty := Label.new()
        empty.text = LocalizationService.tr_key("game.combinations.none")
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        column.add_child(empty)
    if not combination_options.is_empty():
        var options_scroll := ScrollContainer.new()
        options_scroll.name = "CombinationOptions"
        options_scroll.custom_minimum_size = Vector2(0, minf(220.0, 42.0 * combination_options.size()))
        options_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        var options_column := VBoxContainer.new()
        options_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        options_column.add_theme_constant_override("separation", 5)
        options_scroll.add_child(options_column)
        for index in combination_options.size():
            var option_button := Button.new()
            option_button.name = "CombinationAction_%d" % index
            option_button.text = _combination_option_label(combination_options[index])
            option_button.custom_minimum_size = Vector2(0, 38)
            option_button.tooltip_text = option_button.text
            _style_game_button(option_button)
            option_button.pressed.connect(_execute_combination_option.bind(index))
            options_column.add_child(option_button)
        column.add_child(options_scroll)
    _append_popup_actions(column)
    add_child(combination_popup)
    combination_popup_arrow = Label.new()
    combination_popup_arrow.text = "◀"
    combination_popup_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    combination_popup_arrow.z_index = 301
    combination_popup_arrow.add_theme_font_size_override("font_size", 24)
    add_child(combination_popup_arrow)
    _position_context_popup(gem.cell)

func _open_stone_popup_for(cell: Vector2i) -> void:
    _close_combination_popup()
    if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or not runtime.construction.stones.has(cell): return
    combination_popup = PanelContainer.new()
    combination_popup.name = "StoneActionPopup"
    combination_popup.z_index = 300
    combination_popup.mouse_filter = Control.MOUSE_FILTER_STOP
    combination_popup.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    combination_popup.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    combination_popup.custom_minimum_size = Vector2(300, 0)
    combination_popup.add_theme_stylebox_override("panel", _hud_panel())
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    combination_popup.add_child(column)
    var entity_header := HBoxContainer.new()
    entity_header.add_theme_constant_override("separation", 8)
    var entity_icon := TextureRect.new()
    entity_icon.custom_minimum_size = Vector2(42, 42)
    entity_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    entity_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    entity_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    entity_icon.texture = _stone_icon_texture()
    entity_header.add_child(entity_icon)
    var entity_name := Label.new()
    entity_name.text = LocalizationService.tr_key("game.selection.stone")
    entity_name.add_theme_font_override("font", MODAL_TITLE_FONT)
    entity_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    entity_header.add_child(entity_name)
    column.add_child(entity_header)
    column.add_child(HSeparator.new())
    _append_popup_actions(column)
    add_child(combination_popup)
    combination_popup_arrow = Label.new()
    combination_popup_arrow.text = "◀"
    combination_popup_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    combination_popup_arrow.z_index = 301
    combination_popup_arrow.add_theme_font_size_override("font_size", 24)
    add_child(combination_popup_arrow)
    _position_context_popup(cell)

func _append_popup_actions(column: VBoxContainer) -> void:
    var action_header := Label.new()
    action_header.text = LocalizationService.tr_key("game.combinations.actions")
    action_header.add_theme_font_size_override("font_size", 15)
    action_header.add_theme_font_override("font", MODAL_TITLE_FONT)
    column.add_child(action_header)
    for index in command_model.actions.size():
        var action: Dictionary = command_model.actions[index]
        var id: String = action.id
        if not action.get("visible", false): continue
        # Combination choices are rendered as independent direct actions above.
        # Keep the command-card action available to open this popup, but never
        # render a second confirmation button inside the popup itself.
        if id == "combine": continue
        var button := Button.new()
        button.text = _command_label(id)
        button.custom_minimum_size = Vector2(0, 36)
        button.disabled = not action.get("enabled", false)
        _style_game_button(button)
        var action_index := index
        button.pressed.connect(func(): _popup_action_pressed(action_index))
        column.add_child(button)

func _popup_action_pressed(index: int) -> void:
    _close_combination_popup()
    _execute_command(index)

func _combination_entity_stats(gem: GemInstance) -> String:
    var definition := runtime.foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
    var stats := TowerCombatStats.from_gem(gem, definition)
    return LocalizationService.tr_key("game.inspector.tower.stats", {"level": gem.level, "damage": "%.1f" % stats.damage, "range": "%.1f" % stats.range_units, "speed": "%.1f" % stats.total_attack_speed(), "abilities": _gem_abilities(gem)})

func _combination_option_label(option: Dictionary) -> String:
    var result_id: StringName = option.get("result_id", &"")
    var result_name := _display_gem_name(result_id)
    var maximum := int(option.get("max_required_level", 0))
    if option.get("kind") == &"basic":
        var upgrade := 1 if int(option.get("count", 0)) == 2 else 2
        return LocalizationService.tr_key("game.combinations.basic", {"result": result_name, "count": option.get("count", 0), "upgrade": upgrade, "level": maximum})
    var recipe := option.get("recipe") as RecipeDefinition
    var secret_suffix: String = "" if recipe == null or not recipe.secret else " " + LocalizationService.tr_key("game.combinations.secret")
    var type_key: String = "game.combinations.one_shot" if option.get("one_shot", false) else "game.combinations.advanced"
    return "%s%s · %s · %s" % [result_name, secret_suffix, LocalizationService.tr_key(type_key), LocalizationService.tr_key("game.combinations.max_level", {"level": maximum})]

func _combination_option_identity(option: Dictionary) -> String:
    if option.get("kind") == &"basic":
        return "basic:%d" % int(option.get("count", 0))
    var recipe := option.get("recipe") as RecipeDefinition
    return "recipe:%s" % (String(recipe.id) if recipe != null else "")

func _execute_combination_option(option_index: int) -> void:
    if option_index < 0 or option_index >= combination_options.size(): return
    var selected := _selected_combination_gem()
    if selected == null: return
    var requested: Dictionary = combination_options[option_index]
    var identity := _combination_option_identity(requested)
    var fresh_options := runtime.construction.contextual_combinations(selected)
    var exact_option: Dictionary = {}
    for candidate: Dictionary in fresh_options:
        if _combination_option_identity(candidate) == identity:
            exact_option = candidate
            break
    if exact_option.is_empty():
        _set_feedback("game.feedback.invalid_action")
        _open_combination_popup_for(selected)
        return
    var result := runtime.construction.execute_contextual_combination(selected, exact_option)
    if result == null:
        _set_feedback("game.feedback.invalid_action")
        _open_combination_popup_for(selected)
        return
    _close_combination_popup()
    selection.clear()
    _refresh_ui()

func _close_combination_popup() -> void:
    if is_instance_valid(combination_popup): combination_popup.queue_free()
    if is_instance_valid(combination_popup_arrow): combination_popup_arrow.queue_free()
    combination_popup = null
    combination_popup_arrow = null
    combination_options.clear()

func _close_context_popup_for_camera_change() -> void:
    # Camera movement invalidates the popup anchor. Clear only presentation
    # state; gameplay entities, ingredients and grid occupancy are untouched.
    _close_combination_popup()
    if selection != null and not selection.is_empty(): selection.clear()

func _position_context_popup(cell: Vector2i) -> void:
    if not is_instance_valid(combination_popup) or map_view == null: return
    var anchor: Vector2 = map_view.global_position_for_cell(cell) - global_position
    combination_popup.position = anchor + Vector2(32.0, -combination_popup.size.y * 0.5)
    call_deferred("_clamp_combination_popup", anchor)

func _clamp_combination_popup(anchor: Vector2 = Vector2.ZERO) -> void:
    if not is_instance_valid(combination_popup): return
    var popup_minimum := combination_popup.get_combined_minimum_size()
    combination_popup.size = Vector2(maxf(390.0, popup_minimum.x), popup_minimum.y)
    var viewport_size := size
    combination_popup.position.y = anchor.y - combination_popup.size.y * 0.5
    combination_popup.position.x = clampf(combination_popup.position.x, 4.0, maxf(4.0, viewport_size.x - combination_popup.size.x - 4.0))
    combination_popup.position.y = clampf(combination_popup.position.y, 4.0, maxf(4.0, viewport_size.y - combination_popup.size.y - 4.0))
    if is_instance_valid(combination_popup_arrow):
        combination_popup_arrow.position = Vector2(combination_popup.position.x - 18.0, clampf(anchor.y - 12.0, combination_popup.position.y + 12.0, combination_popup.position.y + combination_popup.size.y - 30.0))

func _attack_selected() -> void:
    if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.COMBAT or selection.kind != SelectionState.Kind.TOWER: return
    var tower := selection.value as TowerRuntime
    if tower == null: return
    # "Attack" is also the combat-phase activation action for towers that
    # were disabled during the preceding construction phase.
    if not tower.attack_enabled:
        tower.set_attack_enabled(true)
        _rebuild_command_card()
    for enemy: EnemyRuntime in runtime.combat.enemies:
        if enemy.is_alive() and tower.attack(enemy): return
    _set_feedback("game.feedback.invalid_action")

func _toggle_attack_selected() -> void:
    if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or selection.kind != SelectionState.Kind.TOWER: return
    var tower := selection.value as TowerRuntime
    if tower == null: return
    var popup_was_open := is_instance_valid(combination_popup)
    var gem := tower.gem
    tower.toggle_attack_enabled()
    _rebuild_command_card()
    if popup_was_open: _open_combination_popup_for(gem)

func _stop_selected() -> void:
    if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.COMBAT or selection.kind != SelectionState.Kind.TOWER: return
    var tower := selection.value as TowerRuntime
    if tower != null:
        tower.toggle_stop()
        _rebuild_command_card()

func _keep_selected() -> void:
    if selection.kind == SelectionState.Kind.GEM: runtime.construction.keep(selection.value)

func _remove_selected_stone() -> void:
    if runtime != null and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION and selection.kind == SelectionState.Kind.STONE:
        runtime.construction.remove_stone(selection.value); selection.clear()

func _toggle_recipes() -> void:
    if recipes_overlay != null: _close_overlay(recipes_overlay); recipes_overlay = null; return
    recipes_overlay = _make_parchment_overlay(LocalizationService.tr_key("game.recipes.title"), Vector2(1280, 0), func(): _close_overlay(recipes_overlay); recipes_overlay = null)
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
    scroll.custom_minimum_size = Vector2(1160, 560)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    list_margin.add_child(scroll)
    _style_modal_scrollbar(scroll.get_v_scroll_bar())
    recipe_rows = GridContainer.new(); recipe_rows.columns = 4; recipe_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL; recipe_rows.add_theme_constant_override("h_separation", 8); recipe_rows.add_theme_constant_override("v_separation", 8); scroll.add_child(recipe_rows)
    _populate_recipes()
    add_child(recipes_overlay)

func _show_reward(wave_number: int, candidates: Array) -> void:
    reward_overlay = _make_overlay(LocalizationService.tr_key("game.reward.title", {"wave": wave_number}))
    var column := _overlay_column(reward_overlay)
    for i in candidates.size():
        var id: StringName = candidates[i]
        var picked_id := id
        var reward_name: String = LocalizationService.tr_key("game.reward.skill.%s" % str(picked_id))
        var button := Button.new(); button.text = "%d. %s" % [i + 1, reward_name]; button.custom_minimum_size = Vector2(320, 42); _style_modal_action_button(button); button.process_mode = Node.PROCESS_MODE_ALWAYS; button.pressed.connect(func(): runtime.support_rewards.choose(picked_id); _close_overlay(reward_overlay); reward_overlay = null; get_tree().paused = false); column.add_child(button)
    var close := _close_icon_button(func(): _close_overlay(reward_overlay); reward_overlay = null; get_tree().paused = false); column.add_child(close); column.move_child(close, 0)
    add_child(reward_overlay)
    get_tree().paused = true

func _show_end(victory: bool) -> void:
    end_overlay = _make_overlay(LocalizationService.tr_key("game.end.victory" if victory else "game.end.defeat"))
    var column := _overlay_column(end_overlay)
    var score := Label.new(); score.text = LocalizationService.tr_key("game.end.score", {"score": runtime.player_state.score}); column.add_child(score)
    var restart := Button.new(); restart.text = LocalizationService.tr_key("game.restart"); _style_modal_action_button(restart, true); restart.process_mode = Node.PROCESS_MODE_ALWAYS; restart.pressed.connect(_restart); column.add_child(restart)
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
    CursorManager.set_clickable(toggle)
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
    if gem_gallery != null:
        gem_gallery.queue_free(); gem_gallery = null; return
    if debug_overlay != null: _close_overlay(debug_overlay); debug_overlay = null; return
    debug_overlay = _make_overlay(LocalizationService.tr_key("game.debug.title"))
    var column := _overlay_column(debug_overlay)
    var info := Label.new(); info.text = LocalizationService.tr_key("game.debug.info", {"seed": runtime.foundation.random.effective_seed, "gems": runtime.foundation.catalog.gems.size(), "recipes": runtime.foundation.catalog.recipes.size(), "waves": runtime.foundation.catalog.waves.size()}); column.add_child(info)
    var gallery_button := Button.new()
    gallery_button.text = "Base gem/tower gallery"
    gallery_button.custom_minimum_size = Vector2(0, 40)
    _style_game_button(gallery_button)
    gallery_button.pressed.connect(_open_gem_gallery)
    column.add_child(gallery_button)
    var close := _close_icon_button(func(): _close_overlay(debug_overlay); debug_overlay = null); column.add_child(close); column.move_child(close, 0); add_child(debug_overlay)

func _open_gem_gallery() -> void:
    if gem_gallery != null: return
    if debug_overlay != null: _close_overlay(debug_overlay); debug_overlay = null
    gem_gallery = GemAssetGalleryScript.new()
    gem_gallery.setup(gem_assets, func():
        if is_instance_valid(gem_gallery): gem_gallery.queue_free()
        gem_gallery = null
    )
    add_child(gem_gallery)

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
        row_panel.custom_minimum_size = Vector2(280, 148)
        row_panel.add_theme_stylebox_override("panel", _recipe_row_style(shown % 2 == 1))
        recipe_rows.add_child(row_panel)
        var row_margin := MarginContainer.new()
        row_margin.add_theme_constant_override("margin_left", 10)
        row_margin.add_theme_constant_override("margin_right", 10)
        row_panel.add_child(row_margin)
        var recipe_column := VBoxContainer.new(); recipe_column.add_theme_constant_override("separation", 4); row_margin.add_child(recipe_column)
        var result_row := HBoxContainer.new(); result_row.add_theme_constant_override("separation", 6); recipe_column.add_child(result_row)
        _add_gem_icon(result_row, recipe.result_id, 1, 30)
        var result_label := Label.new(); result_label.text = _display_gem_name(recipe.result_id); result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; result_label.add_theme_color_override("font_color", Color("3b2418")); result_row.add_child(result_label)
        var formula := HFlowContainer.new(); formula.add_theme_constant_override("h_separation", 3); formula.add_theme_constant_override("v_separation", 3); formula.size_flags_horizontal = Control.SIZE_EXPAND_FILL; recipe_column.add_child(formula)
        for index in recipe.ingredients.size():
            if index > 0:
                var plus := Label.new(); plus.text = "+"; plus.add_theme_color_override("font_color", Color("6d4a32")); formula.add_child(plus)
            var ingredient: Dictionary = recipe.ingredients[index]
            var ingredient_id: StringName = StringName(ingredient["id"])
            var ingredient_level := int(ingredient.get("level", 1))
            var chip := PanelContainer.new()
            chip.custom_minimum_size = Vector2(92, 34)
            chip.add_theme_stylebox_override("panel", _recipe_reference_style(_recipe_reference_state(ingredient_id, ingredient_level)))
            var chip_row := HBoxContainer.new(); chip_row.add_theme_constant_override("separation", 3); chip.add_child(chip_row)
            _add_gem_icon(chip_row, ingredient_id, ingredient_level, 27)
            var chip_label := Label.new(); chip_label.text = "%s L%s" % [_display_gem_name(ingredient_id), ingredient_level]; chip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; chip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; chip_label.add_theme_color_override("font_color", Color("3b2418")); chip_row.add_child(chip_label)
        shown += 1
    if shown == 0:
        var empty := Label.new(); empty.text = LocalizationService.tr_key("game.help.empty"); empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty.add_theme_color_override("font_color", Color("6d4a32")); empty.custom_minimum_size = Vector2(0, 72); empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; recipe_rows.add_child(empty)

func _recipe_reference_state(gem_id: StringName, level: int) -> int:
    var in_field := false
    for gem: GemInstance in runtime.construction.board_gems:
        if gem not in runtime.construction.current_gems and gem.id == gem_id and gem.level == level: in_field = true; break
    var in_construction := false
    for gem: GemInstance in runtime.construction.available_gems:
        if gem.id == gem_id and gem.level == level: in_construction = true; break
    return (2 if in_field else 0) + (1 if in_construction else 0)

func _recipe_reference_style(state: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new(); style.bg_color = Color("dedede") if state in [2, 3] else Color(0.0, 0.0, 0.0, 0.08); style.border_color = Color.WHITE; style.set_border_width_all(2 if state in [1, 3] else 0); style.set_corner_radius_all(3); style.content_margin_left = 3; style.content_margin_right = 3; style.content_margin_top = 2; style.content_margin_bottom = 2; return style

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
    var main_menu := Button.new(); main_menu.text = LocalizationService.tr_key("game.pause.main_menu"); main_menu.icon = visual_assets.main_menu; main_menu.expand_icon = true; main_menu.custom_minimum_size = Vector2(360, 46); main_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; main_menu.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(main_menu); main_menu.pressed.connect(func(): _show_exit_confirmation(false)); column.add_child(main_menu)
    var logout := Button.new(); logout.text = LocalizationService.tr_key("game.pause.logout"); logout.icon = visual_assets.logout; logout.expand_icon = true; logout.custom_minimum_size = Vector2(360, 46); logout.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; logout.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(logout, false, true); logout.pressed.connect(func(): _show_exit_confirmation(true)); column.add_child(logout)
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
    var confirm := Button.new(); confirm.text = LocalizationService.tr_key("game.pause.confirm"); confirm.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(confirm, true); confirm.pressed.connect(func(): _confirm_exit(logout)); column.add_child(confirm)
    var cancel := Button.new(); cancel.text = LocalizationService.tr_key("game.pause.cancel"); cancel.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(cancel); cancel.pressed.connect(_close_exit_confirmation); column.add_child(cancel)
    add_child(exit_confirm_overlay)

func _show_quit_confirmation() -> void:
    if exit_confirm_overlay != null: return
    exit_confirm_overlay = _make_overlay(LocalizationService.tr_key("game.pause.confirm_exit"))
    var column := _overlay_column(exit_confirm_overlay)
    column.add_child(_close_icon_button(func(): _close_exit_confirmation()))
    var message := Label.new(); message.text = LocalizationService.tr_key("game.pause.confirm_message"); message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(message)
    var confirm := Button.new(); confirm.text = LocalizationService.tr_key("game.pause.confirm"); confirm.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(confirm, true); confirm.pressed.connect(_confirm_quit); column.add_child(confirm)
    var cancel := Button.new(); cancel.text = LocalizationService.tr_key("game.pause.cancel"); cancel.process_mode = Node.PROCESS_MODE_ALWAYS; _style_modal_action_button(cancel); cancel.pressed.connect(_close_exit_confirmation); column.add_child(cancel)
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

func _legacy_gem_texture(gem_id: StringName, level: int) -> Texture2D:
    var color := _gem_color_key(gem_id)
    var family := clampi(level, 1, 10)
    var path := "res://assets/art/gameplay/gems/%s/gem_%d_%s.png" % [color, family, color]
    var texture := load(path) as Texture2D
    if texture == null and not _missing_gem_texture_diagnostics.has(path):
        _missing_gem_texture_diagnostics[path] = true
        push_warning("Missing gem texture: %s" % path)
    return texture

func _gem_texture(gem_id: StringName, level: int) -> Texture2D:
    var base_texture := gem_assets.get_gem_texture(gem_id, level) if gem_assets != null else null
    return base_texture if base_texture != null else _legacy_gem_texture(gem_id, level)

func _tower_texture(gem_id: StringName, level: int) -> Texture2D:
    var base_texture := gem_assets.get_tower_texture(gem_id, level) if gem_assets != null else null
    return base_texture if base_texture != null else _legacy_gem_texture(gem_id, level)

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
    close.icon = visual_assets.close
    close.expand_icon = true
    close.custom_minimum_size = Vector2(42, 42)
    close.size_flags_horizontal = Control.SIZE_SHRINK_END
    close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    close.add_theme_constant_override("icon_max_width", 32)
    close.mouse_filter = Control.MOUSE_FILTER_STOP
    close.process_mode = Node.PROCESS_MODE_ALWAYS
    close.tooltip_text = LocalizationService.tr_key("game.close")
    _style_modal_close_button(close)
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
    for tower in runtime.combat.towers:
        if tower.position.distance_to(Vector2(cell) * 100.0 + Vector2.ONE * 50.0) < 80.0:
            var state_key := "game.state.attack_enabled" if tower.attack_enabled else "game.state.attack_disabled"
            map_view.tooltip_text = LocalizationService.tr_key("game.tooltip.tower", {"id": _display_gem_name(tower.id), "damage": snapped(tower.stats.damage, 0.1), "range": snapped(tower.stats.range_units, 0.1), "stopped": LocalizationService.tr_key(state_key)})
            return
    var gem := runtime.construction.gem_at_cell(cell)
    if gem != null:
        map_view.tooltip_text = LocalizationService.tr_key("game.tooltip.gem", {"id": _display_gem_name(gem.id), "level": gem.level, "quality": _quality_label(gem.quality), "cell": gem.cell})
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

func _player_quality_probability_tooltip() -> String:
    if runtime == null or runtime.progression == null:
        return ""
    var level := clampi(runtime.progression.quality_level, 1, 5)
    var probabilities := GemGenerator.quality_probabilities(level)
    var lines: Array[String] = [LocalizationService.tr_key("game.player.quality_probabilities", {"level": level})]
    for index in probabilities.size():
        lines.append("%s %d%%" % [_quality_label(index + 1), roundi(probabilities[index])])
    return "\n".join(lines)

func _make_parchment_overlay(title_text: String, minimum_size: Vector2, close_callback: Callable) -> PanelContainer:
    var overlay := PanelContainer.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_theme_stylebox_override("panel", _modal_backdrop())
    overlay.z_index = 300
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
    title.add_theme_font_override("font", MODAL_TITLE_FONT)
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
    overlay.z_index = 300
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
    title.add_theme_font_override("font", MODAL_TITLE_FONT)
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
    if is_instance_valid(player_level_label) and runtime.progression != null:
        player_level_label.text = LocalizationService.tr_key("game.player.level", {"level": runtime.progression.quality_level})
    if is_instance_valid(xp_bar) and runtime.progression != null:
        xp_bar.value = runtime.progression.progress_ratio() * 100.0
        var quality_tooltip := _player_quality_probability_tooltip()
        xp_bar.tooltip_text = quality_tooltip
        if is_instance_valid(player_level_label): player_level_label.tooltip_text = quality_tooltip
        if is_instance_valid(xp_value_label): xp_value_label.tooltip_text = quality_tooltip
    if is_instance_valid(xp_value_label) and runtime.progression != null:
        xp_value_label.text = LocalizationService.tr_key("game.player.xp_percent", {"percent": roundi(runtime.progression.progress_ratio() * 100.0)})
    if is_instance_valid(progress_bar): progress_bar.value = clampf(float(runtime.player_state.progress), 0.0, 100.0)
    if is_instance_valid(progress_value_label): progress_value_label.text = "%.2f%%" % float(runtime.player_state.progress)
    _refresh_inspector_content()
    if is_instance_valid(inspector_panel): inspector_panel.visible = false
    if is_instance_valid(inspector_icon):
        inspector_icon.texture = null
        if selection.kind == SelectionState.Kind.GEM:
            var selected_gem: GemInstance = selection.value
            inspector_icon.texture = _gem_texture(selected_gem.id, selected_gem.level)
        elif selection.kind == SelectionState.Kind.TOWER:
            var selected_tower: TowerRuntime = selection.value
            inspector_icon.texture = _tower_texture(selected_tower.id, selected_tower.gem.level if selected_tower.gem != null else 1)
        elif selection.kind == SelectionState.Kind.ENEMY:
            var selected_enemy: EnemyRuntime = selection.value
            inspector_icon.texture = _enemy_icon_texture(selected_enemy.profile_id, runtime.current_wave_is_boss)
        elif selection.kind == SelectionState.Kind.STONE:
            inspector_icon.texture = _stone_icon_texture()

func _enemy_sheet_path(profile_id: StringName, boss: bool = false) -> String:
    var preferred := ENEMY_NORMAL_SHEET_PATH
    if boss or profile_id == &"invincible_dog_w10": preferred = ENEMY_BOSS_SHEET_PATH
    elif profile_id == &"invisible_spider_w8": preferred = ENEMY_INVISIBLE_SHEET_PATH
    elif profile_id == &"frenzied_pig": preferred = ENEMY_NECROMANCER_SHEET_PATH
    return preferred if ResourceLoader.exists(preferred) else ENEMY_FALLBACK_SHEET_PATH

func _enemy_direction_row(direction: Vector2, boss: bool) -> int:
    if absf(direction.x) > absf(direction.y):
        # The normal/necromancer sheets place left-facing frames on row 1
        # and right-facing frames on row 2. The boss sheet uses the reverse
        # order, so keep its existing mapping explicit.
        if boss: return 2 if direction.x < 0.0 else 1
        return 1 if direction.x < 0.0 else 2
    return 3 if direction.y < 0.0 else 0

func _enemy_icon_path(profile_id: StringName, boss: bool = false) -> String:
    var preferred := ENEMY_NORMAL_ICON_PATH
    if boss or profile_id == &"invincible_dog_w10": preferred = ENEMY_BOSS_ICON_PATH
    elif profile_id == &"invisible_spider_w8": preferred = ENEMY_INVISIBLE_ICON_PATH
    elif profile_id == &"frenzied_pig": preferred = ENEMY_NECROMANCER_ICON_PATH
    return preferred if ResourceLoader.exists(preferred) else ENEMY_FALLBACK_ICON_PATH

func _enemy_sheet(profile_id: StringName, boss: bool = false) -> Texture2D:
    var path := _enemy_sheet_path(profile_id, boss)
    if _enemy_sheet_cache.has(path): return _enemy_sheet_cache[path] as Texture2D
    var requested_path := path
    var texture := load(path) as Texture2D
    if texture == null and path != ENEMY_FALLBACK_SHEET_PATH:
        path = ENEMY_FALLBACK_SHEET_PATH
        texture = load(path) as Texture2D
    if texture != null:
        _enemy_sheet_cache[requested_path] = texture
        _enemy_sheet_cache[path] = texture
    return texture

func _enemy_icon_texture(profile_id: StringName, boss: bool = false) -> Texture2D:
    var path := _enemy_icon_path(profile_id, boss)
    if _enemy_icon_cache.has(path): return _enemy_icon_cache[path] as Texture2D
    var requested_path := path
    var texture := load(path) as Texture2D
    if texture == null and path != ENEMY_FALLBACK_ICON_PATH:
        path = ENEMY_FALLBACK_ICON_PATH
        texture = load(path) as Texture2D
    if texture == null: return null
    if path == ENEMY_FALLBACK_ICON_PATH:
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(0, 0, 32, 32)
        texture = atlas
    _enemy_icon_cache[requested_path] = texture
    _enemy_icon_cache[path] = texture
    return texture

func _stone_icon_texture() -> Texture2D:
    var texture := load("res://assets/art/gameplay/environment/stones/petrified_gem_rocks.png") as Texture2D
    return texture if texture != null else load("res://assets/art/gameplay/environment/stones/stone_01.png") as Texture2D

func _refresh_inspector_content() -> void:
    if not is_instance_valid(inspector_name_label) or not is_instance_valid(inspector_stats_label): return
    inspector_name_label.text = ""
    inspector_stats_label.text = ""
    if selection.is_empty(): return
    if selection.kind == SelectionState.Kind.GEM:
        inspector_title_label.text = LocalizationService.tr_key("game.inspector.tower.title")
        var gem: GemInstance = selection.value
        var definition := runtime.foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
        var stats := TowerCombatStats.from_gem(gem, definition)
        inspector_name_label.text = "[b]%s[/b]" % (_quality_label(gem.quality) + " " + _display_gem_name(gem.id))
        var abilities := _gem_abilities(gem)
        inspector_stats_label.text = LocalizationService.tr_key("game.inspector.tower.stats", {"level": gem.level, "damage": "%.1f" % stats.damage, "range": "%.1f" % stats.range_units, "speed": "%.1f" % stats.total_attack_speed(), "abilities": abilities})
    elif selection.kind == SelectionState.Kind.TOWER:
        inspector_title_label.text = LocalizationService.tr_key("game.inspector.tower.title")
        var tower: TowerRuntime = selection.value
        inspector_name_label.text = "[b]%s[/b]" % _display_gem_name(tower.id)
        inspector_stats_label.text = LocalizationService.tr_key("game.inspector.tower.stats", {"level": tower.gem.level if tower.gem != null else 1, "damage": "%.1f" % tower.stats.damage, "range": "%.1f" % tower.stats.range_units, "speed": "%.1f" % tower.stats.total_attack_speed(), "abilities": ", ".join(tower.abilities) if not tower.abilities.is_empty() else "—"})
    elif selection.kind == SelectionState.Kind.ENEMY:
        inspector_title_label.text = LocalizationService.tr_key("game.inspector.enemy.title")
        var enemy: EnemyRuntime = selection.value
        var enemy_profile := runtime.foundation.catalog.enemy_profile_by_id(enemy.profile_id) as EnemyProfileDefinition
        var catalog_name := enemy_profile.display_name if enemy_profile != null else ""
        inspector_name_label.text = "[b]%s[/b]" % LocalizationService.enemy_display_name(enemy.profile_id, catalog_name)
        inspector_stats_label.text = LocalizationService.tr_key("game.inspector.enemy.stats", {"hp": "%.1f" % enemy.hp, "max_hp": "%.1f" % enemy.max_hp, "armor": "%.1f" % enemy.armor, "magic": "%.1f" % enemy.magic_resistance})
    else:
        inspector_title_label.text = LocalizationService.tr_key("game.inspector.stone.title")
        inspector_name_label.text = "[b]%s[/b]" % LocalizationService.tr_key("game.selection.stone")

func _gem_abilities(gem: GemInstance) -> String:
    if gem == null or runtime == null: return "—"
    var definition := runtime.foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
    var level_data := TowerCombatStats.level_data_for(gem, definition)
    var values := PackedStringArray()
    for value in level_data.get("ability_ids", PackedStringArray()):
        var key := str(value)
        if key not in ["sin_efecto", "spell_steal_placeholder_v1"] and key not in values: values.append(key)
    var display_ability := str(level_data.get("ability", "")).strip_edges()
    if not display_ability.is_empty() and display_ability not in values: values.append(display_ability)
    if values.is_empty(): return "—"
    var described := PackedStringArray()
    for value in values:
        var parts := value.split(" ", false)
        var key := parts[0].to_lower()
        var level := int(parts[1]) if parts.size() > 1 and parts[1].is_valid_int() else gem.level
        var description: String = LocalizationService.tr_key("game.ability.%s" % key, {"level": level})
        described.append("%s — %s" % [value, description] if description != "game.ability.%s" % key else value)
    return ", ".join(described)

    if is_instance_valid(feedback_label): feedback_label.text = LocalizationService.tr_key(feedback_key)
    if is_instance_valid(help_button): help_button.text = LocalizationService.tr_key("game.help.title")

func _selection_summary() -> String:
    if selection.is_empty(): return LocalizationService.tr_key("game.selection.none")
    if selection.kind == SelectionState.Kind.GEM:
        var gem: GemInstance = selection.value
        var definition := runtime.foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
        var stats := TowerCombatStats.from_gem(gem, definition)
        return "%s %s\n%s" % [_quality_label(gem.quality), _display_gem_name(gem.id), LocalizationService.tr_key("game.inspector.tower.stats", {"level": gem.level, "damage": "%.1f" % stats.damage, "range": "%.1f" % stats.range_units, "speed": "%.1f" % stats.total_attack_speed(), "abilities": _gem_abilities(gem)})]
    if selection.kind == SelectionState.Kind.ENEMY:
        var enemy: EnemyRuntime = selection.value
        var enemy_profile := runtime.foundation.catalog.enemy_profile_by_id(enemy.profile_id) as EnemyProfileDefinition
        var catalog_name := enemy_profile.display_name if enemy_profile != null else ""
        return LocalizationService.tr_key("game.selection.enemy", {"id": LocalizationService.enemy_display_name(enemy.profile_id, catalog_name), "hp": snapped(enemy.hp, 0.1), "max_hp": snapped(enemy.max_hp, 0.1), "armor": enemy.armor, "magic": enemy.magic_resistance})
    if selection.kind == SelectionState.Kind.TOWER:
        var tower: TowerRuntime = selection.value
        return LocalizationService.tr_key("game.selection.tower", {"id": _display_gem_name(tower.id), "damage": snapped(tower.stats.damage, 0.1), "range": snapped(tower.stats.range_units, 0.1), "stopped": LocalizationService.tr_key("game.state.stopped" if tower.stopped else "game.state.active")})
    return LocalizationService.tr_key("game.selection.stone")

func _hud_panel() -> StyleBoxTexture:
    var panel := StyleBoxTexture.new(); panel.texture = load("res://assets/ui/panels/rpg_panel_brown.png"); panel.texture_margin_left = 16; panel.texture_margin_top = 16; panel.texture_margin_right = 16; panel.texture_margin_bottom = 16; panel.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT; panel.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT; return panel

func _style_game_button(button: Button) -> void:
    CursorManager.set_clickable(button)
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
    # Keep the same green as Grass_Middle behind the authored map. This
    # makes the non-buildable exterior readable when the player zooms out.
    panel.bg_color = Color("3e8948")
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
    var authored_map: Node2D
    var world_group: CanvasGroup
    var decoration_index: DecorationFootprintIndex
    var world_y_sort: Node2D
    var gem_layer: Node2D
    var terrain_layer: MapTerrainLayer
    var decoration_layer: MapDecorationLayer
    var grid_layer: MapGridLayer
    var restricted_layer: RestrictedZoneLayer
    var runtime_overlay: RuntimeOverlay
    var stone_layer: Node2D
    var stone_nodes: Dictionary = {}
    var enemy_nodes: Dictionary = {}
    var hover_cell := Vector2i(-1, -1)
    var hover_can_place := false
    var map_zoom := 1.0
    var map_pan := Vector2.ZERO
    var board_origin := Vector2.ZERO
    var dragging := false
    var drag_start := Vector2.ZERO
    var pan_start := Vector2.ZERO
    var damage_feedbacks: Array[Dictionary] = []
    const AUTHORED_MAP_SCENE := preload("res://src/gameplay/map/map.tscn")
    const AUTHORED_MAP_SIZE := Vector2(1024.0, 640.0)
    const PROJECTILE_TEXTURE := preload("res://assets/art/gameplay/projectiles/fireball_5_colors.png")
    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP
        clip_contents = true
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # Keep the terrain/decor layers above the map frame's canvas while
        # preserving their negative order relative to this renderer.
        z_index = 3
        authored_map = AUTHORED_MAP_SCENE.instantiate() as Node2D
        if authored_map != null:
            # Keep the authored map in an isolated canvas group so its
            # negative-Z ground/path layers render above the map panel's
            # background without changing their authored ordering. This group
            # is only a render container; no lighting or shader is applied.
            world_group = CanvasGroup.new()
            world_group.name = "WorldRenderGroup"
            world_group.z_index = 100
            add_child(world_group)
            world_group.add_child(authored_map)
            authored_map.z_index = 0
            decoration_index = DecorationFootprintIndex.new()
            var authored_root := authored_map as MapEditorRoot
            if authored_root != null:
                authored_root.prepare_for_runtime()
            var authored_obstacles := authored_map.get_node_or_null("Obstacles") as Node2D
            if authored_obstacles != null:
                authored_obstacles.visible = false
            var authored_gems := authored_map.get_node_or_null("Gems") as Node2D
            if authored_gems != null:
                authored_gems.visible = false
            world_y_sort = authored_map.get_node_or_null("WorldYSort") as Node2D
            if world_y_sort != null:
                world_y_sort.y_sort_enabled = true
                world_y_sort.z_index = 0
            else:
                world_y_sort = Node2D.new()
                world_y_sort.name = "WorldYSort"
                world_y_sort.y_sort_enabled = true
                authored_map.add_child(world_y_sort)
        terrain_layer = MapTerrainLayer.new()
        terrain_layer.runtime = runtime
        terrain_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        terrain_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        terrain_layer.z_index = -2
        terrain_layer.show_behind_parent = true
        terrain_layer.visible = false
        add_child(terrain_layer)
        decoration_layer = MapDecorationLayer.new()
        decoration_layer.runtime = runtime
        decoration_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        decoration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        decoration_layer.z_index = -1
        decoration_layer.show_behind_parent = true
        # The authored map scene owns checkpoint visuals too; the procedural
        # layer stays hidden so it cannot add a second set of flags.
        decoration_layer.visible = false
        add_child(decoration_layer)
        grid_layer = MapGridLayer.new()
        grid_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        grid_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        grid_layer.z_index = 0
        grid_layer.visible = false
        add_child(grid_layer)
        restricted_layer = RestrictedZoneLayer.new()
        restricted_layer.runtime = runtime
        restricted_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        restricted_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # Sit above flat authored layers but below every y-sorted world object.
        restricted_layer.z_index = 90
        add_child(restricted_layer)
        # Runtime actors are direct children of the same y-sorted canvas as
        # authored trees, props and landmarks. Their roots represent the
        # ground contact point; their visuals extend upward from that origin.
        gem_layer = world_y_sort
        stone_layer = world_y_sort
        runtime_overlay = RuntimeOverlay.new()
        runtime_overlay.map_view = self
        runtime_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        runtime_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        runtime_overlay.z_index = 190
        add_child(runtime_overlay)
        var zoom_bar := HBoxContainer.new()
        zoom_bar.position = Vector2(2, 2)
        zoom_bar.z_index = 250
        zoom_bar.add_theme_constant_override("separation", 4)
        for item in [["−", -0.1], ["＋", 0.1], ["⌂", 0.0]]:
            var button := Button.new(); button.text = item[0]; button.custom_minimum_size = Vector2(30, 30); button.tooltip_text = LocalizationService.tr_key("game.zoom"); view._style_game_button(button)
            button.pressed.connect(func():
                view._close_context_popup_for_camera_change()
                if item[1] == 0.0: map_zoom = 1.0; map_pan = Vector2.ZERO
                else: map_zoom = clampf(map_zoom + float(item[1]), 0.65, 2.5); _center_zoom()
                _clamp_pan(); queue_redraw(); sync_gem_sprites())
            zoom_bar.add_child(button)
        add_child(zoom_bar)
        mouse_entered.connect(func(): view._set_map_cursor(hover_can_place))
        mouse_exited.connect(func(): hover_cell = Vector2i(-1, -1); hover_can_place = false; view._leave_map_cursor(); tooltip_text = ""; sync_gem_sprites(); queue_redraw())
        resized.connect(func(): view._close_context_popup_for_camera_change(); sync_gem_sprites())
        call_deferred("sync_gem_sprites")

    func sync_gem_sprites() -> void:
        if runtime == null or view == null or gem_layer == null: return
        var live := {}
        var board_rect := _board_rect()
        var authored_visual_cell_size := AUTHORED_MAP_SIZE.y / 36.0
        if authored_visual_cell_size <= 0.0: return
        board_origin = board_rect.position
        if authored_map != null:
            _sync_authored_map_transform(board_rect)
        decoration_layer.sync(board_rect.size.x, map_zoom, map_pan, board_origin)
        restricted_layer.sync(board_rect.size.x, map_zoom, map_pan, board_origin)
        _sync_stone_sprites()
        for gem: GemInstance in runtime.construction.board_gems:
            var key := str(gem.get_instance_id())
            live[key] = true
            var is_tower_visual := runtime.phases.phase == GamePhaseMachine.Phase.COMBAT or gem.round_id < runtime.construction.round_id
            # Visual scale and anchoring never change the one-cell logical footprint.
            var sprite_size := authored_visual_cell_size * GemAssetLibrary.GEM_SPRITE_CELLS
            if is_tower_visual:
                sprite_size = authored_visual_cell_size * GemAssetLibrary.TOWER_VISIBLE_CELLS
                if view.gem_assets != null and view.gem_assets.has_base_asset(gem.id, gem.level):
                    var visible_fraction := view.gem_assets.get_tower_visible_fraction(gem.id, gem.level)
                    sprite_size /= maxf(0.01, maxf(visible_fraction.x, visible_fraction.y))
            var visual: WorldTextureVisual
            if _gem_nodes_has(key):
                visual = _gem_nodes_get(key)
            else:
                visual = WorldTextureVisual.new()
                visual.name = "Gem_%s" % key
                var sprite := view._make_gem_sprite(gem.id, gem.level, sprite_size)
                # Map entities must be free to shrink below their creation size.
                sprite.custom_minimum_size = Vector2.ZERO
                visual.attach_visual(sprite)
                gem_layer.add_child(visual)
                _gem_nodes_set(key, visual)
            var sprite := visual.visual
            if is_tower_visual:
                sprite.texture = view._tower_texture(gem.id, gem.level)
            elif gem == runtime.construction.selected_board_gem and view.gem_assets != null and not view.gem_assets.has_base_asset(gem.id, gem.level):
                sprite.texture = view._gem_animation_texture(gem.id, gem.level, int(Time.get_ticks_msec() / 140.0))
            else:
                sprite.texture = view._gem_texture(gem.id, gem.level)
            if sprite.texture == null: sprite.texture = view._fallback_gem_texture(gem.id)
            var display_size := Vector2.ONE * sprite_size
            var authored_root := authored_map as MapEditorRoot
            if is_tower_visual and view.gem_assets != null and view.gem_assets.has_base_asset(gem.id, gem.level):
                var visual_anchor := view.gem_assets.get_tower_visual_anchor(gem.id, gem.level)
                visual.position = authored_root.logical_cell_base_to_authored(gem.cell, GemAssetLibrary.TOWER_BASE_CELL_Y)
                visual.set_visual_rect(display_size, visual_anchor)
            else:
                # A construction gem is a marker for the cell itself.  Keep
                # its visual centered on the hovered/placed cell; using the
                # tower pedestal anchor here made the sprite look one row
                # above the highlighted cell even though the logic was right.
                visual.position = authored_root.logical_cell_base_to_authored(gem.cell, 0.5)
                var gem_anchor := view.gem_assets.get_gem_visual_anchor(gem.id, gem.level) if view.gem_assets != null else Vector2(0.5, 0.5)
                visual.set_visual_rect(display_size, gem_anchor)
            # Keep the logical anchor fixed for navigation/selection, while
            # nudging only the artwork down on horizontal road cells so it
            # sits naturally on the path surface.
            if _is_horizontal_route_cell(gem.cell):
                visual.visual.position.y += authored_visual_cell_size * 0.18
            if is_tower_visual:
                # Tower artwork was anchored a little high relative to the
                # one-cell props (stones).  Keep the logical tower cell and
                # hit area unchanged; lower only its rendered sprite.
                visual.visual.position.y += authored_visual_cell_size * 0.16
            visual.visible = true
        for key in _gem_nodes_keys():
            if not live.has(key):
                var stale := _gem_nodes_get(key)
                if is_instance_valid(stale): stale.queue_free()
                _gem_nodes_erase(key)
        _sync_enemy_nodes()

    func queue_enemy_redraw() -> void:
        _sync_enemy_nodes()

    func _gem_nodes_has(key: String) -> bool:
        return _gem_nodes().has(key)

    func _gem_nodes_get(key: String) -> WorldTextureVisual:
        return _gem_nodes()[key] as WorldTextureVisual

    func _gem_nodes_set(key: String, value: WorldTextureVisual) -> void:
        _gem_nodes()[key] = value

    func _gem_nodes_erase(key: String) -> void:
        _gem_nodes().erase(key)

    func _gem_nodes_keys() -> Array:
        return _gem_nodes().keys()

    func _gem_nodes() -> Dictionary:
        return view._gem_nodes

    func _sync_stone_sprites() -> void:
        if runtime == null or not is_instance_valid(stone_layer): return
        var live := {}
        var visual_cell_size := AUTHORED_MAP_SIZE.y / 36.0
        var target_visible_size := visual_cell_size * GemAssetLibrary.STONE_VISIBLE_CELLS
        var target_max_size := target_visible_size / StoneDecoration.VISIBLE_MAX_FRACTION
        var authored_root := authored_map as MapEditorRoot
        for cell: Vector2i in runtime.construction.stones:
            var key := str(cell)
            live[key] = true
            var visual := stone_nodes.get(key) as WorldTextureVisual
            if not is_instance_valid(visual):
                visual = WorldTextureVisual.new()
                visual.name = "Stone_%s_%s" % [cell.x, cell.y]
                var sprite := StoneDecoration.new()
                sprite.cell = cell
                sprite.stone_clicked.connect(_on_stone_sprite_clicked)
                visual.attach_visual(sprite)
                stone_layer.add_child(visual)
                stone_nodes[key] = visual
            else:
                (visual.visual as StoneDecoration).cell = cell
            var sprite := visual.visual as StoneDecoration
            if sprite.texture == null: continue
            var source_size := sprite.texture.get_size()
            var max_dimension := maxf(source_size.x, source_size.y)
            if max_dimension <= 0.0: continue
            var display_size := source_size * (target_max_size / max_dimension)
            visual.position = authored_root.logical_cell_base_to_authored(cell, 0.75)
            visual.set_visual_rect(display_size, Vector2(0.5, 0.78))
        for key in stone_nodes.keys():
            if not live.has(key):
                var stale := stone_nodes[key] as WorldTextureVisual
                if is_instance_valid(stale): stale.queue_free()
                stone_nodes.erase(key)

    func _sync_enemy_nodes() -> void:
        if runtime == null or view == null or world_y_sort == null or authored_map == null: return
        var live := {}
        var authored_root := authored_map as MapEditorRoot
        for enemy: EnemyRuntime in runtime.combat.enemies:
            if not enemy.is_alive(): continue
            var key := str(enemy.get_instance_id())
            live[key] = true
            var visual := enemy_nodes.get(key) as EnemyVisualNode
            if not is_instance_valid(visual):
                visual = EnemyVisualNode.new()
                visual.name = "Enemy_%s" % key
                visual.runtime = runtime
                visual.view = view
                visual.enemy = enemy
                world_y_sort.add_child(visual)
                enemy_nodes[key] = visual
            visual.position = authored_root.logical_world_to_authored(enemy.position)
            visual.queue_redraw()
        for key in enemy_nodes.keys():
            if not live.has(key):
                var stale := enemy_nodes[key] as EnemyVisualNode
                if is_instance_valid(stale): stale.queue_free()
                enemy_nodes.erase(key)

    func _on_stone_sprite_clicked(cell: Vector2i) -> void:
        if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or not runtime.construction.stones.has(cell): return
        view.place_gem_mode = false
        view.selection.select(SelectionState.Kind.STONE, cell)
        runtime.construction.select_stone(cell)
        view._open_stone_popup_for(cell)
        queue_redraw()

    func show_damage_feedback(world_position: Vector2) -> void:
        damage_feedbacks.append({"position": world_position, "created_ms": Time.get_ticks_msec()})
        queue_redraw()


    func place_gem_at_hover() -> void:
        place_gem_at_cell(hover_cell)

    func place_gem_at_cell(cell: Vector2i) -> void:
        if runtime == null or runtime.phases.phase != GamePhaseMachine.Phase.CONSTRUCTION:
            return
        if cell.x < 0 or not _can_preview_placement(cell):
            view._set_feedback("game.feedback.invalid_action")
            return
        var placed := runtime.construction.place_gem(cell, int(runtime.player_state.player_level))
        if placed == null:
            view._set_feedback("game.feedback.invalid_action")
            return
        _remove_decorations_at_cell(cell)
        view.selection.clear()
        view.place_gem_mode = false
        hover_can_place = false
        view._set_map_cursor(false)

    func _remove_decorations_at_cell(cell: Vector2i) -> void:
        # Environment art is a decorative tile layer, never a gameplay obstacle.
        if decoration_layer != null:
            decoration_layer.remove_at_cell(cell)
        if authored_map == null:
            return
        var authored_decorations := authored_map.get_node_or_null("Decorations")
        # Remove authored decoration tiles when a gem is built on their cell;
        # this does not touch the fence layer or any logical/path cell data.
        var authored_cell := cell
        var authored_root := authored_map as MapEditorRoot
        if authored_root != null and decoration_index != null:
            decoration_index.rebuild(authored_map)
            var authored_rect := authored_root.logical_cell_to_authored_rect(cell)
            for group: Dictionary in decoration_index.groups_for_placement(authored_rect):
                decoration_index.erase_group(group)
        else:
            # Keep the old single-cell fallback for malformed/legacy maps.
            if authored_root != null:
                authored_cell = authored_root._logical_to_authored_cell(cell)
            for layer_name in ["FlatDetails", "FlatDetailsForeground"]:
                var tile_layer := authored_decorations.get_node_or_null(layer_name) as TileMapLayer
                if tile_layer != null:
                    tile_layer.erase_cell(authored_cell)
        for child in authored_decorations.get_children().duplicate():
            if child is MapDecorationMarker and (child as MapDecorationMarker).cell == cell:
                child.queue_free()
    func _gui_input(event: InputEvent) -> void:
        # Container layout can settle after the first frame. Resolve pointer
        # cells from the current board rect so the first hover/click uses the
        # same origin as the rendered map (without requiring a preliminary
        # click to initialize it).
        if size.x > 0.0 and size.y > 0.0:
            var current_board_rect := _board_rect()
            board_origin = current_board_rect.position
            if authored_map != null and current_board_rect.size != Vector2.ZERO:
                _sync_authored_map_transform(current_board_rect)
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            view._close_context_popup_for_camera_change()
            map_zoom = clampf(map_zoom + 0.1, 0.65, 2.5); _center_zoom(); _clamp_pan(); queue_redraw(); sync_gem_sprites(); return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            view._close_context_popup_for_camera_change()
            map_zoom = clampf(map_zoom - 0.1, 0.65, 2.5); _center_zoom(); _clamp_pan(); queue_redraw(); sync_gem_sprites(); return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
            if event.pressed: view._close_context_popup_for_camera_change()
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
            var pointer_tower := _tower_at_pointer(event.position)
            if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
                var tower := pointer_tower if pointer_tower != null else _tower_at_cell(cell)
                var gem := runtime.construction.gem_at_cell(cell)
                if tower != null:
                    view.place_gem_mode = false
                    view.selection.select(SelectionState.Kind.TOWER, tower)
                    view._rebuild_command_card()
                    view._open_combination_popup_for(tower.gem)
                elif gem != null:
                    view.place_gem_mode = false
                    view.selection.select(SelectionState.Kind.GEM, gem); runtime.construction.select_board_gem(cell)
                    view._open_combination_popup_for(gem)
                elif runtime.construction.stones.has(cell):
                    view.place_gem_mode = false
                    view.selection.select(SelectionState.Kind.STONE, cell); runtime.construction.select_stone(cell)
                    view._open_stone_popup_for(cell)
                elif view.place_gem_mode:
                    place_gem_at_cell(cell)
                else: view.selection.clear()
                hover_can_place = _can_preview_placement(cell)
                view._set_map_cursor(hover_can_place)
            else:
                var clicked_entity := false
                if pointer_tower != null:
                    view.selection.select(SelectionState.Kind.TOWER, pointer_tower); clicked_entity = true; view._open_combination_popup_for(pointer_tower.gem); queue_redraw(); return
                var pointer_enemy := _enemy_at_pointer(event.position)
                if pointer_enemy != null:
                    view.selection.select(SelectionState.Kind.ENEMY, pointer_enemy); clicked_entity = true
                else:
                    for enemy in runtime.combat.enemies:
                        if enemy.is_alive() and enemy.position.distance_to(Vector2(cell) * 100.0 + Vector2.ONE * 50.0) < 80.0:
                            view.selection.select(SelectionState.Kind.ENEMY, enemy); clicked_entity = true; break
                if not clicked_entity: view.selection.clear()
            queue_redraw()

    func _tower_at_cell(cell: Vector2i) -> TowerRuntime:
        if runtime == null: return null
        var center := Vector2(cell) * 100.0 + Vector2.ONE * 50.0
        for tower: TowerRuntime in runtime.combat.towers:
            if tower != null and tower.position.distance_to(center) < 80.0:
                return tower
        return null

    func _tower_at_pointer(pointer_position: Vector2) -> TowerRuntime:
        if runtime == null or authored_map == null:
            return null
        var authored_root := authored_map as MapEditorRoot
        if authored_root == null:
            return null
        var pointer_global: Vector2 = get_global_transform_with_canvas() * pointer_position
        var nearest: TowerRuntime = null
        var nearest_distance := INF
        for tower: TowerRuntime in runtime.combat.towers:
            if tower == null:
                continue
            var authored_position := authored_root.logical_world_to_authored(tower.position)
            var tower_global := authored_map.to_global(authored_position)
            var distance: float = pointer_global.distance_to(tower_global)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = tower
        var hit_radius := maxf(18.0, _cell_view_size().y * map_zoom * 1.25)
        return nearest if nearest != null and nearest_distance <= hit_radius else null

    func _enemy_at_pointer(pointer_position: Vector2) -> EnemyRuntime:
        if runtime == null or authored_map == null:
            return null
        var authored_root := authored_map as MapEditorRoot
        if authored_root == null:
            return null
        var pointer_global: Vector2 = get_global_transform_with_canvas() * pointer_position
        var nearest: EnemyRuntime = null
        var nearest_distance := INF
        for enemy: EnemyRuntime in runtime.combat.enemies:
            if enemy == null or not enemy.is_alive():
                continue
            var authored_position := authored_root.logical_world_to_authored(enemy.position)
            var enemy_global := authored_map.to_global(authored_position)
            var distance: float = pointer_global.distance_to(enemy_global)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = enemy
        var hit_radius := maxf(18.0, _cell_view_size().y * map_zoom * 1.25)
        return nearest if nearest != null and nearest_distance <= hit_radius else null

    func _board_rect() -> Rect2:
        if size.x <= 0.0 or size.y <= 0.0:
            return Rect2(Vector2.ZERO, Vector2.ZERO)
        var fit_scale := minf(size.x / AUTHORED_MAP_SIZE.x, size.y / AUTHORED_MAP_SIZE.y)
        var display_size := AUTHORED_MAP_SIZE * fit_scale
        return Rect2((size - display_size) * 0.5, display_size)

    func _sync_authored_map_transform(board_rect: Rect2) -> void:
        # Keep the scene's authored transform intact. The saved root offset is
        # part of the map's editor framing; the runtime board is positioned
        # from the same top-left used by the logical 36x36 coordinates.
        var fit_scale := minf(board_rect.size.x / AUTHORED_MAP_SIZE.x, board_rect.size.y / AUTHORED_MAP_SIZE.y)
        authored_map.position = board_rect.position + map_pan
        authored_map.scale = Vector2.ONE * fit_scale * map_zoom

    func _cell_view_size() -> Vector2:
        return _board_rect().size / 36.0

    func _cell_view_position(cell: Vector2i, anchor: Vector2, cell_size: Vector2 = Vector2.ZERO) -> Vector2:
        var authored_root := authored_map as MapEditorRoot
        if authored_root != null:
            var authored_point := authored_root.logical_world_to_authored((Vector2(cell) + anchor) * 100.0)
            var fit_scale := _board_rect().size.x / AUTHORED_MAP_SIZE.x
            return board_origin + map_pan + authored_point * fit_scale * map_zoom
        var resolved_cell_size := cell_size if cell_size != Vector2.ZERO else _cell_view_size()
        return board_origin + map_pan + (Vector2(cell) + anchor) * resolved_cell_size * map_zoom

    func _world_view_position(world_position: Vector2, cell_size: Vector2) -> Vector2:
        return Vector2(world_position.x / 100.0 * cell_size.x, world_position.y / 100.0 * cell_size.y)

    func global_position_for_cell(cell: Vector2i) -> Vector2:
        return global_position + _cell_view_position(cell, Vector2.ONE * 0.5)
    func _cell_at(position: Vector2) -> Vector2i:
        var cell_size := _cell_view_size()
        if cell_size.x <= 0.0 or cell_size.y <= 0.0 or map_zoom <= 0.0:
            return Vector2i(-1, -1)
        var fit_scale := _board_rect().size.x / AUTHORED_MAP_SIZE.x
        if fit_scale <= 0.0:
            return Vector2i(-1, -1)
        var authored := (position - _board_rect().position - map_pan) / (map_zoom * fit_scale)
        var authored_cell := authored / MapEditorRoot.CELL_SIZE
        var logical_x := authored_cell.x * 36.0 / float(MapEditorRoot.GRID_WIDTH)
        var logical_y := (authored_cell.y - 3.5) * 29.0 / 32.0 + 3.5
        return Vector2i(floori(logical_x), floori(logical_y))

    func _clamp_pan() -> void:
        var board_size := _board_rect().size
        var scaled := board_size * map_zoom
        var min_offset := Vector2(minf(0.0, board_size.x - scaled.x), minf(0.0, board_size.y - scaled.y))
        var max_offset := Vector2(maxf(0.0, (board_size.x - scaled.x) * 0.5), maxf(0.0, (board_size.y - scaled.y) * 0.5))
        map_pan.x = clampf(map_pan.x, min_offset.x, max_offset.x)
        map_pan.y = clampf(map_pan.y, min_offset.y, max_offset.y)

    func _center_zoom() -> void:
        var board_size := _board_rect().size
        map_pan = (board_size - board_size * map_zoom) * 0.5
    func _can_preview_placement(cell: Vector2i) -> bool:
        return runtime != null and runtime.construction.can_place_at(cell)

    func _is_horizontal_route_cell(cell: Vector2i) -> bool:
        if runtime == null or runtime.map == null:
            return false
        return runtime.map.route_cells.has(cell + Vector2i.LEFT) and runtime.map.route_cells.has(cell + Vector2i.RIGHT)
    func _draw() -> void:
        if is_instance_valid(runtime_overlay):
            runtime_overlay.queue_redraw()

    func _draw_runtime_overlay(canvas: CanvasItem) -> void:
        if runtime == null: return
        var board_size := _board_rect().size
        var cell_size := board_size / 36.0
        var visual_cell_size := minf(cell_size.x, cell_size.y)
        canvas.draw_set_transform(board_origin + map_pan, 0.0, Vector2.ONE * map_zoom)
        if hover_cell.x >= 0 and runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
            var authored_root := authored_map as MapEditorRoot
            var fit_scale := board_size.x / AUTHORED_MAP_SIZE.x
            var authored_hover_rect := authored_root.logical_cell_to_runtime_authored_rect(hover_cell) if authored_root != null else Rect2(Vector2(hover_cell) * cell_size, cell_size)
            var hover_rect := Rect2(authored_hover_rect.position * fit_scale, authored_hover_rect.size * fit_scale)
            var outline_color := Color("ffd477") if hover_can_place else Color("e66b6b")
            canvas.draw_rect(hover_rect.grow(-1.0), outline_color, false, 2.0)
        for gem: GemInstance in runtime.construction.board_gems:
            var p := (Vector2(gem.cell)+Vector2.ONE*0.5)*cell_size
        for cell: Vector2i in runtime.construction.stones:
            var stone_visual := stone_nodes.get(str(cell)) as WorldTextureVisual
            var stone := stone_visual.visual as StoneDecoration if is_instance_valid(stone_visual) else null
            if not is_instance_valid(stone) or stone.texture == null:
                canvas.draw_circle((Vector2(cell)+Vector2.ONE*0.5)*cell_size, maxf(4.0, visual_cell_size * 0.3), Color("8b8f9a"))
        var range_center := Vector2.ZERO
        var range_units := -1.0
        if view.selection.kind == SelectionState.Kind.TOWER:
            var selected_tower := view.selection.value as TowerRuntime
            if selected_tower != null:
                range_center = _world_view_position(selected_tower.position, cell_size)
                range_units = selected_tower.stats.range_units
        elif view.selection.kind == SelectionState.Kind.GEM:
            var selected_gem := view.selection.value as GemInstance
            if selected_gem != null:
                var definition := runtime.foundation.catalog.gem_definition_for_id(selected_gem.id) as GemDefinition
                range_center = (Vector2(selected_gem.cell) + Vector2.ONE * 0.5) * cell_size
                range_units = TowerCombatStats.from_gem(selected_gem, definition).range_units
        if range_units >= 0.0:
            canvas.draw_circle(range_center, maxf(12.0, range_units / 100.0 * visual_cell_size), Color(1.0, 0.82, 0.35, 0.72), false, 3.0)
        for projectile: HomingProjectile in runtime.combat.projectiles:
            _draw_projectile(projectile, cell_size, canvas)
        # Reset the projectile's rotated transform before drawing the impact
        # marker in board coordinates.
        canvas.draw_set_transform(board_origin + map_pan, 0.0, Vector2.ONE * map_zoom)
        var now_ms := Time.get_ticks_msec()
        for index in range(damage_feedbacks.size() - 1, -1, -1):
            var feedback: Dictionary = damage_feedbacks[index]
            var age := (float(now_ms) - float(feedback.get("created_ms", now_ms))) / 1000.0
            if age >= 0.45:
                damage_feedbacks.remove_at(index)
                continue
            var impact_position: Vector2 = feedback.get("position", Vector2.ZERO)
            var impact_point := _world_view_position(impact_position, cell_size)
            var progress := clampf(age / 0.45, 0.0, 1.0)
            var radius := maxf(7.0, visual_cell_size * (0.12 + progress * 0.14))
            var alpha := 0.85 * (1.0 - progress)
            canvas.draw_circle(impact_point, radius, Color(1.0, 0.42, 0.22, alpha), false, maxf(2.0, visual_cell_size * 0.035))
            canvas.draw_circle(impact_point, maxf(2.0, radius * 0.28), Color(1.0, 0.88, 0.48, alpha * 0.9))
        if not damage_feedbacks.is_empty():
            canvas.queue_redraw()
        canvas.draw_set_transform(board_origin + map_pan, 0.0, Vector2.ONE * map_zoom)

    func _draw_projectile(projectile: HomingProjectile, cell_size: Vector2, canvas: CanvasItem) -> void:
        var projectile_point := _world_view_position(projectile.position, cell_size)
        var projectile_size := maxf(12.0, minf(cell_size.x, cell_size.y) * 1.05)
        var frame := int(Time.get_ticks_msec() / 90.0) % 4
        var row := _projectile_color_row(projectile.source_gem_id)
        canvas.draw_set_transform(board_origin + map_pan + projectile_point * map_zoom, projectile.direction.angle(), Vector2.ONE * map_zoom)
        canvas.draw_texture_rect_region(PROJECTILE_TEXTURE, Rect2(Vector2.ONE * projectile_size * -0.5, Vector2.ONE * projectile_size), Rect2(frame * 32.0, row * 32.0, 32.0, 32.0))

    func _projectile_color_row(gem_id: StringName) -> int:
        match view._gem_color_key(gem_id):
            "purple", "lilac": return 1
            "light_green": return 2
            "red": return 3
            "blue", "turquoise", "dark_blue": return 4
            _: return 0
    func _gem_color(gem: GemInstance) -> Color:
        var colors := {&"amethyst":Color("b78cff"),&"aquamarine":Color("68d8e8"),&"diamond":Color("e9f6ff"),&"emerald":Color("55d889"),&"opal":Color("f3a7d8"),&"ruby":Color("ef6262"),&"sapphire":Color("6598ff"),&"topaz":Color("f4c95d")}; return colors.get(gem.id, Color("d99b50"))

class RuntimeOverlay extends Control:
    var map_view: GameplayView.MapDebugView

    func _draw() -> void:
        if map_view != null:
            map_view._draw_runtime_overlay(self)

class WorldTextureVisual extends Node2D:
    var visual: TextureRect

    func attach_visual(value: TextureRect) -> void:
        visual = value
        visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
        visual.custom_minimum_size = Vector2.ZERO
        add_child(visual)

    func set_visual_rect(display_size: Vector2, anchor: Vector2) -> void:
        if not is_instance_valid(visual): return
        visual.size = display_size
        visual.position = -anchor * display_size

class EnemyVisualNode extends Node2D:
    var runtime: GameRuntime
    var view: GameplayView
    var enemy: EnemyRuntime

    func _draw() -> void:
        if runtime == null or view == null or enemy == null or not enemy.is_alive(): return
        var visual_cell_size := 640.0 / 36.0
        var is_boss := runtime.current_wave_is_boss
        var is_invisible := enemy.profile_id == &"invisible_spider_w8" and not is_boss
        var enemy_size := visual_cell_size * (2.4 if is_boss else 1.95)
        var frame := int(Time.get_ticks_msec() / 160) % 3
        var direction := Vector2.ZERO
        if enemy.path_index < enemy.path.size() - 1: direction = enemy.path[enemy.path_index + 1] - enemy.position
        var row := view._enemy_direction_row(direction, is_boss)
        var enemy_sheet := view._enemy_sheet(enemy.profile_id, runtime.current_wave_is_boss)
        var vertical_x_offset := 0.0
        if row == 0:
            vertical_x_offset = -enemy_size * 0.07
        elif row == 3:
            vertical_x_offset = -enemy_size * 0.10
        var feet_offset := enemy_size * (0.03 if is_boss else 0.08)
        var enemy_visual_offset := Vector2(vertical_x_offset, feet_offset)
        # The route art is slightly lower on horizontal segments. Keep the
        # EnemyVisualNode root unchanged so Y-sort and pathfinding still use
        # the exact logical enemy position; only the artwork follows the road
        # surface a little more closely.
        var route_cell := Vector2i(floori(enemy.position.x / 100.0), floori(enemy.position.y / 100.0))
        var on_horizontal_segment := absf(direction.x) > absf(direction.y) and absf(direction.x) > 0.01
        if runtime.map != null and runtime.map.route_cells.has(route_cell + Vector2i.LEFT) and runtime.map.route_cells.has(route_cell + Vector2i.RIGHT):
            on_horizontal_segment = true
        if on_horizontal_segment:
            # Keep the gameplay anchor centered on its logical cell, while
            # lowering only the artwork to sit naturally on horizontal roads.
            enemy_visual_offset.y += enemy_size * 0.28
        if enemy_sheet != null:
            var frame_size := Vector2(enemy_sheet.get_width() / 3.0, enemy_sheet.get_height() / 4.0)
            var sprite_modulate := Color(1.0, 1.0, 1.0, 0.72) if is_invisible else Color.WHITE
            var enemy_rect := Rect2(Vector2(-enemy_size * 0.5, -enemy_size) + enemy_visual_offset, Vector2.ONE * enemy_size)
            draw_texture_rect_region(enemy_sheet, enemy_rect, Rect2(frame * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y), sprite_modulate)
        var health_ratio := clampf(enemy.hp / maxf(enemy.max_hp, 0.001), 0.0, 1.0)
        var is_ghost := enemy.profile_id == &"thrilling_ghost_w40"
        var health_bar_size := 5.0 if is_boss and not is_ghost else 4.0
        var health_bar_color := Color("ffd56a") if is_boss and not is_ghost else (Color("c9c7ff") if is_invisible else Color("e66b6b"))
        var health_bar_rect := Rect2(enemy_visual_offset + Vector2(-enemy_size * 0.42, -enemy_size - health_bar_size - 2.0), Vector2(enemy_size * 0.84, health_bar_size))
        draw_rect(health_bar_rect, Color("3a1820"))
        draw_rect(Rect2(health_bar_rect.position, Vector2(health_bar_rect.size.x * health_ratio, health_bar_size)), health_bar_color)


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

class RestrictedZoneLayer extends Control:
    const GRID_SIZE := 36
    # The kitten spawn remains non-buildable logically, but its portal area
    # keeps the normal terrain tone instead of receiving the gray tint.
    const SPAWN_RESTRICTED_MIN := Vector2i(1, 1)
    const SPAWN_RESTRICTED_MAX := Vector2i(10, 7)
    var runtime: GameRuntime
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
        if runtime == null or runtime.grid == null or visual_board_size <= 0.0: return
        var cell_size := visual_board_size / float(GRID_SIZE) * visual_zoom
        if cell_size <= 0.0: return
        var origin := visual_origin + visual_pan
        var restricted_color := Color(0.16, 0.18, 0.22, 0.24)
        for y in range(GRID_SIZE):
            for x in range(GRID_SIZE):
                var cell := Vector2i(x, y)
                if runtime.grid.is_restricted(cell) and not _is_spawn_zone(cell):
                    draw_rect(Rect2(origin + Vector2(cell) * cell_size, Vector2.ONE * cell_size), restricted_color)

    func _is_spawn_zone(cell: Vector2i) -> bool:
        return cell.x >= SPAWN_RESTRICTED_MIN.x and cell.x <= SPAWN_RESTRICTED_MAX.x and cell.y >= SPAWN_RESTRICTED_MIN.y and cell.y <= SPAWN_RESTRICTED_MAX.y

class MapDecorationLayer extends Control:
    const GRID_SIZE := 36
    # Authored map.tscn owns terrain and environment art. Runtime keeps only
    # the animated checkpoint flags from this layer.
    const ENABLE_PROCEDURAL_ENVIRONMENT := false
    const FENCE_RENDER_LAYER := 6
    const TREE_RENDER_LAYER := 7
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
            if ENABLE_PROCEDURAL_ENVIRONMENT:
                _generate_decorations()
                _generate_border_fences()
                _generate_border_trees()
                _generate_field_trees()
                _generate_background_decorations()
            generated = true
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
                # The spawn and endpoint have dedicated landmarks; only the
                # five intermediate checkpoints use the animated flag tile.
                if point == runtime.map.spawn or point == runtime.map.endpoint: continue
                var key := str(point)
                var waypoint_flag := waypoint_flags.get(key) as FlagDecoration
                if not is_instance_valid(waypoint_flag):
                    waypoint_flag = FlagDecoration.new()
                    waypoint_flag.z_index = 10
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

    func remove_at_cell(cell: Vector2i) -> void:
        _remove_decorations_from_array(decorations, cell, "cell")
        _remove_decorations_from_array(background_decorations, cell, "virtual_cell")
        _remove_decorations_from_array(border_trees, cell, "cell")

    func _remove_decorations_from_array(items: Array[TextureRect], cell: Vector2i, metadata_key: String) -> void:
        for item: TextureRect in items.duplicate():
            if not is_instance_valid(item):
                items.erase(item)
                continue
            var item_cell := item.get_meta(metadata_key, Vector2i(-999, -999)) as Vector2i
            if item_cell != cell:
                continue
            items.erase(item)
            item.queue_free()

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
                if "/trees/" in path:
                    decoration.z_as_relative = false
                    decoration.z_index = TREE_RENDER_LAYER
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
        # Border fences are a foreground edge: they must occlude the castle
        # where the landmark meets the map boundary.
        fence.z_as_relative = false
        fence.z_index = FENCE_RENDER_LAYER
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
        fence.z_as_relative = false
        fence.z_index = FENCE_RENDER_LAYER
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
        var board_size := minf(size.x, size.y)
        var cell_size := maxf(1.0, board_size / float(GRID_SIZE))
        # The board is square and centered. Only the strips outside that
        # square can be visible, so calculate horizontal and vertical margins
        # independently instead of allocating a large square around it.
        var horizontal_margin := maxi(2, ceili(maxf(0.0, size.x - board_size) / (cell_size * 2.0)) + 2)
        var vertical_margin := maxi(2, ceili(maxf(0.0, size.y - board_size) / (cell_size * 2.0)) + 2)
        for y in range(-vertical_margin, GRID_SIZE + vertical_margin):
            for x in range(-horizontal_margin, GRID_SIZE + horizontal_margin):
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
            if entry["category"] == "tree":
                decoration.z_as_relative = false
                decoration.z_index = TREE_RENDER_LAYER
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
        # Tree canopies and trunks remain in front of the border fence.
        tree.z_as_relative = false
        tree.z_index = TREE_RENDER_LAYER
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
        var target_height := cell_size * 1.65 * map_zoom
        var source_size := Vector2(32, 64)
        size = source_size * (target_height / source_size.y)
        position = value_origin + map_pan + (Vector2(cell) + Vector2(0.5, 0.95)) * cell_size * map_zoom - Vector2(size.x * 0.5, size.y)

    func _process(_delta: float) -> void:
        if atlas.atlas == null: return
        var next_frame := int(Time.get_ticks_msec() / 160) % 6
        if next_frame == current_frame: return
        current_frame = next_frame
        atlas.region = Rect2(current_frame * 32, 0, 32, 64)

class StoneDecoration extends TextureRect:
    signal stone_clicked(cell: Vector2i)

    const STONE_TEXTURE_PATH := "res://assets/art/gameplay/environment/stones/petrified_gem_rocks.png"
    const STONE_REGION := Rect2(360, 380, 605, 530)
    const VISIBLE_MAX_FRACTION := 589.0 / 605.0
    var cell := Vector2i(-1, -1)

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var sheet := load(STONE_TEXTURE_PATH) as Texture2D
        if sheet == null:
            push_warning("Stone texture missing: %s" % STONE_TEXTURE_PATH)
            return
        var cropped := AtlasTexture.new()
        cropped.atlas = sheet
        cropped.region = STONE_REGION
        cropped.filter_clip = true
        texture = cropped

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            stone_clicked.emit(cell)
            accept_event()

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
