class_name ConstructionHarness
extends PanelContainer

var runtime: GameRuntime
var status_label: Label
var x_input: SpinBox
var y_input: SpinBox
var place_button: Button
var keep_button: Button
var combine_button: Button
var remove_button: Button
var degrade_button: Button
var last_feedback := ""

func setup(value: GameRuntime) -> void:
	runtime = value
	custom_minimum_size = Vector2(280, 0)
	var panel_style := StyleBoxTexture.new()
	panel_style.texture = load("res://assets/art/gameplay/hud_blue.png")
	panel_style.texture_margin_left = 8.0; panel_style.texture_margin_top = 8.0; panel_style.texture_margin_right = 8.0; panel_style.texture_margin_bottom = 8.0
	add_theme_stylebox_override("panel", panel_style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := Label.new(); title.name = "Title"; column.add_child(title)
	var coordinates := HBoxContainer.new(); column.add_child(coordinates)
	x_input = _spin("X", coordinates); y_input = _spin("Y", coordinates)
	place_button = _button("", _place); column.add_child(place_button)
	keep_button = _button("", _keep); column.add_child(keep_button)
	combine_button = _button("", _combine); column.add_child(combine_button)
	degrade_button = _button("", _degrade); column.add_child(degrade_button)
	remove_button = _button("", _remove); column.add_child(remove_button)
	status_label = Label.new(); status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(status_label)
	runtime.construction.construction_changed.connect(func(_count: int, _total: int): _refresh())
	runtime.construction.gem_placed.connect(func(_gem: GemInstance): _refresh())
	runtime.construction.stone_created.connect(func(_stone: StoneInstance): _refresh())
	runtime.construction.placement_rejected.connect(func(code: StringName, _cell: Vector2i): last_feedback = "Rejected: %s" % code; _refresh())
	runtime.construction.construction_finalized.connect(func(_result: GemInstance): last_feedback = "Construction finalized"; _refresh())
	LocalizationService.locale_changed.connect(func(_locale: String): _refresh())
	_refresh()

func _spin(label_text: String, parent: Container) -> SpinBox:
	var box := SpinBox.new(); box.name = label_text; box.min_value = 0; box.max_value = GridModel.WIDTH - 1; box.step = 1; box.value = 8 if label_text == "X" else 8; box.custom_minimum_size = Vector2(100, 30); parent.add_child(box); return box

func _button(label_text: String, action: Callable) -> Button:
	var button := Button.new(); button.text = label_text; button.pressed.connect(action); return button

func _cell() -> Vector2i:
	return Vector2i(int(x_input.value), int(y_input.value))

func _place() -> void:
	runtime.construction.place_gem(_cell(), int(runtime.player_state.player_level)); _refresh()

func _keep() -> void:
	if not runtime.construction.current_gems.is_empty(): runtime.construction.keep(runtime.construction.current_gems[0]); _refresh()

func _combine() -> void:
	var options := runtime.construction.basic_combinations()
	if not options.is_empty(): runtime.construction.combine_basic(options[0].gems[0], int(options[0].count)); _refresh()

func _degrade() -> void:
	if not runtime.construction.current_gems.is_empty(): runtime.construction.degrade(runtime.construction.current_gems[0]); _refresh()

func _remove() -> void:
	runtime.construction.remove_stone(_cell()); _refresh()

func _refresh() -> void:
	if status_label == null or runtime == null: return
	var c := runtime.construction
	var phase_key := "game.phase.construction" if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION else "game.phase.combat"
	var phase_text := LocalizationService.tr_key(phase_key)
	status_label.text = LocalizationService.tr_key("game.harness.status", {"gems": c.placed_count(), "stones": c.stones.size(), "phase": phase_text})
	if not last_feedback.is_empty():
		status_label.text += "\n" + (LocalizationService.tr_key("game.harness.finalized") if last_feedback == "Construction finalized" else LocalizationService.tr_key("game.harness.rejected", {"code": last_feedback.trim_prefix("Rejected: ")}))
	var title := get_node_or_null("VBoxContainer/Title") as Label
	if title != null: title.text = LocalizationService.tr_key("game.harness.title")
	place_button.text = LocalizationService.tr_key("game.harness.place")
	keep_button.text = LocalizationService.tr_key("game.harness.keep")
	combine_button.text = LocalizationService.tr_key("game.harness.combine")
	degrade_button.text = LocalizationService.tr_key("game.harness.degrade")
	remove_button.text = LocalizationService.tr_key("game.harness.remove")
	place_button.disabled = not c.can_place()
	keep_button.disabled = c.placed_count() != 5
	combine_button.disabled = c.basic_combinations().is_empty()
	degrade_button.disabled = c.placed_count() != 5
	remove_button.disabled = not c.stones.has(_cell())
