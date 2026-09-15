class_name ConstructionHarness
extends PanelContainer

var runtime: GameRuntime
var status_label: Label
var select_button: Button
var combine_button: Button
var remove_button: Button
var degrade_button: Button
var last_feedback := ""

func setup(value: GameRuntime) -> void:
	runtime = value
	custom_minimum_size = Vector2(280, 0)
	var panel_style := StyleBoxTexture.new()
	panel_style.texture = load("res://assets/art/gameplay/hud/hud_blue.png")
	panel_style.texture_margin_left = 8.0; panel_style.texture_margin_top = 8.0; panel_style.texture_margin_right = 8.0; panel_style.texture_margin_bottom = 8.0
	add_theme_stylebox_override("panel", panel_style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := Label.new(); title.name = "Title"; column.add_child(title)
	select_button = _button("", _select_final); column.add_child(select_button)
	combine_button = _button("", _combine); column.add_child(combine_button)
	degrade_button = _button("", _degrade); column.add_child(degrade_button)
	remove_button = _button("", _remove); column.add_child(remove_button)
	status_label = Label.new(); status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(status_label)
	runtime.construction.construction_changed.connect(func(_count: int, _total: int): _refresh())
	runtime.construction.gem_placed.connect(func(_gem: GemInstance): _refresh())
	runtime.construction.stone_created.connect(func(_stone: StoneInstance): _refresh())
	runtime.construction.placement_rejected.connect(func(code: StringName, _cell: Vector2i): last_feedback = "Rejected: %s" % code; _refresh())
	runtime.construction.construction_finalized.connect(func(_result: GemInstance): last_feedback = "Construction finalized"; _refresh())
	runtime.construction.selection_changed.connect(func(_gem: GemInstance): _refresh())
	runtime.construction.stone_selected.connect(func(_cell: Vector2i): _refresh())
	LocalizationService.locale_changed.connect(func(_locale: String): _refresh())
	_refresh()

func _button(label_text: String, action: Callable) -> Button:
	var button := Button.new(); button.text = label_text; CursorManager.set_clickable(button); button.pressed.connect(action); return button

func _select_final() -> void:
	if runtime.construction.selected_board_gem != null:
		runtime.construction.keep(runtime.construction.selected_board_gem)
	else:
		last_feedback = "Rejected: select_gem"
	_refresh()

func _combine() -> void:
	var options := runtime.construction.basic_combinations()
	if runtime.construction.selected_board_gem == null:
		last_feedback = "Rejected: select_gem"; _refresh(); return
	for option in options:
		if runtime.construction.selected_board_gem in option.gems:
			runtime.construction.combine_basic(runtime.construction.selected_board_gem, int(option.count)); _refresh(); return
	last_feedback = "Rejected: no_combination"; _refresh()

func _degrade() -> void:
	var selected := runtime.construction.selected_board_gem
	if selected == null:
		last_feedback = "Rejected: select_gem"
	else:
		var result := runtime.construction.degrade(selected)
		if result == null: last_feedback = "Rejected: quality_min"
	_refresh()

func _remove() -> void:
	if runtime.construction.selected_stone_cell.x >= 0: runtime.construction.remove_stone(runtime.construction.selected_stone_cell)
	_refresh()

func _refresh() -> void:
	if status_label == null or runtime == null: return
	var c := runtime.construction
	var phase_key := "game.phase.construction" if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION else "game.phase.combat"
	var phase_text := LocalizationService.tr_key(phase_key)
	status_label.text = LocalizationService.tr_key("game.harness.status", {"gems": c.placed_count(), "stones": c.stones.size(), "phase": phase_text})
	if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
		if c.placed_count() < 5:
			status_label.text += "\n" + LocalizationService.tr_key("game.harness.select_gem")
		elif c.selected_board_gem == null:
			status_label.text += "\n" + LocalizationService.tr_key("game.harness.select_gem")
		elif c.selected_board_gem.quality <= GemInstance.Quality.CHIPPED:
			status_label.text += "\n" + LocalizationService.tr_key("game.harness.degrade_hint")
	if not last_feedback.is_empty():
		status_label.text += "\n" + (LocalizationService.tr_key("game.harness.finalized") if last_feedback == "Construction finalized" else LocalizationService.tr_key("game.harness.rejected", {"code": last_feedback.trim_prefix("Rejected: ")}))
	var title := get_node_or_null("VBoxContainer/Title") as Label
	if title != null: title.text = LocalizationService.tr_key("game.harness.title")
	select_button.text = LocalizationService.tr_key("game.harness.select")
	combine_button.text = LocalizationService.tr_key("game.harness.combine")
	degrade_button.text = LocalizationService.tr_key("game.harness.degrade")
	degrade_button.tooltip_text = LocalizationService.tr_key("game.harness.degrade_hint")
	remove_button.text = LocalizationService.tr_key("game.harness.remove")
	var in_construction := runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION
	select_button.visible = in_construction
	combine_button.visible = in_construction
	degrade_button.visible = in_construction
	remove_button.visible = in_construction
	select_button.disabled = c.placed_count() != 5 or c.selected_board_gem == null
	combine_button.disabled = c.placed_count() != 5 or c.selected_board_gem == null or c.basic_combinations().is_empty()
	degrade_button.disabled = c.placed_count() != 5 or c.selected_board_gem == null or c.selected_board_gem.quality <= GemInstance.Quality.CHIPPED
	remove_button.disabled = not c.stones.has(c.selected_stone_cell)
