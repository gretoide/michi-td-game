class_name GameplayView
extends Control

var runtime: GameRuntime
var phase_label: Label
var wave_label: Label
var combat_label: Label

func setup(value: GameRuntime) -> void:
	runtime = value
	set_process(true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new(); background.color = Color("152238"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var map_view := MapDebugView.new(); map_view.runtime = runtime; map_view.set_anchors_preset(Control.PRESET_FULL_RECT); map_view.offset_left = 40; map_view.offset_top = 70; map_view.offset_right = -340; map_view.offset_bottom = -70; background.add_child(map_view)
	var hud := PanelContainer.new(); hud.set_anchors_preset(Control.PRESET_TOP_WIDE); hud.offset_left = 20; hud.offset_top = 12; hud.offset_right = -20; hud.offset_bottom = 64; hud.add_theme_stylebox_override("panel", _hud_panel()); background.add_child(hud)
	var hud_row := HBoxContainer.new(); hud_row.add_theme_constant_override("separation", 14); hud.add_child(hud_row)
	phase_label = Label.new(); phase_label.text = LocalizationService.tr_key("game.phase.construction"); phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hud_row.add_child(phase_label)
	wave_label = Label.new(); wave_label.text = LocalizationService.tr_key("game.wave", {"number": 1}); hud_row.add_child(wave_label)
	combat_label = Label.new(); hud_row.add_child(combat_label)
	var locale := LocaleSelector.new(); locale.custom_minimum_size = Vector2(100,38); locale.setup()
	hud_row.add_child(locale)
	var pause := Button.new(); pause.custom_minimum_size = Vector2(42,38); pause.text = "Ⅱ"; pause.tooltip_text = LocalizationService.tr_key("game.pause"); pause.pressed.connect(func(): get_tree().paused = not get_tree().paused); pause.process_mode = Node.PROCESS_MODE_ALWAYS; hud_row.add_child(pause)
	var harness := ConstructionHarness.new(); harness.setup(runtime); harness.anchor_left = 1.0; harness.anchor_right = 1.0; harness.offset_left = -300; harness.offset_top = 76; harness.offset_right = -24; harness.offset_bottom = 450; background.add_child(harness)
	runtime.construction.gem_placed.connect(func(_gem: GemInstance): map_view.queue_redraw())
	runtime.construction.stone_created.connect(func(_stone: StoneInstance): map_view.queue_redraw())
	runtime.construction.construction_changed.connect(func(_count: int, _total: int): map_view.queue_redraw())
	runtime.combat.combat_changed.connect(func(): map_view.queue_redraw())
	runtime.combat.combat_changed.connect(func(): _refresh_combat_label())
	runtime.phases.phase_entered.connect(_on_phase)
	LocalizationService.locale_changed.connect(func(_locale: String): _on_phase(runtime.phases.phase); _refresh_combat_label())
	_refresh_combat_label()

func _process(delta: float) -> void:
	if runtime != null:
		runtime.tick(delta)
		queue_redraw()

func _hud_panel() -> StyleBoxTexture:
	var panel := StyleBoxTexture.new()
	panel.texture = load("res://assets/art/gameplay/hud_blue.png")
	panel.texture_margin_left = 8.0; panel.texture_margin_top = 8.0; panel.texture_margin_right = 8.0; panel.texture_margin_bottom = 8.0
	panel.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	panel.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return panel

func _add_gameplay_sprite(parent: Control, path: String, size: Vector2, region_size: Vector2, position: Vector2) -> void:
	var atlas := AtlasTexture.new(); atlas.atlas = load(path); atlas.region = Rect2(Vector2.ZERO, region_size)
	var sprite := TextureRect.new(); sprite.texture = atlas; sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; sprite.size = size; sprite.position = position; sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(sprite)

func _on_phase(value: GamePhaseMachine.Phase) -> void:
	phase_label.text = LocalizationService.tr_key("game.phase.construction" if value == GamePhaseMachine.Phase.CONSTRUCTION else "game.phase.combat")
	wave_label.text = LocalizationService.tr_key("game.wave", {"number": runtime.phases.wave_number})

func _refresh_combat_label() -> void:
	if combat_label == null or runtime == null or runtime.combat == null: return
	combat_label.text = LocalizationService.tr_key("game.combat.summary", {"towers": runtime.combat.towers.size(), "enemies": runtime.combat.enemies.size(), "projectiles": runtime.combat.projectiles.size()})

class MapDebugView extends Control:
	var runtime: GameRuntime
	const ENEMY_TEXTURE := preload("res://assets/art/gameplay/orc_idle.png")
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and runtime != null:
			var scale_value := minf(get_rect().size.x, get_rect().size.y) / 36.0
			var cell := Vector2i(floori(event.position.x / scale_value), floori(event.position.y / scale_value))
			if runtime.construction.gem_at_cell(cell) != null:
				runtime.construction.select_board_gem(cell)
			else:
				runtime.construction.place_gem(cell, int(runtime.player_state.player_level))
			queue_redraw()

	func _draw() -> void:
		if runtime == null: return
		var area := get_rect().size
		var scale_value := minf(area.x, area.y) / 36.0
		for x in range(37): draw_line(Vector2(x * scale_value, 0), Vector2(x * scale_value, 36 * scale_value), Color(1,1,1,0.12))
		for y in range(37): draw_line(Vector2(0, y * scale_value), Vector2(36 * scale_value, y * scale_value), Color(1,1,1,0.12))
		var points := runtime.map.ordered_waypoints()
		for index in range(points.size()):
			var point := (Vector2(points[index]) + Vector2.ONE * 0.5) * scale_value
			draw_circle(point, 7.0, Color("65d6a6") if index > 0 and index < points.size() - 1 else Color("f2c14e"))
		for gem: GemInstance in runtime.construction.board_gems:
			var gem_point := (Vector2(gem.cell) + Vector2.ONE * 0.5) * scale_value
			draw_circle(gem_point, 9.0, _gem_color(gem))
			draw_circle(gem_point, 11.0, Color(1, 1, 1, 0.8), false, 2.0)
			if gem == runtime.construction.selected_board_gem:
				draw_circle(gem_point, 15.0, Color("fff1a8"), false, 3.0)
		for cell: Vector2i in runtime.construction.stones:
			var stone_point := (Vector2(cell) + Vector2.ONE * 0.5) * scale_value
			draw_circle(stone_point, 8.0, Color("8b8f9a"))
			draw_circle(stone_point, 10.0, Color(0.2, 0.2, 0.25, 0.9), false, 2.0)
		if runtime.combat != null:
			for enemy: EnemyRuntime in runtime.combat.enemies:
				if enemy.is_alive():
					var enemy_point := enemy.position / 100.0 * scale_value
					draw_texture_rect_region(ENEMY_TEXTURE, Rect2(enemy_point - Vector2.ONE * 24.0, Vector2.ONE * 48.0), Rect2(0, 0, 128, 128))
					draw_rect(Rect2(enemy_point + Vector2(-18.0, 20.0), Vector2(36.0, 4.0)), Color("3a1820"))
					draw_rect(Rect2(enemy_point + Vector2(-18.0, 20.0), Vector2(36.0 * enemy.hp / enemy.max_hp, 4.0)), Color("e66b6b"))
			for projectile: HomingProjectile in runtime.combat.projectiles:
				draw_circle(projectile.position / 100.0 * scale_value, 4.0, Color("fff1a8"))

	func _gem_color(gem: GemInstance) -> Color:
		var colors := {&"amethyst": Color("b78cff"), &"aquamarine": Color("68d8e8"), &"diamond": Color("e9f6ff"), &"emerald": Color("55d889"), &"opal": Color("f3a7d8"), &"ruby": Color("ef6262"), &"sapphire": Color("6598ff"), &"topaz": Color("f4c95d")}
		return colors.get(gem.id, Color("ffffff"))
